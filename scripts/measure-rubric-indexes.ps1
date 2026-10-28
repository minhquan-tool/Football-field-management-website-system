param([Parameter(Mandatory=$true)][ValidatePattern('^QuanLySanBong_Fixtures_[A-Za-z0-9_]+$')][string]$Database,[string]$Server='tcp:localhost,1433')
$ErrorActionPreference='Stop'
$qaRoot=Split-Path $PSScriptRoot -Parent
$qaOutput=Join-Path $qaRoot 'exports/rubric-indexes'
$null=New-Item -ItemType Directory -Force -Path $qaOutput
& sqlcmd -S $Server -E -C -d $Database -b -f 65001 -v "ReviewedDatabase=$Database" -i (Join-Path $qaRoot 'database/migrations/legacy/rubric-index-benchmark.sql') -o (Join-Path $qaOutput 'setup.log')
if($LASTEXITCODE -ne 0){throw 'Benchmark preparation failed; existing tables are never overwritten'}
$qaCases=@(
 @{name='booking';query="SELECT COUNT_BIG(*) hits FROM rubric_bench.Booking WHERE MaSan='S42' AND NgayChoi>='20260301' AND NgayChoi<'20260401'";ddl='CREATE INDEX IX_Booking_SanNgay ON rubric_bench.Booking(MaSan,NgayChoi,GioBatDau)';source='IX_DatSan_SanNgayBatDau'},
 @{name='payment';query="SELECT SUM(SoTien) amount FROM rubric_bench.Payment WHERE MaDatSan='B000012346' AND TrangThai=N'Thành công'";ddl='CREATE INDEX IX_Payment_BookingState ON rubric_bench.Payment(MaDatSan,TrangThai) INCLUDE(SoTien)';source='IX_ThanhToan_BookingState'},
 @{name='service';query="SELECT SUM(SoLuong*DonGia) amount FROM rubric_bench.Service WHERE MaDatSan='B000002346'";ddl='CREATE INDEX IX_Service_BookingSku ON rubric_bench.Service(MaDatSan,MaDV) INCLUDE(SoLuong,DonGia)';source='IX_CTDV_BookingSku (covering variant in laboratory)'},
 @{name='account';query="SELECT MaTK FROM rubric_bench.Account WHERE TenDangNhap='rubric_user_12345'";ddl='CREATE UNIQUE INDEX UQ_Account_Username ON rubric_bench.Account(TenDangNhap)';source='UQ_TaiKhoan_TenDangNhap'},
 @{name='customer';query="SELECT MaKH FROM rubric_bench.Customer WHERE SoDienThoai='0900012345'";ddl='CREATE UNIQUE INDEX UQ_Customer_Phone ON rubric_bench.Customer(SoDienThoai)';source='UQ_KhachHang_SDT'}
)
$qaResults=@()
foreach($qaCase in $qaCases){
 $qaPair=[ordered]@{case=$qaCase.name;sourceIndex=$qaCase.source;rows=50000;query=$qaCase.query;ddl=$qaCase.ddl}
 foreach($qaPhase in @('before','after')){
  if($qaPhase -eq 'after'){
   & sqlcmd -S $Server -E -C -d $Database -b -f 65001 -Q $qaCase.ddl -o (Join-Path $qaOutput "$($qaCase.name)-create.log")
   if($LASTEXITCODE -ne 0){throw 'Index creation failed'}
  }
  $qaFile=Join-Path $qaOutput "$($qaCase.name)-$qaPhase.txt"
  & sqlcmd -S $Server -E -C -d $Database -b -f 65001 -y 0 -w 65535 -Q "SET NOCOUNT ON; SET STATISTICS IO ON; SET STATISTICS TIME ON; SET STATISTICS XML ON; $($qaCase.query); SET STATISTICS XML OFF;" -o $qaFile
  if($LASTEXITCODE -ne 0){throw 'Benchmark query failed'}
  $qaText=Get-Content -LiteralPath $qaFile -Raw
  $qaReads=[regex]::Matches($qaText,'logical reads (\d+)')
  if(-not $qaReads.Count){throw 'Missing STATISTICS IO output; inspect localization'}
  $qaPair[$qaPhase+'LogicalReads']=($qaReads | ForEach-Object {[int]$_.Groups[1].Value} | Measure-Object -Sum).Sum
  $qaXml=[regex]::Match($qaText,'(?s)<ShowPlanXML.*?</ShowPlanXML>')
  if(-not $qaXml.Success){throw 'Missing actual execution plan'}
  [IO.File]::WriteAllText((Join-Path $qaOutput "$($qaCase.name)-$qaPhase.sqlplan"),$qaXml.Value,[Text.UTF8Encoding]::new($false))
 }
 $qaPair['readReductionPercent']=[math]::Round((1-$qaPair.afterLogicalReads/$qaPair.beforeLogicalReads)*100,2)
 $qaResults+=[pscustomobject]$qaPair
}
$qaResults | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $qaOutput 'results.json') -Encoding utf8
$qaResults | Format-Table case,beforeLogicalReads,afterLogicalReads,readReductionPercent
Write-Output 'Synthetic laboratory only; not a claim of production speedup. CPU/elapsed and actual XML plans retained per case.'
