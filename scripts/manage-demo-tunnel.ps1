param(
    [ValidateSet('start','status','stop')][string]$Action='status',
    [string[]]$AllowedEmail,
    [ValidateRange(1024,65535)][int]$Port=8082
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$binary=Join-Path $root 'exports/tunnel-tools/cloudflared.exe'
$stateDirectory=Join-Path $root 'run'
$stateFile=Join-Path $stateDirectory 'demo-tunnel.json'
$logFile=Join-Path $stateDirectory 'demo-tunnel.log'
function Read-State {
    if(Test-Path -LiteralPath $stateFile){return Get-Content -LiteralPath $stateFile -Raw|ConvertFrom-Json}
    return $null
}
function Find-Process($state) {
    if(-not $state){return $null}
    $process=Get-Process -Id $state.processId -ErrorAction SilentlyContinue
    if(-not $process){return $null}
    if($process.Path -ne $binary -or $process.StartTime.ToUniversalTime().Ticks.ToString() -ne $state.startedTicks){
        throw 'PID ownership mismatch. Inspect manually; no process was stopped.'
    }
    return $process
}
$state=Read-State
if($Action -eq 'stop'){
    $process=Find-Process $state
    if($process){Stop-Process -Id $process.Id;Write-Output 'Demo tunnel stopped. Backend remains running.'}
    else{Write-Output 'Demo tunnel is not running.'}
    if($state){$state.status='STOPPED';$state|ConvertTo-Json|Set-Content -LiteralPath $stateFile -Encoding utf8}
    exit
}
if($Action -eq 'status'){
    $process=Find-Process $state
    if($process){Write-Output "Tunnel process running: $($process.Id)";Write-Output "Demo URL: $($state.url)/trang-chu";Write-Output 'External email-PIN/client verification is still required.'}
    else{Write-Output 'Demo tunnel is not running.'}
    exit
}
if(Find-Process $state){throw 'Demo tunnel is already running. Use -Action status or stop first.'}
if(-not(Test-Path -LiteralPath $binary)){throw 'cloudflared missing. Use the official Windows release; see docs/HTTPS_DEMO_TUNNEL.md.'}
if(-not $AllowedEmail){throw 'Supply -AllowedEmail with the exact email addresses permitted to access the demo.'}
$emails=@($AllowedEmail|ForEach-Object {$_ -split ','}|ForEach-Object {$_.Trim().ToLowerInvariant()}|Select-Object -Unique)
foreach($email in $emails){
    if($email -notmatch '^[a-z0-9._%+\-]+@[a-z0-9\-]+(?:\.[a-z0-9\-]+)+$'){
        throw 'Use explicit valid email addresses; wildcards and empty addresses are not accepted.'
    }
}
$help=& $binary tunnel --help
if(-not($help -match '--allowed-mail')){throw 'This cloudflared version does not support protected Quick Tunnels. Refusing an unprotected fallback.'}
$health=Invoke-WebRequest -Uri "http://127.0.0.1:$Port/api/health" -UseBasicParsing -TimeoutSec 10
if($health.StatusCode -ne 200){throw 'Backend is not healthy.'}
foreach($name in @('config.yaml','config.yml')){
    if(Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".cloudflared/$name")){
        throw 'Existing cloudflared configuration found. Review it before using a Quick Tunnel; it was not modified.'
    }
}
New-Item -ItemType Directory -Force -Path $stateDirectory|Out-Null
$argsForTunnel=@('tunnel','--no-autoupdate','--url',"http://127.0.0.1:$Port",'--allowed-mail',($emails -join ','),'--loglevel','info')
$process=Start-Process -FilePath $binary -ArgumentList $argsForTunnel -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardError $logFile -RedirectStandardOutput (Join-Path $stateDirectory 'demo-tunnel-stdout.log')
$state=[pscustomobject]@{status='STARTING';processId=$process.Id;startedTicks=$process.StartTime.ToUniversalTime().Ticks.ToString();url='';originPort=$Port}
$state|ConvertTo-Json|Set-Content -LiteralPath $stateFile -Encoding utf8
try{
    for($attempt=0;$attempt -lt 40;$attempt++){
        $process.Refresh()
        if($process.HasExited){throw 'cloudflared exited. See run/demo-tunnel.log.'}
        if(Test-Path -LiteralPath $logFile){
            $match=[regex]::Match((Get-Content -LiteralPath $logFile -Raw),'https://[a-z0-9-]+\.trycloudflare\.com')
            if($match.Success){$state.url=$match.Value;break}
        }
        Start-Sleep -Seconds 1
    }
    if(-not $state.url){throw 'No demo URL was assigned within 40 seconds.'}
    $state.status='URL_ASSIGNED_NOT_CLIENT_VERIFIED'
    $state|ConvertTo-Json|Set-Content -LiteralPath $stateFile -Encoding utf8
    Write-Output "Demo URL: $($state.url)/trang-chu"
    Write-Output 'Only allowed emails can pass the email-PIN gate. Then sign in with a web account.'
    Write-Output 'URL changes on restart. Keep this computer, backend and tunnel running.'
}catch{
    $process.Refresh();if(-not $process.HasExited){Stop-Process -Id $process.Id}
    $state.status='FAILED';$state|ConvertTo-Json|Set-Content -LiteralPath $stateFile -Encoding utf8
    throw
}
