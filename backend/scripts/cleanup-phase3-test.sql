:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- ONLY for the exact generated HTTP-test pitch; never reset existing business data.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @id varchar(10)='$(PITCH_TEST_ID)';
IF LEN(@id)<>9 OR LEFT(@id,3)<>'T3T' OR SUBSTRING(@id,4,6) LIKE '%[^0-9A-F]%'
    THROW 50001,'Invalid generated test ID; cleanup refused',1;
IF EXISTS(SELECT 1 FROM San WHERE MaSan=@id AND ISNULL(MoTa,N'')<>N'Phase3 automated temporary test')
    THROW 50002,'Pitch marker changed; cleanup refused',1;
IF EXISTS(SELECT 1 FROM DatSan WHERE MaSan=@id) OR EXISTS(SELECT 1 FROM DanhGia WHERE MaSan=@id)
    THROW 50003,'Pitch has history; cleanup refused',1;
DELETE FROM NhatKyHeThong WHERE DoiTuong=@id AND ChucNang=N'Quản lý sân';
DELETE FROM San WHERE MaSan=@id AND MoTa=N'Phase3 automated temporary test';
COMMIT;
GO
