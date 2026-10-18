# Trang chủ khách vãng lai FC-UTE — 14/10/2026

## Phạm vi được giao

Tham khảo bố cục người dùng gửi, làm trang chủ riêng cho project nhóm; map/chỉ đường tại sân ĐH SPKT TP.HCM; điều hướng chỉ sân bóng; guest search không yêu cầu login; mở link ứng dụng vào trang này trước. Không thêm module ngoài yêu cầu, không sửa UI nghiệp vụ bên trong, schema hoặc chính sách tiền.

## Thực hiện từng bước

| Bước | Thay đổi | Kiểm tra |
|---|---|---|
|1. Giao diện|Trang_chu.html, CSS public-home, SVG sân/bóng local; FC-UTE, một cơ sở, thống kê để API cung cấp; auth.js bỏ auto-login redirect chỉ với body publicPage|Static frontend PASS; package bước1 PASS trong bản sao|
|2. Bản đồ/chỉ đường|venue-map.js, iframe, link Maps, origin nhập hoặc geolocation sau click, fallback khi bị từ chối/timeout|Unit URL PASS; package bước2 PASS; browser thấy map tại tọa độ đúng, denied/granted giả lập PASS|
|3. Điều hướng sân bóng|Tìm sân, bản đồ, loại sân bóng, login/register, chủ sân/nhân viên; bỏ Blog, quảng bá phần mềm, môn khác|Links/static PASS; menu mobile mở/đóng PASS; không mở module chưa có|
|4. Guest search|PublicPitchController → PublicPitchService tái sử dụng PitchService/BookingService; GET options/pitches/availability; tìm tên/mã/loại, ngày và khoảng giờ, giá thật|Package và17unit PASS; anonymous GET thật PASS; private reads và anonymous writes bị chặn|
|5. Entry page|HomeController `/` redirect Trang_chu.html; login và role dashboard cũ giữ route|Package và5routing/service tests PASS; browser `/api/` redirect đúng trang mới|

PublicPitchServiceTest3case và PublicHomeRoutingTest2case là test mới. Với14unit password regression, tổng19case khác nhau đã được chạy trong các bước; không gọi đây là full DB regression. Hai suite bước4/5 chạy lại một số case.

## File thay đổi

- frontend/Trang_chu.html; css/public-home.css; assets/football-field.svg; js/public-home.js; js/venue-map.js (mới).
- frontend/js/auth.js: vẫn cung cấp helper API, nhưng không ép guest page gọi auth/me rồi redirect login.
- backend controller/PublicPitchController.java, service/PublicPitchService.java (mới); controller/HomeController.java; config/SecurityConfig.java.
- tests/PublicPitchServiceTest.java, PublicHomeRoutingTest.java; scripts/venue-map-check.mjs, public-home-browser-check.js (mới).
- Báo cáo này, cây thư mục và README.

Maven vẫn đóng gói frontend vào static. Không thay dependency, không migration/reset/fixture/cleanup DB, không đổi booking-hour/price/legacy/cancellation/payment rules. Public APIs chỉ GET dữ liệu sân/giá; không trả hồ sơ khách, account, booking IDs hay giao dịch. Existing private APIs không được permitAll. Giá/overlap/validation dùng cùng BookingService đã có.

## Bản đồ và vị trí

Điểm đến10.8505572,106.7729939 lấy từ link của người dùng; không tự tạo thêm địa chỉ/số hotline. Dùng [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started) để mở map/directions không cần API key. Google tính đường đi/quãng đường/thời gian trên trang Maps, ứng dụng không bịa ETA hoặc khoảng cách. Không gọi geolocation lúc tải trang; origin chỉ nằm trên trình duyệt và trong link Maps khi người dùng chọn, không gửi/lưu backend.

Browser đã tải iframe và quan sát marker sân. Map phụ thuộc Google/Internet, có link mở Maps khi embed không tải. Geolocation denied/granted được mô phỏng để test; chưa chứng nhận tọa độ thật của máy khách hoặc hướng dẫn điều hướng trên điện thoại thật. HTTP localhost hỗ trợ permission browser; khi triển khai mạng khác cần kiểm secure-context theo môi trường, LAN chưa được triển khai.

## Bằng chứng

- exports/guest-step1-build.log, guest-step2-build.log, guest-step4-build.log, guest-step5-build.log.
- exports/guest-step1-frontend.json, guest-step2-frontend.json, guest-step4-frontend.json.
- exports/guest-home-browser-check.log:7sân catalog,5khả dụng trong khoảng giờ test; root/anonymous access/denied write/error recovery/map/mobile PASS;0pageerror.
- exports/guest-home-desktop.png, guest-home-mobile.png, guest-map-preview.png.

Console có favicon404 từ đường dẫn root ngoài context và503 do test chủ động mock lỗi search; không ghi chúng thành lỗi nghiệp vụ hoặc nói console hoàn toàn sạch. Test không tạo booking/account hoặc fixture DB. Read-only startup/GET không bật migration.

## Chạy và xem bản mới

Bản preview mới đang chạy loopback8083, dùng config DEV hiện có, đã SELECT xác nhận marker dev/test trước startup. Link: **http://127.0.0.1:8083/api/**. Metadata tiến trình: exports/guest-preview-server.json. Bản8082 của người dùng giữ nguyên, nên link8082 vẫn là JAR cũ cho tới khi người dùng build/restart bản đó.

Để chạy bản mới trên8082 sau khi ngừng bản cũ bằng Ctrl+C, có thể đóng gói source với cùng các unit test không dùngDB:

```powershell
mvn.cmd -B -f backend/pom.xml '-Dtest=PublicPitchServiceTest,PublicHomeRoutingTest,BcryptSecurityRegressionTest,PasswordPolicyTest' package
./backend/manage-backend.ps1 -Action run -EnvFile ./.env.test.local
```

JAVA_HOME phải JDK24; config DEV/test thực tế đã xác nhận. Lệnh trên chọn unit/routing tests, không phải fullsuite. Không build đè JAR còn đang chạy. Chưa triển khai LAN/server nội bộ mới hoặc ngân hàng.

## Ý tưởng chờ người dùng duyệt

1. Giữ sân/ngày/giờ đã chọn sau khi khách login rồi đưa vào form đặt sân hiện có.
2. Hiển thị lỗi cụ thể từng ô trong đăng ký để tránh thông báo “dữ liệu không hợp lệ” chung.
3. Thay ảnh minh họa bằng ảnh thực tế từng sân khi nhóm có ảnh được phép dùng.

Chưa triển khai các ý tưởng này. Chỉ làm sau khi người dùng chốt từng mục; không thêm SMS/Zalo/payment gateway/GPS tracking/đa chi nhánh.
