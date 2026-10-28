-- VERIFYONLY checks readability, not successful full restoration.
DECLARE @BackupFile nvarchar(4000)=N'REPLACE_WITH_EXISTING_BACKUP.bak';
IF @BackupFile LIKE N'REPLACE%' THROW 51443,'Choose backup file',1;
RESTORE HEADERONLY FROM DISK=@BackupFile;
RESTORE FILELISTONLY FROM DISK=@BackupFile;
RESTORE VERIFYONLY FROM DISK=@BackupFile WITH CHECKSUM;
