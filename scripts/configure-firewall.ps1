param([ValidateRange(1024,65535)][int]$Port=8080)
$ErrorActionPreference='Stop'
if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run elevated PowerShell to create the reviewed LAN-only web firewall rule.'}
if(Get-NetFirewallRule -Name 'SanBong-Internal-Web' -ErrorAction SilentlyContinue){throw 'Rule exists; review instead of broadening it.'}
New-NetFirewallRule -Name 'SanBong-Internal-Web' -DisplayName 'San_Bong internal web' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -RemoteAddress LocalSubnet -Profile Private,Domain
# Deliberately does not open SQL1433, Public profile, or Internet/router forwarding.
