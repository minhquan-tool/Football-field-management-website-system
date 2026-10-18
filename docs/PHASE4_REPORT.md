# Phase 4 — Tra cứu sân trống, đặt sân, lịch đặt sân

**CODE COMPLETE / AWAITING MANUAL UI VERIFICATION** — 2026-10-02.
Người dùng xác nhận Phase 1–3 đã kiểm tra. Chỉ kiểm tra dependency của Phase 4;
không audit lại project, không thay framework/version, không đổi schema/seed hoặc dùng SqlProxy.
Giữ bố cục/sidebar/card, màu và CSS hiện có. Thay nội dung mô phỏng bằng dữ liệu API,
khóa phạm vi dịch vụ/tài chính/giao sân bằng thông báo chưa triển khai. Chưa chuyển Phase 5.

## A. File tạo mới

Các file Java dưới `backend/src/main/java/com/sanbong/`:

- `dto/BookingRequest.java`, `BookingCancelRequest.java`, `BookingView.java`, `AvailableSlot.java`.
- `repository/KhungGioRepository.java`, `BookingWorkflowRepository.java`.
- `service/BookingService.java`, `BookingNotFoundException.java`.
- `controller/BookingController.java`.
- `backend/src/test/java/com/sanbong/BookingManagementTest.java`, `BookingConcurrencyTest.java`.
- `frontend/js/bookings.js`.
- `backend/scripts/phase4-http-check.mjs`, `cleanup-phase4-test.sql`.
- `docs/PHASE4_REPORT.md`.

## B. File chỉnh sửa

- `AGENTS.md`: phạm vi Phase 4 và dừng trước Phase 5.
- `backend/src/main/resources/application.yml`: lịch ngày lễ qua môi trường.
- `config/SecurityConfig.java`: API booking cho CUSTOMER/PITCH_STAFF/ADMIN, lịch cho khách hàng;
  giữ nguyên các cổng phân quyền API sân/administration của Phase 2–3.
- `controller/ApiExceptionHandler.java`: 404 booking/slot, 400 date/query sai, 409 lock conflict.
- `repository/DatSanRepository.java`: query booking chiếm slot theo ngày, khóa booking và specification.
- `repository/KhachHangRepository.java`: tra cứu khách có sẵn theo đúng số điện thoại.
- `frontend/Dat_san_tai_quay.html`, `Man_hinh_chinh_Dat_san_KH.html`, `Quan_ly_lich_dat_san.html`:
  vùng dữ liệu thật, form/API, trạng thái loading/error; bỏ script và dữ liệu booking/giá mô phỏng.
- `frontend/js/auth.js`: cho phép riêng các trang Phase 4 đã nối API; giữ chặn demo ở trang khác.
- `backend/README.md`: hướng dẫn API, giá, test và checklist.

## C. API endpoint

Tất cả dưới context path cấu hình (hiện `/api`). Trả `ApiResponse` Phase 2.

| Method | Endpoint | Chức năng |
|---|---|---|
| GET | `/booking-options` | Sân, loại sân, khung giờ, trạng thái, ngày server; khách hàng của tài khoản CUSTOMER |
| GET | `/booking-customers?phone=...` | Nhân viên/quản lý tìm khách có sẵn theo số điện thoại chính xác |
| GET | `/availability?date=...&type=...&slot=...&status=...` | Slot tương lai còn trống, sân Trống, có bảng giá hiệu lực |
| GET | `/bookings?date=...&pitch=...&slot=...&status=...` | Lịch theo ngày và filter; CUSTOMER chỉ có booking của mình |
| GET | `/bookings/{id}` | Chi tiết, snapshot tiền đã lưu |
| POST | `/bookings` | Tạo booking Chờ xác nhận, không thu tiền |
| POST | `/bookings/{id}/confirm` | Xác nhận booking chờ, nhân viên/quản lý |
| POST | `/bookings/{id}/cancel` | Hủy booking tương lai chưa thanh toán |

Body tạo: `maSan`, `ngayChoi` ISO date, `maKhungGio`, `maKH` cho nhân viên, `ghiChu` tùy chọn.
CUSTOMER lấy MaKH từ TaiKhoan trong SQL; mã khách khác bị 403. Giá/tổng tiền/trạng thái
gửi thêm từ client không được sử dụng. Body hủy chỉ có `lyDo`; không nhận tỷ lệ hoàn tiền.
401 chưa đăng nhập, 403 role/permission/ownership/CSRF, 400 validation/date sai,
404 sân/slot/booking không tồn tại, 409 trùng/bảo trì/giá/trạng thái/lock conflict,
503 lỗi database và 500 lỗi nội bộ. Frontend chỉ báo thành công sau response thành công;
không đưa stack trace ra client.

## D. Schema và query đã đối chiếu

`DatSan` thực tế: MaDatSan varchar(10); FK MaKH→KhachHang, MaSan→San,
MaKhungGio→KhungGio, MaKM→KhuyenMai, MaNV→NhanVien; NgayChoi date;
ThoiLuong decimal(4,2); DonGia/TienSan/TienDichVu/TienGiam/TongTien decimal(18,2);
NgayDat datetime; TrangThai nvarchar(20); GhiChu nvarchar(255).
Trạng thái CHECK: **Chờ xác nhận, Đã xác nhận, Đã sử dụng, Đã hủy**.

Index thật `UX_DatSan_KhongTrungLich` UNIQUE `(MaSan,NgayChoi,MaKhungGio)`
WHERE `TrangThai <> N'Đã hủy'`; giữ nguyên. KhungGio có giờ bắt đầu/kết thúc,
ThoiLuong và CHECK giờ kết thúc > giờ bắt đầu. Không có trigger trên DatSan;
trigger cập nhật tiền hiện nằm trên ChiTietDichVu và không được gọi ở Phase 4.

`V_KhungGioTrong` thật chỉ CROSS JOIN San/KhungGio, bỏ sân bảo trì;
không kiểm tra ngày hoặc booking. **Không dùng và không sửa view**.
Repository `occupied(date,cancelled)` đọc booking không hủy theo đúng ngày, trạng thái
truyền bằng bind parameter Unicode. Service so thời gian giao nhau của slot để lọc và
kiểm tra lại khi tạo; không dùng SQL literal tiếng Việt không có Unicode như lỗi Phase 3.
Lịch dùng Specification filter ngày/sân/slot/trạng thái/owner; sắp giờ rồi mã sân/booking.

## E. Business rules

- Ngày chơi từ hôm nay, bắt đầu khung giờ phải ở tương lai theo Asia/Ho_Chi_Minh;
  giới hạn năm trong phạm vi SQL Server. Lịch được xem cả ngày quá khứ.
- Sân phải **Trống**; Bảo trì/Đang sử dụng bị loại khỏi tra cứu và từ chối khi đặt/xác nhận.
- Sân, slot, khách phải tồn tại; không tự tạo khách hoặc tài khoản mới trong booking.
- Booking không hủy chiếm slot theo ngày, kể cả Đã sử dụng (nhất quán filtered index).
  Backend còn chặn hai khung giờ khác mã nhưng giao nhau trên cùng sân/ngày.
- Tạo luôn Chờ xác nhận; xác nhận chỉ từ Chờ xác nhận, chỉ trước giờ chơi.
- Hủy chỉ Chờ xác nhận/Đã xác nhận, trước giờ chơi và đúng quyền/owner.
  Booking có ThanhToan Chờ xử lý hoặc Thành công bị chặn hủy, giữ nguyên dữ liệu để
  Phase 5 xử lý tài chính. Không tạo hoàn tiền giả hoặc đánh dấu tiền đã hoàn.
- Hủy ghi HuyDatSan thật với lý do, người hủy suy ra từ role, TiLeHoan/SoTienHoan=0;
  đổi DatSan→Đã hủy, giữ lịch sử, cho phép đặt lại slot qua filtered index.
- Không có API DELETE booking, check-in/giao sân hoặc tự chuyển Đã sử dụng ở Phase 4.

## F–G. Chống trùng và transaction

Tạo/xác nhận/hủy dùng transaction READ_COMMITTED và khóa pessimistic write trên
**San trước, DatSan sau**. Tạo kiểm tra availability lại sau khóa, không tin query trước
đó ở UI. Khóa San dùng chính `SanRepository.lockById` Phase 3, phối hợp với bảo trì.
Sau khi chờ khóa, transition refresh entity để không dùng trạng thái cũ trong persistence
context. Giữ unique index làm lớp bảo vệ cuối cùng. Trùng/lock conflict trả 409.

DatSan, HuyDatSan và NhatKyHeThong cùng transaction qua JPA/JdbcTemplate;
bất kỳ bước nào lỗi đều rollback. Test riêng transaction độc lập chứng minh audit thất bại
sau flush tạo không để lại booking; audit thất bại lúc hủy không để lại HuyDatSan/trạng thái hủy.
Payment guard dùng UPDLOCK/HOLDLOCK. Phase 5 phải tuân thủ cùng thứ tự khóa khi xử lý tiền.

## H. Giá tại thời điểm đặt

- Chọn BangGia đúng loại sân + slot + LoaiNgay, NgayHieuLuc ≤ NgayChoi ≤ NgayHetHieuLuc
  (hoặc không có ngày hết). Từ chối khi không có giá hoặc có nhiều dòng chồng hiệu lực.
- Thứ Bảy/Chủ Nhật dùng Cuối tuần; ngày khác dùng Ngày thường. Ngày lễ cấu hình bằng
  `APP_BOOKING_HOLIDAYS=yyyy-MM-dd,yyyy-MM-dd`, ưu tiên Ngày lễ so với cuối tuần.
  Calendar mặc định rỗng; người triển khai phải cấu hình ngày lễ thực tế. Không tự suy đoán
  ngày nghỉ/bù hoặc fallback từ giá lễ/cuối tuần sang giá thường.
- DonGia là giá cho **cả khung giờ**, giữ cách dùng dữ liệu thực tế DS01/DS02:
  ThoiLuong=1.5, DonGia=250000/300000, TienSan=250000/300000.
  Không nhân 1.5 thêm lần nữa. Lưu DonGia/ThoiLuong/TienSan/TongTien tại thời điểm đặt.
- Phase 4: TienDichVu=0, TienGiam=0, MaKM=null, TongTien=TienSan.
  Đổi BangGia về sau không đổi booking cũ; regression test đã kiểm chứng.
- SQL hiện thiếu nhiều giá cuối tuần và chưa có giá lễ; slot không có giá không hiện
  là slot đặt được. Không bổ sung giá vào database khi chưa có quyết định nghiệp vụ.

## I–J. Authorization và logging

| Thao tác | CUSTOMER | PITCH_STAFF / ADMIN | ACCOUNTANT |
|---|---|---|---|
| Tra cứu/options | CN02_XEM | CN02_XEM | Không |
| Lịch/chi tiết | CN02_XEM, chỉ của mình | CN02_XEM | Không |
| Tạo | CN02_THEM, chỉ cho mình | CN02_THEM, khách có sẵn | Không |
| Xác nhận | Không | CN02_SUA | Không |
| Hủy | CN02_SUA, chỉ của mình | CN02_SUA | Không |
| Lookup khách | Không | CN02_THEM | Không |

Tái sử dụng session/CSRF và reload permission Phase 2; không có role/permission/schema mới.
Tạo, xác nhận, hủy ghi `SecurityRepository.audit` vào NhatKyHeThong (ChucNang=Đặt sân)
và SLF4J với booking/pitch/account ID. Không tạo hệ thống nhật ký khác.

## K. Build/test

`clean verify`: **37 tests, 0 failures, 0 errors, BUILD SUCCESS**.
Gồm AuthenticationTest 7, PitchManagementTest 6, SqlServerConnectionTest 1,
BookingManagementTest 19, BookingConcurrencyTest 4. Spring Boot/JDBC/Hibernate validate
startup thành công. Sau chỉnh text/phone UI cuối, kiểm tra syntax và package lại thành công,
không thay code backend và không chạy lại test đã đạt. Backend hiện chạy bản JAR cuối.
HTTP read cuối với cả nvsan và khachhang đã xác nhận trang đóng gói/lịch trả 200,
options đọc 7 sân/5 slot, KH01 đúng account và slot S04/KG01 ngày 2026-10-05 giá 150000.
Startup cuối 9,582 giây, Tomcat 8080 `/api`, PID 14392; không có startup error.

| Yêu cầu | Kết quả |
|---|---|
| 1. Tra cứu sân trống | PASS SQL thật, ngày/loại/slot/options |
| 2. Sân đã đặt không trả là trống | PASS; không ảnh hưởng ngày kế tiếp |
| 3. Loại sân bảo trì | PASS, thêm cả Đang sử dụng |
| 4. Tạo hợp lệ | PASS, SQL snapshot/audit, không tạo ThanhToan |
| 5. Sân không tồn tại | PASS 404 |
| 6. Slot không tồn tại | PASS 404 |
| 7. Ngày/giờ sai | PASS 400; quá khứ, giờ đã bắt đầu, date malformed/thiếu |
| 8. Đặt trùng | PASS 409; unique index còn nguyên |
| 9. Hai request cạnh tranh | PASS 200 + 409, đúng một booking; cả MockMvc và HTTP hai session |
| 10. Giá đúng | PASS giá SQL, snapshot không đổi, client không tự chọn tiền/trạng thái |
| 11. Chưa login | PASS 401 read; mutation thiếu CSRF bị 403 |
| 12. Thiếu quyền/role | PASS 403; accountant, quyền bị thu hồi, khách đặt/xem/hủy hộ |
| 13. Lịch theo ngày | PASS filters/owner |
| 14. Chi tiết | PASS, missing 404; fresh read SQL |
| 15. Hủy hợp lệ | PASS HuyDatSan/Đã hủy, slot đặt lại được |
| 16. Hủy không hợp lệ | PASS 409: Đã sử dụng, quá giờ, có tiền; không tạo record hủy |
| 17. Rollback | PASS tạo/hủy khi audit thất bại sau flush |
| Giá lễ/cuối tuần/thiếu/hết/chồng giá | PASS |
| Slot giao nhau khác mã | PASS 409 |
| Race xác nhận/hủy | PASS, trạng thái cuối Đã hủy, không bị xác nhận lại |
| JavaScript syntax/HTML nesting/ID | PASS ba trang, auth.js/bookings.js |
| Browser render/click/F5 | **PENDING**, browser tool trả danh sách rỗng |

Test đầu có một assertion đọc JSON Unicode sai encoding; đã dùng UTF-8 tường minh,
không sửa nghiệp vụ/dữ liệu để làm test pass. Build clean ban đầu gặp JAR bị khóa bởi
backend Phase 3; dừng đúng tiến trình đó rồi build lại thành công.

HTTP thật tạo sân riêng `P4H2229BD`, ngày 2026-10-19, ba booking thử:
DS11f11f90/DS7a3259b5 giá 150000 tại KG01; DSf9ec61ed giá 200000 tại KG02.
Đối chiếu SQL được 3 booking Đã hủy, 3 HuyDatSan không hoàn tiền, 7 nhật ký booking,
0 ThanhToan. Cleanup exact ID/marker/state/history đã xóa đúng dữ liệu này.
Lần cleanup đầu thiếu QUOTED_IDENTIFIER cho filtered index nên transaction rollback;
đã bổ sung các SET session bắt buộc và chạy lại thành công. Không thay index/schema.
Sau cleanup: **7 sân, 2 booking, 11 giá, 0 hủy, 4 tài khoản**, test row/journal còn 0;
DS01/DS02 giữ ngày 2026-10-01, giá/tổng 250000/230000 và 300000/300000.
Giữ sân `s08` và trạng thái S03 Bảo trì do người dùng có trước test.
Nhật ký đăng nhập/đăng xuất test giữ lại; test integration có rollback hoặc cleanup fixture riêng.

Log và kết quả local: `backend/target/phase4-build.log`, `surefire-reports/`,
`phase4-startup-final.log`, `phase4-http-state.json`; target không đưa vào source control.

## L. Checklist UI thủ công — còn chờ

Server hiện http://127.0.0.1:8080/api. Không mở LAN.
Nếu server chưa chạy: đặt JAVA_HOME và cấu hình DB trong môi trường hoặc `.env`,
chạy `backend/manage-backend.ps1 run` từ root. Không cần thao tác SQL Server/SSMS cho Phase 4.
Không hiển thị lại password trong checklist; dùng thông tin đăng nhập mẫu đã cung cấp.

1. **A — Login:** mở http://127.0.0.1:8080/api/Dang_nhap.html, dùng `nvsan`
   (PITCH_STAFF), hoặc `admin`. Mong đợi đăng nhập thành công/profile đúng.
2. **B–D — Tra cứu/chọn:** mở **hai tab**
   http://127.0.0.1:8080/api/Dat_san_tai_quay.html.
   Ở cả hai tab: nhập SĐT khách hiện có `0987654321`, nhấn **Tra cứu**;
   chọn ngày **2026-10-05** (Thứ Hai), loại **Sân 5 người**, sân **S04**, khung
   **KG01 06:00–07:30**. Nếu slot bị người khác chiếm, dừng test và báo lại;
   không đổi/hủy booking hiện có. Mong đợi giá từ API **150.000đ cho 1,5 giờ**.
   Điền ghi chú `Phase4 manual UI test` ở cả hai tab; giữ tab B chưa submit.
3. **E — Tạo:** tab A nhấn **TẠO PHIẾU ĐẶT SÂN**. Mong đợi mã DS mới, Chờ xác nhận,
   tổng 150.000đ, chưa thanh toán. Ghi lại mã booking để báo kết quả.
4. **F–G — Lịch/F5:** bấm **Xem lịch đặt sân**, hoặc mở
   http://127.0.0.1:8080/api/Quan_ly_lich_dat_san.html?date=2026-10-05&pitch=S04.
   Nhấn **Chi tiết**, kiểm tra ngày/sân/giờ/khách/giá. F5: booking vẫn còn đúng dữ liệu.
5. **H — Trùng:** quay tab B đã chọn slot trước bước E, nhấn **TẠO PHIẾU ĐẶT SÂN**.
   Mong đợi lỗi sân đã đặt, không có phiếu thứ hai; UI tra cứu lại và bỏ slot đã chiếm.
   Có thể xem Network để xác nhận POST trả **409**. Không refresh tab B trước thử này.
6. **Workflow:** tại lịch tab A nhấn **Xác nhận**, đồng ý hộp xác nhận; booking trở thành
   Đã xác nhận. F5 và Chi tiết vẫn đúng. Nút này chỉ dành nhân viên/quản lý đủ quyền.
7. **I–J — Hủy/F5:** bấm **Hủy** đúng mã DS test, điền lý do `Phase4 manual UI test`,
   nhấn **Xác Nhận Hủy**. Mong đợi Đã hủy, không ghi thanh toán/hoàn tiền. F5 vẫn Đã hủy;
   tra cứu lại sân/slot được giải phóng. Giữ lịch sử hủy, không xóa bằng API.
8. **CUSTOMER:** đăng xuất, dùng `khachhang`, mở
   http://127.0.0.1:8080/api/Man_hinh_chinh_Dat_san_KH.html và lịch cùng ngày.
   Mong đợi profile/khách của tài khoản, chỉ booking KH01, không có nút xác nhận;
   SQL/API chống truy cập booking người khác đã được test backend.

Checklist có hiệu lực trước 06:00 ngày 2026-10-05 theo giờ Việt Nam. Nếu kiểm tra sau đó,
chọn một ngày Thứ Hai tương lai có giá/slot còn trống, ghi rõ ngày mới trong phản hồi.
Để chốt DoD, báo A–J PASS/FAIL, mã DS thử và lỗi thực tế nếu có.

## M. Technical debt / giới hạn

- Browser chưa khả dụng: không tuyên bố PASS HTML→JS→API→SQL→UI/F5 chỉ dựa vào API test.
- CN02 hiện gộp quyền sân/booking như Phase 3; chưa tách permission mới.
- Lịch ngày lễ cần cấu hình môi trường; giá lễ/cuối tuần thiếu cần quyết định chủ sân,
  không tự tạo giá/schema. Khi chồng giá, hiện từ chối thay vì tự ưu tiên một dòng.
- Chỉ đặt cho khách có sẵn; đăng ký CUSTOMER Phase 2 vẫn dùng được. CRUD khách/vãng lai riêng
  chưa thuộc phạm vi này. Một số tên khách trong SQL đang có lỗi encoding từ dữ liệu trước;
  UI phản ánh dữ liệu thật, không tự viết lại tên khách.
- San Đang sử dụng bị chặn toàn bộ ngày; cần workflow nhận/trả sân ở phase vận hành để cập nhật
  đúng trạng thái. Hiện không có trạng thái check-in mới ngoài CHECK của SQL.
- Query đọc occupancy theo ngày, phù hợp quy mô app nội bộ; pagination/tối ưu khi dữ liệu lớn
  là phần sau khi có tải đo được, không thêm framework trong Phase 4.
- Payment writers ở Phase 5 phải khóa booking theo cùng thứ tự và kiểm tra trạng thái đã hủy;
  không được coi payment guard hiện tại là một hệ thống hoàn tiền hoàn chỉnh.

## N. Chuyển sang Phase 5 (chưa thực hiện)

Dịch vụ phát sinh, khuyến mãi nếu cần, hóa đơn, thanh toán, hoàn tiền, đối soát;
workflow vận hành/giao sân và tài chính cho booking đã đến giờ hoặc đã thanh toán.
Quản lý nhân viên/báo cáo doanh thu chưa làm. Dừng Phase 4 tại kiểm thử UI, không tự triển khai Phase 5.
