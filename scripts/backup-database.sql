-- sqlcmd administrator only: -v BackupFile="server-accessible absolute path".
SET NOCOUNT ON;
DECLARE @file nvarchar(4000)=N'$(BackupFile)';
IF @file LIKE '%$(%' OR RIGHT(@file,4)<>'.bak' THROW 50720,'Provide a reviewed backup path',1;
IF EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@file) WHERE file_exists=1)
 THROW 50722,'Use a new backup filename; existing backup is protected',1;
BACKUP DATABASE [QuanLySanBong] TO DISK=@file WITH COPY_ONLY,CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@file WITH CHECKSUM;
-- Never WITH INIT: use a new filename for each backup; inspect FILELISTONLY/HEADERONLY before restoration.
