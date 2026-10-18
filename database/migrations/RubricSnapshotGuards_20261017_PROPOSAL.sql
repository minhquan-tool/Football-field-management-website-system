/* Financial snapshot guards: REVIEW REQUIRED before applying on the operating DB.
   No data backfill, no table alteration, no additional total calculation.
   Test first on the disposable fixture copy. All triggers are statement/set based.
   SQLCMD: -f 65001 -b -v ReviewedDatabase=<reviewed database> */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51020,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51021,'DEV/test marker required',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID('dbo.TRG_AuditContentImmutable') IS NOT NULL OR OBJECT_ID('dbo.TRG_ServicePriceSnapshot') IS NOT NULL OR OBJECT_ID('dbo.TRG_SuccessfulPaymentSnapshot') IS NOT NULL OR OBJECT_ID('dbo.TRG_SealedInvoiceSnapshot') IS NOT NULL THROW 51022,'Guard already installed; review before upgrade',1;
 EXEC(N'CREATE TRIGGER dbo.TRG_AuditContentImmutable ON dbo.NhatKyHeThong AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT * FROM inserted EXCEPT SELECT * FROM deleted)
 THROW 51023,''Audit records are append-only; content cannot be rewritten'',1;
 END;');
 EXEC(N'CREATE TRIGGER dbo.TRG_ServicePriceSnapshot ON dbo.ChiTietDichVu AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM inserted
 EXCEPT SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM deleted)
 THROW 51024,''Service SKU/price snapshot is immutable; only quantity may change before financial closing'',1;
 END;');
 EXEC(N'CREATE TRIGGER dbo.TRG_SuccessfulPaymentSnapshot ON dbo.ThanhToan AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM deleted WHERE TrangThai=N''Thành công''
 EXCEPT SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM inserted)
 THROW 51025,''A received payment is immutable; record a separate authorized refund'',1;
 END;');
 EXEC(N'CREATE TRIGGER dbo.TRG_SealedInvoiceSnapshot ON dbo.HoaDon AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM deleted WHERE DaChot=1
 EXCEPT SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM inserted)
 THROW 51026,''Sealed invoice identity and amounts cannot change; received total/status may be synchronized'',1;
 END;');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
