param([Parameter(Mandatory=$true)][string]$EnvFile,[ValidateSet('8082','8084')][string]$Port='8084',[string]$Session='ui-redesign',[ValidateSet('pages','forms')][string]$Check='pages',[switch]$UseLegacyDemoPassword)
$ErrorActionPreference='Stop'
$qaRoot=Split-Path $PSScriptRoot -Parent
$qaPassword=$null
foreach($qaLine in Get-Content -LiteralPath (Resolve-Path -LiteralPath $EnvFile).Path -Encoding utf8){if($qaLine -match '^AUTH_TEST_PASSWORD=(.*)$'){$qaPassword=$matches[1].Trim().Trim('"').Trim("'")}}
if(-not $qaPassword -and $UseLegacyDemoPassword){
 if(-not(Get-Content -LiteralPath $EnvFile | Where-Object {$_ -match '^SAN_BONG_TEST_MODE=(dev|test)$'})){throw 'Demo authentication requires DEV/test opt-in'}
 $qaPassword='123456'
}
if(-not $qaPassword){throw 'Private AUTH_TEST_PASSWORD is required'}
$qaCli=(Get-Command playwright-cli.cmd -ErrorAction Stop).Source
$qaTemplate=if($Check -eq 'forms'){'backend/scripts/ui-redesign-forms-browser.js'}else{'backend/scripts/ui-redesign-browser.js'}
$qaCode=[IO.File]::ReadAllText((Join-Path $qaRoot $qaTemplate))
$qaSecretJson=ConvertTo-Json -InputObject $qaPassword -Compress
$qaCode=$qaCode.Replace('__QA_BASE_JSON__',(ConvertTo-Json "http://127.0.0.1:$Port/api/" -Compress)).Replace('__QA_PASSWORD_JSON__',$qaSecretJson)
$qaPrivate=Join-Path $qaRoot 'run/ui-redesign-browser-private.js'
try{
 [IO.File]::WriteAllText($qaPrivate,$qaCode,[Text.UTF8Encoding]::new($false))
 $qaAcl=[Security.AccessControl.FileSecurity]::new();$qaAcl.SetAccessRuleProtection($true,$false)
 foreach($qaSid in @([Security.Principal.WindowsIdentity]::GetCurrent().User,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'),[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'))){$qaAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($qaSid,'FullControl','Allow'))}
 Set-Acl -LiteralPath $qaPrivate -AclObject $qaAcl
 $qaOutput=& $qaCli "-s=$Session" run-code "--filename=$qaPrivate" 2>&1
 $qaExit=$LASTEXITCODE
 $qaSafe=($qaOutput | ForEach-Object {$_.ToString().Replace($qaSecretJson,'"[REDACTED]"').Replace($qaPassword,'[REDACTED]')}) -join "`n"
 [IO.File]::WriteAllText((Join-Path $qaRoot "exports/ui-redesign-$Check-$Port.log"),$qaSafe,[Text.UTF8Encoding]::new($false))
 if($qaExit -ne 0 -or $qaSafe -notmatch '"status"\s*:\s*"PASS"'){throw "UI check failed; inspect exports/ui-redesign-$Check-$Port.log"}
 "UI REDESIGN PASS on $Port; sanitized evidence saved"
}finally{
 $qaPassword=$null;$qaCode=$null
 if(Test-Path -LiteralPath $qaPrivate){Remove-Item -LiteralPath $qaPrivate}
}
