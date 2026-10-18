# FINAL FIX 03 — F03 Future booking availability

Ngày: 09/10/2026. Chỉ sửa F03; F01/F02 giữ nguyên. **Đã hoàn thành: build, 196 regression, HTTP thật và SQL verification PASS. Chưa deploy/restart internal.**

## Root cause và reproduction trước patch

Đã đọc FINAL_SYSTEM_AUDIT.md, FINAL_FIX01_F02_REPORT.md, FINAL_FIX02_F01_REPORT.md; đối chiếu BookingService/Controller, PitchService, SanRepository, DatSanRepository và OperationsService.

Hai điều kiện sai đều nằm trong BookingService:

- `activePitch`, dùng tại create/confirm, từ chối mọi trạng thái khác Trống mà không xét ngày/giờ yêu cầu.
- `availability` bỏ mọi sân không Trống trước khi xét booking của ngày được tìm.

DatSanRepository.occupied đã lọc đúng NgayChoi và bỏ Đã hủy; overlap dùng `aStart < bEnd && bStart < aEnd`, cho phép sát biên. Không cần sửa query hoặc giá. PitchService bảo trì dùng lock/chặn visit chưa trả và booking active tương lai. OperationsService check-in yêu cầu đúng ngày/cửa sổ thời gian, sân Trống và không có visit mở; checkout giữ rule nhận/trả cùng snapshot F01.

Minimal regression trước patch dùng một sân fixture DEV có trạng thái Đang sử dụng, chưa có booking tương lai: đặt ngày mai 08:00–09:00 phải thành công; availability +30 ngày phải có sân. **2/2 FAIL**: create trả 409 thay vì 200; availability không có sân. Log `run/fix03/red.log`. Test không phụ thuộc clock/mock hoặc lịch hiện có.

## Giải pháp và guard giữ nguyên

Một predicate `bookablePitch` chung chỉ cho hai trạng thái Trống/Đang sử dụng tham gia xét lịch. `activePitch` vẫn báo conflict với Bảo trì và từ chối trạng thái không hoạt động khác. Availability dùng cùng predicate, sau đó vẫn lọc loại sân, status được người dùng yêu cầu và interval overlap.

Trạng thái San không bị sửa về Trống khi đặt/xác nhận tương lai. Response availability vẫn trả trạng thái vận hành thật Đang sử dụng. Nếu caller truyền `status=Trống`, đây vẫn là bộ lọc trạng thái vận hành và sẽ loại sân đang dùng; UI booking hiện tại không truyền bộ lọc đó, không cần đổi HTML/JS.

Create giữ transaction READ_COMMITTED và pessimistic lock San trước overlap/insert. Confirm giữ lock San → DatSan và refresh sau chờ lock. Không đổi khoảng 07:00–22:00, start trong tương lai, end > start, precision theo phút, ownership/permission, maintenance, check-in/check-out hoặc giá/snapshot.

Khoảng hợp lệ muộn hơn trong cùng ngày cũng xét theo lịch thay vì trạng thái hiện tại; overlap vẫn chặn, check-in vẫn chặn visit đang mở. Availability là tra cứu, không giữ chỗ; create luôn kiểm tra lại dưới lock.

## File sửa

| File | Nội dung |
|---|---|
| backend/src/main/java/com/sanbong/service/BookingService.java | Predicate bookablePitch dùng cho create/confirm và availability |
| backend/src/test/java/com/sanbong/FutureBookingAvailabilityTest.java | 15 case mới cho F03 |
| backend/src/test/java/com/sanbong/BookingManagementTest.java | Bổ sung booking overlap cho fixture test cũ về sân đang sử dụng |
| docs/FINAL_FIX03_F03_REPORT.md | Báo cáo này |

**Giải thích test cũ:** `maintenanceAndInUsePitchesCannotBeBooked` trước đây yêu cầu một sân chỉ có trạng thái Đang sử dụng, không có booking overlap, bị loại ở ngày tương lai. Điều này chính là F03, trái yêu cầu mới. Đã giữ nguyên mọi assertion 409/unavailable của test, thêm booking thực trong khoảng được kiểm tra trước khi đổi fixture sang Đang sử dụng. Vì vậy test tiếp tục kiểm tra chặn maintenance/interval conflict, không còn khẳng định sai rằng vận hành hiện tại khóa mọi ngày. Không xóa, skip hoặc giảm số test; test mới chứng minh case không overlap được phép.

So sánh source với snapshot Fix02 chỉ có các file Java trên thay đổi. FinanceService, OperationsService, PasswordPolicy và mọi file F01/F02 không đổi; không sửa UI, Controller/Repository, pom/dependency, environment hay schema. Script HTTP riêng ở `run/fix03`, không là dependency runtime.

## Tests và concurrency

15 case mới:

- Đặt ngày mai khi sân đang sử dụng.
- Availability +30 ngày có sân.
- Xác nhận booking tương lai giữ trạng thái vận hành hiện tại.
- Overlap 08:00–09:00 / 08:30–09:30: unavailable và 409, một booking.
- Sát biên 09:00–10:00 và ngày khác vẫn hợp lệ.
- Bảo trì chặn availability/create/confirm.
- Bộ lọc status và invalid status vẫn đúng.
- Khoảng trống muộn hơn hôm nay không bị status chặn; gần đóng cửa chọn ngày mai vì không còn khoảng hợp lệ hôm nay.
- Năm boundary: trước07:00, sau22:00, start22:00, end=start, end<start đều400 ở create và availability.
- Hai request đồng thời cùng khoảng: một200/một409, đúng một DatSan.
- Hai request đồng thời không overlap: cả hai200, đúng hai DatSan.

Concurrency dùng session riêng, hai thread/latch, không bỏ lock hoặc overlap check. Fixture có ID riêng và marker; cleanup kiểm tra marker/booking note và không có payment trước khi xóa đúng fixture. Global TestDatabaseSafetyListener từ chối environment/database không dev/test.

`mvn -Dtest=FutureBookingAvailabilityTest test`: **15/15 PASS** sau patch. Log `run/fix03/green.log`.

`mvn clean verify`: **196/196 PASS**, failures=0, errors=0, skipped=0. Giữ đủ 181 baseline +15 case F03; F01 CheckoutSnapshotTest và F02 PasswordPolicyTest/PasswordPolicyIntegrationTest tiếp tục PASS. BUILD SUCCESS lúc 06:50:52, thời gian 3 phút 39 giây. Log `run/fix03/verify.log`.

JAR: `releases/san-bong-fix03-f03-20261009.jar`.

SHA-256: `23F6F9C0E9499B4CF7309F89E298CFD3D7B0EB1E3A7C75AE6DA28F6C1ED9965D`.

Startup DEV loopback8082 PASS; JDBC trực tiếp SQL Server và Hibernate ddl-auto=validate PASS. `/api/health` trả database/status UP. Log `run/fix03/startup.log`; đây là JAR có cả hai fix trước, không thay JAR đang chạy internal.

## HTTP và SQL verification

**PASS lúc 06:51 trên JAR mới**, database QuanLySanBong marker dev. Preflight `/admin/test-safety` xác nhận fixtureTestsAllowed=true và database đúng trước tạo fixture. Booking hôm nay 07:00–08:00 được tạo, confirm và check-in thật qua HTTP trong cửa sổ nhận trước30 phút. Không mock clock hoặc INSERT visit để vượt check-in.

| HTTP verification khi sân đang dùng | Kết quả |
|---|---|
| GET pitch sau check-in | Đang sử dụng |
| Availability +30 ngày 08:00–09:00 | Có sân, trả đúng operating status Đang sử dụng |
| Đặt ngày mai 08:00–09:00 | 200 |
| Đặt +30 ngày 08:00–09:00 và confirm | 200; vẫn giữ San Đang sử dụng |
| Availability 08:30–09:30 / tạo overlap | Không có sân /409 |
| Sát biên 09:00–10:00 | Available /200 |
| Check-in booking tương lai ngay hôm nay | 409 |
| Hai request +31 ngày cùng08:00–09:00 | 200/409 |
| Hai request +31 ngày10:00–11:00 và11:00–12:00 | 200/200 |
| Checkout booking hôm nay | 200; San về Trống; invoice DaChot=true, DaThanhToan=0 |
| GET booking +30 sau checkout | Vẫn Đã xác nhận |
| Pitch fixture riêng Bảo trì | Không available; create409 |

SQL sau checkout, trước cleanup: DatSan hiện tại Đã sử dụng; **6 booking tương lai tồn tại**, đúng **1 booking** ở khoảng08:00–09:00 trong race; **0 cặp interval overlap** trên sân fixture; **1 visit đã trả** cho booking hiện tại. Bằng chứng `run/fix03/http.log`, `http-result.json`, `http-state.json`.

Cleanup dùng script guard sẵn `cleanup-phase5-1c-test.sql`, chỉ hai ID/marker HTTP fixture trên DEV. Marker chung của script được tái sử dụng; không đổi script để mở rộng quyền cleanup. SQL sau cleanup: 0 sân/booking HTTP fixture còn lại và 0 sân fixture của test mới. Không giữ booking thử làm lịch/doanh thu giả. Bằng chứng `run/fix03/cleanup-verify.txt`.

## An toàn dữ liệu và regression risk

Không DB migration, schema/reset, không fixture/cleanup/write internal. Build trong thư mục tạm để giữ JAR đang phục vụ. Fingerprint toàn bộ TaiKhoan và DatSan internal trước/sau giống nhau; số dòng HoaDon/ThanhToan/HoanTien/ChiTietDichVu/XacNhanSan không đổi, đều0. Bằng chứng `run/fix03/internal-before.txt` và `internal-after.txt`. Internal vẫn healthUP; không restart hoặc deploy. JVM DEV do lượt kiểm thử này tạo được dừng sau khi hoàn tất.

Regression risk: **MEDIUM**. Booking/xác nhận nay cho phép sân đang dùng nếu lịch hợp lệ; vận hành vẫn kiểm tra visit mở khi check-in. Trạng thái current-use không biểu diễn bảo trì theo lịch tương lai; policy bảo trì toàn sân hiện có giữ nguyên. Không thiết kế hệ thống bảo trì mới trong F03. Kết quả availability có thể thay đổi giữa tra cứu và đặt, create kiểm tra lại dưới lock.

Carry-over nguyên trạng: **F04** khách tại quầy, **F15** dependency BCrypt, **F16** HTTPS/transport, **F21** canonical env/credential. Không làm thêm phase hoặc tuyên bố production-ready.

Không deploy/restart internal; JAR mới chỉ dùng kiểm chứng DEV. Dừng sau khi hoàn tất báo cáo F03.
