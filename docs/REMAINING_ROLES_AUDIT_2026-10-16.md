# Tổng hợp kiểm tra ba nhóm còn lại — 16/10/2026

## Kết quả đã chạy

Lần kiểm tra chung cuối **95 ca, 0 failure, 0 error, 0 skipped**, build JDK 24 thành công (`exports/remaining-roles-final.log`). Có **40 ca mới**: StaffRoleAuditTest 7, AccountantRoleAuditTest 10, AdminRoleAuditTest 23. Những ca khác kiểm tra nhận/trả, dịch vụ, giá sân, đổi lịch, biên quyền và workflow liên quan. Đây là tập chọn của ba nhóm, không phải toàn bộ suite project.

| Nhóm | Đã báo riêng | Phát hiện và xử lý |
|---|---|---|
| Nhân viên sân | Tập 58/58 đạt; 6 menu | Sửa tạo/tra cứu khách tại quầy cho phép điện thoại sai (+ giữa số/toàn +). |
| Kế toán | Tập 15/15 đạt; 2 menu và UI tài chính giả lập | Chưa phát hiện lỗi mới trong các ca chạy. Xác nhận thu nhiều lần, idempotency, chờ/đã thu, chờ/đã hoàn, snapshot, doanh thu và thực nhận, đối soát. |
| Quản lý hệ thống | 23 ca mới đạt; 11 menu; guard/cấu hình trong tập chung | Sửa điện thoại nhân viên và chặn tạo/sửa liên hệ làm trùng định danh đăng nhập của tài khoản khác. Giữ sửa liên hệ của chính người đó và khả năng ngừng fixture có alias legacy trùng. |

Không cộng số ca các đợt riêng thành tổng vì có các ca guard dùng lại. Báo cáo theo nhóm: `STAFF_LOGIC_AUDIT_2026-10-16.md`, `ACCOUNTANT_LOGIC_AUDIT_2026-10-16.md`, `ADMIN_LOGIC_AUDIT_2026-10-16.md`.

## Lỗi và giới hạn được phân biệt

- Các lần FAIL trước sửa được giữ: staff-audit-before.log (3 ca định dạng); admin-audit-reproduced.log (3 ca định dạng); admin-alias-before.log (4 ca xung đột alias). Lần admin đầu có lỗi Map bất biến trong mã chuẩn bị test, đã sửa và không tính là lỗi web.
- Xung đột alias có thể khiến AuthService tìm thấy nhiều tài khoản rồi từ chối đăng nhập bằng phone/email. Bảo vệ mới chạy trong transaction SERIALIZABLE sẵn có, truy vấn parameterized qua Repository; không đổi schema, hash, role/permission hay tự sửa dữ liệu cũ.
- Chưa chạy stress/concurrency nhiều nhân viên/kế toán/quản trị viên đồng thời. Không chạy nguyên các bộ có fixture commit/cleanup ngoài transaction. Không chạy ngân hàng, LAN hoặc backup/restore thật. Web vẫn có hướng dẫn DBA thay vì nút tự restore đè DB.

## An toàn dữ liệu

Đã SELECT marker dev và bật opt-in. Toàn bộ fixture integration trong các lớp chọn có transaction rollback và giữ safety listener. Reset/khóa/đổi vai trò chỉ trên tài khoản fixture, ngoại trừ các request tự khóa admin được kiểm tra bị chặn trước khi ghi. Permission role thử trong transaction rồi rollback. Không DELETE lịch sử hoặc chạy reset database. Browser chỉ đọc, đăng nhập/đăng xuất và giữ audit thật.

Kiểm tra fixture còn lại ghi ở `exports/remaining-roles-fixtures.txt`. Kết quả từng lớp từ XML ở `exports/remaining-roles-test-summary.json`.

## Mã nguồn thay đổi

- `backend/src/main/java/com/sanbong/dto/WalkInCustomerRequest.java`: định dạng điện thoại tại quầy.
- `backend/src/main/java/com/sanbong/service/BookingService.java`: định dạng tra cứu cùng quy tắc.
- `backend/src/main/java/com/sanbong/dto/EmployeeRequest.java`: định dạng điện thoại nhân viên, vẫn hỗ trợ khoảng trắng.
- `backend/src/main/java/com/sanbong/service/AdminService.java`, `repository/AdminRepository.java`: kiểm tra xung đột alias, loại trừ chính nhân viên, email không phân biệt hoa/thường.
- Mới: RoleAuditSupport, StaffRoleAuditTest, AccountantRoleAuditTest, AdminRoleAuditTest và `backend/scripts/employee-role-browser-audit.js`.

## Bằng chứng browser

Ba nhóm có tổng **19 mục menu**, đã kiểm tra ở 1440/1024/768/390px: sidebar nhất quán, đúng mục active (gồm #logs), menu mobile/Escape và logout. Browser không POST nghiệp vụ tài chính hoặc tạo dữ liệu mới. Các bài giả lập finance UI kiểm tra mất response, tải lại lỗi sau khi POST, chuyển booking và giữ key idempotency theo booking.

Log preview theo nhóm `staff-audit-browser.log`, `accountant-audit-browser.log`, `admin-audit-browser.log`; UI tài chính `accountant-ui-regression.log`, `accountant-ui-money.log`. Kết quả bản chính sau cập nhật ghi riêng `remaining-roles-live-VT02.log`, `VT03.log`, `VT04.log` trong exports.

## Bản chạy

Đã xác minh trực tiếp bản chính: VT02 6 menu, VT03 2 menu, VT04 11 menu đều PASS ở bốn viewport, không page error/GET lỗi. Fixture nhân viên/tài khoản/sân/khách của đợt audit còn 0 theo truy vấn kiểm tra. Server preview 8084/fixture 8093 và phiên Playwright đã đóng; bản chính 8082 được giữ chạy.

JAR trước được giữ tại `exports/backend-before-remaining-roles-20261016.jar`. Hash và tiến trình bản mới tại `exports/remaining-roles-deployment.json`. URL sử dụng `http://127.0.0.1:8082/api/`; bản chính được giữ chạy nền sau xác minh. Các server preview/giả lập và phiên Playwright được đóng khi kết thúc.
