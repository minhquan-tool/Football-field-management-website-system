# Nâng cấp giao diện FC-UTE ngày 15/10/2026

## Các phần đã triển khai

| Phần | Thay đổi |
|---|---|
| Giao diện chung | Bảng màu xanh FC-UTE, nền và đường viền thống nhất, chữ/nút/ô nhập đồng bộ, focus bàn phím, trạng thái vô hiệu hóa rõ ràng, giảm chuyển động theo thiết lập thiết bị. |
| Khách hàng | Thẻ sân rõ tên và loại; liên kết chọn sân chuyển đúng mã sân; sân đang chọn có viền và aria-pressed; tổng tiền nổi bật; tiến trình/lịch sử có nhãn trạng thái; nội dung trang chủ phù hợp đặt sân bóng. |
| Nhân viên sân | Trạng thái lượt đặt và sân có nhãn chữ kèm màu; lịch thao tác vẫn dùng các nút theo quyền hiện có; bảng cuộn ngang, hàng việc có khoảng cách và vùng bấm rõ. |
| Kế toán | Chi tiết hóa đơn bổ sung ba ô tiền: đã xác nhận thu, còn thiếu trên hóa đơn, chờ xác nhận hoàn. Chỉ cộng thanh toán Thành công và hoàn Chờ duyệt tương ứng; không suy đoán thực thu từ yêu cầu chờ. Lượt hủy không bị hiển thị thành yêu cầu thu thêm. |
| Điện thoại | Form co theo vùng chứa, bảng có vùng cuộn bằng bàn phím, menu mobile giữ chức năng, hộp thoại giới hạn chiều cao và cuộn nội dung, nhóm tiền xếp dọc. |

Đã bỏ nội dung mẫu “Thành viên Bạc”, dấu số thông báo 1 và lời chào cố định buổi chiều trên trang khách. Đăng xuất được đưa vào menu do role-navigation tạo và vẫn gọi API để hủy phiên. Không thêm màn hình hay nút nghiệp vụ chưa có API.

## File thay đổi

- Mới: `frontend/css/fc-ute.css`, `frontend/js/ui.js`.
- 19 file HTML trong `frontend` được gắn stylesheet/script chung. Hai trang `Man_hinh_chinh_KH.html`, `Man_hinh_chinh_Dat_san_KH.html` điều chỉnh nội dung và vị trí Đăng xuất.
- `frontend/js/bookings.js`: nhãn trạng thái và aria-pressed cho sân được chọn.
- `frontend/js/customer-home.js`, `customer-care.js`, `staff-operations.js`: trình bày thẻ, liên kết sân và nhãn trạng thái.
- `frontend/js/finance.js`: các ô tiền, ẩn/xóa giá trị khi tải booking khác hoặc khi tải lỗi.
- `frontend/js/role-navigation.js`: Đăng xuất trong menu khách hàng.
- Mới: `backend/scripts/ui-browser-check.js`, `ui-money-check.js` để xác minh giao diện.

## Kiểm tra

- JavaScript syntax, liên kết frontend, kiểm tra booking intent: đạt.
- Build Maven/JDK 24 trong thư mục riêng: đạt, xem `exports/ui-build.log`. Không thay Java hay SQL; package dùng skipTests, không khẳng định đã chạy lại toàn bộ test backend.
- Kiểm tra hồi quy bốn vai trò và 25 liên kết menu, báo cáo CSV/in, từ chối sai quyền/dữ liệu: PASS, 0 page error/0 API tải trang lỗi; xem `exports/ui-role-regression.log`.
- Giao diện 25 trang menu ở 390/768/1024/1440px, thêm trang khách vãng lai/đăng nhập/đăng ký và logout menu mobile: xem kết quả cuối `exports/ui-browser-results.log`.
- Kiểm tra giữ sân sau đăng nhập và in/dọn phiếu: `exports/ui-experience-regression.log`.
- Kiểm tra tài chính giả lập: `exports/ui-finance-regression.log`, `ui-money-results.log`; phân biệt thực thu/giao dịch chờ, số còn thiếu và hoàn chờ, giữ idempotency khi mất phản hồi, không giữ tiền của booking cũ khi tải thất bại. Không kết nối DB cho dữ liệu giả lập.
- Ảnh giao diện máy tính/điện thoại được lưu tại `exports/ui-VT01-*`, `ui-VT02-*`, `ui-VT03-*`, `ui-VT04-*` và `ui-booking-detail-mobile.png`; đã xem ảnh khách hàng, kế toán và hộp thoại mobile.

## Bản chạy đã bàn giao

Đã triển khai và kiểm tra trực tiếp tại `http://127.0.0.1:8082/api/`. Kết quả cuối PASS trên 25 trang menu ở 390/768/1024/1440px, 0 page error; xem `exports/ui-live-results.log`. Hash JAR và tiến trình tại `exports/ui-deployment.json`. Bản trước được giữ trong `exports/backend-before-ui-20261015.jar`. Server kiểm tra 8084/8093 và phiên Playwright đã đóng; server 8082 được giữ chạy nền. Có audit đăng nhập/đăng xuất, không tạo hoặc sửa dữ liệu nghiệp vụ.

## Phạm vi còn lại

Đây là nâng cấp cách trình bày và khả năng sử dụng, không thay quy tắc đặt/hủy/thu/hoàn, quyền API, schema, giá lịch sử hoặc mật khẩu. Không thêm dependency. Những hạn chế nghiệp vụ trong báo cáo trước vẫn giữ nguyên. Font/Tailwind/icon vẫn dùng các nguồn CDN hiện có; chưa chuyển sang bản phân phối offline. Kiểm tra responsive là trên trình duyệt tự động với các viewport, chưa phải xác minh LAN hay thiết bị điện thoại thật.
