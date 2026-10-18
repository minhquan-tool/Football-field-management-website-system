$ErrorActionPreference='Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'verification-suites.ps1')
$qaRuntime=(Get-SanBongVerificationTests -Suite runtime) -split ','
$qaFixtures=(Get-SanBongVerificationTests -Suite fixtures) -split ','
if($qaFixtures.Count -ne 7 -or @($qaRuntime | Where-Object {$_ -in $qaFixtures}).Count){throw 'Unsafe overlapping suite selection'}
foreach($qaClass in $qaFixtures){$qaFile=Join-Path (Split-Path $PSScriptRoot -Parent) "src/test/java/com/sanbong/$qaClass.java";if([IO.File]::ReadAllText($qaFile) -notmatch '@AuditCleanupFixture'){throw "Missing fixture marker: $qaClass"}}
$qaSaved=@{};foreach($qaKey in @('SAN_BONG_TEST_MODE','APP_DB_USER','SQLCMD_TEST_DATABASE')){$qaSaved[$qaKey]=[Environment]::GetEnvironmentVariable($qaKey,'Process')}
function Assert-Rejected([scriptblock]$Action){$qaRejected=$false;try{& $Action}catch{$qaRejected=$true};if(-not $qaRejected){throw 'Unsafe profile accepted'}}
try{
 $env:SAN_BONG_TEST_MODE='test';$env:APP_DB_USER='SanBongApp';$env:SQLCMD_TEST_DATABASE='QuanLySanBong'
 Assert-SanBongVerificationProfile runtime
 Assert-Rejected {Assert-SanBongVerificationProfile fixtures}
 $env:APP_DB_USER='SanBongFixture_Check';$env:SQLCMD_TEST_DATABASE='QuanLySanBong_Fixtures_Check'
 Assert-SanBongVerificationProfile fixtures
 Assert-Rejected {Assert-SanBongVerificationProfile runtime}
 $env:SAN_BONG_TEST_MODE='internal'
 Assert-Rejected {Assert-SanBongVerificationProfile fixtures}
}finally{foreach($qaKey in $qaSaved.Keys){[Environment]::SetEnvironmentVariable($qaKey,$qaSaved[$qaKey],'Process')}}
Write-Output 'VERIFICATION_SUITE_POLICY_PASS: disjoint suites, seven fixture markers, runtime/fixture profile boundaries, opt-in; no database accessed.'
