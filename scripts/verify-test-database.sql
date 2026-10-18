:ON ERROR EXIT
-- READ ONLY preflight. Connect with the intended runtime login and reviewed -d target.
SET NOCOUNT ON;
SELECT DB_NAME() AS DatabaseName,
       ORIGINAL_LOGIN() AS RuntimeLogin,
       IS_SRVROLEMEMBER('sysadmin') AS IsSysadmin,
       IS_MEMBER('db_owner') AS IsDbOwner,
       HAS_PERMS_BY_NAME('dbo.fn_TyLeHoan','OBJECT','EXECUTE') AS CanExecuteRefundRate,
       HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','DELETE') AS CanDeleteAudit,
       HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','UPDATE') AS CanUpdateAudit,
       HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','INSERT') AS CanAppendAudit,
       HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','SELECT') AS CanReadAudit;
SELECT CONVERT(nvarchar(20),value) AS EnvironmentMarker
FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment';
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment'
 AND CONVERT(nvarchar(20),value) IN (N'dev',N'test'))
 THROW 50703,'Selected database is not classified dev/test; no fixture tests allowed',1;
IF ISNULL(IS_SRVROLEMEMBER('sysadmin'),1)<>0 OR ISNULL(IS_MEMBER('db_owner'),1)<>0
 THROW 50712,'Test runtime identity must not be sysadmin/db_owner',1;
IF ISNULL(HAS_PERMS_BY_NAME('dbo.fn_TyLeHoan','OBJECT','EXECUTE'),0)<>1
 THROW 50713,'Runtime identity cannot execute refund rate function',1;
IF ISNULL(HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','DELETE'),1)<>0
 THROW 50714,'Runtime identity can delete audit history; review effective permissions',1;
IF ISNULL(HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','UPDATE'),1)<>0
 OR EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.NhatKyHeThong')
 AND HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE',name,N'COLUMN')=1)
 THROW 50715,'Runtime identity can update audit history; review effective permissions',1;
IF ISNULL(HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','INSERT'),0)<>1
 OR ISNULL(HAS_PERMS_BY_NAME('dbo.NhatKyHeThong','OBJECT','SELECT'),0)<>1
 THROW 50716,'Runtime identity must retain append/read audit permissions',1;
