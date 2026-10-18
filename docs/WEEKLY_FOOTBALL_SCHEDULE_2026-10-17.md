# Lịch đá bóng theo tuần

## Sử dụng

Nhân viên sân (VT02) hoặc chủ sân/quản lý hệ thống (VT04) chọn **Lịch đá bóng** từ menu. Cần quyền `CN02_XEM`. Khách hàng và kế toán không được mở trang/API này.

- Tuần bắt đầu thứ Hai và kết thúc Chủ nhật. Chọn bất kỳ ngày nào trong tuần, dùng Tuần trước/Tuần sau hoặc Tuần hiện tại. Ngày hiện tại theo giờ Việt Nam được tô nổi.
- Lọc tất cả sân hoặc một sân. Mặc định ẩn lượt đã hủy; có thể chọn xem tất cả hoặc lọc từng trạng thái.
- Trục dọc là giờ đá, mặc định 07:00–22:00. Nếu dữ liệu legacy có giờ ngoài khoảng này, lịch mở rộng trục giờ để không giấu lịch cũ. Không đổi giờ/giá/snapshot legacy.
- Vị trí và chiều cao lượt đặt theo thời gian thực, không làm tròn về khung 30/60 phút. Lượt cùng giờ được chia cột cạnh nhau; không chồng che nhau. Lượt rất ngắn có thể xem đầy đủ qua danh sách và tiêu đề hỗ trợ bàn phím.
- Bấm lượt đặt để mở chi tiết trong **Lịch / Nhận trả sân / Dịch vụ** hiện có. Các thao tác xác nhận, hủy, nhận/trả sân, dịch vụ, hóa đơn vẫn qua API nghiệp vụ hiện tại. Trang tuần chỉ đọc, không đổi lịch bằng kéo/thả.
- Trên điện thoại, cuộn ngang trong bảng để xem đủ 7 ngày, hoặc bấm **Xem danh sách lượt đặt**. Trang không tràn ngang ra ngoài vùng lịch.
- **In lịch tuần** in danh sách đầy đủ theo bộ lọc hiện tại, có khoảng ngày, tên sân và trạng thái; không chỉ in phần lưới đang thấy trong vùng cuộn. Chưa có dữ liệu hoặc tải lỗi thì không in dữ liệu cũ.

Giao diện dùng cách bố trí tuần/giờ của ảnh tham khảo, giữ tông xanh–trắng và menu theo vai trò của FC-UTE. Thay bộ lọc năm học/học kỳ bằng sân, ngày và trạng thái phù hợp nghiệp vụ sân bóng.

## Kỹ thuật và quyền truy cập

Trang `frontend/Lich_da_bong.html`, CSS `frontend/css/weekly-schedule.css`, JS `frontend/js/weekly-schedule.js`; menu trong `frontend/js/role-navigation.js`.

`GET /staff/weekly-schedule?date=yyyy-MM-dd&pitch=<mã sân>&status=<trạng thái>` được giới hạn hai vai trò và quyền xem ở backend. Ngày được chuẩn hóa về thứ Hai; chỉ truy vấn 7 ngày tương ứng. Bỏ trống status là loại lượt đã hủy; `ALL` gồm cả hủy. Không nhận khoảng ngày tùy ý không giới hạn.

`WeeklyScheduleController → WeeklyScheduleService → DatSanRepository`. Truy vấn một khoảng ngày có EntityGraph lấy quan hệ phục vụ lịch; sắp theo ngày, giờ bắt đầu, sân, mã đặt sân. Không gọi API từng ngày hoặc từng lượt đặt để ráp lịch. Bộ lọc sân/trạng thái kiểm tra ở backend. Giữ nguyên schema và quy trình ghi/transaction hiện có.

Frontend dùng `textContent`, URL chi tiết cố định với tham số được encode; không chèn HTML từ tên khách. Sau đổi bộ lọc, xóa nội dung cũ và vô hiệu hóa in cho đến khi tải thành công. Chỉ phản hồi mới nhất được phép cập nhật lịch; lỗi có thông báo và nút tải lại. Ngày dùng UTC cho phép cộng/trừ ngày, ngày hiện tại dùng múi giờ Việt Nam để tránh lệch tuần theo máy khách.

Không thêm dependency, migration hoặc quyền SQL. Chỉ đọc database qua tài khoản runtime hiện có.

## Kiểm thử

`WeeklyScheduleTest`: quyền trang/API cho 4 vai trò và khách chưa đăng nhập; biên thứ Hai–Chủ nhật, loại hai tuần kề; lọc sân/trạng thái/hủy; biên năm; không phát sinh hóa đơn/nhận sân khi chỉ xem; tham số sai trả lỗi. Fixture nằm trong transaction rollback trên database được đánh dấu DEV và có opt-in.

`backend/scripts/weekly-schedule-browser.js`: trang thật/phiên nhân viên thật nhưng dữ liệu lịch/options bị chặn và trả fixture trong trình duyệt. Kiểm tra 7 cột ngày, giờ lẻ, làn cho lượt đồng thời, khung giờ legacy sớm, liên kết chi tiết, XSS, lọc/tuần trống, phản hồi đến trễ, lỗi và thử lại, bố cục mobile và bản in. Không tạo lượt đặt hoặc giao dịch thật để chạy UI test.

Kết quả đợt này: **101 test backend đạt** (5 test mới cho lịch tuần), 0 lỗi/0 bỏ qua; build JDK 24 thành công. Kiểm thử UI trên 1440/1024/768/390 px đạt, ảnh desktop/mobile đã kiểm tra; điều hướng **27 trang của 4 vai trò** đạt, không lỗi API hoặc JavaScript trong lượt kiểm tra điều hướng. Xác nhận SQL không còn fixture sân/khách/khuyến mãi sau rollback. Bản cũ được sao lưu tại `exports/backend-before-weekly-schedule-20261017.jar` trước khi cập nhật server chính cổng 8082.

Đã xác nhận trên server chính 8082 với dữ liệu thật (chỉ đọc): VT02 và VT04 mở trang/lịch/API thành công, menu có đúng một mục lịch mới. VT01 và VT03 không thấy mục này; API trả 403, truy cập trực tiếp trang HTML được chuyển về trang chủ đúng vai trò với `accessDenied=1` theo cơ chế hiện có. Không tạo booking, hóa đơn hoặc giao dịch thật để nghiệm thu.

Trong lượt kiểm tra bổ sung sau triển khai, tài khoản mẫu `nvsan` đã ở trạng thái `Khóa` (nhật ký có thao tác quản trị lên tài khoản này). Không tự mở khóa hoặc thay mật khẩu. Test lịch tuần được đổi sang tạo nhân viên/tài khoản VT02 tạm, hash mật khẩu ngẫu nhiên và rollback toàn bộ fixture, tránh phụ thuộc trạng thái tài khoản mẫu. Bổ sung kiểm tra servlet path để xác minh đúng chuyển hướng HTML về trang theo vai trò, thay vì chỉ kiểm tra 403 của API.
