-- SSMS normal mode; SQL Server service needs access to this NEW destination.
SET NOCOUNT ON;
DECLARE @Database sysname=N'QuanLySanBong';
DECLARE @BackupFile nvarchar(4000)=N'REPLACE_WITH_NEW_ABSOLUTE_PATH.bak';
IF DB_ID(@Database) IS NULL OR @Database NOT IN(N'QuanLySanBong',N'QuanLySanBong_Test') THROW 51440,'Review database',1;
IF @BackupFile LIKE N'REPLACE%' OR RIGHT(@BackupFile,4)<>N'.bak' THROW 51441,'Choose backup path',1;
IF EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@BackupFile) WHERE file_exists=1) THROW 51442,'Backup exists; choose new filename',1;
BACKUP DATABASE @Database TO DISK=@BackupFile WITH COPY_ONLY,CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@BackupFile WITH CHECKSUM;
