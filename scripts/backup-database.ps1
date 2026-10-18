[CmdletBinding(SupportsShouldProcess=$true)]
param(
 [string]$SqlServer='tcp:localhost,1433',
 [string]$BackupDirectory,
 [string]$ArchiveDirectory,
 [string]$ReceiptDirectory,
 [ValidateRange(7,365)][int]$KeepDays=14,
 [switch]$Prune
)
$ErrorActionPreference='Stop'
if(-not $ReceiptDirectory){$ReceiptDirectory=Join-Path (Split-Path $PSScriptRoot -Parent) 'run/backup-receipts'}
# Run on the SQL host under a Windows DBA/backup identity, never with web runtime credentials.
if($SqlServer -notmatch '^(tcp:)?(localhost|127\.0\.0\.1)(,\d+)?$'){throw 'Run this local-file backup runner on the SQL host using localhost'}
try{Add-Type -AssemblyName System.Data.SqlClient}catch{Add-Type -AssemblyName System.Data}
$qaBuilder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$qaBuilder['Data Source']=$SqlServer;$qaBuilder['Initial Catalog']='master';$qaBuilder['Integrated Security']=$true
$qaBuilder['Encrypt']=$true;$qaBuilder['TrustServerCertificate']=$true
$qaConnection=[System.Data.SqlClient.SqlConnection]::new($qaBuilder.ConnectionString)
try{
 $qaConnection.Open()
 if(-not $BackupDirectory){$qaLookup=$qaConnection.CreateCommand();$qaLookup.CommandText="SELECT CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultBackupPath'))";try{$BackupDirectory=[string]$qaLookup.ExecuteScalar()}finally{$qaLookup.Dispose()}}
 if(-not $BackupDirectory -or -not [IO.Path]::IsPathRooted($BackupDirectory)){throw 'A local absolute backup directory is required'}
 $qaRoot=[IO.Path]::GetFullPath($BackupDirectory).TrimEnd('\')
 if(-not(Test-Path -LiteralPath $qaRoot -PathType Container)){throw 'Backup directory must exist and be writable by the SQL service'}
 if((Get-Item -LiteralPath $qaRoot).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Backup directory must not be a reparse point'}
 if($ArchiveDirectory -and (-not [IO.Path]::IsPathRooted($ArchiveDirectory) -or -not(Test-Path -LiteralPath $ArchiveDirectory -PathType Container))){throw 'Reviewed archive directory must already exist'}
 $qaName='QuanLySanBong_Auto_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.bak'
 $qaFile=Join-Path $qaRoot $qaName
 if(-not $PSCmdlet.ShouldProcess($qaFile,'Create COPY_ONLY CHECKSUM backup and verify it')){return}
 $qaCommand=$qaConnection.CreateCommand();$qaCommand.CommandTimeout=300
 $qaCommand.CommandText=@'
IF EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@file) WHERE file_exists=1) THROW 50890,'Backup exists; no overwrite',1;
BACKUP DATABASE [QuanLySanBong] TO DISK=@file WITH COPY_ONLY,CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@file WITH CHECKSUM;
'@
 $null=$qaCommand.Parameters.Add('@file',[System.Data.SqlDbType]::NVarChar,4000);$qaCommand.Parameters['@file'].Value=$qaFile
 try{$null=$qaCommand.ExecuteNonQuery()}finally{$qaCommand.Dispose()}
 $qaHash=$null
 try{$qaHash=(Get-FileHash -LiteralPath $qaFile -Algorithm SHA256 -ErrorAction Stop).Hash}
 catch{Write-Warning 'SQL CHECKSUM/VERIFYONLY passed, but this Windows identity cannot hash the backup file. Archive/retention require reviewed OS read rights.'}
 $qaRecord=[ordered]@{managedBy='SanBongBackupV1';database='QuanLySanBong';verified=$true;verification='SQL COPY_ONLY CHECKSUM and RESTORE VERIFYONLY';createdAt=[DateTimeOffset]::UtcNow.ToString('o');file=$qaFile;sha256=$qaHash;archiveVerified=$false;archiveFile=$null}
 $qaReceiptRoot=[IO.Path]::GetFullPath($ReceiptDirectory)
 if(-not(Test-Path -LiteralPath $qaReceiptRoot)){New-Item -ItemType Directory -Path $qaReceiptRoot | Out-Null}
 $qaManifest=Join-Path $qaReceiptRoot ($qaName+'.verified.json')
 if($ArchiveDirectory){
  if(-not $qaHash){throw 'Local SQL backup verified, but Windows file read rights are required before archive copy; no retention performed'}
  $qaArchiveFile=Join-Path ([IO.Path]::GetFullPath($ArchiveDirectory)) $qaName
  [IO.File]::Copy($qaFile,$qaArchiveFile,$false)
  if((Get-FileHash -LiteralPath $qaArchiveFile -Algorithm SHA256).Hash -ne $qaHash){throw 'Archive hash mismatch; local backup retained, no retention pruning'}
  $qaRecord.archiveVerified=$true;$qaRecord.archiveFile=$qaArchiveFile
 }
 $qaRecord | ConvertTo-Json | Set-Content -LiteralPath $qaManifest -Encoding utf8
 if($Prune){
  $qaCutoff=[DateTimeOffset]::UtcNow.AddDays(-$KeepDays)
  foreach($qaCandidate in Get-ChildItem -LiteralPath $qaReceiptRoot -File -Filter 'QuanLySanBong_Auto_*.bak.verified.json'){
   $qaOld=Get-Content -LiteralPath $qaCandidate.FullName -Raw | ConvertFrom-Json
   if($qaOld.managedBy -ne 'SanBongBackupV1' -or $qaOld.database -ne 'QuanLySanBong' -or $qaOld.verified -ne $true){continue}
   if([DateTimeOffset]::Parse($qaOld.createdAt) -ge $qaCutoff){continue}
   $qaOldFile=[IO.Path]::GetFullPath([string]$qaOld.file)
   if(-not [string]::Equals([IO.Path]::GetDirectoryName($qaOldFile),$qaRoot,[StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($qaOldFile) -notmatch '^QuanLySanBong_Auto_\d{8}_\d{6}_[a-f0-9]{8}\.bak$' -or
    $qaCandidate.Name -ne ([IO.Path]::GetFileName($qaOldFile)+'.verified.json')){throw 'Retention manifest escapes reviewed directory'}
   if(-not $qaOld.sha256){Write-Warning 'Skip old backup without an OS hash; retention needs reviewed Windows read/delete rights';continue}
   if($ArchiveDirectory -and $qaOld.archiveVerified -ne $true){continue}
   if(-not(Test-Path -LiteralPath $qaOldFile -PathType Leaf)){continue}
   if((Get-Item -LiteralPath $qaOldFile).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Retention refuses reparse-point files'}
   if((Get-FileHash -LiteralPath $qaOldFile -Algorithm SHA256).Hash -ne $qaOld.sha256){throw 'Old backup changed; retention refuses deletion'}
   if($PSCmdlet.ShouldProcess($qaOldFile,'Delete only this runner verified backup older than retention')){Remove-Item -LiteralPath $qaOldFile;Remove-Item -LiteralPath $qaCandidate.FullName}
  }
 }
 $qaRecord | ConvertTo-Json
}finally{$qaConnection.Dispose()}
