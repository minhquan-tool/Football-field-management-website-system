/* DBA executes on the disposable fixture. No persistent permission changes.
   Demo accounts have no login and can only be impersonated by authorized DBA. */
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1) THROW 51060,'Disposable fixture required',1;
EXECUTE AS USER='SB_DemoCustomer';
IF HAS_PERMS_BY_NAME('dbo.San','OBJECT','SELECT')<>1 OR HAS_PERMS_BY_NAME('dbo.ThanhToan','OBJECT','SELECT')<>0 THROW 51061,'Customer permissions mismatch',1;
SELECT TOP(1) MaSan FROM dbo.San;
REVERT;
EXECUTE AS USER='SB_DemoPitchStaff';
IF HAS_PERMS_BY_NAME('dbo.usp_ReportUsage','OBJECT','EXECUTE')<>1 OR HAS_PERMS_BY_NAME('dbo.usp_ReportFinance','OBJECT','EXECUTE')<>0 THROW 51062,'Pitch staff permissions mismatch',1;
EXEC dbo.usp_ReportUsage '20261017','20261017','';
REVERT;
EXECUTE AS USER='SB_DemoAccountant';
IF HAS_PERMS_BY_NAME('dbo.usp_ReportFinance','OBJECT','EXECUTE')<>1 OR HAS_PERMS_BY_NAME('dbo.San','OBJECT','UPDATE')<>0 THROW 51063,'Accountant permissions mismatch',1;
EXEC dbo.usp_ReportFinance '20261017','20261017','';
REVERT;
EXECUTE AS USER='SB_DemoManager';
IF HAS_PERMS_BY_NAME('dbo.San','OBJECT','UPDATE')<>1 OR HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','UPDATE')<>0 OR HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','DELETE')<>0 THROW 51064,'Manager permissions mismatch',1;
SELECT TOP(1) MaNhatKy FROM dbo.NhatKyHeThong;
REVERT;
-- Prove actual SQL denial, rather than relying solely on metadata.
EXECUTE AS USER='SB_DemoCustomer';
BEGIN TRY
 SELECT TOP(1) MaTT FROM dbo.ThanhToan;
 REVERT;
 THROW 51065,'Customer unexpectedly read all receipts',1;
END TRY
BEGIN CATCH
 DECLARE @denied int=ERROR_NUMBER();REVERT;
 IF @denied<>229 THROW;
 SELECT 'CUSTOMER_SELECT_DENIED_229' result;
END CATCH;
-- GRANT -> REVOKE -> DENY, rolled back to the reviewed role matrix.
BEGIN TRY
 BEGIN TRANSACTION;
 GRANT SELECT ON dbo.KhungGio TO SB_Customer;
 EXECUTE AS USER='SB_DemoCustomer';
 IF HAS_PERMS_BY_NAME('dbo.KhungGio','OBJECT','SELECT')<>1 THROW 51066,'GRANT failed',1;
 REVERT;
 REVOKE SELECT ON dbo.KhungGio FROM SB_Customer;
 EXECUTE AS USER='SB_DemoCustomer';
 IF HAS_PERMS_BY_NAME('dbo.KhungGio','OBJECT','SELECT')<>0 THROW 51067,'REVOKE failed',1;
 REVERT;
 DENY SELECT ON dbo.KhungGio TO SB_Customer;
 EXECUTE AS USER='SB_DemoCustomer';
 IF HAS_PERMS_BY_NAME('dbo.KhungGio','OBJECT','SELECT')<>0 THROW 51068,'DENY failed',1;
 REVERT;
 ROLLBACK;
 SELECT 'FOUR_ROLES_AND_GRANT_REVOKE_DENY_PASS' result;
END TRY
BEGIN CATCH
 IF USER_NAME()='SB_DemoCustomer' REVERT;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
