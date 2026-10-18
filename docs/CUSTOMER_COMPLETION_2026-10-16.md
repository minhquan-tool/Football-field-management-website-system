# Hoàn thiện khách hàng — đợt 16/10/2026

## Đã triển khai

1. **Tự đổi mật khẩu tại Thông tin / Phản hồi**: POST /customer/password chỉ cho VT01, bắt buộc CSRF, kiểm tra mật khẩu hiện tại, xác nhận mật khẩu mới, chính sách chung tối thiểu 10 ký tự/tối đa 72 byte UTF-8, không dùng lại mật khẩu hiện tại. Khóa tài khoản bằng PESSIMISTIC_WRITE trong transaction; lưu BCrypt, ghi audit không chứa mật khẩu/hash. Không nhận mã tài khoản đích từ client. Cơ chế credentialFingerprint hiện có loại các phiên cũ ở request kế tiếp, kể cả phiên vừa đổi; UI xóa ô mật khẩu, khóa các form ghi và đưa liên kết đăng nhập lại. Nếu mất phản hồi, hướng dẫn thử đăng nhập mật khẩu mới, không khẳng định đổi thất bại/thành công khi chưa biết.
2. **Lỗi nhập liệu rõ ràng**: API validation trả message và data.fieldErrors, không trả rejectedValue. Đăng ký/hồ sơ hiển thị lỗi ngay tại trường, đánh dấu aria-invalid/aria-describedby và focus trường sai. Tên đăng nhập có hướng dẫn ký tự không dấu; giới hạn điện thoại frontend khớp backend. Lưu hồ sơ thành công cập nhật tên đang hiển thị ở menu.
3. **Lịch sử dễ tra cứu**: giữ lọc trạng thái/từ khóa, bổ sung số lượng kết quả và giải thích không tìm thấy, sắp xếp ngày chơi mới/cũ (kèm giờ). Giữ liên kết chi tiết/hóa đơn và điều kiện đánh giá; không tự suy diễn thực thu từ trạng thái đặt sân.
4. **Chặn form chưa sẵn sàng**: khi tải hồ sơ lỗi, không cho submit mặc định hoặc gửi dữ liệu chưa tải. Lỗi server/mạng không hiển thị thành công giả.

## Kiểm tra thực tế

- Build JDK 24 thành công, 67 ca được chọn trong một lệnh: CustomerCompletionTest 13, CustomerJourneyIntegrationTest 24, AuthenticationTest 7, AdminRoleAuditTest 23. Tất cả 0 failure/error/skipped. Không phải toàn bộ suite của project.
- 13 ca mới kiểm tra hash, phiên cũ ở hai trình duyệt giả lập MockMvc, login cũ/mới, bảo vệ tài khoản khác, sai mật khẩu hiện tại, xác nhận sai, mật khẩu yếu/quá byte, dùng lại mật khẩu, trường trống, CSRF, ba vai trò còn lại bị chặn, thông báo validation và không lộ secrets.
- Lần compile đầu helper customer() trùng kiểu trả về của lớp cha; đổi thành customerSession(), không sửa production để né lỗi test.
- Playwright: 1440/1024/768/390px; hồ sơ khởi tạo 503 bị khóa; xác nhận sai không gửi request; mật khẩu hiện tại sai bị API thật từ chối; lỗi hồ sơ/đăng ký rõ trường; lịch sử lọc/sắp xếp đúng.
- UI thành công đổi mật khẩu và lỗi transport được giả lập bằng route interception để không đổi mật khẩu demo. Luồng đổi mật khẩu thực được kiểm chứng trong integration test rollback.
- Kiểm tra điều hướng 25 lượt mục menu thuộc bốn vai trò, bốn kích thước màn hình: khách vẫn thanh ngang, nhân viên sidebar, duy nhất một mục active, mở/đóng menu điện thoại và đăng xuất đạt, không page error/GET API lỗi trong lượt điều hướng.
- Console có các lỗi 400/503 và transport cố ý từ bài kiểm tra, favicon 404 và cảnh báo Tailwind CDN hiện có; không tuyên bố mọi console entry đều sạch.
- Booking intent regression đạt: giữ lựa chọn sân/giờ và không nhận URL chuyển hướng ngoài.

## An toàn database

Đã SELECT marker SanBongEnvironment=dev trước khi chạy, bật SAN_BONG_TEST_MODE=dev và giữ global safety listener. Cả bốn lớp được chọn đều transactional rollback. Không đổi mật khẩu tài khoản hiện có, không tạo migration/schema/quyền mới, không DROP/reset hoặc sửa dữ liệu demo sai dấu. Audit đăng nhập/đăng xuất browser là thao tác thật và được giữ lại.

## File thay đổi

- backend/src/main/java/com/sanbong/dto/CustomerPasswordRequest.java (mới), RegisterRequest.java.
- backend/src/main/java/com/sanbong/repository/TaiKhoanRepository.java: khóa khi tự đổi mật khẩu.
- backend/src/main/java/com/sanbong/service/AuthService.java: nghiệp vụ tự đổi mật khẩu khách.
- backend/src/main/java/com/sanbong/controller/CustomerCareController.java, ApiExceptionHandler.java.
- frontend/Tai_khoan_KH.html, Dang_ky.html; frontend/js/auth.js, customer-care.js.
- backend/src/test/java/com/sanbong/CustomerCompletionTest.java (mới).
- backend/scripts/customer-completion-browser.js (mới).

## Bằng chứng và bản chạy

- exports/customer-completion-build.log, customer-completion-package.log.
- exports/customer-completion-browser-preview.log, customer-completion-navigation-preview.log.
- exports/customer-completion-test-summary.json: tổng hợp XML 67 ca.
- exports/customer-completion-deployment.json: hash, PID và xác minh bản chính sau khi cập nhật.
- exports/backend-before-customer-completion-20261016.jar: bản sao JAR trước cập nhật.
- exports/customer-completion-profile.png: kiểm tra bố cục trang hồ sơ.

## Còn lại, không coi là đã hoàn thành

- Quên mật khẩu qua email/SMS: chưa có kênh gửi và xác minh liên hệ. Cần thiết kế token một lần có thời hạn và cấu hình kênh gửi; không reset chỉ bằng việc biết số điện thoại/email. Hiện nút này chưa được kích hoạt.
- Ghi nhớ đăng nhập dài hạn chưa triển khai; phiên hiện tại vẫn hết hạn sau 30 phút không hoạt động. Không lưu mật khẩu trong localStorage/cookie để giả lập chức năng.
- Thanh toán ngân hàng thật, kiểm thử tải/đặt trùng đồng thời, phân trang lịch sử quy mô lớn, offline hoàn toàn và thiết bị/LAN thật chưa được chứng nhận trong đợt này.
- Dữ liệu tên/địa chỉ demo đã sai encoding vẫn giữ nguyên; dữ liệu Unicode đăng ký mới đã được kiểm tra riêng.

## Xác nhận bản chính
Đã cập nhật bản chính cổng 8082. Cả hai lượt Playwright trên bản chính đạt: chức năng khách hàng mới và 25 mục điều hướng bốn vai trò. Năm truy vấn fixture còn lại đều bằng 0 (exports/customer-completion-fixtures.txt). Hash/PID bản chạy và bản sao trước cập nhật ghi trong customer-completion-deployment.json. Không cần build lại để dùng bản đã cập nhật; sau khi tắt máy vẫn phải khởi động backend lại.

