param(
 [Parameter(Mandatory=$true)][string]$BackupFile,
 [Parameter(Mandatory=$true)][ValidatePattern('^QuanLySanBong_Fixtures_[A-Za-z0-9_]+$')][string]$Database,
 [Parameter(Mandatory=$true)][ValidatePattern('^SanBongFixture_[A-Za-z0-9_]+$')][string]$Login,
 [Parameter(Mandatory=$true)][string]$BaseEnvFile,
 [string]$EnvFile=(Join-Path (Split-Path $PSScriptRoot -Parent) '.env.fixture.local'),
 [string]$SqlServer='tcp:localhost,1433'
)
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $EnvFile){throw 'Private fixture profile already exists; never overwrite it'}
$EnvFile=[IO.Path]::GetFullPath($EnvFile)
if(-not(Test-Path -LiteralPath ([IO.Path]::GetDirectoryName($EnvFile)) -PathType Container)){throw 'Private profile parent directory must already exist'}
$qaBase=[ordered]@{}
foreach($qaLine in Get-Content -LiteralPath (Resolve-Path -LiteralPath $BaseEnvFile).Path -Encoding utf8){if($qaLine -match '^([A-Z][A-Z0-9_]*)=(.*)$'){$qaBase[$matches[1]]=$matches[2].Trim().Trim('"').Trim("'")}}
if($qaBase['APP_DB_URL'] -notmatch '(?i)databaseName=QuanLySanBong(?:;|$)'){throw 'Expected source JDBC profile; no database/login created'}
Add-Type -AssemblyName System.Data.SqlClient
$qaBuilder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$qaBuilder['Data Source']=$SqlServer;$qaBuilder['Initial Catalog']='master';$qaBuilder['Integrated Security']=$true
$qaBuilder['Encrypt']=$true;$qaBuilder['TrustServerCertificate']=$true
$qaConnection=[System.Data.SqlClient.SqlConnection]::new($qaBuilder.ConnectionString)
function Invoke-FixtureSql([string]$Sql,[hashtable]$Values=@{}){
 $qaCommand=$qaConnection.CreateCommand();$qaCommand.CommandText=$Sql;$qaCommand.CommandTimeout=120
 foreach($qaKey in $Values.Keys){$null=$qaCommand.Parameters.AddWithValue('@'+$qaKey,$Values[$qaKey])}
 $qaTable=[System.Data.DataTable]::new();$qaAdapter=[System.Data.SqlClient.SqlDataAdapter]::new($qaCommand)
 try{$null=$qaAdapter.Fill($qaTable);return ,$qaTable}finally{$qaAdapter.Dispose();$qaCommand.Dispose()}
}
try{
 $qaConnection.Open()
 $qaPreflight=Invoke-FixtureSql "SELECT DB_ID(@target) TargetId,SUSER_ID(@login) LoginId,CONVERT(nvarchar(20),value) Marker FROM QuanLySanBong.sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment'" @{target=$Database;login=$Login}
 if($qaPreflight.Rows.Count -ne 1 -or $qaPreflight.Rows[0].Marker -notin @('dev','test') -or $qaPreflight.Rows[0].TargetId -isnot [DBNull] -or $qaPreflight.Rows[0].LoginId -isnot [DBNull]){throw 'Review target/source: existing DB/login or missing DEV/test classification'}
 $qaHeader=Invoke-FixtureSql 'RESTORE HEADERONLY FROM DISK=@file' @{file=$BackupFile}
 if($qaHeader.Rows.Count -ne 1 -or $qaHeader.Rows[0].DatabaseName -ne 'QuanLySanBong' -or $qaHeader.Rows[0].BackupType -ne 1 -or -not $qaHeader.Rows[0].HasBackupChecksums -or $qaHeader.Rows[0].IsDamaged){throw 'Expected one reviewed full checksum backup of QuanLySanBong'}
 $qaFiles=Invoke-FixtureSql 'RESTORE FILELISTONLY FROM DISK=@file WITH FILE=1' @{file=$BackupFile}
 if($qaFiles.Rows.Count -ne 2 -or @($qaFiles.Rows | Where-Object {$_.LogicalName -eq 'QuanLySanBong' -and $_.Type -eq 'D'}).Count -ne 1 -or @($qaFiles.Rows | Where-Object {$_.LogicalName -eq 'QuanLySanBong_log' -and $_.Type -eq 'L'}).Count -ne 1){throw 'Unreviewed backup file layout'}
 $qaRestore=@'
DECLARE @data nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath'))+@target+N'.mdf';
DECLARE @log nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath'))+@target+N'_log.ldf';
IF @data IS NULL OR @log IS NULL OR DB_ID(@target) IS NOT NULL THROW 50880,'Invalid target; no overwrite',1;
IF EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@data) WHERE file_exists=1) OR EXISTS(SELECT 1 FROM sys.dm_os_file_exists(@log) WHERE file_exists=1) THROW 50881,'Target file exists; no overwrite',1;
RESTORE VERIFYONLY FROM DISK=@file WITH FILE=1,CHECKSUM;
DECLARE @sql nvarchar(max)=N'RESTORE DATABASE '+QUOTENAME(@target)+N' FROM DISK=@f WITH FILE=1,CHECKSUM,MOVE N''QuanLySanBong'' TO @d,MOVE N''QuanLySanBong_log'' TO @l;';
EXEC sys.sp_executesql @sql,N'@f nvarchar(4000),@d nvarchar(4000),@l nvarchar(4000)',@f=@file,@d=@data,@l=@log;
'@
 $null=Invoke-FixtureSql $qaRestore @{target=$Database;file=$BackupFile}
 $qaRandom=[Security.Cryptography.RandomNumberGenerator]::Create();$qaRandomBytes=New-Object byte[] 24
 try{$qaRandom.GetBytes($qaRandomBytes)}finally{$qaRandom.Dispose()}
 $qaPassword='Fixture!'+(($qaRandomBytes | ForEach-Object {$_.ToString('X2')}) -join '')+'a1'
 $qaProvision=@'
IF SUSER_ID(@login) IS NOT NULL THROW 50882,'Fixture login exists; no password changes allowed',1;
DECLARE @sql nvarchar(max)=N'CREATE LOGIN '+QUOTENAME(@login)+N' WITH PASSWORD='+QUOTENAME(@password,'''')+N',DEFAULT_DATABASE='+QUOTENAME(@target)+N',CHECK_POLICY=ON,CHECK_EXPIRATION=OFF;';
EXEC sys.sp_executesql @sql;
SET @sql=N'USE '+QUOTENAME(@target)+N'; CREATE USER '+QUOTENAME(@login)+N' FOR LOGIN '+QUOTENAME(@login)+N'; ALTER ROLE db_datareader ADD MEMBER '+QUOTENAME(@login)+N'; ALTER ROLE db_datawriter ADD MEMBER '+QUOTENAME(@login)+N'; GRANT EXECUTE ON OBJECT::dbo.fn_TyLeHoan TO '+QUOTENAME(@login)+N'; DENY CONNECT TO SanBongApp; EXEC sys.sp_addextendedproperty @name=N''SanBongFixtureDatabase'',@value=1;';
EXEC sys.sp_executesql @sql;
'@
 $null=Invoke-FixtureSql $qaProvision @{target=$Database;login=$Login;password=$qaPassword}
 $qaBase['APP_DB_URL']=[regex]::Replace($qaBase['APP_DB_URL'],'(?i)databaseName=[^;]+',"databaseName=$Database")
 $qaBase['APP_DB_USER']=$Login;$qaBase['APP_DB_PASSWORD']=$qaPassword
 $qaBase['APP_ENV']='test';$qaBase['SAN_BONG_TEST_MODE']='test';$qaBase['SQLCMD_TEST_DATABASE']=$Database
 $qaBase['APP_HOST']='127.0.0.1';$qaBase['APP_PORT']='8086';$qaBase['AUTH_TEST_BASE_URL']='http://127.0.0.1:8086/api'
 $qaBase['APP_BANK_TRANSFER_ENABLED']='false';$qaBase['APP_MIGRATE_LEGACY_PASSWORDS']='false'
 $qaStream=[IO.File]::Open($EnvFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$qaWriter=[IO.StreamWriter]::new($qaStream,[Text.UTF8Encoding]::new($false));$qaWriter.WriteLine('# PRIVATE: disposable fixture identity; never use for the web runtime or commit this file.');foreach($qaKey in $qaBase.Keys){$qaWriter.WriteLine("$qaKey=$($qaBase[$qaKey])")};$qaWriter.Flush()}finally{$qaStream.Dispose()}
 $qaAcl=[Security.AccessControl.FileSecurity]::new();$qaAcl.SetAccessRuleProtection($true,$false)
 foreach($qaSid in @([Security.Principal.WindowsIdentity]::GetCurrent().User,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'),[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'))){$qaAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($qaSid,'FullControl','Allow'))}
 Set-Acl -LiteralPath $EnvFile -AclObject $qaAcl
 Write-Output "Disposable database created: $Database. Private fixture profile: $EnvFile. No existing database/login/password changed."
}finally{$qaPassword=$null;$qaConnection.Dispose()}
