-- Authorized 2026-10-17: fix the high-priority audit permission finding.
-- Future executions still require the operator's authorization for the target database.
-- Connect to the reviewed QuanLySanBong DEV/test database with an administrator.
-- Only blocks UPDATE/DELETE of audit records by the runtime database user.
-- INSERT/SELECT and business-table permissions are not changed.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'QuanLySanBong' THROW 50810,'Expected reviewed database QuanLySanBong',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test'))
    THROW 50811,'Reviewed DEV/test marker required',1;
IF DATABASE_PRINCIPAL_ID(N'SanBongApp') IS NULL THROW 50812,'Runtime database user missing',1;
IF OBJECT_ID(N'dbo.NhatKyHeThong',N'U') IS NULL THROW 50813,'Audit table missing',1;
-- Capture current direct permissions for DBA review/rollback planning before changing them.
SELECT USER_NAME(grantee_principal_id) AS PrincipalName,state_desc,permission_name
FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'SanBongApp')
AND major_id=OBJECT_ID(N'dbo.NhatKyHeThong');
BEGIN TRY
    BEGIN TRANSACTION;
    DENY UPDATE,DELETE ON OBJECT::dbo.NhatKyHeThong TO SanBongApp;
    DECLARE @canInsert int,@canSelect int,@canUpdate int,@canDelete int,@columnUpdate int;
    EXECUTE AS USER=N'SanBongApp';
    SELECT @canInsert=HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'INSERT'),
           @canSelect=HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'SELECT'),
           @canUpdate=HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE'),
           @canDelete=HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'DELETE');
    SELECT @columnUpdate=COUNT(*) FROM sys.columns
    WHERE object_id=OBJECT_ID(N'dbo.NhatKyHeThong')
      AND HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE',name,N'COLUMN')=1;
    REVERT;
    IF ISNULL(@canInsert,0)<>1 OR ISNULL(@canSelect,0)<>1
       OR ISNULL(@canUpdate,1)<>0 OR ISNULL(@canDelete,1)<>0 OR ISNULL(@columnUpdate,1)<>0
        THROW 50814,'Audit permissions failed verification; change will roll back',1;
    COMMIT;
END TRY
BEGIN CATCH
    IF USER_NAME()=N'SanBongApp' REVERT;
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
-- Verification, no record is updated/deleted by this script.
EXECUTE AS USER=N'SanBongApp';
SELECT CURRENT_USER AS RuntimeUser,
    HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'INSERT') AS CanAppendAudit,
    HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE') AS CanUpdateAudit,
    HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'DELETE') AS CanDeleteAudit;
REVERT;
