param([ValidateSet('start','run','stop','restart')][string]$Action='start',[string]$EnvFile)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root 'run';$logs=Join-Path $root 'logs';$pidFile=Join-Path $run 'server.json'
[void](New-Item -ItemType Directory -Force -Path $run,$logs)
function Stop-Server {
 param([int]$ExpectedId=0)
 if(-not(Test-Path -LiteralPath $pidFile)){Write-Output 'No managed server PID file.';return}
 $saved=Get-Content -LiteralPath $pidFile -Raw | ConvertFrom-Json
 if($ExpectedId -ne 0 -and $saved.id -ne $ExpectedId){throw 'Startup ownership changed; stop refused.'}
 $process=Get-Process -Id $saved.id -ErrorAction SilentlyContinue
 if($process){
  $info=Get-CimInstance Win32_Process -Filter "ProcessId=$($saved.id)"
  if($info.Name -notmatch '^java(w)?[.]exe$' -or -not $info.CommandLine.Contains($saved.jar) -or $process.StartTime.ToUniversalTime().ToString('o') -ne $saved.started){throw 'PID identity changed; stop refused.'}
  # Windows Stop-Process terminates JVM; use only after users stop writes. SQL rolls back interrupted transactions.
  Stop-Process -Id $saved.id -ErrorAction Stop
  $process.WaitForExit()
 }
 Remove-Item -LiteralPath $pidFile
 Write-Output 'Managed server stopped.'
}
function Clear-OwnPid([int]$Id) {
 if(Test-Path -LiteralPath $pidFile){$saved=Get-Content -LiteralPath $pidFile -Raw|ConvertFrom-Json;if($saved.id -eq $Id){Remove-Item -LiteralPath $pidFile}}
}
if($Action -eq 'stop'){Stop-Server;exit}
if($Action -ne 'restart' -and (Test-Path -LiteralPath $pidFile)){$saved=Get-Content -LiteralPath $pidFile -Raw|ConvertFrom-Json;if(Get-Process -Id $saved.id -ErrorAction SilentlyContinue){throw 'Managed server is already running.'};Remove-Item -LiteralPath $pidFile}
if(-not $EnvFile){$EnvFile=$env:SAN_BONG_ENV_FILE};if(-not $EnvFile){$EnvFile=Join-Path $root 'deploy.env'}
if(-not(Test-Path -LiteralPath $EnvFile)){throw 'Supply -EnvFile or SAN_BONG_ENV_FILE; deploy.env example has no credentials.'}
foreach($line in Get-Content -LiteralPath $EnvFile -Encoding UTF8){if($line -match '^([A-Z][A-Z0-9_]*)=(.*)$'){[Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process')}}
if(-not $env:APP_ENV){$env:APP_ENV='internal'}
if($env:APP_ENV -notin @('dev','test','internal')){throw 'APP_ENV must be dev, test or internal.'}
foreach($key in @('APP_DB_URL','APP_DB_USER','APP_DB_PASSWORD')){if(-not[Environment]::GetEnvironmentVariable($key,'Process')){throw "Configure $key privately before starting."}}
if($env:APP_DB_URL -match '(?i)(password|pwd)\s*='){throw 'Do not embed DB password in JDBC URL.'}
$java=if($env:JAVA_HOME){Join-Path $env:JAVA_HOME 'bin/java.exe'}else{(Get-Command java.exe -ErrorAction Stop).Source}
. (Join-Path $PSScriptRoot 'java-toolchain.ps1')
Assert-SanBongJava24 -JavaPath $java
$jar=if($env:APP_JAR){$env:APP_JAR}else{Join-Path $root 'backend/target/san-bong-backend-1.0.0.jar'}
if(-not [IO.Path]::IsPathRooted($jar)){$jar=Join-Path $root $jar}
$jar=(Resolve-Path -LiteralPath $jar).Path
if($Action -eq 'restart'){Stop-Server}
$port=if($env:APP_PORT){[int]$env:APP_PORT}else{8080}
if(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue){throw "Port $port is already occupied; do not stop an unknown process."}
if(-not $env:APP_LOG_FILE){$env:APP_LOG_FILE=Join-Path $logs 'application.log'}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$process=Start-Process -FilePath $java -ArgumentList @('-jar',('"'+$jar+'"')) -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs "startup-$stamp.log") -RedirectStandardError (Join-Path $logs "startup-$stamp-error.log") -PassThru
@{id=$process.Id;jar=$jar;started=$process.StartTime.ToUniversalTime().ToString('o')}|ConvertTo-Json|Set-Content -LiteralPath $pidFile -Encoding UTF8
$context=if($env:APP_CONTEXT_PATH){$env:APP_CONTEXT_PATH}else{'/api'}
$scheme=if($env:SERVER_SSL_ENABLED -eq 'true'){'https'}else{'http'}
$health="$($scheme)://127.0.0.1:$port$context/health"
if($env:APP_HEALTH_URL){$health=$env:APP_HEALTH_URL}
$ready=$false
for($attempt=0;$attempt -lt 45;$attempt++){
 if($process.HasExited){Clear-OwnPid $process.Id;throw 'Java exited during startup. Review local application/startup logs.'}
 try{$response=Invoke-RestMethod -Uri $health -TimeoutSec 2;if($response.status -eq 'UP'){$ready=$true;break}}catch{}
 Start-Sleep -Milliseconds 500
}
if(-not $ready){Stop-Server -ExpectedId $process.Id;throw 'Health did not become UP; server stopped.'}
Write-Output "Server running PID=$($process.Id); health UP; logs=$logs"
if($Action -eq 'run'){
 $process.WaitForExit()
 Clear-OwnPid $process.Id
 if($process.ExitCode -ne 0){throw 'Java exited unexpectedly; scheduler recovery may restart it.'}
}
