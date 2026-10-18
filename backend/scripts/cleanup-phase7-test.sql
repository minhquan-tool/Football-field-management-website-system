:ON ERROR EXIT
-- Select the reviewed DEV/TEST database with sqlcmd -d; never change databases here.
-- Explicit opt-in: environment SAN_BONG_TEST_MODE=dev/test or sqlcmd -v SAN_BONG_TEST_MODE=dev/test.
IF N'$(SAN_BONG_TEST_MODE)' NOT IN (N'dev',N'test') THROW 50704,'Fixture SQL requires explicit dev/test opt-in',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN('dev','test')) THROW 50703,'Fixture SQL refused: target is not dev/test',1;
-- Dev/test fixture only; use state exact IDs, sqlcmd -f65001 -b.
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @pitch varchar(10)='$(PitchId)',@nv varchar(10)='$(EmployeeId)',@tk varchar(10)='$(AccountId)';
IF LEN(@pitch)<>9 OR @pitch NOT LIKE 'P7H%' OR SUBSTRING(@pitch,4,6) LIKE '%[^0-9A-F]%'
 OR LEN(@nv)<>10 OR @nv NOT LIKE 'NV%' OR LEN(@tk)<>10 OR @tk NOT LIKE 'TK%'
 THROW 50640,'Invalid fixture identifiers',1;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM NhanVien WITH(UPDLOCK,HOLDLOCK) WHERE MaNV=@nv AND HoTen=N'Phase7 E2E fixture '+@pitch)
 OR NOT EXISTS(SELECT 1 FROM TaiKhoan WHERE MaTK=@tk AND MaNV=@nv AND TenDangNhap='test_'+@pitch)
 THROW 50641,'Employee/account marker missing',1;
IF EXISTS(SELECT 1 FROM San WHERE MaSan=@pitch AND (MoTa IS NULL OR MoTa<>N'Phase7 E2E fixture'))
 OR EXISTS(SELECT 1 FROM DatSan WHERE MaSan=@pitch AND (GhiChu IS NULL OR GhiChu<>N'Phase7 E2E fixture'))
 OR EXISTS(SELECT 1 FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@pitch AND (t.MaGiaoDich IS NULL OR t.MaGiaoDich NOT LIKE @pitch+'-%'))
 OR EXISTS(SELECT 1 FROM XacNhanSan x JOIN DatSan d ON d.MaDatSan=x.MaDatSan WHERE d.MaSan=@pitch AND x.ThoiGianKetThuc IS NULL)
 OR EXISTS(SELECT 1 FROM DanhGia WHERE MaSan=@pitch)
 OR EXISTS(SELECT 1 FROM DatSan WHERE MaNV=@nv AND MaSan<>@pitch)
 OR EXISTS(SELECT 1 FROM TaiKhoan WHERE MaNV=@nv AND MaTK<>@tk)
 THROW 50642,'Non-fixture history; stop cleanup',1;
DELETE h FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@pitch;
DELETE t FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan WHERE d.MaSan=@pitch;
DELETE c FROM HuyDatSan c JOIN DatSan d ON d.MaDatSan=c.MaDatSan WHERE d.MaSan=@pitch;
DELETE c FROM ChiTietDichVu c JOIN DatSan d ON d.MaDatSan=c.MaDatSan WHERE d.MaSan=@pitch;
DELETE h FROM HoaDon h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan=@pitch;
DELETE x FROM XacNhanSan x JOIN DatSan d ON d.MaDatSan=x.MaDatSan WHERE d.MaSan=@pitch;
DELETE NhatKyHeThong WHERE MaTK=@tk OR DoiTuong IN(@pitch,@nv,@tk) OR DoiTuong IN(SELECT MaDatSan FROM DatSan WHERE MaSan=@pitch);
DELETE DatSan WHERE MaSan=@pitch;
DELETE San WHERE MaSan=@pitch AND MoTa=N'Phase7 E2E fixture';
DELETE TaiKhoan WHERE MaTK=@tk AND MaNV=@nv;
DELETE NhanVien WHERE MaNV=@nv AND HoTen=N'Phase7 E2E fixture '+@pitch;
COMMIT;
