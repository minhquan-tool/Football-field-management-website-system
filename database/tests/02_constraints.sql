SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1)
 OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1) THROW 51413,'Untrusted/disabled constraints',1;
DECLARE @rejected bit=0;
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.San(MaSan,TenSan,MaLoaiSan,TrangThai) VALUES('ZZ_BAD_FK',N'Test','ZZ_NO_TYPE',N'Trống');
 ROLLBACK;
END TRY BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>547 THROW;
 SET @rejected=1;
END CATCH;
IF @rejected=0 THROW 51414,'Foreign key did not reject invalid type',1;
SELECT N'PASS' AS Constraints;
