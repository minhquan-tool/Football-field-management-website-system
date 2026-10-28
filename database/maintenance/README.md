# Backup / Restore

1. Chọn file .bak mới trên máy SQL Server trong backup-database.sql; service SQL cần quyền ghi thư mục.
2. Chạy verify-backup.sql để kiểm tra checksum và xem logical filenames.
3. Điền logical filenames trong restore-as-new-database.sql; chỉ khôi phục sang tên fixture mới, không REPLACE.
4. Chạy bộ tests trên bản khôi phục sau khi xác minh dữ liệu.
VERIFYONLY không thay thế restore thực tế. Không commit .bak hay dữ liệu riêng vào Git.
Không tự động chạy các script này khi khởi động web. Mọi script là SSMS normal mode và cần chạy cả file.
