/* After verify-backup.sql: fill logical file names from FILELISTONLY.
Supports exactly one data + one log file; additional files need DBA-reviewed MOVE entries.
Never uses REPLACE. New SQL physical files must not already exist.
*/
DECLARE @Target sysname=N'QuanLySanBong_Fixtures_RestoreReview';
DECLARE @BackupFile nvarchar(4000)=N'REPLACE_WITH_EXISTING_BACKUP.bak';
DECLARE @LogicalData sysname=N'REPLACE_LOGICAL_DATA',@LogicalLog sysname=N'REPLACE_LOGICAL_LOG';
DECLARE @DataFile nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath'))+@Target+N'.mdf';
DECLARE @LogFile nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath'))+@Target+N'_log.ldf';
IF @Target NOT LIKE N'QuanLySanBong[_]Fixtures[_]%' OR @Target LIKE N'%[^A-Za-z0-9_]%' OR DB_ID(@Target) IS NOT NULL THROW 51444,'Choose NEW fixture database',1;
IF @BackupFile LIKE N'REPLACE%' OR @LogicalData LIKE N'REPLACE%' OR @LogicalLog LIKE N'REPLACE%' THROW 51445,'Review backup and logical files',1;
IF @DataFile IS NULL OR @LogFile IS NULL THROW 51446,'Default file paths unavailable',1;
IF EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@DataFile) WHERE file_exists=1) OR EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@LogFile) WHERE file_exists=1) THROW 51447,'Physical file exists',1;
RESTORE DATABASE @Target FROM DISK=@BackupFile WITH FILE=1,CHECKSUM,MOVE @LogicalData TO @DataFile,MOVE @LogicalLog TO @LogFile;
DBCC CHECKDB(@Target) WITH NO_INFOMSGS;
-- Mark only after successful restore, before any test runner may use the copy.
DECLARE @sql nvarchar(max)=N'USE '+QUOTENAME(@Target)+N';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N''SanBongEnvironment'') EXEC sys.sp_updateextendedproperty @name=N''SanBongEnvironment'',@value=N''test'';
ELSE EXEC sys.sp_addextendedproperty @name=N''SanBongEnvironment'',@value=N''test'';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N''SanBongFixtureDatabase'') EXEC sys.sp_updateextendedproperty @name=N''SanBongFixtureDatabase'',@value=1;
ELSE EXEC sys.sp_addextendedproperty @name=N''SanBongFixtureDatabase'',@value=1;';
EXEC sys.sp_executesql @sql;
