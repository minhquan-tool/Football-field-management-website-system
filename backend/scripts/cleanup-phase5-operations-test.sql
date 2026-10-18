:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- Exact generated operational fixture only. UTF-8: sqlcmd -b -f 65001.
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
IF NOT EXISTS(SELECT 1 FROM San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@id AND MoTa=N'Phase5 HTTP operations temporary test')
    OR NOT EXISTS(SELECT 1 FROM DatSan WHERE MaDatSan=@id AND MaSan=@id AND MaKhungGio=@id AND GhiChu=N'Phase5 HTTP operations temporary test')
    THROW 50002,'Fixture ownership marker changed; cleanup refused',1;
IF EXISTS(SELECT 1 FROM ThanhToan WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM HuyDatSan WHERE MaDatSan=@id)
    OR EXISTS(SELECT 1 FROM DanhGia WHERE MaSan=@id OR MaDatSan=@id)
    OR EXISTS(SELECT 1 FROM DatSan WHERE MaDatSan<>@id AND (MaSan=@id OR MaKhungGio=@id))
    OR EXISTS(SELECT 1 FROM BangGia WHERE MaKhungGio=@id)
    THROW 50003,'Non-test or financial history found; cleanup refused',1;
DELETE FROM ChiTietDichVu WHERE MaDatSan=@id;
DELETE FROM XacNhanSan WHERE MaDatSan=@id;
DELETE FROM NhatKyHeThong WHERE DoiTuong=@id AND ChucNang=N'Nhận sân / Dịch vụ';
DELETE FROM DatSan WHERE MaDatSan=@id;
DELETE FROM San WHERE MaSan=@id AND MoTa=N'Phase5 HTTP operations temporary test';
DELETE FROM KhungGio WHERE MaKhungGio=@id;
COMMIT;
GO
