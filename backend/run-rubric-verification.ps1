param([Parameter(Mandatory=$true)][string]$EnvFile,[switch]$Offline)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'verification-suites.ps1')
foreach($qaLine in Get-Content -LiteralPath (Resolve-Path -LiteralPath $EnvFile).Path -Encoding utf8){if($qaLine -match '^([A-Z][A-Z0-9_]*)=(.*)$'){[Environment]::SetEnvironmentVariable($matches[1],$matches[2].Trim().Trim('"').Trim("'"),'Process')}}
Assert-SanBongVerificationProfile -Suite fixtures
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/java-toolchain.ps1')
Assert-SanBongJava24 -JavaPath (Join-Path $env:JAVA_HOME 'bin/java.exe')
$qaMaven=if($env:MAVEN_HOME){Join-Path $env:MAVEN_HOME 'bin/mvn.cmd'}else{(Get-Command mvn.cmd -ErrorAction Stop).Source}
$qaTests=(Get-SanBongVerificationTests fixtures)+',RubricSqlIntegrationTest'
$qaArguments=@('-B',"-Dtest=$qaTests",'test');if($Offline){$qaArguments=@('-o')+$qaArguments}
Push-Location $PSScriptRoot
try{
 $ErrorActionPreference='Continue'; & $qaMaven @qaArguments; $qaExit=$LASTEXITCODE; $ErrorActionPreference='Stop'
 if($qaExit -ne 0){throw "Rubric fixture verification failed ($qaExit)"}
}finally{Pop-Location}
