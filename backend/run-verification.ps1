param(
 [Parameter(Mandatory=$true)][ValidateSet('runtime','fixtures')][string]$Suite,
 [Parameter(Mandatory=$true)][string]$EnvFile,
 [switch]$Offline,
 [switch]$ListOnly
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'verification-suites.ps1')
$qaTests=Get-SanBongVerificationTests -Suite $Suite
if($ListOnly){Write-Output "$Suite : $qaTests";return}
foreach($qaLine in Get-Content -LiteralPath (Resolve-Path -LiteralPath $EnvFile).Path -Encoding utf8){if($qaLine -match '^([A-Z][A-Z0-9_]*)=(.*)$'){[Environment]::SetEnvironmentVariable($matches[1],$matches[2].Trim().Trim('"').Trim("'"),'Process')}}
Assert-SanBongVerificationProfile -Suite $Suite
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/java-toolchain.ps1')
Assert-SanBongJava24 -JavaPath (Join-Path $env:JAVA_HOME 'bin/java.exe')
$qaCommand=Get-Command mvn.cmd -ErrorAction SilentlyContinue
if($env:MAVEN_HOME){$qaMaven=Join-Path $env:MAVEN_HOME 'bin/mvn.cmd'}elseif($qaCommand){$qaMaven=$qaCommand.Source}else{throw 'Install Maven on PATH or set MAVEN_HOME to the real local installation'}
$qaArguments=@('-B',"-Dtest=$qaTests",'test');if($Offline){$qaArguments=@('-o')+$qaArguments}
Push-Location $PSScriptRoot
try{
 $ErrorActionPreference='Continue'
 & $qaMaven @qaArguments
 $qaExit=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 if($qaExit -ne 0){throw "Verification suite failed: $Suite (exit $qaExit)"}
}finally{Pop-Location}
