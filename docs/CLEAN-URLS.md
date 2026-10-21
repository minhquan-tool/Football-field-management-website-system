# Đường dẫn giao diện gọn — 21/10/2026

Ứng dụng hiện phục vụ giao diện tại gốc website, không có /api hoặc .html trên URL trang. API dữ liệu vẫn ở /api/...; không đổi schema/database hoặc nghiệp vụ.

## Địa chỉ sử dụng

- Trang chủ: http://127.0.0.1:8082/trang-chu
- Đăng nhập: http://127.0.0.1:8082/dang-nhap
- Khách: http://127.0.0.1:8082/lich-dat-cua-toi
- Nhân viên/admin: http://127.0.0.1:8082/dieu-phoi-san

| File giao diện giữ nguyên | URL mới |
|---|---|
| Trang_chu.html | /trang-chu |
| Dang_nhap.html | /dang-nhap |
| Dang_ky.html | /dang-ky |
| Man_hinh_chinh_KH.html | /khach-hang |
| Man_hinh_chinh_Dat_san_KH.html | /dat-san |
| Quan_ly_lich_dat_san.html | /dieu-phoi-san |
| Man_hinh_LS&ĐG_KH.html | /lich-su-dat-san |
| Man_hinh_Khuyen_mai_KH.html | /khuyen-mai |
| Tai_khoan_KH.html | /tai-khoan |
| Man_hinh_chinh_NVKH.html | /nhan-vien |
| Lich_da_bong.html | /lich-san |
| Dat_san_tai_quay.html | /dat-san-tai-quay |
| Quan_ly_san.html | /quan-ly-san |
| Man_hinh_chinh_NVKT.html | /hoa-don |
| Hoan_tien_KT.html | /hoan-tien |
| Thanh_toan_VietQR_KT.html | /thanh-toan |
| Bao_cao.html | /bao-cao |
| Man_hinh_chinh.html | /quan-tri |
| Cau_hinh_san.html | /cau-hinh |
| Man_hinh_chinh_TK&PQ_HT.html | /nhan-su-phan-quyen |
| Doanh_thu.html | /doanh-thu |
| Sao_luu.html | /sao-luu |
| Phan_hoi.html | /phan-hoi |

Trang Quan_ly_lich_dat_san.html còn được phục vụ tại /lich-dat-cua-toi, dành riêng cho khách hàng. /dieu-phoi-san dành cho nhân viên/admin. Trang Sao_luu.html vẫn được bảo vệ quyền admin, không thêm lại vào menu.

## Tương thích và bảo mật

- URL cũ dạng /Ten_trang.html và /api/Ten_trang.html chuyển hướng 302 sang URL mới, giữ query date/pitch/booking/payment. Fragment do trình duyệt giữ khi chuyển hướng.
- Liên kết cũ của lịch đặt chuyển sang trang khách nếu người mở đã đăng nhập VT01; các vai trò khác chuyển sang điều phối. Nếu chưa đăng nhập, đăng nhập xong dùng menu đúng vai trò.
- Cấu hình bảo mật áp dụng riêng cho từng URL mới. URL cũ chỉ chuyển hướng; không phục vụ HTML riêng để vượt quyền.
- Chưa đăng nhập mở trang riêng được chuyển tới /dang-nhap; API vẫn trả JSON 401/403. Không dùng chuyển hướng HTML để che lỗi API.
- Cookie phiên mới có Path=/; các trang mới xóa cookie JSESSIONID cũ Path=/api để tránh xung đột. Có thể cần đăng nhập lại sau restart.
- Servlet context cố định ở /; APP_CONTEXT_PATH cũ không còn được sử dụng. Host/port/database vẫn cấu hình qua môi trường.
- /api/health và URL API bên ngoài giữ nguyên như trước; prefix /api hiện được cấu hình ở MVC cho các RestController.
- Không thay đổi giới hạn khách qua Internet/nội bộ; việc này cần triển khai riêng.

## File thay đổi

Backend và vận hành:
- backend/src/main/java/com/sanbong/config/ApiRoutesConfig.java (mới): prefix REST /api.
- backend/src/main/java/com/sanbong/controller/PageController.java (mới): whitelist trang, HTML resources và redirect URL cũ.
- backend/src/main/java/com/sanbong/controller/HomeController.java: / và /api/ về /trang-chu.
- backend/src/main/java/com/sanbong/config/SecurityConfig.java: URL trang, API, login/logout và chuyển hướng theo vai trò.
- backend/src/main/java/com/sanbong/config/LoginRateLimitFilter.java: bảo vệ endpoint /api/auth/login.
- backend/src/main/resources/application.yml: context gốc.
- scripts/server.ps1, scripts/deploy-ui-redesign.ps1, scripts/manage-demo-tunnel.ps1: health, assets và địa chỉ trang demo.
- .env.example, .env.test.example, deploy.env.example và cấu hình local đang chạy: bỏ servlet context cũ.
- README.md: địa chỉ và cấu hình mới.

Frontend: cập nhật liên kết trong các file HTML, menu và các JS điều hướng/auth; giữ nguyên tên file, ID, sự kiện và cấu trúc chức năng. Các module có liên kết được cập nhật:
- frontend/js/admin.js
- frontend/js/auth.js
- frontend/js/booking-policy.js
- frontend/js/bookings.js
- frontend/js/customer-home.js
- frontend/js/dashboard.js
- frontend/js/public-home.js
- frontend/js/public-promotions.js
- frontend/js/reports.js
- frontend/js/role-navigation.js
- frontend/js/staff-operations.js
- frontend/js/weekly-schedule.js

Kiểm thử: cập nhật URL API/trang trong các test Java hiện có. RoleBoundaryTest bổ sung kiểm tra ánh xạ toàn bộ màn hình, redirect cũ, query, quyền và CSRF. Không chạy integration fixture. Tài liệu bổ sung docs/page-route-map.json và tài liệu này.

## Kết quả kiểm tra

- 42 unit/MVC mock đạt: RoleBoundaryTest 7, CancellationRequestTest 13, LoginAttemptLimiterTest 13, BookingTimeDefaultsTest 4, RescheduleTest 5.
- Browser mock cho cả bốn vai trò ở 320/390/768/1440px: trang khách đặt/lịch/lịch sử/khuyến mãi/tài khoản; lịch/điều phối nhân viên; hóa đơn/hoàn/QR/báo cáo của kế toán và admin. Không JS exception, không tràn toàn trang; menu tablet, hiển thị dữ liệu và lỗi API đạt.
- HTTP server thật: 46 redirect URL cũ (23 file × 2 tiền tố) giữ query; toàn bộ URL trang riêng yêu cầu đăng nhập; trang chủ/đăng nhập/đăng ký và tài nguyên công khai 200.
- API CSRF và cookie root đạt; header xóa cookie context cũ đạt; API public/options và health/database UP.
- Cú pháp tất cả JS đạt, 23 file HTML nguồn được giữ nguyên. Build JDK 24 đạt; manifest JarLauncher và tất cả frontend resource đóng gói khớp source.
- Đã chạy bản mới tại cổng 8082. Không triển khai LAN, tunnel, không đẩy GitHub.
- Không thực hiện đặt/hủy sân, thu/hoàn tiền, đổi mật khẩu hoặc thay quyền trên dữ liệu thật để thử. Chưa khẳng định E2E ghi dữ liệu của mọi nghiệp vụ.
