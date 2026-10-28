param(
 [string]$Server='tcp:localhost,1433',
 [ValidatePattern('^QuanLySanBong_(Test|Fixtures_[A-Za-z0-9_]+)$')][string]$Database='QuanLySanBong_Test',
 [switch]$IncludeTransactions
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$logRoot=Join-Path $projectRoot ('run/database-tests/'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
[void](New-Item -ItemType Directory -Path $logRoot -Force)
$failures=0
foreach($testFile in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.sql' | Sort-Object Name) {
 if($testFile.Name -match '^11') { continue }
 if($testFile.Name -match '^08' -and -not $IncludeTransactions) { Write-Output 'SKIP transaction fixture (use -IncludeTransactions)'; continue }
 $inputFile=$testFile.FullName
 if($testFile.Name -match '^08') {
  $inputFile=Join-Path $logRoot 'transactions-optin.sql'
  $text=[IO.File]::ReadAllText($testFile.FullName).Replace('DECLARE @EnableDemo bit=0;','DECLARE @EnableDemo bit=1;')
  [IO.File]::WriteAllText($inputFile,$text,[Text.UTF8Encoding]::new($true))
 }
 & sqlcmd -S $Server -E -C -d $Database -b -f 65001 -i $inputFile -o (Join-Path $logRoot ($testFile.BaseName+'.log'))
 if($LASTEXITCODE -ne 0){$failures++;Write-Output ('FAIL '+$testFile.Name)}else{Write-Output ('PASS '+$testFile.Name)}
}
Write-Output ('Logs: '+$logRoot)
if($failures -gt 0){throw "$failures SQL checks failed"}
Write-Output 'PASS automated SQL checks. Concurrency A/B and backup/restore are separate checks.'