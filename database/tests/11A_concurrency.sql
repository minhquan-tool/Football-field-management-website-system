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

-- Mở cùng DB ở hai cửa sổ. Chạy A, trong 20 giây chuyển sang B.
BEGIN TRY
 BEGIN TRANSACTION;
 SELECT MaSan FROM dbo.San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@Pitch;
 SELECT @Pitch LockedPitch,@@SPID SessionA;
 WAITFOR DELAY '00:00:20';
 ROLLBACK;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
SELECT N'LOCK_RELEASED_NO_WRITES' Result;
