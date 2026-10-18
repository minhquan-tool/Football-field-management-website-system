[CmdletBinding(SupportsShouldProcess=$true)]
param()
$ErrorActionPreference='Stop'
$qaProject=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$qaRun=Join-Path $qaProject 'run'
$qaBackup=Join-Path $qaRun 'backups'
# Never change permissions on an existing SQL/system/user folder.
foreach($qaPath in @($qaProject,$qaRun)){
 if((Get-Item -LiteralPath $qaPath).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Backup parent must not be a reparse point'}
}
if(Test-Path -LiteralPath $qaBackup){throw 'Backup directory exists; inspect its ACL rather than resetting permissions automatically'}
try{Add-Type -AssemblyName System.Data.SqlClient}catch{Add-Type -AssemblyName System.Data}
$qaConnection=[System.Data.SqlClient.SqlConnection]::new('Data Source=tcp:localhost,1433;Initial Catalog=master;Integrated Security=True;Encrypt=True;TrustServerCertificate=True')
try{
 $qaConnection.Open();$qaCommand=$qaConnection.CreateCommand()
 $qaCommand.CommandText="SELECT service_account FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server (%'"
 $qaService=[string]$qaCommand.ExecuteScalar();$qaCommand.Dispose()
 if(-not $qaService){throw 'Cannot determine local SQL engine service account'}
 $qaServiceSid=([Security.Principal.NTAccount]::new($qaService)).Translate([Security.Principal.SecurityIdentifier])
}finally{$qaConnection.Dispose()}
if($PSCmdlet.ShouldProcess($qaBackup,"Create private backup directory; only current Windows user, SYSTEM, administrators and SQL engine ($qaService)")){
 $qaAcl=[Security.AccessControl.DirectorySecurity]::new();$qaAcl.SetAccessRuleProtection($true,$false)
 $qaInheritance=[Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
 foreach($qaSid in @([Security.Principal.WindowsIdentity]::GetCurrent().User,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'),[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'))){
  $qaAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($qaSid,'FullControl',$qaInheritance,'None','Allow'))
 }
 $qaAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($qaServiceSid,'Modify',$qaInheritance,'None','Allow'))
 $null=New-Item -ItemType Directory -Path $qaBackup
 Set-Acl -LiteralPath $qaBackup -AclObject $qaAcl
 [pscustomobject]@{directory=$qaBackup;sqlEngine=$qaService;protectedAcl=(Get-Acl -LiteralPath $qaBackup).AreAccessRulesProtected}|ConvertTo-Json
}
