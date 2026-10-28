/* SSMS normal mode. DBA creates dedicated server login privately first.
No password is included or changed. Run whole file in chosen NEW database.
*/
SET XACT_ABORT ON;
DECLARE @ReviewedDatabase sysname=N'QuanLySanBong_Test';
DECLARE @AppLogin sysname=N'REPLACE_WITH_EXISTING_APP_LOGIN';
IF DB_NAME()<>@ReviewedDatabase OR (@ReviewedDatabase NOT IN(N'QuanLySanBong',N'QuanLySanBong_Test') AND @ReviewedDatabase NOT LIKE N'QuanLySanBong[_]Fixtures[_]%') THROW 51430,'Wrong reviewed target',1;
IF @AppLogin=N'REPLACE_WITH_EXISTING_APP_LOGIN' OR @AppLogin IN(N'sa',N'dbo') OR SUSER_ID(@AppLogin) IS NULL THROW 51431,'Choose dedicated existing login',1;
IF IS_SRVROLEMEMBER(N'sysadmin',@AppLogin)=1 THROW 51432,'Runtime must not be sysadmin',1;
IF DATABASE_PRINCIPAL_ID(@AppLogin) IS NOT NULL THROW 51433,'User already exists; inspect mapping and rights manually',1;
IF DATABASE_PRINCIPAL_ID(N'SanBongRuntime') IS NULL THROW 51434,'Run full installer first',1;
BEGIN TRY BEGIN TRANSACTION;
DECLARE @sql nvarchar(max)=N'CREATE USER '+QUOTENAME(@AppLogin)+N' FOR LOGIN '+QUOTENAME(@AppLogin)+N'; ALTER ROLE SanBongRuntime ADD MEMBER '+QUOTENAME(@AppLogin)+N';';
EXEC sys.sp_executesql @sql;
COMMIT;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
