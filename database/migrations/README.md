# Migration

Máy mới: chỉ chạy ../QuanLySanBong_Full.sql, KHÔNG chạy tiếp mọi migration.
Các migration hiện có là lịch sử nâng cấp, có thứ tự/prerequisite riêng. Không tự đổi tên/ghép hoặc chạy toàn thư mục.
Database đang dùng: backup, chọn migration đúng trạng thái schema, thử trên bản sao, verify rồi mới áp dụng đã duyệt.
File *_PROPOSAL không mặc nhiên đã được áp dụng. Giữ rollback để đối chiếu.
legacy/ chứa cách dựng/schema/seed và kiểm tra cũ, không phải trình cài đặt máy mới.
