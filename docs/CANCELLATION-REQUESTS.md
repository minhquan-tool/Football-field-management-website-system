# Yêu cầu hủy đặt sân — đã kích hoạt ngày 21/10/2026

## Cách sử dụng
1. Khách hàng mở Lịch đặt của tôi, chọn Yêu cầu hủy và nhập lý do trước giờ chơi.
2. Yêu cầu chuyển sang Chờ duyệt hủy. Booking giữ nguyên trạng thái/chiếm chỗ; chưa tạo HuyDatSan hoặc HoanTien.
3. Kế toán/chủ sân thấy bộ đếm trên menu Hoàn tiền và danh sách Yêu cầu hủy đặt sân ở đầu trang. Bộ đếm cập nhật khi vào trang, quay lại cửa sổ hoặc mỗi 60 giây khi trang hiển thị; có nút Tải lại. Đây là thông báo trong ứng dụng, không gửi email/push.
4. Chọn Xem & xử lý, nhập ghi chú và duyệt hoặc từ chối.
5. Duyệt: transaction hủy booking và tạo các khoản hoàn chờ xác nhận theo thực thu, nếu số hoàn lớn hơn 0. Từ chối: giữ booking, ghi lý do để khách xem.
6. Sau khi thực sự trả tiền, kế toán xác nhận khoản hoàn riêng. Duyệt hủy không xác nhận đã chuyển tiền cho khách.

## Quy tắc
- Chỉ khách hàng sở hữu booking được gửi yêu cầu. Kế toán/admin cần CN04_SUA và hồ sơ nhân viên đang hoạt động để xử lý.
- Tỷ lệ hoàn lấy từ fn_TyLeHoan tại thời điểm gửi và lưu trong yêu cầu. Không giảm tỷ lệ vì kế toán xử lý chậm.
- Số hoàn khi duyệt = thực thu ròng hiện tại × tỷ lệ đã lưu, làm tròn 2 chữ số, không vượt thực thu. Chưa xác nhận tiền chuyển khoản không tính vào thực thu.
- Ví dụ lúc gửi thực thu 100.000đ, tỷ lệ 50%: ước tính 50.000đ. Nếu khi duyệt thực thu ròng là 200.000đ thì số hoàn là 100.000đ; tỷ lệ vẫn 50%.
- Booking đã nhận sân/hoàn thành/đã hủy không được duyệt hủy. Yêu cầu đã gửi trước giờ chơi vẫn có thể được duyệt sau giờ bắt đầu nếu chưa nhận sân; giữ tỷ lệ lúc gửi.
- Khi có yêu cầu PENDING, chặn đổi lịch, nhận sân và hủy trực tiếp. Nhân viên cần đề nghị kế toán/chủ sân xử lý yêu cầu trước.
- Khóa San -> DatSan chung với các nghiệp vụ khác, re-read trạng thái sau khóa. Unique filtered index chỉ cho một yêu cầu PENDING/booking. Retry cùng quyết định không tạo thêm hủy/hoàn; quyết định đối nghịch bị từ chối.
- Khách xem lịch sử yêu cầu của chính tài khoản; trang kế toán hiển thị hàng đợi chờ duyệt. Lịch sử xử lý lưu trong bảng mới và nhật ký.
- Giữ các snapshot/hủy/hoàn legacy; không tự tạo yêu cầu từ các booking đã hủy trước đây.

## Database và triển khai
Người dùng đã cho phép thêm bảng và bật luồng mới trong phiên làm việc này.
- Đã sao lưu COPY_ONLY,CHECKSUM và RESTORE VERIFYONLY trước migration. File backup ở thư mục mặc định SQL Server, biên nhận trong run/backup-receipts. Không thực hiện phục hồi.
- Đã áp dụng database/migrations/CancellationRequests_20261021.sql: thêm bảng, FK, check constraints, unique pending index và indexes hàng đợi/khách hàng. Không backfill hoặc sửa dữ liệu cũ.
- Đã áp dụng database/migrations/CancellationRequests_20261021_Permissions.sql: SELECT/INSERT/UPDATE bảng mới cho các vai trò runtime hiện có, không cấp DELETE hoặc quyền quản trị.
- File CancellationRequests_20261021_PROPOSAL.sql là bản đề xuất lịch sử, không dùng để triển khai.
- Build JDK 24; JAR mặc định giữ Spring Boot JarLauncher và chứa đủ source frontend mới. Server localhost:8082 đã khởi động và health UP.

## File thay đổi của phần này
Backend:
- backend/src/main/java/com/sanbong/controller/CancellationRequestController.java (mới)
- backend/src/main/java/com/sanbong/service/CancellationRequestService.java (mới)
- backend/src/main/java/com/sanbong/repository/CancellationRequestRepository.java (mới)
- backend/src/main/java/com/sanbong/service/BookingService.java
- backend/src/main/java/com/sanbong/service/OperationsService.java
- backend/src/main/java/com/sanbong/service/FinanceService.java
- backend/src/test/java/com/sanbong/CancellationRequestTest.java (mới)
- backend/src/test/java/com/sanbong/RoleBoundaryTest.java
- backend/src/test/java/com/sanbong/RescheduleTest.java
Database: hai migration đã nêu ở trên.
Frontend:
- frontend/Quan_ly_lich_dat_san.html
- frontend/Hoan_tien_KT.html
- frontend/js/cancellation-requests.js (mới)
- frontend/css/cancellation-requests.css (mới)
- frontend/js/bookings.js
- frontend/js/finance.js
- frontend/js/role-navigation.js
- frontend/css/fc-ute.css
Tài liệu: docs/CANCELLATION-REQUESTS.md.

## Kiểm tra
- 33 unit/MVC mock đạt: CancellationRequestTest 13; RoleBoundaryTest 5; RescheduleTest 5; AccountingReadModelTest 4; ReservationPaymentAmountsTest 4; StaffTransferRequestTest 2.
- Browser mock: khách hàng/kế toán/admin ở 320/390/768/1440px; không tràn toàn trang, không JS exception; form bắt buộc ghi chú, mở form không duyệt, gửi một lần và tải lại hàng đợi; API lỗi hiện lỗi.
- Hồi quy lịch và điều phối nhân viên sân: cùng bốn kích thước, menu tablet, khoảng giờ tự do và trạng thái lỗi đạt.
- Đối chiếu schema thật, tất cả FK/check của bảng mới được bật và trusted; tài khoản runtime SELECT repository/phân trang đạt, quyền INSERT/UPDATE được kiểm tra bằng HAS_PERMS_BY_NAME, không ghi dữ liệu thử.
- Không chạy fixture/cleanup hoặc tạo booking/yêu cầu hủy/thu/hoàn tiền thật để kiểm thử trên DB internal. Chưa có E2E ghi dữ liệu trên DB kiểm thử riêng.
- VietQR vẫn cần xác nhận thực nhận/chi thực tế, không bổ sung webhook ngân hàng trong phần này.
