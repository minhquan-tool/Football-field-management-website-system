param([Parameter(Mandatory=$true)][string]$EnvFile)
$ErrorActionPreference='Stop'
$qaRoot=Split-Path $PSScriptRoot -Parent
$qaStage=Join-Path $qaRoot 'exports/ui-redesign-stage'
$qaJar=Join-Path $qaRoot 'backend/target/san-bong-backend-1.0.0.jar'
$qaCandidate=Join-Path $qaStage 'backend/target/san-bong-backend-1.0.0.jar'
$qaBackup=Join-Path $qaRoot ('exports/backend-before-ui-redesign-'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.jar')
foreach($qaFamily in @('frontend','backend/src/main')){
 foreach($qaSource in Get-ChildItem -LiteralPath (Join-Path $qaRoot $qaFamily) -Recurse -File){
  $qaRelative=$qaSource.FullName.Substring($qaRoot.Length+1)
  $qaCopy=Join-Path $qaStage $qaRelative
  if(-not(Test-Path -LiteralPath $qaCopy) -or (Get-FileHash -LiteralPath $qaSource.FullName).Hash -ne (Get-FileHash -LiteralPath $qaCopy).Hash){throw "Candidate differs from source: $qaRelative"}
 }
}
foreach($qaCheck in @('pages','forms')){
 $qaEvidence=Get-Content -LiteralPath (Join-Path $qaRoot "exports/ui-redesign-$qaCheck-8084.log") -Raw
 if($qaEvidence -notmatch '"status"\s*:\s*"PASS"'){throw "Candidate $qaCheck verification is missing"}
}
foreach($qaLine in Get-Content -LiteralPath (Resolve-Path -LiteralPath $EnvFile).Path -Encoding utf8){
 if($qaLine -match '^([A-Z][A-Z0-9_]*)=(.*)$'){[Environment]::SetEnvironmentVariable($matches[1],$matches[2].Trim().Trim('"').Trim("'"),'Process')}
}
if($env:APP_DB_USER -ne 'SanBongApp' -or $env:APP_DB_URL -notmatch 'databaseName=QuanLySanBong(?:;|$)'){throw 'Expected the existing reviewed runtime profile'}
$qaListeners=@(Get-NetTCPConnection -LocalPort 8082 -State Listen -ErrorAction Stop | Select-Object -ExpandProperty OwningProcess -Unique)
if($qaListeners.Count -ne 1){throw 'Expected exactly one current web process'}
$qaOld=Get-CimInstance Win32_Process -Filter "ProcessId=$($qaListeners[0])"
if($qaOld.Name -ne 'java.exe' -or $qaOld.CommandLine -notlike '*san-bong-backend-1.0.0.jar*'){throw 'Listener is not the project Java process'}
$qaOldHash=(Get-FileHash -LiteralPath $qaJar).Hash
Copy-Item -LiteralPath $qaJar -Destination $qaBackup
Stop-Process -Id $qaOld.ProcessId
$env:APP_PORT='8082';$env:APP_LOG_FILE=Join-Path $qaRoot 'exports/ui-redesign-main-application.log'
function Start-ReviewedWeb{
 Start-Process -FilePath (Join-Path $env:JAVA_HOME 'bin/java.exe') -ArgumentList '-jar','target/san-bong-backend-1.0.0.jar' -WorkingDirectory (Join-Path $qaRoot 'backend') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $qaRoot 'exports/ui-redesign-main.log') -RedirectStandardError (Join-Path $qaRoot 'exports/ui-redesign-main-error.log')
}
$qaNew=$null
try{
 Copy-Item -LiteralPath $qaCandidate -Destination $qaJar -Force
 $qaNew=Start-ReviewedWeb
 $qaHealthy=$false
 for($qaAttempt=0;$qaAttempt -lt 35;$qaAttempt++){
  try{if((Invoke-RestMethod 'http://127.0.0.1:8082/api/health' -TimeoutSec 2).status -eq 'UP'){$qaHealthy=$true;break}}catch{}
  $qaNew.Refresh();if($qaNew.HasExited){throw 'New web exited'}
  Start-Sleep -Seconds 1
 }
 if(-not $qaHealthy){throw 'New web startup timed out'}
 $qaHtml=(Invoke-WebRequest 'http://127.0.0.1:8082/api/Trang_chu.html' -TimeoutSec 5).Content
 $qaCss=(Invoke-WebRequest 'http://127.0.0.1:8082/api/css/experience.css' -TimeoutSec 5).Content
 if($qaHtml -notmatch 'css/experience.css' -or $qaCss -notmatch 'FC-UTE UI/UX Pro Max'){throw 'New assets were not served'}
 [ordered]@{status='DEPLOYED_HEALTHY';deployedAt=[DateTimeOffset]::Now.ToString('o');runtimePid=$qaNew.Id;port=8082;jarSha256=(Get-FileHash -LiteralPath $qaJar).Hash;previousJarSha256=$qaOldHash;rollbackJar=$qaBackup;databaseMigrations=0;htmlPages=20;candidateMenuRoutes=27;candidateForms='PASS';candidatePages='PASS'}|ConvertTo-Json|Set-Content (Join-Path $qaRoot 'exports/ui-redesign-deployment.json') -Encoding utf8
 'UI REDESIGN DEPLOYED; health and new assets verified on 8082'
}catch{
 $qaFailure=$_
 if($qaNew){$qaNew.Refresh();if(-not $qaNew.HasExited){Stop-Process -Id $qaNew.Id}}
 Copy-Item -LiteralPath $qaBackup -Destination $qaJar -Force
 $qaRollback=Start-ReviewedWeb
 throw "UI deployment failed; previous JAR restarted as PID $($qaRollback.Id). $($qaFailure.Exception.Message)"
}
