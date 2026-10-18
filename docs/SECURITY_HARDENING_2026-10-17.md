# Bổ sung bảo mật và bằng chứng phân quyền — 17/10/2026

> **Đợt mức trung bình mới nhất:** SanBongApp đã bỏ db_datareader/db_datawriter, dùng whitelist25bảng/3view/hàm. Guard forwarding giữ chế độ direct, chặn cấu hình tin header chưa review. Môi trường fixture có login/database riêng, không truy cập chéo với database nguồn trong cặp đã kiểm tra. Chi tiết và giới hạn tại [báo cáo mức trung bình](MEDIUM_FIXES_2026-10-17.md).

> **Cập nhật mới:** Yêu cầu sửa nhóm cao ngày17/10 đã cho phép áp dụng ProtectAuditPermissions_20261017.sql. Đã DENY UPDATE/DELETE audit cho SanBongApp; INSERT/SELECT giữ nguyên. Probe SQL thực tế và hồi quy nghiệp vụ đạt. Các đoạn “đang chờ duyệt/chưa áp dụng” dưới đây mô tả thời điểm trước yêu cầu mới. Xem [kết quả CNPM/DBMS](KE_HOACH_SUA_LOI_CNPM_DBMS_2026-10-17.md).

## Chức năng mới

Giới hạn thử đăng nhập sai được thực hiện ở backend, áp dụng bốn vai trò và cả tên không tồn tại. Mặc định một cặp IP/tên đăng nhập được sai 5 lần trong cửa sổ 300 giây; IP có tổng ngân sách 30 lần sai trong cùng cửa sổ để hạn chế đổi username/email/điện thoại liên tục. Hết ngân sách, request tiếp theo trả HTTP 429, Retry-After và data.retryAfterSeconds. Không đổi trạng thái tài khoản SQL hay mật khẩu người dùng.

Chuỗi filter: CSRF → LoginRateLimitFilter → kiểm tra mật khẩu Spring Security. Thiếu CSRF không tiêu hao ngân sách. Có reservation trước khi chạy BCrypt để nhiều request đồng thời không cùng vượt ngưỡng. Kết thúc request luôn giải phóng reservation; chỉ lỗi thông tin xác thực/trạng thái tài khoản mới tăng bộ đếm. Đăng nhập thành công xóa số lần sai của đúng cặp, không xóa tổng lần sai của IP. Lỗi hạ tầng không bị cộng như sai mật khẩu; HTTP lỗi hạ tầng đăng nhập hiện vẫn dùng thông báo chung của handler sẵn có.

Tên đăng nhập được trim và chuyển chữ thường để khớp chính sách login; IP lấy getRemoteAddr(), không tin X-Forwarded-For hoặc CF-Connecting-IP do client tự gửi. Bộ nhớ chỉ chứa digest của khóa IP/cặp, số đếm và thời hạn; không chứa mật khẩu hay username/IP nguyên văn. Tối đa 10.000 mục, thu hồi mục hết hạn, từ chối request tạo mục mới nếu hết dung lượng, không đẩy mục đang bị chặn ra để mở đường vượt giới hạn.

UI đăng nhập hiển thị lỗi bền vững và đếm ngược trên nút khi nhận 429. Nút tự mở lại khi hết hạn; sửa JavaScript hoặc tải lại trang không bỏ được kiểm tra backend. Không lưu mật khẩu hoặc trạng thái xác thực dài hạn vào localStorage.

## Cấu hình

Các biến tùy chọn trong .env.example và application.yml:

| Biến | Mặc định |
|---|---:|
| APP_LOGIN_LIMIT_PER_IDENTIFIER | 5 |
| APP_LOGIN_LIMIT_PER_IP | 30 |
| APP_LOGIN_LIMIT_WINDOW_SECONDS | 300 |
| APP_LOGIN_LIMIT_MAX_ENTRIES | 10000 |

Thay cấu hình cần khởi động lại backend. Giá trị không hợp lệ làm startup thất bại, không tự tắt bảo vệ. Không đổi file môi trường bí mật hiện có để chạy thử ngưỡng thấp.

## Phân quyền phục vụ báo cáo CNPM

| Phạm vi | Khách hàng | NV sân bóng | Kế toán | Quản lý |
|---|---|---|---|---|
| Hồ sơ/tự đổi mật khẩu khách | Chính mình | Không dùng API khách | Không dùng API khách | Không dùng API khách |
| Lượt đặt, dịch vụ, lịch | Lượt của mình, thao tác theo trạng thái | Vận hành nhận/trả sân và dịch vụ | Xem thông tin qua nghiệp vụ tài chính được cấp | Vận hành/quản lý theo quyền |
| Ghi nhận thu/hoàn nội bộ | Gửi yêu cầu, không tự xác nhận thực thu | Ghi nhận/xác nhận tiền mặt; không xác nhận chuyển khoản hoặc hoàn tiền | Đối chiếu thu/hoàn theo quyền và trạng thái | Đối chiếu thu/hoàn theo quyền và trạng thái |
| Nhân viên/tài khoản/phân quyền | Không | Không | Không | Vai trò quản trị và permission tương ứng |
| Nhật ký hệ thống | Không | Không | Không | Tra cứu; API không có thao tác xóa |

Backend kiểm tra cả role, permission, ownership và trạng thái nghiệp vụ. Ẩn menu chỉ là hỗ trợ giao diện. Hash BCrypt, CSRF, kiểm tra phiên theo credentialFingerprint, khóa/reset tài khoản và nhật ký nghiệp vụ hiện có được giữ nguyên.

## Phát hiện SQL cần xử lý riêng

SELECT quyền thực tế của SanBongApp ngày 17/10 cho thấy:

| Quyền | Giá trị |
|---|---:|
| sysadmin | 0 |
| db_owner | 0 |
| BACKUP DATABASE | 0 |
| UPDATE dbo.NhatKyHeThong | 1 |
| DELETE dbo.NhatKyHeThong | 1 |

Vì vậy API chặn xóa nhật ký chưa có nghĩa tài khoản database không xóa được. Đã tạo **đề xuất** database/migrations/ProtectAuditPermissions_20261017.sql: chỉ DENY UPDATE/DELETE nhật ký cho runtime user, giữ INSERT/SELECT và bảng nghiệp vụ; không xóa bản ghi, đổi schema hay mật khẩu. Có guard đúng database và marker dev/test. Đang chờ người dùng duyệt trước khi thực thi.

Các test concurrency cũ có cleanup DELETE audit không được dùng với runtime đã chặn quyền; phải tách tài khoản/database fixture phù hợp, không cấp lại quyền sửa/xóa nhật ký chỉ để làm test đạt. Trước thay quyền, DBA lưu quyền trực tiếp và các role hiện tại để lập kế hoạch rollback; không GRANT lại quyền rộng một cách tự động. Tài khoản backup/restore tiếp tục tách khỏi runtime web.

## Kiểm chứng và file

- Unit: LoginAttemptLimiterTest kiểm tra ngưỡng/hết hạn đúng biên, chuẩn hóa, đổi danh tính/IP, thành công không xóa ngân sách IP, 12 luồng tranh reservation, giải phóng idempotent, dung lượng và cấu hình sai.
- MVC: LoginRateLimitHttpTest dùng chuỗi Spring Security thật và user mock, không có database. Kiểm tra 429/Retry-After trước khi gọi authentication, header giả không vượt, thiếu CSRF, context path, thành công và lỗi hạ tầng. Slice test không dùng datasource nên không bỏ guard của các integration test có dữ liệu.
- Chạy cùng AuthenticationTest, RoleBoundaryTest, CustomerCompletionTest, CustomerJourneyIntegrationTest, AdminRoleAuditTest. Các integration test có dữ liệu giữ DEV/test marker và transaction rollback.
- Lần chạy đầu có một lỗi setup Mockito khi ghi đè stub vốn ném UsernameNotFoundException; sửa bằng doThrow().when(), không đổi production để né bài test. Log trước sửa: exports/login-security-before.log.
- Browser: backend/scripts/login-security-browser.js dùng tên không tồn tại riêng, không dò mật khẩu thật hay đổi mật khẩu demo. Thử sai thật 5 lần, lần 6 bị chặn; reload/header giả không vượt. Đếm ngược ngắn 2 giây được giả lập riêng tại UI. Test các menu bốn vai trò sau thay đổi mã gọi API dùng chung.
- Code: LoginAttemptLimiter.java, LoginRateLimitFilter.java, SecurityConfig.java, application.yml; frontend/js/auth.js, frontend/Dang_nhap.html; .env.example. Hai lớp test mới và script browser mới. Không thêm dependency/framework hay đổi schema.

Bằng chứng: exports/login-security-build.log, login-security-test-summary.json, login-security-sql-permissions.txt, login-security-browser-preview.log, login-security-navigation-preview.log. Bản chính/backup/PID/hash được ghi ở login-security-deployment.json sau khi cập nhật.

## Giới hạn cần trình bày đúng

Đây là bộ giới hạn trong bộ nhớ cho một server hiện tại: restart xóa bộ đếm, không bảo vệ nhiều node hoặc tấn công phân tán hoàn chỉnh. Username/email/điện thoại có thể là các cặp riêng, ngân sách IP là lớp hạn chế bổ sung. Người dùng chung NAT/proxy có chung ngân sách IP; Cloudflare Tunnel hiện chuyển về loopback nên các lượt qua tunnel có thể chung IP. Không bật tin header proxy khi origin vẫn truy cập trực tiếp từ LAN; cấu hình proxy tin cậy phải được đánh giá riêng. Không coi tính năng này là thay cho HTTPS, mật khẩu mạnh, khôi phục mật khẩu có xác minh hoặc kiểm thử tải thực tế.

## Kết quả build và browser
Lệnh Maven package cuối đạt 91 ca trong 7 lớp, 0 failure/error/skipped; trong đó 20 ca mới. Đây là tập kiểm tra chọn cho thay đổi, không phải toàn bộ project. Browser bản xem trước đạt kiểm tra 5 lần sai thật/lần 6 bị chặn, header giả/reload không vượt, đếm ngược ngắn giả lập và đăng nhập tài khoản khác. Lần browser đầu dừng vì script đợi menu desktop visible sau khi đã đổi viewport sang 390px (menu mobile đang đóng); đã sửa script quay về desktop trước khi kiểm tra, không thay production để làm test đạt. Log đầu lưu ở login-security-browser-before.log. Điều hướng 25 mục bốn vai trò ở 1440/1024/768/390px đạt.


## Bản chính
Đã cập nhật cổng 8082 và xác minh qua browser: chống dò mật khẩu/đếm ngược và 25 mục điều hướng đều đạt. Bốn truy vấn fixture còn lại bằng 0, không đổi mật khẩu tài khoản thật. Backend vẫn giữ cấu hình LAN. Metadata hash/PID/backup ở exports/login-security-deployment.json, log browser có hậu tố -live. SQL ProtectAuditPermissions vẫn chưa áp dụng do đang chờ người dùng duyệt; quyền UPDATE/DELETE audit hiện chưa được coi là đã khắc phục. Hạn chế đúng hai quyền đó không nằm trong kết quả 91 test ứng dụng.

