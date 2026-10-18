param([string]$BackupDirectory,[string]$ArchiveDirectory,[ValidateRange(7,365)][int]$KeepDays=14,[switch]$Prune)
$ErrorActionPreference='Stop'
$qaLogs=Join-Path (Split-Path $PSScriptRoot -Parent) 'run/backup-task-logs'
if(-not(Test-Path -LiteralPath $qaLogs)){New-Item -ItemType Directory -Path $qaLogs | Out-Null}
$qaLog=Join-Path $qaLogs ('backup_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.log')
Start-Transcript -LiteralPath $qaLog | Out-Null
try{
 & (Join-Path $PSScriptRoot 'backup-database.ps1') @PSBoundParameters
}finally{Stop-Transcript | Out-Null}
