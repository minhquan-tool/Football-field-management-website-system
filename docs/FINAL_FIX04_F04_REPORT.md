# FINAL FIX 04 — F04 Staff create walk-in customer

Ngày: 09/10/2026. Chỉ F04; F01/F02/F03 không thay đổi. **Đã triển khai; 212 regression, HTTP E2E và SQL PASS. Chưa deploy/restart internal. UI/browser thao tác trực tiếp còn checklist thủ công.**

## Root cause/gap và model hiện có

Đã đọc FINAL_SYSTEM_AUDIT và ba báo cáo Fix01–03; đối chiếu BookingController/Service, KhachHang/TaiKhoan model, repository, SecurityConfig/permission, trang quầy và bookings.js. Không có API customer-create phù hợp ngoài registration tạo cả account, nên không tái sử dụng registration.

GET `/booking-customers?phone=...` hiện chỉ tra cứu. Khi chưa tìm thấy, bookings.js báo chỉ đặt cho khách đã có; ô tên readonly, không có create flow. Regression trước patch chứng minh lookup rỗng và POST create **405**, thay vì200: **1/1 FAIL**, `run/fix04/red.log`.

Schema SQL Server thực tế: KhachHang bắt buộc MaKH varchar10, HoTen nvarchar100, SoDienThoai varchar15 và NgayDangKy date; Email/DiaChi/GhiChu nullable. Index **UQ_KhachHang_SDT unique** đã tồn tại. TaiKhoan có FK tùy chọn tới KhachHang, không có FK bắt hồ sơ khách phải có account. DatSan lưu MaKH qua quan hệ khách hiện có. Không cần account, username/password/email hoặc migration.

## API và authorization

Giữ GET lookup; thêm **POST `/booking-customers`** cùng convention booking. Request chỉ hoTen/soDienThoai. Response ApiResponse200 chỉ chứa **maKH, hoTen, soDienThoai**; không trả entity/account/password/hash.

Backend `@PreAuthorize`: ADMIN hoặc PITCH_STAFF **và CN02_THEM** giống quyền lookup/đặt tại quầy. SecurityConfig route hiện có được tái sử dụng; customer/accountant403, anonymous có CSRF hợp lệ401; CSRF writes vẫn enforce. Không dựa vào nút frontend.

DTO trim hai field, tên không blank/tối đa100; SĐT theo chính regex lookup quầy hiện có **[0-9+]{7,15}**, giữ dấu+ và số0 đầu. Không phát minh chuẩn SĐT mới; registration có độ dài9–15 riêng, không sửa registration trong F04. NgayDangKy sinh phía server theo Asia/Ho_Chi_Minh; optional fields không bị ép nhập.

WalkInCustomerService → KhachHangRepository → SQL Server. Tạo khách/audit cùng transaction READ_COMMITTED. Precheck số đã có trả409 thân thiện; nếu race vượt precheck, unique constraint là chốt cuối, existing DataIntegrityViolation handler trả409 và transaction rollback. Không synchronized/global lock. Audit chỉ ghi ID và hành động Tạo hồ sơ khách tại quầy, không ghi dữ liệu cá nhân/password.

Booking vẫn là bước riêng qua BookingService không đổi; lỗi booking không xóa hoặc làm hỏng hồ sơ vừa tạo. Không combined endpoint và không bypass giá/giờ/ownership/overlap/lock/maintenance/F03.

## Frontend flow

Giữ layout/CSS hiện có, tái sử dụng ô SĐT và tên. Tra cứu có khách thì chọn hồ sơ cũ, tên readonly. Nếu lookup thành công nhưng rỗng, mở ô tên tối đa100 và hiện nút Tạo khách nhỏ bên dưới. Sau create thành công, tự chọn MaKH vừa tạo và cho tiếp tục booking, không reload trang.

Hai nút được disable trong request; biến customerBusy chặn double-submit và nút booking cũng bị disable lúc xử lý khách. Tra cứu hiển thị Đang xử lý. Khi SĐT đổi, selection/create mode bị hủy; sequence kiểm tra response cũ để không chọn nhầm khách.

Create409 không báo success: tra cứu lại cùng SĐT; nếu đã có thì chọn hồ sơ tồn tại và hiển thị **Khách hàng với số điện thoại này đã tồn tại**. Nếu lỗi khác hoặc lookup lại thất bại, hiển thị lỗi API, không giả lưu thành công. DOM dùng value/textContent và API same-origin hiện có.

## File thay đổi

| File | Nội dung |
|---|---|
| backend/src/main/java/com/sanbong/controller/BookingController.java | POST booking-customers, method authorization/validation |
| backend/src/main/java/com/sanbong/dto/WalkInCustomerRequest.java | DTO nhỏ, trim và validation |
| backend/src/main/java/com/sanbong/service/WalkInCustomerService.java | Atomic customer create/unique/audit, không account |
| backend/src/test/java/com/sanbong/WalkInCustomerTest.java | 16 case regression F04 |
| frontend/Dat_san_tai_quay.html | ID nút tra cứu và nút Tạo khách nhỏ |
| frontend/js/bookings.js | Lookup/create/loading/duplicate/stale-response flow |
| docs/FINAL_FIX04_F04_REPORT.md | Báo cáo này |

So sánh snapshot Fix03 xác nhận chỉ các source trên đổi. BookingService/F03, FinanceService/OperationsService/F01, PasswordPolicy/F02, schema, dependency/pom, SecurityConfig và runtime env không sửa. Test cũ/expected đều giữ nguyên.

## Tests

`mvn -Dtest=WalkInCustomerTest test`: **16/16 PASS**. Gồm create/trim/lookup/persistence/no account/safe response; admin; duplicate giữ hồ sơ gốc; hai staff cùng SĐT chỉ1row; customer/accountant403; anonymous401; sáu invalid name/phone; missing fields/tên quá dài400; khách mới book đúngMaKH/F03 khi sân đang dùng/overlap409/maintenance409; lỗi audit503 rollback cả hồ sơ.

Test fixture có phone/ID riêng, marker tên/sân và cleanup scoped, global safety listener từ chối internal. Không sửa password/account người dùng hoặc fixtures internal.

`mvn clean verify`: **212/212 PASS**, gồm baseline196 +16 mới; failures=0, errors=0, skipped=0. BUILD SUCCESS lúc16:15:53, thời gian5 phút05 giây. F01 CheckoutSnapshotTest, F02 PasswordPolicyTest/PasswordPolicyIntegrationTest và F03 FutureBookingAvailabilityTest đều PASS; không thay expected hoặc test cũ. Log `run/fix04/verify.log`.

JAR mới: `releases/san-bong-fix04-f04-20261009.jar`.

SHA-256: `DCE664F7580DD8C8CD951CA806AF0407788132820D83976FE77DE72F0DF1481F`.

Startup JAR riêng DEV loopback8082, JDBC trực tiếp và Hibernate ddl-auto=validate PASS; `/api/health` database/statusUP. Log `run/fix04/startup.log`. Build trong TEMP, không ghi đè JAR đang phục vụ internal.

## HTTP E2E và SQL

**PASS trên JAR mới**, database QuanLySanBong có marker dev; preflight `/admin/test-safety` xác nhận fixtureTestsAllowed=true và đúngdatabase trước ghi dữ liệu.

| HTTP E2E | Kết quả |
|---|---|
| Login nhân viên/lookup SĐT fixture chưa có | Thành công/danh sách rỗng |
| POST booking-customers tên+SĐT | 200; nhậnMaKH; response chỉ3field |
| Lookup lại cùngSĐT | ĐúngMaKH vừa tạo |
| Tạo booking/GET chi tiết | 200; đúngMaKH |
| Create lại cùngSĐT | 409; không sửa tên hồ sơ cũ |
| Booking overlap | 409 |
| Customer POST staff-create | 403 |
| Anonymous POST cóCSRF hợp lệ | 401 |
| Hai staff/request cùngracePhone | Một200, một409 |

SQL trực tiếp: **1 KhachHang cho SĐT chính; 1 KhachHang cho SĐT race; 0 TaiKhoan liên kết hai khách; tổng TaiKhoan không đổi; DatSan.MaKH đúng khách mới; 0 orphan**. Chứng cứ `run/fix04/http.log`, `http-result.json`, `http-state.json`.

Cleanup đúng pitch ID/note và hai customer ID/phone/name trên DEV, kiểm dependency trước xóa. Dùng script pitch có guard sẵn và script customer riêng có marker dev/test, identity whitelist, transaction/rollback và từ chối hồ sơ có account/booking/review/feedback. Sau cleanup: 0 customer phone fixture, 0 pitch/booking fixture còn lại. Chứng cứ `run/fix04/cleanup-verify.txt`; script riêng trong run, không migration/runtime component.

## UI verification và manual checklist

`node --check frontend/js/bookings.js` PASS; review luồng DOM/request/loading/stale response. HTTP authenticated trên JAR xác nhận trang quầy chứa đúng bốn ID cho phone/name/lookup/create và JS phục vụ giống source đã sửa (`run/fix04/ui-source-check.log`: PASS). Công cụ browser báo không có browser khả dụng (`getState` rỗng; iab unavailable), vì vậy **chưa xác nhận thao tác UI/browser thực tế**. Kiểm chứng source được phục vụ không thay thế click/type/render thực tế; không ghi UI E2E PASS khi chưa chạy được.

Checklist thủ công trên DEV sau chạy JAR mới:

1. Login nhân viên, mở Đặt sân tại quầy; tìm SĐT khách cũ, kiểm tên readonly và chọn đúng khách.
2. Tìm SĐT mới; nhập tên, Tạo khách; kiểm trạng thái loading/disable và chọn hồ sơ không reload.
3. Chọn ngày/giờ/sân/dịch vụ, tạo booking; lịch/chi tiết hiển thị đúng khách.
4. Hai tab tra cứu cùng số chưa có rồi cùng tạo; tab thua hiển thị thông báo trùng, chọn khách đã có, không báo tạo mới thành công.
5. Đổi SĐT khi request đang chạy; response cũ không chọn lại khách sai. Double-click nút không gửi hai create.
6. Dữ liệu sai/phiên hết hạn/API lỗi không báo thành công; kiểm form customer web và lịch cũ không bị ảnh hưởng.

## Data safety, regression risk và carry-over

Không DB migration/schema/reset. Không fixture, cleanup hoặc write internal. Fingerprint toàn bộ TaiKhoan/DatSan/KhachHang internal trước/sau giống nhau; số dòng HoaDon/ThanhToan/HoanTien/ChiTietDichVu/XacNhanSan không đổi. Chứng cứ `run/fix04/internal-before.txt`, `internal-after.txt`. Server internal vẫnhealthUP, không restart/deploy; patch chưa có hiệu lực trên server đó. JVM DEV của lượt kiểm thử được dừng sau khi hoàn tất.

Regression risk **LOW–MEDIUM**: thêm hồ sơ khách độc lập nên tạo thành công nhưng chưa đặt được có thể để lại khách chưa có booking — đúng thiết kế hai bước, có thể dùng lần sau. Nếu tạo và registration cạnh tranh cùng SĐT, unique constraint đảm bảo chỉ một customer thắng; UI xử lý409. Format SĐT giữ nguyên hạn chế rule lookup cũ, không chuẩn hóa sang chuẩn quốc tế hoặc tự gộp các số khác cách viết. Atomic audit lỗi thì create rollback và cần retry sau khắc phục.

Carry-over **F15 dependency BCrypt, F16 HTTPS/transport, F21 canonical env/credential** không sửa. F01–F03 giữ nguyên và PASS regression đầy đủ. JAR mới chưa deploy internal; dừng sau báo cáo F04, không thêm phase.
