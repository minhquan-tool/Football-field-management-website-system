-- Reviewed additive permissions for the four-role workflow repair.
-- Run explicitly against the intended database with a DBA account; no schema/data reset.
:ON ERROR EXIT
SET XACT_ABORT ON;
IF DB_NAME() IN ('master','model','msdb','tempdb') THROW 50800,'Select application database explicitly',1;
IF DATABASE_PRINCIPAL_ID('SanBongApp') IS NULL THROW 50801,'Expected runtime user is missing',1;
BEGIN TRANSACTION;
GRANT INSERT, UPDATE ON dbo.DanhGia TO SanBongApp;
GRANT INSERT ON dbo.ChiTietDanhGia TO SanBongApp;
GRANT INSERT, UPDATE ON dbo.PhanHoi TO SanBongApp;
GRANT INSERT, UPDATE ON dbo.LoaiSan TO SanBongApp;
GRANT INSERT, UPDATE ON dbo.KhungGio TO SanBongApp;
GRANT INSERT ON dbo.BangGia TO SanBongApp;
GRANT UPDATE ON dbo.GiaTheoCa TO SanBongApp;
GRANT INSERT, UPDATE ON dbo.KhuyenMai TO SanBongApp;
-- Only supply a missing permission row; never override a deliberate revocation.
IF NOT EXISTS(SELECT 1 FROM dbo.PhanQuyen WHERE MaVaiTro='VT02' AND MaChucNang='CN06')
 INSERT dbo.PhanQuyen(MaVaiTro,MaChucNang,Xem,Them,Sua,Xoa) VALUES('VT02','CN06',1,1,0,0);
COMMIT;
