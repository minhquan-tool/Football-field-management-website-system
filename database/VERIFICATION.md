# Kết quả sắp xếp database FC-UTE

Đã thực hiện ngày 28/10/2026 trên bản dự án local.

## Cấu trúc hiện hành

- database/QuanLySanBong_Full.sql: bộ cài độc lập, SSMS normal mode, mặc định tạo QuanLySanBong_Test mới.
- database/README.md: cách dựng CSDL, kết nối backend và ánh xạ 9 nội dung DBMS.
- database/tests/: 11 kiểm tra SQL tự động (00..10), 2 script đồng thời (11A/11B), Run-Tests.ps1.
- database/security/: hướng dẫn và script ánh xạ login có sẵn vào runtime role; không chứa password.
- database/maintenance/: backup, verify-backup, restore-as-new-database.
- database/migrations/legacy/: 10 script lịch sử được di chuyển, không chạy thêm sau bộ cài chính.
- database/migrations/ và metadata/: giữ công cụ nâng cấp và đầu vào generator.
- database/report-demo/ và repair-paid-booking-status-20261022.sql: dữ liệu công việc riêng có sẵn trên máy, giữ nguyên.

Đã loại 69 file tách trong database/final/ sau khi xác minh bộ cài thay thế.
Đã cập nhật đường dẫn trong README, tài liệu và script liên quan. Exporter thành phần cũ xuất vào exports/database-components/ thay vì tái tạo database/final/.

## Đã kiểm chứng

- Bộ cài mới tạo độc lập QuanLySanBong_Fixtures_Structure_20261028 từ đầu: PASS.
- 28 bảng nghiệp vụ, 9 view, 6 function, 5 stored procedure, 5 trigger.
- Đối chiếu tên/kiểu/độ dài/precision/scale/nullability/identity/computed của cột: không thiếu cột so với CSDL vận hành (loại sysdiagrams).
- 11 script 00..10: PASS trên fixture mới. Các kiểm tra SP/view là smoke test, không khẳng định mọi kết quả báo cáo đều đúng.
- Transaction: 5 COMMIT_PASS + 5 ROLLBACK_PASS.
- Hai phiên đồng thời: phiên A giữ khóa và nhả khóa không ghi; phiên B gặp 1222 như dự kiến, không ghi dữ liệu.
- Backup QuanLySanBong_Test bằng COPY_ONLY/CHECKSUM, VERIFYONLY: PASS.
- Restore sang QuanLySanBong_Fixtures_RestoreReview và DBCC CHECKDB: PASS.
- 10 kiểm tra không tạo fixture chạy lại trên bản restore: PASS.
- Bộ cài từ chối database đã có (51404); kiểm thử từ chối database vận hành (51410): PASS.
- git diff --check: PASS.

## Giới hạn và dữ liệu được giữ

Không thay đổi CSDL QuanLySanBong đang chạy, cấu hình môi trường, mật khẩu hoặc thay đổi mã ứng dụng của người dùng.
Bộ cài dùng snapshot dữ liệu của bộ final có sẵn, không xuất dữ liệu live mới nhất; giữ nguyên lịch sử và hash tài khoản, không tự tạo/reset mật khẩu web.
Chưa chạy lại backend/JPA/E2E và chưa xác nhận đăng nhập web trên bản mới. Không dùng kết quả SQL thay cho nghiệm thu toàn ứng dụng.
QuanLySanBong_Test được tạo và giữ lại để sử dụng; hai fixture xác minh cũng được giữ, không tự xóa database.
Backup test mới được lưu trong thư mục Backup mặc định của SQL Server, không đưa lên Git.
Kết quả trên ghi nhận tại thời điểm kiểm thử cấu trúc mới.

## Lệnh dùng lại

Chạy tại thư mục gốc dự án:

```powershell
.\database\tests\Run-Tests.ps1 -Database QuanLySanBong_Test -IncludeTransactions
```

Kịch bản transaction có COMMIT sẽ giữ dữ liệu tổng hợp. Chỉ dùng trên database test.