param([Parameter(Mandatory=$true)][string]$EnvFile,[string]$TaskUser="$env:USERDOMAIN\$env:USERNAME")
$ErrorActionPreference='Stop'
if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run elevated PowerShell after reviewing task user and secret file permissions.'}
$script=(Join-Path $PSScriptRoot 'server.ps1');$file=(Resolve-Path -LiteralPath $EnvFile).Path
if(Get-ScheduledTask -TaskName 'SanBongInternal' -ErrorAction SilentlyContinue){throw 'Task exists; review before replacing it.'}
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`" -Action run -EnvFile `"$file`"" -WorkingDirectory (Split-Path $PSScriptRoot -Parent)
$principal=New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType S4U -RunLevel Limited
$settings=New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'SanBongInternal' -Action $action -Trigger (New-ScheduledTaskTrigger -AtStartup) -Principal $principal -Settings $settings -Description 'Spring Boot internal; local SQL auth/env, no wrapper dependency'
