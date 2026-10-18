# Kịch bản demo FC-UTE cho CNPM và DBMS

Chạy trên database DEV/test có marker đã xác minh. Chọn sân, giờ tương lai và dữ liệu demo riêng; không thực hiện thanh toán hoặc hoàn tiền thật để minh họa. Không đưa mật khẩu vào báo cáo. Đăng xuất trước khi đổi vai trò hoặc dùng các cửa sổ riêng.

## 1. Khách hàng

1. Mở trang chủ khách vãng lai, tìm sân trống theo ngày và giờ.
2. Bấm Đăng nhập để đặt sân; đăng nhập tài khoản khách. Kiểm tra sân/ngày/giờ được giữ lại và hệ thống tra cứu lại giá, lịch trống.
3. Chọn dịch vụ nếu cần và đặt sân. Ghi lại mã lượt đặt. Đối chiếu phản hồi API thành công trước khi khẳng định đã lưu.
4. Mở Lịch sử đặt sân và đánh giá; lọc theo trạng thái hoặc tìm bằng mã. Xem tiến trình và chi tiết hóa đơn. In/lưu PDF phiếu đặt sân từ chi tiết lịch.
5. Nếu gửi yêu cầu thanh toán, giải thích trạng thái chờ xác minh chưa phải tiền đã thu.

## 2. Nhân viên sân

1. Mở bảng điều khiển; tìm mã trong Việc cần xử lý hôm nay. Nếu demo vào ngày khác, mở Lịch đặt và chọn đúng ngày.
2. Mở chi tiết lượt đặt, xác nhận, nhận sân khi phù hợp quy tắc thời gian. Không thay đổi đồng hồ để vượt kiểm tra.
3. Thêm dịch vụ phát sinh, kiểm tra đơn vị/lốc và tổng tiền do backend tính.
4. Trả sân, kiểm tra hóa đơn được chốt. Không sửa giá lịch sử.

## 3. Nhân viên kế toán

1. Tra cứu đúng mã lượt đặt tại màn hình tài chính.
2. Chỉ xác nhận thu khi có căn cứ; demo dùng giao dịch giả lập trên DEV/test. Kiểm tra số còn thiếu và lịch sử giao dịch.
3. Mở báo cáo thu/hoàn, doanh thu và đối soát. Giải thích doanh thu phát sinh khi trả sân khác thực nhận thu trừ hoàn.
4. Minh họa hủy/hoàn bằng lượt đặt demo khác đáp ứng quy tắc 10h/2h; không hủy lượt vừa hoàn thành. Xác nhận hoàn là ghi nhận nội bộ, không tự chuyển khoản ngân hàng.

## 4. Quản lý hệ thống

1. Xem danh mục sân, cấu hình giá/dịch vụ, nhân viên, tài khoản và quyền theo phạm vi được cấp.
2. Mở nhật ký để chỉ ra các thao tác vừa demo; không xóa lịch sử.
3. Minh họa phân quyền bằng cách mở URL của vai trò khác; trang chuyển về nơi phù hợp hoặc API trả 403. Không dùng tài khoản quản trị để chứng minh quyền khách hàng.
4. Trình bày quy trình backup/restore có kiểm soát; không restore đè database đang dùng khi báo cáo.

## Minh chứng cần ghi trong báo cáo

- CNPM: luồng bốn vai trò, màn hình, validation, phản hồi khi API lỗi, phân quyền và ca kiểm thử.
- DBMS: khóa/transaction chống đặt trùng, ràng buộc, snapshot giá và hóa đơn, trigger tổng dịch vụ, idempotency thu/hoàn, quyền runtime và nhật ký.
- Phiếu đặt sân là thông tin lượt đặt tại thời điểm tra cứu, không thay thế hóa đơn hoặc biên nhận.
- Chụp minh chứng lỗi/403 và đối chiếu dữ liệu bằng truy vấn chỉ đọc. Không chụp secrets, không chạy DROP/reset hoặc sửa trực tiếp số tiền.

Đây là kịch bản thao tác để nhóm chạy khi demo; không phải xác nhận đã tạo đủ giao dịch minh họa trên database.
