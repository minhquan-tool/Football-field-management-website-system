# Database FC-UTE

## Dựng database trong SSMS

SQL Server 2022, SSMS; dùng tài khoản DBA có quyền CREATE DATABASE. Mở QuanLySanBong_Full.sql, chạy CẢ FILE trong normal mode (không cần SQLCMD Mode).
- Mặc định: tạo QuanLySanBong_Test, môi trường test. Không sửa/ghi đè QuanLySanBong đang tồn tại.
- Máy mới chạy dự án: đổi @NewDatabase=N'QuanLySanBong' và @Environment='dev'. Nếu tên đã tồn tại, script dừng; tuyệt đối không DROP để chạy lại.
- Dữ liệu là snapshot có sẵn trong bộ final của dự án, KHÔNG phải dữ liệu live mới nhất hay bộ demo đã ẩn danh. Có lịch sử và hash mật khẩu; không có mật khẩu SQL login. Không công bố bản xuất dữ liệu riêng mới.
- Không tự đặt/reset mật khẩu tài khoản web; dùng tài khoản sẵn có của snapshot hoặc luồng khởi tạo đã được phê duyệt trong README gốc.

## Kết nối backend

DBA tạo dedicated SQL login riêng, dùng security/provision-runtime-user.sql để ánh xạ user vào SanBongRuntime.
Trong cấu hình .env riêng đặt APP_DB_URL trỏ đến database đã chọn, APP_DB_USER và APP_DB_PASSWORD; giữ ddl-auto=validate. Không sửa file môi trường đang dùng để test.
Ví dụ URL: jdbc:sqlserver://localhost:1433;databaseName=QuanLySanBong_Test;encrypt=false;trustServerCertificate=true (local development).
Chạy backend trên port riêng nếu kiểm thử song song. Hướng dẫn build/run ở ../README.md.

## Chín nội dung DBMS

| Nội dung | Vị trí |
|---|---|
| Ràng buộc | SQL chính: PK/FK/UNIQUE/CHECK/DEFAULT/NOT NULL |
| SP | SQL chính: 5 stored procedures báo cáo |
| Function | SQL chính: 6 hàm |
| Trigger | SQL chính: 5 trigger nghiệp vụ |
| View | SQL chính: 9 view |
| Index | SQL chính: index và unique constraint |
| Transaction | Bộ cài TRY/CATCH/ROLLBACK; tests/08_transactions.sql; transaction nghiệp vụ ở backend |
| Backup | maintenance/: backup, verify, restore bản sao mới |
| Bảo mật/phân quyền | SQL chính: 4 demo roles + SanBongRuntime; security/ ánh xạ login riêng |

## Thư mục

- tests/: kiểm tra 9 nội dung DBMS; chỉ dùng DB test, đọc README trong thư mục.
- maintenance/: backup/restore chủ động, không chạy tự động.
- security/: cấu hình runtime, không chứa password.
- migrations/: lịch sử và legacy, không chạy nối tiếp sau bộ cài mới.
- metadata/: đầu vào các script Python sinh tài liệu/migration; giữ để công cụ hiện có hoạt động.
- report-demo/ (nếu có trên máy): kịch bản bảo vệ riêng hiện có, giữ nguyên; không thuộc chuỗi cài đặt hoặc bộ test mới.

## Nộp báo cáo

Nộp SQL chính + README, kết quả kiểm thử thực tế; .bak là lựa chọn thêm. File .bak không thuộc Git.
Không tuyên bố web/E2E/backup restore PASS chỉ từ việc tạo file: xem kết quả xác minh cụ thể.
