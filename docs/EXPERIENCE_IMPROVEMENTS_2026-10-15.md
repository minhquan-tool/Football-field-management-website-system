# Cải tiến trải nghiệm FC-UTE ngày 15/10/2026

## Phần đã thực hiện

1. Khách vãng lai chọn kết quả sân trống rồi đăng nhập: giữ mã sân, ngày, giờ và loại sân. Liên kết sang đăng ký và quay về đăng nhập cũng giữ lựa chọn. Chỉ khách hàng được chuyển sang form đặt sân; nhân viên/kế toán/quản lý về đúng màn hình riêng. Chỉ nhận các bộ lọc có định dạng hợp lệ, không nhận URL chuyển hướng tùy ý. Server tra cứu lại lịch trống và giá; lựa chọn không giữ chỗ và không cam kết giá cũ.
2. Lịch sử lượt đặt có tìm mã/tên sân, lọc trạng thái và tiến trình Đã đặt → Đã xác nhận → Đã sử dụng/trả sân; hủy hiển thị riêng. Không suy đoán khách đã nhận sân hay đã thanh toán từ trạng thái xác nhận. Chi tiết/hóa đơn vẫn dùng chức năng hiện có.
3. Bảng điều khiển nhân viên có Việc cần xử lý hôm nay: chờ xác nhận và đã xác nhận, sắp theo giờ bắt đầu, đi thẳng đến chi tiết đúng lượt đặt. Có nút tải lại; không tự xác nhận/nhận/trả sân. Ngày khác tiếp tục tra cứu qua Lịch đặt.
4. Chi tiết lịch đặt có In / Lưu PDF phiếu đặt sân. Tải lại lượt đặt và dòng dịch vụ từ API trước khi in, dùng DOM textContent để xử lý tên/nội dung an toàn; lỗi tải không gọi in. Phiếu có mã, khách, sân/giờ, trạng thái, tiền sân/dịch vụ/giảm/tổng và thời điểm tra cứu. Ghi rõ không phải hóa đơn/biên nhận. In xong loại bản in khỏi DOM. Lưu PDF qua hộp thoại in của trình duyệt, không bổ sung dependency.
5. Có kịch bản demo bốn vai trò và danh sách minh chứng CNPM/DBMS tại `docs/DEMO_4_VAI_TRO.md`.

## File nguồn thay đổi

- `frontend/js/auth.js`, `public-home.js`, `bookings.js`: tiếp tục lựa chọn sau đăng nhập, giữ mã lượt đặt trong liên kết chi tiết.
- `frontend/Dang_nhap.html`, `Dang_ky.html`: chuyển hướng và giữ lựa chọn.
- `frontend/js/customer-care.js`: tiến trình, tìm kiếm và lọc lịch sử.
- `frontend/js/staff-operations.js`: danh sách việc hôm nay.
- `frontend/js/booking-receipt.js` và `frontend/Quan_ly_lich_dat_san.html`: phiếu in.
- `backend/scripts/booking-intent-check.cjs`, `experience-browser-check.js`: kiểm tra riêng cho cải tiến.
- Hai tài liệu trong thư mục `docs`.

## Kiểm chứng

- `node --check` các file JavaScript và `phase7-frontend-check.mjs`: đạt.
- `booking-intent-check.cjs`: đạt kiểm tra giữ lựa chọn, tách vai trò, loại bộ lọc sai và URL ngoài.
- Maven/JDK 24 package trong `exports/experience-build`: build đạt. Đợt này không sửa Java, SQL, quyền DB hoặc schema; không chạy lại toàn bộ 112 test backend của đợt trước. Build dùng skipTests, không ghi là test suite đã chạy.
- Playwright trên cổng preview 8084: giữ lựa chọn qua đăng ký/đăng nhập, tra cứu lại và chọn đúng sân, lọc lịch sử với hai lượt hiện có, chuẩn bị phiếu in đúng mã, CSS in không đưa nút thao tác vào phiếu, nhân viên không rơi vào form khách, giao diện 390px không tràn ngang. Không tạo booking/thu/hoàn mới. Có audit đăng nhập thật.
- Kiểm tra hồi quy bốn vai trò, 25 menu: đạt, không page error và không API tải trang thất bại; xem `exports/experience-role-regression.log`.
- Kết quả kiểm tra cuối trên cổng 8082 ghi tại `exports/experience-live-results.log`; build tại `exports/experience-build.log`.

Đã cập nhật JAR chính và xác nhận luồng mới trực tiếp tại `http://127.0.0.1:8082/api/`. Kết quả cuối PASS, 0 lỗi JavaScript, không ghi nghiệp vụ. Kiểm tra cả dọn phiếu sau in và in bình thường khi không có phiếu. Bản trước được giữ tại `exports/backend-before-experience-20261015.jar`; hash và tiến trình bản mới ở `exports/experience-deployment.json`. Server preview đã dừng; server 8082 được giữ chạy nền.

## Giới hạn và phần tiếp theo

- Lựa chọn được truyền trong URL; không lưu qua việc đóng trình duyệt hoặc đổi thiết bị. Nếu sân vừa được người khác đặt, form sẽ tra cứu lại và bỏ chọn sân không còn trống.
- Tiến trình chưa có bước nhận sân riêng hoặc trạng thái tài chính tổng hợp trong thẻ lịch sử; các dữ liệu đó vẫn xem ở chi tiết. Danh sách việc chưa phân nhóm nhận/trả theo thời điểm thực tế, không có nhắc việc tự động.
- PDF cần người dùng chọn Lưu dưới dạng PDF trong hộp thoại in. Không tạo hóa đơn thuế, ký số hoặc gửi chứng từ tự động.
- Kịch bản demo là tài liệu hướng dẫn, không phải khẳng định đã tạo đủ dữ liệu giao dịch để trình diễn.
- Các giới hạn trước về xóa loại sân, backup/restore qua web, đổi sân sau thu tiền, ngân hàng và LAN vẫn giữ theo `docs/ROLE_WORKFLOW_REVIEW_2026-10-15.md`.
