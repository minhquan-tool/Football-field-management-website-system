[CmdletBinding(SupportsShouldProcess=$true)]
param(
 [ValidatePattern('^\d{2}:\d{2}$')][string]$AtTime='02:00',
 [ValidateRange(7,365)][int]$KeepDays=14,
 [string]$BackupDirectory,
 [string]$ArchiveDirectory,
 [switch]$Interactive,
 [switch]$Prune,
 [string]$TaskUser="$env:USERDOMAIN\$env:USERNAME",
 [string]$TaskName='SanBongSqlBackup'
)
$ErrorActionPreference='Stop'
$qaAt=[DateTime]::ParseExact($AtTime,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
$qaRoot=Split-Path $PSScriptRoot -Parent
$qaScript=Join-Path $PSScriptRoot 'run-scheduled-backup.ps1'
foreach($qaValue in @($qaScript,$BackupDirectory,$ArchiveDirectory)){if($qaValue -and $qaValue.Contains('"')){throw 'Embedded quotes are not allowed in task paths'}}
if($ArchiveDirectory.StartsWith('\\')){throw 'S4U cannot access a network share; configure a reviewed service identity in Task Scheduler for off-machine archives'}
$qaArguments="-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$qaScript`" -KeepDays $KeepDays"
if($Prune){$qaArguments+=' -Prune'}
if($BackupDirectory){$qaArguments+=" -BackupDirectory `"$BackupDirectory`""}
if($ArchiveDirectory){$qaArguments+=" -ArchiveDirectory `"$ArchiveDirectory`""}
$qaPlan=[pscustomobject]@{task=$TaskName;database='QuanLySanBong';dailyAt=$AtTime;keepDays=$KeepDays;prune=[bool]$Prune;interactive=[bool]$Interactive;user=$TaskUser;execute='powershell.exe';arguments=$qaArguments;workingDirectory=$qaRoot;networkArchiveConfigured=[bool]$ArchiveDirectory}
$qaPlan | ConvertTo-Json
if($PSCmdlet.ShouldProcess($TaskName,'Register reviewed daily SQL backup task (no overwrite)')){
 if($Interactive -and $TaskUser -ne [Security.Principal.WindowsIdentity]::GetCurrent().Name){throw 'Interactive task must use the current Windows identity'}
 if(-not $Interactive -and -not [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'S4U requires elevated PowerShell; use -Interactive for a same-user task that runs only while logged in'}
 if(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue){throw 'Task exists; inspect it, no automatic replacement'}
 $qaAction=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $qaArguments -WorkingDirectory $qaRoot
 $qaPrincipal=if($Interactive){New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType Interactive -RunLevel Limited}else{New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType S4U -RunLevel Highest}
 $qaSettings=New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 10) -ExecutionTimeLimit (New-TimeSpan -Hours 2)
 Register-ScheduledTask -TaskName $TaskName -Action $qaAction -Trigger (New-ScheduledTaskTrigger -Daily -At $qaAt) -Principal $qaPrincipal -Settings $qaSettings -Description 'SanBong SQL backup: COPY_ONLY/CHECKSUM/VERIFYONLY; verified receipts and bounded local retention; no web runtime credentials'
}
