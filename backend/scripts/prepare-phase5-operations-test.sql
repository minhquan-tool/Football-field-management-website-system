:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- Test-only fixture in existing tables. No payment, refund, schema reset or change to existing bookings.
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
DECLARE @id varchar(10)='$(OPERATIONS_TEST_ID)';
IF LEN(@id)<>9 OR LEFT(@id,3)<>'P5H' OR SUBSTRING(@id,4,6) LIKE '%[^0-9A-F]%'
    THROW 50001,'Invalid generated operations test ID',1;
IF EXISTS(SELECT 1 FROM San WHERE MaSan=@id) OR EXISTS(SELECT 1 FROM KhungGio WHERE MaKhungGio=@id)
    OR EXISTS(SELECT 1 FROM DatSan WHERE MaDatSan=@id)
    THROW 50002,'Fixture ID already exists; no changes made',1;
INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa)
VALUES(@id,N'Phase5 HTTP test only','LS01',N'Trống',N'Phase5 HTTP operations temporary test');
INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES(@id,'00:00','23:59:59',23.99);
INSERT INTO DatSan(MaDatSan,MaKH,MaSan,MaKhungGio,NgayChoi,GioBatDau,GioKetThuc,ThoiLuong,DonGia,TienSan,TongTien,TrangThai,GhiChu)
VALUES(@id,'KH01',@id,@id,CAST(GETDATE() AS date),'00:00','23:59:59',23.99,150000,150000,150000,N'Đã xác nhận',N'Phase5 HTTP operations temporary test');
COMMIT;
GO
