SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
IF EXISTS(SELECT 1 FROM sys.triggers WHERE parent_class=1 AND is_disabled=1) THROW 51419,'Disabled trigger',1;
DECLARE @id varchar(10)=(SELECT TOP(1) MaHoaDon FROM dbo.HoaDon WHERE DaChot=1 ORDER BY MaHoaDon),@rejected bit=0;
IF @id IS NULL THROW 51420,'Sealed invoice fixture missing; do not silently skip',1;
BEGIN TRY BEGIN TRANSACTION;
 UPDATE dbo.HoaDon SET NgayLap=DATEADD(second,1,NgayLap) WHERE MaHoaDon=@id;
 ROLLBACK;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; IF ERROR_NUMBER()<>51026 THROW; SET @rejected=1; END CATCH;
IF @rejected=0 THROW 51421,'Sealed invoice update was accepted',1;
SELECT N'PASS' AS Triggers;
