-- Administrator drill only. This script cannot overwrite the live database.
SET NOCOUNT ON;
DECLARE @target sysname=N'QuanLySanBong_Phase7_RestoreTest';
IF DB_ID(@target) IS NOT NULL THROW 50721,'Restore test database already exists; no overwrite allowed',1;
DECLARE @file nvarchar(4000)=N'$(BackupFile)';
DECLARE @data nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath'))+@target+N'.mdf';
DECLARE @log nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath'))+@target+N'_log.ldf';
RESTORE FILELISTONLY FROM DISK=@file WITH FILE=1;
-- Review logical names before running. These names match the existing project database backup.
RESTORE DATABASE [QuanLySanBong_Phase7_RestoreTest] FROM DISK=@file
 WITH FILE=1,CHECKSUM,MOVE N'QuanLySanBong' TO @data,MOVE N'QuanLySanBong_log' TO @log;
DBCC CHECKDB([QuanLySanBong_Phase7_RestoreTest]) WITH NO_INFOMSGS;
