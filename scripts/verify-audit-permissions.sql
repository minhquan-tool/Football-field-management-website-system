:ON ERROR EXIT
-- Run as the web runtime identity. No record is modified: both probes use WHERE 1=0.
SET NOCOUNT ON;
IF CURRENT_USER<>N'SanBongApp' THROW 50820,'Connect as the intended runtime identity SanBongApp',1;
IF ISNULL(HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'INSERT'),0)<>1
 OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'SELECT'),0)<>1
 THROW 50821,'Audit append/read must remain available',1;
IF ISNULL(HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE'),1)<>0
 OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'DELETE'),1)<>0
 OR EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.NhatKyHeThong')
 AND HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE',name,N'COLUMN')=1)
 THROW 50822,'Runtime can rewrite audit history',1;
DECLARE @updateDenied bit=0,@deleteDenied bit=0;
BEGIN TRY
 EXEC(N'UPDATE dbo.NhatKyHeThong SET NoiDungThayDoi=NoiDungThayDoi WHERE 1=0;');
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>229 THROW;
 SET @updateDenied=1;
END CATCH;
BEGIN TRY
 EXEC(N'DELETE FROM dbo.NhatKyHeThong WHERE 1=0;');
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>229 THROW;
 SET @deleteDenied=1;
END CATCH;
IF @updateDenied<>1 OR @deleteDenied<>1 THROW 50823,'Expected SQL permission denial for both audit probes',1;
SELECT N'PASS' AS AuditIntegrity,CURRENT_USER AS RuntimeIdentity,
 @updateDenied AS UpdateDenied,@deleteDenied AS DeleteDenied,
 (SELECT COUNT_BIG(*) FROM dbo.NhatKyHeThong) AS ReadableAuditRows;
