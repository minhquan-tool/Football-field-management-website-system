:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- Exact generated HTTP-test pitch and its isolated test history only. Read UTF-8: sqlcmd -f 65001.
SET XACT_ABORT ON;
-- Required by SQL Server's existing filtered unique index; these are session settings, not DDL.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
DECLARE @id varchar(10)='$(PITCH_TEST_ID)';
DECLARE @marker nvarchar(255)=N'Phase4 HTTP automated temporary test';
IF LEN(@id)<>9 OR LEFT(@id,3)<>'P4H' OR SUBSTRING(@id,4,6) LIKE '%[^0-9A-F]%'
    THROW 50001,'Invalid generated test ID; cleanup refused',1;
IF NOT EXISTS(SELECT 1 FROM San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@id AND MoTa=@marker)
    THROW 50002,'Test pitch absent or marker changed; cleanup refused',1;
IF EXISTS(SELECT 1 FROM DatSan WHERE MaSan=@id AND (ISNULL(GhiChu,N'')<>@marker OR TrangThai<>N'Đã hủy'))
    THROW 50003,'Booking marker/state changed; cleanup refused',1;
IF EXISTS(SELECT 1 FROM DanhGia WHERE MaSan=@id)
    OR EXISTS(SELECT 1 FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@id)
    OR EXISTS(SELECT 1 FROM ChiTietDichVu c JOIN DatSan d ON d.MaDatSan=c.MaDatSan WHERE d.MaSan=@id)
    THROW 50004,'Pitch has non-test financial/service/review history; cleanup refused',1;
DECLARE @bookings TABLE(id varchar(10));
INSERT INTO @bookings SELECT MaDatSan FROM DatSan WHERE MaSan=@id;
DELETE FROM NhatKyHeThong WHERE ChucNang=N'Đặt sân' AND DoiTuong IN(SELECT id FROM @bookings);
DELETE FROM HuyDatSan WHERE MaDatSan IN(SELECT id FROM @bookings) AND LyDo=@marker AND SoTienHoan=0;
DELETE FROM DatSan WHERE MaDatSan IN(SELECT id FROM @bookings);
DELETE FROM NhatKyHeThong WHERE ChucNang=N'Quản lý sân' AND DoiTuong=@id;
DELETE FROM San WHERE MaSan=@id AND MoTa=@marker;
COMMIT;
GO
