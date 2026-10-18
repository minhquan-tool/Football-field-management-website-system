# Tài nguyên giao diện phục vụ local

Không dùng CDN khi mở các trang nghiệp vụ. CSS Tailwind được biên dịch trước, không chạy compiler trong trình duyệt. Bản đồ/chỉ đường Google Maps vẫn cần Internet khi người dùng mở chức năng đó.

- Tailwind CSS3.4.17: https://github.com/tailwindlabs/tailwindcss/releases/tag/v3.4.17 — compiler Windows x64 chỉ dùng lúc build, không đóng gói vào web. MIT license ở tailwind/LICENSE.txt. Cấu hình frontend/tailwind.config.cjs quét cả HTML và JavaScript để giữ các lớp của form render động.
- Font Awesome Free6.0.0: https://github.com/FortAwesome/Font-Awesome/tree/6.0.0 — giữ bộ font/icon và LICENSE.txt hiện có.
- Montserrat variable normal: https://github.com/google/fonts/tree/main/ofl/montserrat — giữ OFL.txt, hỗ trợ tiếng Việt. Hash file cục bộ được ghi trong asset-manifest.json.
- Logo HCMUTE: lưu lại đúng URL Wikimedia vốn được HTML tham chiếu; xem nguồn trong asset-manifest.json. Không thay logo/biểu tượng của trường.
- Ảnh nền HCMUTE cũ trả HTML thay ảnh. Các trang liên quan tái sử dụng assets/football-field.svg đã có trong project.

Build lại CSS khi sửa lớp HTML/JS: scripts/build-frontend-css.ps1 -CompilerPath <đường dẫn compiler3.4.17 đã kiểm tra>. JAR/runtime không cần Node, npm hoặc compiler Tailwind. Không sửa trực tiếp css/tailwind.css.
