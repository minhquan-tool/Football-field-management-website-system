:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- Exact finance HTTP fixture only. sqlcmd -f 65001 -b -v PitchId=FCHxxxxxx
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @id varchar(10)='$(PitchId)';
IF LEN(@id)<>9 OR @id NOT LIKE 'FCH%' OR SUBSTRING(@id,4,6) LIKE '%[^0-9A-F]%'
 THROW 50610,'Invalid fixture ID',1;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@id AND MoTa=N'Phase5.1C HTTP temporary test')
 THROW 50611,'Fixture marker missing',1;
IF EXISTS(SELECT 1 FROM DatSan WHERE MaSan=@id AND (GhiChu IS NULL OR GhiChu<>N'Phase5.1C HTTP temporary test'))
 OR EXISTS(SELECT 1 FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@id AND (t.MaGiaoDich IS NULL OR t.MaGiaoDich NOT LIKE @id+'-%'))
 OR EXISTS(SELECT 1 FROM XacNhanSan x JOIN DatSan d ON d.MaDatSan=x.MaDatSan WHERE d.MaSan=@id AND x.ThoiGianKetThuc IS NULL)
 OR EXISTS(SELECT 1 FROM DanhGia WHERE MaSan=@id)
 THROW 50612,'Non-test history or open visit; cleanup refused',1;
DELETE h FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@id;
DELETE t FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@id;
DELETE h FROM HuyDatSan h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan=@id;
DELETE c FROM ChiTietDichVu c JOIN DatSan d ON d.MaDatSan=c.MaDatSan WHERE d.MaSan=@id;
DELETE h FROM HoaDon h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan=@id;
DELETE x FROM XacNhanSan x JOIN DatSan d ON d.MaDatSan=x.MaDatSan WHERE d.MaSan=@id;
DELETE FROM NhatKyHeThong WHERE DoiTuong=@id OR DoiTuong IN(SELECT MaDatSan FROM DatSan WHERE MaSan=@id);
DELETE FROM DatSan WHERE MaSan=@id;
DELETE FROM San WHERE MaSan=@id;
COMMIT;
