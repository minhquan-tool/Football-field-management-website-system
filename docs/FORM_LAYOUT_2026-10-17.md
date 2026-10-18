# Chuẩn hóa form và sửa icon đăng nhập/đăng ký

## Thay đổi giao diện

- Nhãn cố định trên ô nhập, khoảng cách nhãn–ô 8px; khoảng cách giữa các trường/form rõ hơn. Bổ sung liên kết label–control và placeholder cho các trường còn thiếu, giữ tên/ID/control gốc.
- Form tài khoản, nhân viên và thông tin khách dùng hai cột trên desktop, một cột dưới 768px. Trường textarea và nhóm hành động chiếm cả hàng; ô nội dung phản hồi đủ rộng.
- Input/select cao 44px, nút có vùng bấm tối thiểu 44px; textarea có chiều cao riêng và cho phép kéo dọc. Viền xám `#E5E7EB`, bo 8px và focus ring xanh nhẹ. Viền đỏ và mô tả lỗi validation được giữ.
- Nút lưu dùng màu xanh FC-UTE; Đóng/Hủy trong form có kiểu nút phụ viền xám. Form tài khoản/nhân viên có nhóm nút cuối form, không dính với trường nhập.
- Tên đăng nhập và mật khẩu mới có placeholder. Đổi nhãn Role thành Vai trò trên form tài khoản.
- Sửa CSS ghi đè padding của Tailwind làm chữ đè lên icon: ô có icon trái dành 44px; ô có nút hiện mật khẩu dành 56px bên phải. Icon và nút chỉ căn giữa theo ô cao 44px, không theo chiều cao cả nhóm khi có thông báo lỗi.
- Đăng nhập có nhãn đúng các định danh được hỗ trợ, autocomplete phù hợp, nút hiện/ẩn mật khẩu có aria-label/aria-pressed. Đăng ký có autocomplete và gợi ý giới hạn mật khẩu đặt dưới form, không nhồi vào placeholder.

## Giữ hành vi hiện có

`ui.js` chỉ bổ sung lớp trình bày/label, không gọi API, không thay value/name/required/pattern/validation, không quyết định quyền. Các control và event handler cũ được giữ. Form render sau khi đăng nhập cũng được chuẩn hóa bằng MutationObserver cho thay đổi DOM/hidden; không quan sát gõ phím hoặc thay đổi giá trị input.

Các label đã bọc trường tài khoản không bị thay cấu trúc, để logic ẩn Nhân viên/Tên đăng nhập/Vai trò khi reset mật khẩu và hiện lại khi tạo tài khoản vẫn hoạt động. Đóng reset vẫn xóa mật khẩu trong ô, không reset mật khẩu thực tế. Checkbox, textarea và điều khoản được xử lý riêng; không biến checkbox thành ô cao 44px.

Không đổi backend, schema, migration, phân quyền hoặc mật khẩu. Không thay hình thức trang chủ khách vãng lai vốn có bộ lọc riêng. `ddl-auto=validate` và JDK 24 giữ nguyên.

## File thay đổi

- `frontend/css/fc-ute.css`: quy tắc form dùng chung và căn icon.
- `frontend/js/ui.js`: label/placeholder/lớp trình bày cho form tĩnh và form render động.
- `frontend/Man_hinh_chinh_TK&PQ_HT.html`: nhóm hành động, nhãn và placeholder.
- `frontend/Dang_nhap.html`, `frontend/Dang_ky.html`: gợi ý và thuộc tính hỗ trợ nhập liệu/trợ năng.
- `backend/scripts/form-layout-browser.js`: kiểm tra trình duyệt, không tạo dữ liệu nghiệp vụ.

Nguồn trước thay đổi được sao lưu tại `exports/form-layout-before-20261017/`. Bản đóng gói được build JDK 24 riêng trong `exports/form-layout-20261017/` để kiểm tra trước khi cập nhật server chính.

## Phạm vi kiểm tra

Playwright kiểm tra 1440/768/390px: khoảng cách icon–text, tâm icon (cả khi báo lỗi), chiều cao input/select 44px, hiện/ẩn mật khẩu, lỗi đăng ký mock, form tài khoản hai/một cột, mở/đóng và chuyển tạo tài khoản ↔ reset, checkbox nhân viên, tải thông tin khách và các trang đặt sân/cấu hình/lịch/hóa đơn.

Đăng nhập thật bằng chủ sân/khách để đọc UI; phản hồi lỗi đăng ký được chặn và giả lập tại trình duyệt, không tạo tài khoản. Không bấm Lưu tài khoản, Reset thật, Lưu nhân viên hoặc thanh toán để kiểm tra CSS. Tài khoản `nvsan` đang Khóa được giữ nguyên; trang vận hành được rà bằng quyền chủ sân, không tuyên bố đã đăng nhập lại thành công bằng nvsan.

Kết quả: build/đóng gói JDK 24 thành công; kiểm tra cú pháp `ui.js` và luồng form bằng Playwright đạt. Đã kiểm tra và xem ảnh đăng nhập/đăng ký trên mobile, form tài khoản mobile và nhân viên desktop. Điều hướng **20 trang của 3 tài khoản đang hoạt động** đạt tại 1440/1024/768/390px, không lỗi API hay JavaScript trong lượt kiểm tra điều hướng. Nút tạo/reset/đóng và checkbox vẫn hoạt động, input/select đo được 44px, nhãn nằm trên ô, icon không che chữ và không lệch khi có lỗi. Không chạy lại bộ integration sửa dữ liệu tài khoản chỉ để kiểm tra CSS.

Năm file HTML/CSS/JS nguồn đã đối chiếu hash khớp bản preview được đóng gói. JAR trước cập nhật được sao lưu tại `exports/backend-before-form-layout-20261017.jar` trước khi thay bản chính 8082.

Đã chạy lại các kiểm tra form trên **server chính 8082** và đạt: icon ở cả hai phía/căn giữa khi có lỗi, hiện/ẩn mật khẩu, lỗi đăng ký giả lập, form tài khoản tạo/reset/đóng, nhân viên, các trang dùng chung và form khách hàng. Không ghi thay đổi nghiệp vụ; chỉ có nhật ký đăng nhập/đăng xuất thông thường của quá trình kiểm tra. Preview đã đóng, server chính tiếp tục chạy.
