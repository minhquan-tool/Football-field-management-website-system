-- SSMS thường, KHÔNG cần SQLCMD Mode. Chạy CẢ FILE, không bỏ đoạn chặn môi trường.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @EnableDemo bit=0; -- Chủ động đổi thành 1 CHỈ trên bản sao demo.
IF @EnableDemo<>1 THROW 51200,'Opt-in required: set EnableDemo=1 on a disposable copy',1;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test'))
 THROW 51201,'Disposable fixture name AND test/dev markers required. Never mark the operating DB.',1;
IF @@TRANCOUNT<>0 THROW 51202,'Close existing transaction before demonstration',1;
SELECT @@SERVERNAME AS ServerName,DB_NAME() AS DemoDatabase;

DECLARE @Pitch varchar(10),@Day date;
SELECT TOP(1) @Pitch=d.MaSan,@Day=d.NgayChoi FROM dbo.DatSan d JOIN dbo.San s ON s.MaSan=d.MaSan
WHERE s.MoTa=N'Isolated synthetic transaction demonstration' AND d.GhiChu=N'Rubric transaction fixture'
 AND d.TrangThai=N'Đã xác nhận' ORDER BY d.MaSan,d.MaDatSan;
IF @Pitch IS NULL THROW 51270,'Run 02 fixture first',1;

SET LOCK_TIMEOUT 2000;
DECLARE @Stage int=0;
BEGIN TRY
 BEGIN TRANSACTION;
 SELECT MaSan FROM dbo.San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@Pitch;
 SET @Stage=1;
 SELECT MaDatSan FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@Pitch AND NgayChoi=@Day;
 IF EXISTS(SELECT 1 FROM dbo.DatSan WHERE MaSan=@Pitch AND NgayChoi=@Day AND TrangThai<>N'Đã hủy' AND GioBatDau<'09:00' AND GioKetThuc>'08:00')
 THROW 51271,'Overlapping booking rejected by interval check after San lock',1;
 THROW 51272,'No overlapping fixture found; inspect 02 fixture data',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 SET LOCK_TIMEOUT -1;
 IF ERROR_NUMBER() NOT IN(1222,51271) THROW;
 SELECT ERROR_NUMBER() ObservedError,ERROR_MESSAGE() Explanation,@Stage LockAcquired;
END CATCH;
-- Khi A đang khóa: 1222. Chạy lại B sau A rollback: 51271 do trùng 08:00–09:00.
-- Không INSERT thật trong bài này. Muốn chứng minh hai API đặt sân: dùng test backend riêng.
