# Nghiệm thu chuẩn hóa, view legacy và backup tự động — 18/10/2026

Đã xử lý tuần tự cả ba phần trên database `QuanLySanBong` và bản web cổng 8082. Không đổi mật khẩu người dùng, không reset database, không sửa UI hoặc thay stack. Migration tài chính và JAR được triển khai sau khi người dùng duyệt riêng. Đây là bàn giao kỹ thuật, không phải báo cáo cuối kỳ hay slide.

## 1. DBMS: chuẩn hóa và bảo toàn snapshot

### Đã làm

Chuyển 9 cột sang **computed persisted** để SQL Server làm nguồn tính công thức:

| Bảng | Cột do SQL tính |
|---|---|
| DatSan | ThoiLuong, TienSan, TongTien |
| HoaDon | TongTien, ConLai, HoanTatTaiChinh |
| ChiTietDichVu | SoDonViMoiQuyCach, DonGia, ThanhTien |

Ba cột lưu snapshot kế thừa mới là `DatSan.ThoiLuongLegacySnapshot`, `DatSan.TienSanLegacySnapshot`, `ChiTietDichVu.DonGiaLegacySnapshot`. CHECK phân biệt dữ liệu legacy với dữ liệu tính theo công thức mới. Booking GIA_KHUNG giữ nguyên thời lượng và tiền cũ, không bị định giá lại theo GiaTheoCa. Dịch vụ LEGACY giữ nguyên đơn giá đã ghi.

GIA_GIO tính tiền từ **số phút thật**, không nhân với thời lượng giờ đã làm tròn. Ví dụ 37 phút hiển thị 0,62 giờ nhưng tiền vẫn tính đơn giá × 37/60. Giá đơn vị dịch vụ là snapshot độc lập với giá catalog hiện tại; lốc 6 giảm 3%. Đổi giá catalog không làm đổi hóa đơn đã bán. Trigger dịch vụ chỉ cập nhật TienDichVu; TongTien tự tính, tránh hai nơi ghi cùng một giá trị.

Đã công bố khóa, phụ thuộc hàm và giả định nghiệp vụ cho 27 quan hệ trong `DBMS_NORMALIZATION_MODEL.md`; công cụ kiểm tra closure/3NF đạt **theo mô hình FD đã khai báo**. Không suy ra FD chỉ từ số dòng mẫu hoặc chỉ từ PK.

### Giới hạn cần nói đúng khi trình bày

Không khẳng định mọi cột vật lý đều là mô hình 3NF thuần túy: computed persisted vẫn lưu kết quả để phục vụ đọc; snapshot hóa đơn là sự kiện lịch sử; TienDichVu và DaThanhToan là các tổng liên bảng được kiểm soát bởi trigger/transaction. Những giá trị này có chủ đích và không được xóa chỉ để gọi là chuẩn hóa. KhungGio.ThoiLuong của legacy là đơn vị tính giá lịch sử, không mặc định luôn bằng chênh lệch thời gian đồng hồ.

### Bằng chứng

- 205/205 kiểm thử trên database riêng, không lỗi hoặc bỏ qua.
- 130/130 kiểm thử với tài khoản runtime SanBongApp sau triển khai.
- Trình duyệt 4 vai trò ở chiều rộng 1440 và 390: đạt; bản candidate và bản chính đều được kiểm tra.
- Migration → rollback → áp dụng lại thành công trên bản sao.
- SHA-256 của phép chiếu **toàn bộ cột gốc** trên 9 bảng giữ nguyên trước/sau migration và sau hồi quy: DatSan, HoaDon, ChiTietDichVu, ThanhToan, HoanTien, HuyDatSan, XacNhanSan, DichVu, GiaTheoCa. Ba cột mới không nằm trong phép chiếu cột gốc. Không suy rộng chứng minh này sang bảng ngoài danh sách.
- JAR triển khai: `FC3AEF8934AD500B237682EA0F736E247046075BC7EBD1F71247035F452CD8F4`.

File SQL: `NormalizeFinancialDerivations_20261017_PROPOSAL.sql` **đã được duyệt và áp dụng**, cùng bản `_ROLLBACK.sql`. Nếu cần quay lại phải phối hợp schema với JAR cũ; không chỉ thay JAR cũ vào schema computed mới.

## 2. DBMS: sửa hợp đồng view legacy

| Đối tượng | Hành vi sau sửa |
|---|---|
| fn_KhungGioTrongTheoNgay(@Ngay) | Tra cứu các khung catalog nằm trong 07:00–22:00, theo ngày chọn; loại sân bảo trì và mọi interval overlap của booking chưa hủy |
| V_KhungGioTrong | Dùng hàm trên cho ngày hiện tại theo múi giờ Việt Nam; giữ 6 cột đầu và thêm NgayChoi |
| V_ThuTienTheoNgay | Thu thành công gộp theo ngày/phương thức, trước hoàn |
| V_DoanhThuTheoNgay | Alias tương thích của V_ThuTienTheoNgay; giữ nguyên 4 cột cũ, đánh dấu tên deprecated |
| V_DoanhThuPhatSinhTheoNgay | Doanh thu tại ngày trả sân, dựa trên V_Phase6_Revenue và snapshot |
| V_TyLeSuDungTheoNgay | Phút đặt trong 07–22h / (900 phút × số sân hiện tại) |
| V_TyLeLapDay | Dùng tỷ lệ theo phút; giữ các cột cũ và thêm PhutDat, PhutCongSuat |

`TongKhungGio` giữ lại để tương thích và chỉ là thông tin catalog; **không phải mẫu số** của tỷ lệ mới. Mẫu số là công suất lý thuyết từ danh mục sân hiện tại, cùng quy ước của usp_ReportUsage. Chưa có dữ liệu lịch sử bảo trì/ngừng sân nên không gọi đây là công suất khả dụng lịch sử chính xác. Không ép tỷ lệ về 100% để che overlap legacy nếu có.

View/hàm đọc lịch trống không giữ chỗ; thao tác đặt vẫn phải khóa San → DatSan và kiểm tra lại trong transaction. Hàm này trả khung catalog, không liệt kê mọi khoảng giờ tự do có thể đặt. Web tiếp tục dùng BookingService cho lựa chọn giờ tự do. Không cấp thêm quyền ghi hay đưa SQL identity vào trình duyệt; các module mới không tự động được công khai qua API.

Đã rà source: repository hiện hành không gọi ba view legacy; các SP báo cáo hiện hành được giữ nguyên. Consumer SQL bên ngoài cần lưu ý cột thêm và ý nghĩa tỷ lệ đổi. Extended property `SanBongContract` trên ba view mô tả cụ thể.

**37/37 kiểm thử** gồm 6 ca view mới và 31 ca SQL/chuẩn hóa hồi quy. Kiểm tra overlap, tiếp giáp biên, ngày khác, booking hủy, bảo trì, NULL/nghỉ ngoài giờ, 37 phút, và phân biệt nguồn tiền thu/doanh thu. Rollback/reapply đã thử trên database riêng trước khi áp dụng chính. Script giao dịch mẫu đã sửa để không ghi cột computed và chạy đủ 5 COMMIT + 5 ROLLBACK trên fixture.

File: `LegacyViewContracts_20261018.sql`, bản `_ROLLBACK.sql`, `LegacyViewsIntegrationTest.java`, `build-legacy-view-migration.py`. Schema-only và từ điển/ERD đã tái sinh từ database chính; tạo database schema rỗng tên mới và CHECKDB đạt: 27 bảng, 9 view, 9 cột computed persisted. Không ghi đè database demo cũ.

## 3. DBMS/vận hành: backup tự động đã bật

| Thiết lập | Giá trị |
|---|---|
| Task Windows | SanBongSqlBackup |
| Lịch | Mỗi ngày 02:00 theo giờ máy Windows |
| Principal | Tài khoản Windows ASUS, Interactive, Limited |
| Bù lượt lỡ | StartWhenAvailable; máy bật và tài khoản đã đăng nhập |
| Thư mục | run/backups, nằm ngoài thư mục web static |
| Kiểm tra | COPY_ONLY, CHECKSUM, RESTORE VERIFYONLY, SHA-256 |
| Log task | run/backup-task-logs |
| Biên nhận | run/backup-receipts/*.verified.json |
| Tự xóa bản cũ | Chưa bật; KeepDays chỉ có tác dụng khi chủ động thêm -Prune |
| Sao lưu ngoài máy | Chưa cấu hình |

Thư mục backup riêng có ACL không kế thừa: tài khoản Windows hiện tại, SYSTEM và Administrators có FullControl; SQL engine NT Service\MSSQLSERVER có Modify. Không thay ACL thư mục backup hệ thống, không cấp backup cho SanBongApp, không lưu mật khẩu Windows/SQL trong task. Đã sửa lỗi tương thích Windows PowerShell 5.1 và thêm transcript để lỗi task có log tra cứu.

Đã **chạy thật qua Start-ScheduledTask**, không chỉ đăng ký: LastTaskResult=0, file BAK có biên nhận verify và hash khớp. Backup từ task đã phục hồi sang `QuanLySanBong_Fixtures_20261018_AutoRestore`, CHECKDB đạt, 9 bảng đối chiếu khớp, JAR khởi động với JPA validate và health UP; preview sau đó đã dừng. Database chính không bị restore đè.

Đây là lịch theo phiên đăng nhập: không chạy lúc máy tắt hoặc người dùng đã sign out. Task chạy bù khi đủ điều kiện; không tự đánh thức/bật máy. Muốn chạy khi chưa đăng nhập cần chuyển sang principal S4U/service được quản trị Windows duyệt và xác minh lại quyền SQL. Bản backup còn cùng máy, nên chưa chống mất ổ đĩa hoặc mất máy; cần thêm kho ngoài máy nếu vận hành thực tế. Các BAK và profile riêng không được đưa lên Git/public.

## 4. CNPM: thay đổi và nghiệm thu

- Entity DatSan đánh dấu các cột dẫn xuất read-only/generated; JPA nhận lại giá trị SQL.
- FinanceRepository không INSERT/UPDATE TongTien của hóa đơn nữa.
- OperationsRepository/Service không ghi DonGia hoặc số đơn vị computed; giữ validation, snapshot giá đơn vị, khóa, transaction và trigger.
- Không sửa giao diện, điều hướng hay quyền 4 vai trò trong đợt này. Đã smoke test chúng sau triển khai; đây không phải chứng nhận mọi thao tác trên mọi trình duyệt.
- Test tài chính biên thời gian được chỉnh Clock trước khi đặt/thu thay vì sửa giờ booking sau khi đã thu để dựng fixture. Test và SQL mẫu đi theo schema mới.
- Giữ bản JAR cũ và migration rollback đã thử; chỉ một server chính cổng 8082 đang phục vụ.

Các file Java chính: model/DatSan.java, repository/FinanceRepository.java, repository/OperationsRepository.java, service/OperationsService.java. Các test/runner mới: NormalizationIntegrationTest.java, LegacyViewsIntegrationTest.java, run-normalization-verification.ps1. Tooling backup: backup-database.ps1, prepare-backup-directory.ps1, register-backup-task.ps1, run-scheduled-backup.ps1.

## 5. Xem và chạy lại

Từ thư mục gốc dự án:

```powershell
# Kiểm tra lịch và lần chạy gần nhất (không cần chạy thêm server):
Get-ScheduledTask -TaskName SanBongSqlBackup
Get-ScheduledTaskInfo -TaskName SanBongSqlBackup

# Chủ động chạy một lượt backup bằng task đã cài:
Start-ScheduledTask -TaskName SanBongSqlBackup

# Chỉ xem kế hoạch đăng ký trên máy khác, không ghi đè task hiện có:
.\scripts\register-backup-task.ps1 -Interactive -AtTime 02:00 -WhatIf

# Runtime dùng profile riêng hiện có, yêu cầu JDK24 và Maven:
.\backend\run-verification.ps1 -Suite runtime -EnvFile .\.env.test.local -Offline

# Test có ghi/rollback chỉ trên fixture đã có cả hai migration:
.\backend\run-normalization-verification.ps1 -EnvFile .\.env.normalization.local -Offline -IncludeLegacyViews
```

Không chạy lại các migration đã áp dụng như lệnh khởi động web. Không chạy fixture test hoặc cleanup bằng database internal. Web đang chạy tại `http://127.0.0.1:8082/api/`; nếu khởi động máy lại vẫn phải chạy backend như hướng dẫn dự án, task backup không thay thế server web.

## 6. Còn lại

Ba hạng mục được giao đã có triển khai và bằng chứng kiểm tra. Các giới hạn còn lại là backup ngoài máy, chế độ chạy khi chưa đăng nhập, công suất lịch sử theo bảo trì, và nghiệm thu truy cập từ thiết bị ở xa. Chưa chứng nhận Internet production. Không tạo Git/lịch sử đóng góp thay nhóm, không viết báo cáo cuối kỳ hoặc slide theo yêu cầu đã loại của người dùng.

Chứng cứ nằm trong exports: normalization-deployment.json, normalization-final-tests-copy.log, normalization-runtime-main.log, normalization-browser-main.log, legacy-view-tests-copy.log, automatic-backup-verification.json, automatic-backup-checkdb.log, autorestore-jpa-verification.txt, normalized-schema-checkdb.log, normalization-views-backup-verification.json. File exports và run có thể bị ignore; cần giữ lại chứng cứ cần dùng khi chuyển máy, giữ profile/BAK thật riêng tư.
