# San_Bong — backup / restore an toàn

## Runner bổ sung — đợt mức trung bình 17/10

`scripts/backup-database.ps1` dùng Windows Authentication của người vận hành, tạo file tên mới với COPY_ONLY/CHECKSUM/VERIFYONLY và receipt trong run/backup-receipts. Có WhatIf, tùy chọn archive và Prune giới hạn backup do chính runner quản lý; không dùng credentials runtime web. Lượt thật đã xác minh SQL thành công; tiến trình Windows hiện không elevated nên không đọc được BAK để hash. Receipt ghi SHA256null, không giả báo archive/retention đạt. Chưa chạy Prune, xóa file hoặc copy ra ngoài máy.

`scripts/register-backup-task.ps1 -WhatIf` chỉ xem kế hoạch. Lịch02:00/giữ14ngày hiện mới là đề xuất, chưa có lựa chọn của người dùng, chưa đăng ký task. Cần chốt identity/quyền Windows, lịch và nơi lưu ngoài máy; thử thực tế task rồi mới coi backup tự động đã nghiệm thu. Xem [báo cáo CNPM/DBMS mức trung bình](MEDIUM_FIXES_2026-10-17.md).

## Quy trình vận hành
SQL administrator thực hiện trên server. Runtime app không được backup/restore, không dùng sa cho ứng dụng. SQL Server service identity cần quyền đọc/ghi thư mục backup; thư mục trên máy SQL, không phải máy browser.

1. Dùng tên file mới có timestamp; ví dụ SSMS New Query trong master:
   ```sql
   BACKUP DATABASE [QuanLySanBong] TO DISK=N'D:\SQLBackups\QuanLySanBong_YYYYMMDD_HHMMSS.bak' WITH COPY_ONLY,CHECKSUM;
   RESTORE VERIFYONLY FROM DISK=N'D:\SQLBackups\QuanLySanBong_YYYYMMDD_HHMMSS.bak' WITH CHECKSUM;
   RESTORE HEADERONLY FROM DISK=N'D:\SQLBackups\QuanLySanBong_YYYYMMDD_HHMMSS.bak';
   RESTORE FILELISTONLY FROM DISK=N'D:\SQLBackups\QuanLySanBong_YYYYMMDD_HHMMSS.bak';
   ```
   Chọn thư mục có thật và quyền SQL service; không dùng WITH INIT để ghi đè backup. Có script `scripts/backup-database.sql`, `sqlcmd -S tcp:localhost,1433 -E -b -i scripts/backup-database.sql -v BackupFile="PATH_DA_REVIEW"`.
2. VERIFYONLY không thay thế restore drill. Kiểm tra position backup set, logical names, đường dẫn data/log. Chỉ restore sang tên database CHƯA TỒN TẠI và file mdf/ldf KHÁC source. Không WITH REPLACE, không DROP hoặc restore đè production.
3. `scripts/restore-test-database.sql` chỉ tạo QuanLySanBong_Phase7_RestoreTest nếu chưa tồn tại, FILE=1, CHECKSUM, MOVE logical QuanLySanBong/QuanLySanBong_log sang file riêng tại SQL default database/Log. Với backup khác logical names hoặc nhiều file/backup sets: dừng và sửa proposal sau kiểm tra FILELIST/HEADER, không chạy máy móc. Script từ chối nếu tên test đã tồn tại; lần drill kế tiếp chọn tên mới có timestamp qua bản script được review.
4. Chạy DBCC CHECKDB trên bản restore; đối chiếu row counts, booking snapshots, hóa đơn/thu/hoàn/audit. App dùng JDBC trực tiếp + ddl-auto=validate đọc bản copy. Đánh dấu bản copy test, không test ghi trên production. SQL login server không nằm trong database backup: tạo/map login và áp dụng quyền runtime trên server mới; xử lý orphan users qua ALTER USER ... WITH LOGIN, không grant db_owner.
5. Lưu log kiểm tra và bản sao backup ngoài máy SQL; bảo vệ ACL và retention do chủ sân xác định. SIMPLE hiện tại không cho point-in-time log restore. Với nhu cầu RPO nhỏ hơn chu kỳ full backup, lập kế hoạch FULL/log backup riêng trước khi đổi recovery model.

## Drill thực tế Phase 7 — 2026-10-08
- Source: QuanLySanBong, recovery SIMPLE.
- File: `C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\QuanLySanBong_Phase7_PreHardening_20261008.bak`.
- COPY_ONLY + CHECKSUM và RESTORE VERIFYONLY CHECKSUM: PASS.
- Restore sang **QuanLySanBong_Phase7_RestoreTest**, file mdf/ldf riêng: PASS, DBCC CHECKDB không lỗi; không ghi đè nguồn. Log `backend/phase7-restore-drill.log`.
- Trước drill: 7 sân, 3 booking, 4 tài khoản; DS01 total230000, DS02 total300000, DS3b97491a total200000. Metadata classification và runtime role tạo sau backup được ghi riêng trong lịch sử Phase 7.

## Drill mới — 17/10/2026

Đã backup COPY_ONLY/CHECKSUM sang file mới QuanLySanBong_QA_20261017_1736.bak tại thư mục backup mặc định SQL, VERIFYONLY và review HEADER/FILELIST. Restore sang **QuanLySanBong_QA_20261017_1736**, file data/log riêng, không ghi đè nguồn. CHECKDB đạt; 8 bảng booking/dịch vụ/hóa đơn/thu/hoàn/hủy/nhận sân/nhật ký được đối chiếu đầy đủ theo hai chiều EXCEPT và khớp tại thời điểm drill. Runtime SanBongApp vẫn bị chặn UPDATE/DELETE audit trên bản restore.

JAR hiện có khởi động với bản copy bằng JDBC, Hibernate validate thành công, health UP. Backend thử loopback8085 đã dừng; server chính8082 giữ database nguồn. Giữ database/file drill để đối chiếu, không tự DROP. Log mới và giới hạn lịch backup/retention/bản sao ngoài máy ở [báo cáo CNPM/DBMS](KE_HOACH_SUA_LOI_CNPM_DBMS_2026-10-17.md). Một drill đạt không chứng minh đã có backup tự động hoặc RPO/RTO được nghiệm thu.

## Khôi phục sự cố / rollback
Ngừng ghi, giữ backup và log hiện tại; người quản lý xác nhận mốc khôi phục và dữ liệu phát sinh có thể mất. Restore sang database mới trước, CHECKDB/validate/đối soát rồi đổi APP_DB_URL và restart có kiểm soát. Không có script tự động restore đè dữ liệu hiện hành. Rollback JAR về bản đã xác nhận tương thích schema; Phase 7 không thay bảng/cột/tiền legacy. Không reset mật khẩu thật hoặc xóa login/role còn đang được sử dụng. Sau khi đổi DB, session không dùng lại được sau restart; yêu cầu login lại.
