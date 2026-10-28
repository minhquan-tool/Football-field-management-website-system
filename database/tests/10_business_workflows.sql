SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
IF EXISTS(SELECT 1 FROM dbo.DatSan WHERE TongTien<>TienSan+TienDichVu-TienGiam) THROW 51425,'Booking total mismatch',1;
IF EXISTS(SELECT 1 FROM dbo.HoaDon WHERE TongTien<>TienSan+TienDichVu-TienGiam OR DaThanhToan<0) THROW 51426,'Invoice totals invalid',1;
IF EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE ThanhTien<>SoLuong*DonGia) THROW 51427,'Service totals invalid',1;
SELECT N'PASS' AS FinancialInvariants;
-- Interval overlap and API transaction/idempotency checks remain in backend tests.
