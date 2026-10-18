# Demo HTTPS qua Cloudflare Quick Tunnel

> **Cấu hình direct origin hiện hành:** backend ghim forwarding NONE và từ chối framework/native hoặc header Tomcat chưa review. Header X-Forwarded-For/CF-Connecting-IP do client gửi không được dùng làm IP limiter. Các khách qua tunnel có thể chung loopback IP và ngân sách đăng nhập; chưa có nghiệm thu tách IP hoặc client xa trong đợt mức trung bình. Không bật forwarding để tự khắc phục khi origin vẫn truy cập trực tiếp. Xem [báo cáo/giới hạn proxy](MEDIUM_FIXES_2026-10-17.md).

Mục đích: máy ngoài Wi-Fi/LAN mở bản demo chạy trên máy chủ hiện tại. Không chuyển database lên Internet, không mở port router/SQL và không thay stack/backend.

## Chuẩn bị đã kiểm tra

- Backend cổng 8082 trả HTTP 200 ở /api/health.
- Binary chính thức Windows amd64 ở exports/tunnel-tools/cloudflared.exe, phiên bản 2026.10.1. SHA-256 khớp digest của GitHub release; metadata ở exports/tunnel-tools/download.json.
- Đã kiểm tra CLI hỗ trợ --allowed-mail. Không dùng debug logging để tránh ghi request headers nhạy cảm.
- Backend còn tài khoản demo nên script yêu cầu danh sách email cụ thể. Không khởi chạy công khai nếu thiếu danh sách; không tự đổi mật khẩu demo/khách hàng.

## Bật

Tại thư mục project, backend phải đang chạy:

```powershell
.\scripts\manage-demo-tunnel.ps1 -Action start -AllowedEmail 'email-cua-ban@example.com','email-nguoi-thu@example.com'
```

Thay bằng email thật được phép truy cập. Không dùng địa chỉ ví dụ. Script tạo tiến trình cloudflared ẩn, in đường dẫn https://<random>.trycloudflare.com/api/ và lưu trạng thái ở run/demo-tunnel.json. Không cần quyền Administrator. File run/ và exports/ được .gitignore loại trừ; log/state có thể chứa URL demo nên không chia sẻ toàn bộ.

Người thử mở URL → xác minh email/PIN do Cloudflare cung cấp → đăng nhập tài khoản của ứng dụng. Email vượt cổng tunnel không thay thế phân quyền bốn vai trò của web. Khi nhập email vào Cloudflare, người thử đồng ý dùng Cloudflare làm trung gian cho đường dẫn demo.

## Xem / dừng

```powershell
.\scripts\manage-demo-tunnel.ps1 -Action status
.\scripts\manage-demo-tunnel.ps1 -Action stop
```

Dừng tunnel không dừng backend hoặc SQL Server. Kiểm tra PID, đường dẫn executable và thời điểm tạo trước khi dừng để tránh dừng nhầm tiến trình. Không cài service hoặc tự bật theo Windows. Tắt máy sẽ mất đường hầm; bật lại bằng start và dùng URL mới.

## Kiểm tra từ mạng ngoài

1. Điện thoại tắt Wi-Fi, dùng 4G/5G, hoặc máy ở mạng khác mở URL.
2. Trình duyệt chưa xác thực phải gặp cổng xác minh email; không được vào thẳng web.
3. Email được cho phép nhận PIN và đi tiếp; email ngoài danh sách không được vào.
4. Kiểm tra trang chủ, đăng nhập và xem sân bằng tài khoản đúng vai trò. Không công bố đạt trước khi có kiểm tra client thật.
5. Khi xong buổi demo, chạy stop. URL tạm không còn là đường vào ứng dụng.

## Giới hạn

Quick Tunnel dành cho thử nghiệm, hostname thay đổi mỗi lần tạo, không có cam kết uptime; không thay thế triển khai production. Máy chủ và backend vẫn phải bật. Danh sách email đổi bằng stop rồi start lại. Không mở port SQL 1433; không gửi file .env hoặc credentials database cho người thử. Không đưa password/OTP vào log hay báo cáo.

Nguồn chính thức: https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/ và https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/.

Trạng thái chuẩn bị: công cụ đã tải, hash/version/flag và backend đã kiểm tra; chưa tạo URL, đang chờ email cho phép từ người dùng.
