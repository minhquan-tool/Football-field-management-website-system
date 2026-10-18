# Hướng mở rộng quy tắc khuyến mãi — đề xuất, chưa thay schema

Hiện tại đã sửa VIP10 theo lựa chọn người dùng: chỉ thứ Tư, kiểm tra ngày chơi ở backend; sáu ngày còn lại bị từ chối cả với nhân viên/kế toán. Snapshot số tiền trong DatSan/HoaDon không thay đổi. Các quy tắc cũ khác vẫn giữ nguyên.

Với danh mục nhỏ hiện có, chưa bắt buộc thêm bảng/cột để chạy đúng. Backend từ chối mã/alias trùng bằng409 và điều kiện không nhận diện cần nhân viên xác minh; không suy đoán đủ điều kiện.

Nếu cần quản lý nhiều chiến dịch, đề xuất xem trước trên bản database copy:

1. Một bảng mã chung `PromotionCode` với `Code` chuẩn hóa hoa làm khóa duy nhất và FK tới `KhuyenMai`. Backfill cả MaKM lẫn alias hiện có vào cùng namespace; dừng migration nếu trùng, không tự chọn bản ghi.
2. Quy tắc có loại dữ liệu rõ: NONE, WEEKDAY, DAY_OF_WEEK với ngày ISO1–7, FIRST_BOOKING hoặc STAFF_VERIFIED. Mô tả tiếng Việt chỉ dùng hiển thị; backend thực thi theo loại quy tắc sau khi migration được duyệt.
3. Promotion đã được sử dụng không được thay chính sách; tạo phiên bản mới. Giữ snapshot tiền legacy và lịch sử mã cũ. Không tự áp lại mã cho hóa đơn đã chốt hoặc đã có giao dịch.
4. Kiểm thử backfill/uniqueness, bảy ngày, booking khác chủ, hạn ngày áp/ngày chơi, trùng alias và xác nhận nhân viên không vượt quy tắc tự động; đối chiếu tổng tiền trước/sau migration.

Đây là đề xuất thiết kế, không phải script đã áp dụng. Không thêm schema tài chính hoặc thay phương thức tính tiền chỉ để hoàn thành mục báo cáo.
