SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
DECLARE @canRead int,@canReadAccounts int;
EXECUTE AS USER=N'SB_DemoCustomer';
SELECT @canRead=HAS_PERMS_BY_NAME(N'dbo.San',N'OBJECT',N'SELECT'),@canReadAccounts=HAS_PERMS_BY_NAME(N'dbo.TaiKhoan',N'OBJECT',N'SELECT');
REVERT;
IF ISNULL(@canRead,0)<>1 OR ISNULL(@canReadAccounts,1)<>0 THROW 51423,'Customer permissions incorrect',1;
DECLARE @sql nvarchar(max);
BEGIN TRY BEGIN TRANSACTION;
 CREATE USER SB_TestRuntime WITHOUT LOGIN;
 ALTER ROLE SanBongRuntime ADD MEMBER SB_TestRuntime;
 EXECUTE AS USER=N'SB_TestRuntime';
 SELECT @canRead=HAS_PERMS_BY_NAME(N'dbo.YeuCauHuyDatSan',N'OBJECT',N'INSERT'),@canReadAccounts=HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'DELETE');
 REVERT;
 IF ISNULL(@canRead,0)<>1 OR ISNULL(@canReadAccounts,1)<>0 THROW 51424,'Runtime permissions incorrect',1;
 ROLLBACK;
END TRY BEGIN CATCH IF USER_NAME()=N'SB_TestRuntime' REVERT; IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
SELECT N'PASS' AS Permissions;
