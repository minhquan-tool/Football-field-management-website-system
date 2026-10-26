[CmdletBinding()]
param(
    [string]$Server = 'tcp:localhost,1433',
    [string]$Database = 'QuanLySanBong',
    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'database\final')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Data
$utf8Bom = [System.Text.UTF8Encoding]::new($true)

if (-not (Test-Path -LiteralPath $OutputDir)) {
    $null = New-Item -ItemType Directory -Path $OutputDir -Force
}

$modulesDir = Join-Path $OutputDir 'modules'
$tablesDir = Join-Path $modulesDir 'tables'
$viewsDir = Join-Path $modulesDir 'views'
$funcsDir = Join-Path $modulesDir 'functions'
$procsDir = Join-Path $modulesDir 'procedures'
$trigsDir = Join-Path $modulesDir 'triggers'

foreach ($dir in @($modulesDir, $tablesDir, $viewsDir, $funcsDir, $procsDir, $trigsDir)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }
}

$connStr = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

Write-Output "Connected to database $Database on $Server."

# 1. Topological order of tables
$tableOrder = @(
    # Tier 0 (No foreign keys)
    'VaiTro',
    'ChucNang',
    'LoaiSan',
    'KhungGio',
    'KhachHang',
    'NhanVien',
    'KhuyenMai',
    'DichVu',
    'TieuChiDanhGia',
    'GiaTheoCa',
    'BaoCao',
    'SaoLuu',
    
    # Tier 1 (References Tier 0)
    'PhanQuyen',
    'TaiKhoan',
    'San',
    'BangGia',
    
    # Tier 2 (References Tier 0, 1)
    'DatSan',
    'NhatKyHeThong',
    
    # Tier 3 (References DatSan, etc.)
    'XacNhanSan',
    'ChiTietDichVu',
    'HoaDon',
    'ThanhToan',
    'HuyDatSan',
    'DanhGia',
    'PhanHoi',
    
    # Tier 4 (References Tier 3)
    'HoanTien',
    'YeuCauHuyDatSan',
    'ChiTietDanhGia'
)

# Fetch table columns metadata
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    c.column_id,
    ty.name AS TypeName,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS ComputedDefinition,
    cc.is_persisted AS ComputedPersisted,
    dc.name AS DefaultConstraintName,
    dc.definition AS DefaultDefinition
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE t.name <> 'sysdiagrams'
ORDER BY t.name, c.column_id
"@

$da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dtCols = New-Object System.Data.DataTable
$da.Fill($dtCols) | Out-Null

# Fetch Primary Keys
$cmd.CommandText = @"
SELECT 
    t.name AS TableName,
    i.name AS PKName,
    c.name AS ColumnName,
    ic.key_ordinal
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name <> 'sysdiagrams'
ORDER BY t.name, ic.key_ordinal
"@
$dtPK = New-Object System.Data.DataTable
(New-Object System.Data.SqlClient.SqlDataAdapter($cmd)).Fill($dtPK) | Out-Null

# Fetch Unique Constraints / Unique Indexes
$cmd.CommandText = @"
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.is_unique,
    i.filter_definition,
    c.name AS ColumnName,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 0 AND i.is_hypothetical = 0
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name <> 'sysdiagrams' AND i.name IS NOT NULL
ORDER BY t.name, i.name, ic.is_included_column, ic.key_ordinal
"@
$dtIdx = New-Object System.Data.DataTable
(New-Object System.Data.SqlClient.SqlDataAdapter($cmd)).Fill($dtIdx) | Out-Null

# Fetch Check Constraints
$cmd.CommandText = @"
SELECT 
    t.name AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS Definition
FROM sys.check_constraints cc
JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE cc.is_ms_shipped = 0 AND t.name <> 'sysdiagrams'
ORDER BY t.name, cc.name
"@
$dtCK = New-Object System.Data.DataTable
(New-Object System.Data.SqlClient.SqlDataAdapter($cmd)).Fill($dtCK) | Out-Null

# Fetch Foreign Keys
$cmd.CommandText = @"
SELECT 
    fk.name AS FKName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS RefTable,
    cr.name AS RefColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE tp.name <> 'sysdiagrams' AND tr.name <> 'sysdiagrams'
ORDER BY tp.name, fk.name, fkc.constraint_column_id
"@
$dtFK = New-Object System.Data.DataTable
(New-Object System.Data.SqlClient.SqlDataAdapter($cmd)).Fill($dtFK) | Out-Null

Write-Output "Metadata fetched: $($dtCols.Rows.Count) columns, $($dtPK.Rows.Count) PK cols, $($dtCK.Rows.Count) checks, $($dtFK.Rows.Count) FKs."

function Format-DataType($row) {
    $typeName = $row.TypeName
    $len = [int]$row.max_length
    $prec = [int]$row.precision
    $scale = [int]$row.scale

    switch ($typeName) {
        'varchar'  { if ($len -eq -1) { return 'varchar(max)' } else { return "varchar($len)" } }
        'nvarchar' { if ($len -eq -1) { return 'nvarchar(max)' } else { $charLen = $len / 2; return "nvarchar($charLen)" } }
        'char'     { return "char($len)" }
        'nchar'    { $charLen = $len / 2; return "nchar($charLen)" }
        'decimal'  { return "decimal($prec, $scale)" }
        'numeric'  { return "numeric($prec, $scale)" }
        'time'     { return "time($scale)" }
        'datetime2'{ return "datetime2($scale)" }
        default    { return $typeName }
    }
}

# Generate 01_tables_and_constraints.sql
$sbTables = [System.Text.StringBuilder]::new()
$null = $sbTables.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 01: CƠ SỞ DỮ LIỆU, BẢNG VÀ RÀNG BUỘC TOÀN VẸN (DDL)
   Bao gồm:
     - 28 Bảng nghiệp vụ chuẩn hóa (Phase 1 -> Phase 7)
     - Khóa chính (PK), Khóa ngoại (FK), Ràng buộc duy nhất (UQ)
     - Ràng buộc kiểm tra (CHECK), Giá trị mặc định (DEFAULT)
     - Chỉ mục tối ưu hóa truy vấn (Non-Clustered Indexes, Filtered Indexes)
   ========================================================================================= */

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'$Database')
BEGIN
    CREATE DATABASE [$Database];
END
GO

USE [$Database];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"@)

foreach ($tbl in $tableOrder) {
    $tblCols = $dtCols | Where-Object { $_.TableName -eq $tbl }
    if (-not $tblCols) { continue }
    
    $sbTableSingle = [System.Text.StringBuilder]::new()
    $null = $sbTableSingle.AppendLine("USE [$Database];`nGO`n`nSET ANSI_NULLS ON;`nGO`nSET QUOTED_IDENTIFIER ON;`nGO`n")
    
    $null = $sbTables.AppendLine("-- ============================================================")
    $null = $sbTables.AppendLine("-- BẢNG: $tbl")
    $null = $sbTables.AppendLine("-- ============================================================")
    $null = $sbTables.AppendLine("IF OBJECT_ID(N'dbo.[$tbl]', N'U') IS NULL")
    $null = $sbTables.AppendLine("BEGIN")
    $null = $sbTables.AppendLine("    CREATE TABLE dbo.[$tbl] (")
    
    $null = $sbTableSingle.AppendLine("IF OBJECT_ID(N'dbo.[$tbl]', N'U') IS NULL")
    $null = $sbTableSingle.AppendLine("BEGIN")
    $null = $sbTableSingle.AppendLine("    CREATE TABLE dbo.[$tbl] (")
    
    $colDefs = @()
    foreach ($col in $tblCols) {
        $cName = $col.ColumnName
        if ($col.is_computed) {
            $compDef = $col.ComputedDefinition
            $persist = if ($col.ComputedPersisted) { " PERSISTED" } else { "" }
            $colDefs += "        [$cName] AS $compDef$persist"
        } else {
            $dtStr = Format-DataType $col
            $ident = if ($col.is_identity) { " IDENTITY(1,1)" } else { "" }
            $nullStr = if ($col.is_nullable) { "NULL" } else { "NOT NULL" }
            $defStr = ""
            if (-not ($col.DefaultDefinition -is [System.DBNull]) -and [string]$col.DefaultDefinition -ne '') {
                $dfName = if (-not ($col.DefaultConstraintName -is [System.DBNull]) -and [string]$col.DefaultConstraintName -ne '') { 
                    "CONSTRAINT [$($col.DefaultConstraintName)] " 
                } else { "" }
                $defStr = " $dfName`DEFAULT $($col.DefaultDefinition)"
            }
            $colDefs += "        [$cName] $dtStr$ident$defStr $nullStr"
        }
    }
    
    # Primary Key
    $pkCols = $dtPK | Where-Object { $_.TableName -eq $tbl }
    if ($pkCols) {
        $pkName = ($pkCols | Select-Object -First 1).PKName
        $pkColList = ($pkCols | ForEach-Object { "[$($_.ColumnName)] ASC" }) -join ', '
        $colDefs += "        CONSTRAINT [$pkName] PRIMARY KEY CLUSTERED ($pkColList)"
    }
    
    $joinedDefs = $colDefs -join ",`n"
    $null = $sbTables.AppendLine($joinedDefs)
    $null = $sbTables.AppendLine("    );`nEND`nGO`n")
    
    $null = $sbTableSingle.AppendLine($joinedDefs)
    $null = $sbTableSingle.AppendLine("    );`nEND`nGO`n")
    
    # Check constraints
    $tblCK = $dtCK | Where-Object { $_.TableName -eq $tbl }
    foreach ($ck in $tblCK) {
        $ckSql = "IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = '$($ck.ConstraintName)')`nBEGIN`n    ALTER TABLE dbo.[$tbl] ADD CONSTRAINT [$($ck.ConstraintName)] CHECK $($ck.Definition);`nEND`nGO"
        $null = $sbTables.AppendLine($ckSql)
        $null = $sbTableSingle.AppendLine($ckSql)
    }
    
    # Indexes / Unique constraints
    $tblIdxGroups = $dtIdx | Where-Object { $_.TableName -eq $tbl } | Group-Object IndexName
    foreach ($grp in $tblIdxGroups) {
        $idxName = $grp.Name
        $first = $grp.Group | Select-Object -First 1
        $isUnique = [bool]$first.is_unique
        $filter = $first.filter_definition
        
        $keyCols = ($grp.Group | Where-Object { -not $_.is_included_column } | ForEach-Object { "[$($_.ColumnName)] ASC" }) -join ', '
        $incCols = ($grp.Group | Where-Object { $_.is_included_column } | ForEach-Object { "[$($_.ColumnName)]" }) -join ', '
        
        $uStr = if ($isUnique) { "UNIQUE " } else { "" }
        $incClause = if ($incCols) { " INCLUDE ($incCols)" } else { "" }
        $filterClause = if (-not ($filter -is [System.DBNull]) -and [string]$filter -ne '') { " WHERE $filter" } else { "" }
        
        $idxSql = "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = '$idxName' AND object_id = OBJECT_ID('dbo.[$tbl]'))`nBEGIN`n    CREATE ${uStr}NONCLUSTERED INDEX [$idxName] ON dbo.[$tbl] ($keyCols)$incClause$filterClause;`nEND`nGO"
        $null = $sbTables.AppendLine($idxSql)
        $null = $sbTableSingle.AppendLine($idxSql)
    }
    
    [System.IO.File]::WriteAllText((Join-Path $tablesDir "$tbl.sql"), $sbTableSingle.ToString(), $utf8Bom)
}

# Foreign Key Constraints
$null = $sbTables.AppendLine(@"
-- ============================================================
-- KHÓA NGOẠI (FOREIGN KEY CONSTRAINTS)
-- ============================================================
"@)

$fkGroups = $dtFK | Group-Object FKName
foreach ($grp in $fkGroups) {
    $fkName = $grp.Name
    $first = $grp.Group | Select-Object -First 1
    $parentTable = $first.ParentTable
    $refTable = $first.RefTable
    $onDelete = $first.OnDelete
    $onUpdate = $first.OnUpdate
    
    $pCols = ($grp.Group | ForEach-Object { "[$($_.ParentColumn)]" }) -join ', '
    $rCols = ($grp.Group | ForEach-Object { "[$($_.RefColumn)]" }) -join ', '
    
    $delClause = if ($onDelete -and $onDelete -ne 'NO_ACTION') { " ON DELETE $($onDelete.Replace('_', ' '))" } else { "" }
    $updClause = if ($onUpdate -and $onUpdate -ne 'NO_ACTION') { " ON UPDATE $($onUpdate.Replace('_', ' '))" } else { "" }
    
    $fkSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = '$fkName')
BEGIN
    ALTER TABLE dbo.[$parentTable] WITH CHECK ADD CONSTRAINT [$fkName] FOREIGN KEY ($pCols) REFERENCES dbo.[$refTable] ($rCols)$delClause$updClause;
    ALTER TABLE dbo.[$parentTable] CHECK CONSTRAINT [$fkName];
END
GO
"@
    $null = $sbTables.AppendLine($fkSql)
}

[System.IO.File]::WriteAllText((Join-Path $OutputDir '01_tables_and_constraints.sql'), $sbTables.ToString(), $utf8Bom)
Write-Output "Generated 01_tables_and_constraints.sql and modules/tables/*.sql"

# 2. Extract Functions (03_functions.sql)
$funcOrder = @(
    'fn_TyLeHoan',
    'fn_BookingNetCash',
    'fn_BookingReceipts',
    'fn_BookingRefunds',
    'fn_KhungGioTrongTheoNgay',
    'fn_ReportDays'
)

$sbFuncs = [System.Text.StringBuilder]::new()
$null = $sbFuncs.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 03: HÀM NGƯỜI DÙNG ĐỊNH NGHĨA (USER-DEFINED FUNCTIONS)
   Bao gồm 6 hàm:
     - fn_TyLeHoan: Tính tỷ lệ hoàn tiền hủy sân theo mốc 10h / 2h (Phase 5.1C)
     - fn_BookingNetCash: Thực nhận theo mã đặt sân (Thu trừ Hoàn)
     - fn_BookingReceipts: Tổng tiền đã thực thu theo mã đặt sân
     - fn_BookingRefunds: Tổng tiền đã hoàn theo mã đặt sân
     - fn_KhungGioTrongTheoNgay: Tra cứu các khung giờ còn trống trong ngày của sân
     - fn_ReportDays: Bảng các ngày trong khoảng thời gian báo cáo
   ========================================================================================= */

USE [$Database];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"@)

foreach ($fName in $funcOrder) {
    $cmd.CommandText = "SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.$fName')"
    $def = [string]$cmd.ExecuteScalar()
    if ($def) {
        $cleanDef = $def.Trim()
        # Ensure CREATE OR ALTER
        if ($cleanDef -match '(?im)^\s*CREATE\s+FUNCTION\b') {
            $createOrAlter = [regex]::new('(?im)^\s*CREATE\s+FUNCTION\b').Replace($cleanDef, 'CREATE OR ALTER FUNCTION', 1)
        } else {
            $createOrAlter = $cleanDef
        }
        $null = $sbFuncs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbFuncs.AppendLine("-- HÀM: $fName")
        $null = $sbFuncs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbFuncs.AppendLine($createOrAlter)
        $null = $sbFuncs.AppendLine("GO`n")
        
        $singleFunc = "USE [$Database];`nGO`n`nSET ANSI_NULLS ON;`nGO`nSET QUOTED_IDENTIFIER ON;`nGO`n`n$createOrAlter`nGO`n"
        [System.IO.File]::WriteAllText((Join-Path $funcsDir "$fName.sql"), $singleFunc, $utf8Bom)
    }
}
[System.IO.File]::WriteAllText((Join-Path $OutputDir '03_functions.sql'), $sbFuncs.ToString(), $utf8Bom)
Write-Output "Generated 03_functions.sql and modules/functions/*.sql"

# 3. Extract Views (02_views.sql)
$viewOrder = @(
    'V_DoanhThuPhatSinhTheoNgay',
    'V_DoanhThuTheoNgay',
    'V_KhungGioTrong',
    'V_Phase6_Revenue',
    'V_Phase6_UsageBooking',
    'V_ThuChiThucNhan',
    'V_ThuTienTheoNgay',
    'V_TyLeLapDay',
    'V_TyLeSuDungTheoNgay'
)

$sbViews = [System.Text.StringBuilder]::new()
$null = $sbViews.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 02: CÁC KHUNG NHÌN DỮ LIỆU (VIEWS)
   Bao gồm 9 View:
     - V_DoanhThuPhatSinhTheoNgay: Doanh thu phát sinh tại thời điểm trả sân
     - V_DoanhThuTheoNgay: Tổng doanh thu các hóa đơn đã thanh toán theo ngày
     - V_KhungGioTrong: Danh sách các khung giờ trống của từng sân
     - V_Phase6_Revenue: Doanh thu theo hóa đơn, tiền sân, tiền dịch vụ, giảm giá
     - V_Phase6_UsageBooking: Thống kê số lượt và giờ sử dụng sân
     - V_ThuChiThucNhan: Dòng tiền thực nhận (Thu từ thanh toán trừ Hoàn tiền)
     - V_ThuTienTheoNgay: Tổng tiền thực thu từng ngày
     - V_TyLeLapDay: Tỷ lệ lấp đầy khung giờ theo ngày
     - V_TyLeSuDungTheoNgay: Tỷ lệ sử dụng thời gian sân thực tế theo ngày
   ========================================================================================= */

USE [$Database];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"@)

foreach ($vName in $viewOrder) {
    $cmd.CommandText = "SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.$vName')"
    $def = [string]$cmd.ExecuteScalar()
    if ($def) {
        $cleanDef = $def.Trim()
        if ($cleanDef -match '(?im)^\s*CREATE\s+VIEW\b') {
            $createOrAlter = [regex]::new('(?im)^\s*CREATE\s+VIEW\b').Replace($cleanDef, 'CREATE OR ALTER VIEW', 1)
        } else {
            $createOrAlter = $cleanDef
        }
        $null = $sbViews.AppendLine("-- ------------------------------------------------------------")
        $null = $sbViews.AppendLine("-- VIEW: $vName")
        $null = $sbViews.AppendLine("-- ------------------------------------------------------------")
        $null = $sbViews.AppendLine($createOrAlter)
        $null = $sbViews.AppendLine("GO`n")
        
        $singleView = "USE [$Database];`nGO`n`nSET ANSI_NULLS ON;`nGO`nSET QUOTED_IDENTIFIER ON;`nGO`n`n$createOrAlter`nGO`n"
        [System.IO.File]::WriteAllText((Join-Path $viewsDir "$vName.sql"), $singleView, $utf8Bom)
    }
}
[System.IO.File]::WriteAllText((Join-Path $OutputDir '02_views.sql'), $sbViews.ToString(), $utf8Bom)
Write-Output "Generated 02_views.sql and modules/views/*.sql"

# 4. Extract Stored Procedures (04_stored_procedures.sql)
$procOrder = @(
    'usp_ReportFinance',
    'usp_ReportPaymentMethods',
    'usp_ReportReconciliation',
    'usp_ReportTopServices',
    'usp_ReportUsage'
)

$sbProcs = [System.Text.StringBuilder]::new()
$null = $sbProcs.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 04: THỦ TỤC LƯU TRỮ BÁO CÁO (STORED PROCEDURES)
   Bao gồm 5 Stored Procedure báo cáo:
     - usp_ReportFinance: Báo cáo tài chính doanh thu phát sinh và thực nhận
     - usp_ReportPaymentMethods: Phân tích cơ cấu phương thức thanh toán (Tiền mặt / Chuyển khoản)
     - usp_ReportReconciliation: Báo cáo đối soát công nợ & trạng thái thanh toán hóa đơn
     - usp_ReportTopServices: Thống kê top dịch vụ bán chạy nhất và doanh thu
     - usp_ReportUsage: Báo cáo công suất, số lượt đặt và tỷ lệ sử dụng sân
   ========================================================================================= */

USE [$Database];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"@)

foreach ($pName in $procOrder) {
    $cmd.CommandText = "SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.$pName')"
    $def = [string]$cmd.ExecuteScalar()
    if ($def) {
        $cleanDef = $def.Trim()
        if ($cleanDef -match '(?im)^\s*CREATE\s+(?:PROCEDURE|PROC)\b') {
            $createOrAlter = [regex]::new('(?im)^\s*CREATE\s+(?:PROCEDURE|PROC)\b').Replace($cleanDef, 'CREATE OR ALTER PROCEDURE', 1)
        } else {
            $createOrAlter = $cleanDef
        }
        $null = $sbProcs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbProcs.AppendLine("-- THỦ TỤC: $pName")
        $null = $sbProcs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbProcs.AppendLine($createOrAlter)
        $null = $sbProcs.AppendLine("GO`n")
        
        $singleProc = "USE [$Database];`nGO`n`nSET ANSI_NULLS ON;`nGO`nSET QUOTED_IDENTIFIER ON;`nGO`n`n$createOrAlter`nGO`n"
        [System.IO.File]::WriteAllText((Join-Path $procsDir "$pName.sql"), $singleProc, $utf8Bom)
    }
}
[System.IO.File]::WriteAllText((Join-Path $OutputDir '04_stored_procedures.sql'), $sbProcs.ToString(), $utf8Bom)
Write-Output "Generated 04_stored_procedures.sql and modules/procedures/*.sql"

# 5. Extract Triggers (05_triggers.sql)
$trigOrder = @(
    'TRG_AuditContentImmutable',
    'TRG_CapNhatTienDatSan',
    'TRG_SealedInvoiceSnapshot',
    'TRG_ServicePriceSnapshot',
    'TRG_SuccessfulPaymentSnapshot'
)

$sbTrigs = [System.Text.StringBuilder]::new()
$null = $sbTrigs.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 05: CÁC TRIGGER NGHIỆP VỤ & BẢO VỆ SNAPSHOT (TRIGGERS)
   Bao gồm 5 Trigger:
     - TRG_AuditContentImmutable: Nhật ký hệ thống chỉ được ghi thêm, chống sửa/xóa log
     - TRG_CapNhatTienDatSan: Tự động tổng hợp tiền dịch vụ vào đặt sân (DatSan.TienDichVu)
     - TRG_SealedInvoiceSnapshot: Hóa đơn đã chốt (DaChot=1) không được thay đổi snapshot tiền
     - TRG_ServicePriceSnapshot: Chi tiết dịch vụ không được sửa đơn giá sau khi đã lưu
     - TRG_SuccessfulPaymentSnapshot: Thanh toán thành công là bất biến, muốn trả lại phải qua HoanTien
   ========================================================================================= */

USE [$Database];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
"@)

foreach ($tName in $trigOrder) {
    $cmd.CommandText = "SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.$tName')"
    $def = [string]$cmd.ExecuteScalar()
    if ($def) {
        $cleanDef = $def.Trim()
        if ($cleanDef -match '(?im)^\s*CREATE\s+TRIGGER\b') {
            $createOrAlter = [regex]::new('(?im)^\s*CREATE\s+TRIGGER\b').Replace($cleanDef, 'CREATE OR ALTER TRIGGER', 1)
        } else {
            $createOrAlter = $cleanDef
        }
        $null = $sbTrigs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbTrigs.AppendLine("-- TRIGGER: $tName")
        $null = $sbTrigs.AppendLine("-- ------------------------------------------------------------")
        $null = $sbTrigs.AppendLine($createOrAlter)
        $null = $sbTrigs.AppendLine("GO`n")
        
        $singleTrig = "USE [$Database];`nGO`n`nSET ANSI_NULLS ON;`nGO`nSET QUOTED_IDENTIFIER ON;`nGO`n`n$createOrAlter`nGO`n"
        [System.IO.File]::WriteAllText((Join-Path $trigsDir "$tName.sql"), $singleTrig, $utf8Bom)
    }
}
[System.IO.File]::WriteAllText((Join-Path $OutputDir '05_triggers.sql'), $sbTrigs.ToString(), $utf8Bom)
Write-Output "Generated 05_triggers.sql and modules/triggers/*.sql"

# 6. Extract Data (06_seed_data.sql)
$sbData = [System.Text.StringBuilder]::new()
$null = $sbData.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 06: DỮ LIỆU CƠ SỞ (DATA INSERTION)
   Chứa toàn bộ dữ liệu hiện tại từ cơ sở dữ liệu QuanLySanBong.
   Thứ tự nạp tuân thủ chặt chẽ khóa ngoại. Triggers và Foreign Key checks được tạm ngưng
   trong lúc import để đảm bảo tính toàn vẹn snapshot lịch sử, sau đó bật lại ngay lập tức.
   ========================================================================================= */

USE [$Database];
GO

SET NOCOUNT ON;
GO

-- Vô hiệu hóa kiểm tra khóa ngoại và trigger tạm thời để nạp dữ liệu sạch
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
GO
EXEC sp_msforeachtable "DISABLE TRIGGER ALL ON ?";
GO
"@)

foreach ($tbl in $tableOrder) {
    # Get columns that are not computed and not rowversion/timestamp
    $insertCols = $dtCols | Where-Object { 
        $_.TableName -eq $tbl -and 
        -not $_.is_computed -and 
        $_.TypeName -notin @('timestamp', 'rowversion') 
    }
    
    if (-not $insertCols) { continue }
    
    $colNames = ($insertCols | ForEach-Object { "[$($_.ColumnName)]" }) -join ', '
    
    # Query data
    $cmd.CommandText = "SELECT $colNames FROM dbo.[$tbl]"
    $dtTblData = New-Object System.Data.DataTable
    $daTbl = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $daTbl.Fill($dtTblData) | Out-Null
    
    $rowCount = $dtTblData.Rows.Count
    $null = $sbData.AppendLine("-- ------------------------------------------------------------")
    $null = $sbData.AppendLine("-- BẢNG: $tbl ($rowCount dòng)")
    $null = $sbData.AppendLine("-- ------------------------------------------------------------")
    
    if ($rowCount -eq 0) {
        $null = $sbData.AppendLine("-- (Bảng không có dữ liệu)`n")
        continue
    }
    
    $hasIdentity = ($insertCols | Where-Object { $_.is_identity }) -ne $null
    if ($hasIdentity) {
        $null = $sbData.AppendLine("SET IDENTITY_INSERT dbo.[$tbl] ON;`nGO")
    }
    
    $batchSize = 50
    $batchIndex = 0
    
    for ($i = 0; $i -lt $rowCount; $i++) {
        $row = $dtTblData.Rows[$i]
        $valList = @()
        
        foreach ($c in $insertCols) {
            $val = $row[$c.ColumnName]
            if ($val -is [System.DBNull]) {
                $valList += "NULL"
            } elseif ($c.TypeName -eq 'bit') {
                $valList += if ([bool]$val) { "1" } else { "0" }
            } elseif ($c.TypeName -in @('int', 'smallint', 'tinyint', 'bigint')) {
                $valList += "$val"
            } elseif ($c.TypeName -in @('decimal', 'numeric', 'money', 'smallmoney', 'float', 'real')) {
                $valList += [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $val)
            } elseif ($c.TypeName -eq 'date') {
                $dtStr = ([DateTime]$val).ToString('yyyy-MM-dd')
                $valList += "CAST(N'$dtStr' AS Date)"
            } elseif ($c.TypeName -in @('time')) {
                $timeStr = $val.ToString()
                $valList += "CAST(N'$timeStr' AS Time)"
            } elseif ($c.TypeName -in @('datetime', 'smalldatetime')) {
                $dtStr = ([DateTime]$val).ToString('yyyy-MM-dd HH:mm:ss')
                $valList += "CAST(N'$dtStr' AS DateTime)"
            } elseif ($c.TypeName -eq 'datetime2') {
                $dtStr = ([DateTime]$val).ToString('yyyy-MM-dd HH:mm:ss.fffffff')
                $valList += "CAST(N'$dtStr' AS DateTime2)"
            } else {
                # Text / varchar / nvarchar
                $escaped = [string]$val
                $escaped = $escaped.Replace("'", "''")
                $valList += "N'$escaped'"
            }
        }
        
        $valString = $valList -join ', '
        $null = $sbData.AppendLine("INSERT INTO dbo.[$tbl] ($colNames) VALUES ($valString);")
        
        $batchIndex++
        if ($batchIndex -ge $batchSize) {
            $null = $sbData.AppendLine("GO")
            $batchIndex = 0
        }
    }
    
    if ($batchIndex -gt 0) {
        $null = $sbData.AppendLine("GO")
    }
    
    if ($hasIdentity) {
        $null = $sbData.AppendLine("SET IDENTITY_INSERT dbo.[$tbl] OFF;`nGO")
    }
    
    $null = $sbData.AppendLine("")
}

$null = $sbData.AppendLine(@"
-- Tái kích hoạt kiểm tra khóa ngoại và trigger sau khi hoàn tất nạp dữ liệu
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
GO
EXEC sp_msforeachtable "ENABLE TRIGGER ALL ON ?";
GO

PRINT N'Hoàn tất nạp dữ liệu vào cơ sở dữ liệu $Database.';
GO
"@)

[System.IO.File]::WriteAllText((Join-Path $OutputDir '06_seed_data.sql'), $sbData.ToString(), $utf8Bom)
Write-Output "Generated 06_seed_data.sql"

# 7. Generate Master 00_full_database.sql
$sbMaster = [System.Text.StringBuilder]::new()
$null = $sbMaster.AppendLine(@"
/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 00: TOÀN BỘ CƠ SỞ DỮ LIỆU TỰ ĐỘNG (MASTER ALL-IN-ONE SCRIPT)
   Script này chạy độc lập, tự động tạo cơ sở dữ liệu QuanLySanBong từ đầu đến cuối:
     1. Khởi tạo Database và các Bảng chuẩn hóa (28 bảng, PK, FK, CHECK, DEFAULT, INDEX)
     2. Tạo các Hàm người dùng (6 UDF)
     3. Tạo các Khung nhìn dữ liệu (9 Views)
     4. Tạo các Thủ tục lưu trữ báo cáo (5 Stored Procedures)
     5. Tạo các Trigger bảo vệ toàn vẹn (5 Triggers)
     6. Nạp toàn bộ dữ liệu chuẩn & lịch sử vận hành
   Chỉ cần mở file này trong SSMS (SQL Server Management Studio) và nhấn F5 (Execute)!
   ========================================================================================= */

"@)

$null = $sbMaster.AppendLine($sbTables.ToString())
$null = $sbMaster.AppendLine($sbFuncs.ToString())
$null = $sbMaster.AppendLine($sbViews.ToString())
$null = $sbMaster.AppendLine($sbProcs.ToString())
$null = $sbMaster.AppendLine($sbTrigs.ToString())
$null = $sbMaster.AppendLine($sbData.ToString())

[System.IO.File]::WriteAllText((Join-Path $OutputDir '00_full_database.sql'), $sbMaster.ToString(), $utf8Bom)
Write-Output "Generated 00_full_database.sql"

# 8. Generate README.md
$readmeContent = @"
# Bộ File SQL Cơ Sở Dữ Liệu QuanLySanBong - Final

Thư mục này chứa toàn bộ các file SQL được xuất hoàn chỉnh, chuẩn hóa và kiểm thử từ cơ sở dữ liệu **QuanLySanBong** chạy trên Microsoft SQL Server (FC UTE Football Management System).

---

## 1. Cấu Trúc Thư Mục

```
database/final/
├── 00_full_database.sql             (Master script: chạy 1 lần là có đầy đủ cấu trúc và dữ liệu)
├── 01_tables_and_constraints.sql    (Tạo CSDL, 28 bảng, khóa chính, khóa ngoại, ràng buộc CHECK, DEFAULT, Indexes)
├── 02_views.sql                     (9 View báo cáo, thống kê và tra cứu lịch sân)
├── 03_functions.sql                 (6 Hàm người dùng: tính hoàn tiền, doanh thu thực nhận, tra cứu khung giờ trống)
├── 04_stored_procedures.sql         (5 Thủ tục lưu trữ báo cáo tài chính, công suất, phương thức thanh toán)
├── 05_triggers.sql                  (5 Trigger nghiệp vụ tự động hóa và bảo vệ snapshot bất biến)
├── 06_seed_data.sql                 (Dữ liệu chuẩn ban đầu & lịch sử giao dịch vận hành hệ thống)
├── README.md                        (Tài liệu hướng dẫn sử dụng và danh mục đối tượng)
└── modules/                         (Các file SQL lẻ từng đối tượng để đọc, đối chiếu hoặc chấm điểm bảo vệ)
    ├── functions/                   (6 file hàm lẻ)
    ├── procedures/                  (5 file thủ tục báo cáo lẻ)
    ├── tables/                      (28 file bảng lẻ)
    ├── triggers/                    (5 file trigger lẻ)
    └── views/                       (9 file view lẻ)
```

---

## 2. Hướng Dẫn Sử Dụng Trong SSMS (SQL Server Management Studio)

### Cách 1: Chạy toàn bộ trong 1 click (Khuyến nghị khi dựng máy mới)
1. Mở **SQL Server Management Studio (SSMS)** và kết nối tới SQL Server của bạn.
2. Mở file **`00_full_database.sql`**.
3. Nhấn **Execute (F5)**.
4. Toàn bộ cơ sở dữ liệu `QuanLySanBong`, cấu trúc bảng, khóa, chỉ mục, view, hàm, thủ tục, trigger và dữ liệu sẽ được tạo hoàn chỉnh.

### Cách 2: Chạy theo từng phần có thứ tự (Khi cần kiểm soát từng bước)
Thực hiện tuần tự các file theo đúng thứ tự sau:
1. **`01_tables_and_constraints.sql`**: Tạo Database và 28 bảng cùng các chỉ mục, ràng buộc.
2. **`03_functions.sql`**: Tạo các hàm tính toán (các View sau này cần gọi hàm).
3. **`02_views.sql`**: Tạo các View thống kê và tra cứu.
4. **`04_stored_procedures.sql`**: Tạo các Stored Procedure báo cáo quản trị.
5. **`05_triggers.sql`**: Tạo các Trigger bảo vệ toàn vẹn và tính tiền.
6. **`06_seed_data.sql`**: Nạp dữ liệu vận hành.

---

## 3. Danh Mục Chi Tiết Các Đối Tượng CSDL

### 3.1. Danh mục 28 Bảng dữ liệu (Tables)
| STT | Tên bảng | Nhóm chức năng | Mô tả tóm tắt |
|:---:|:---|:---|:---|
| 1 | `VaiTro` | Phân quyền | Danh mục vai trò: Quản trị viên, Nhân viên sân, Kế toán, Khách hàng |
| 2 | `ChucNang` | Phân quyền | Danh mục quyền/chức năng nghiệp vụ trong hệ thống |
| 3 | `PhanQuyen` | Phân quyền | Ma trận phân quyền chi tiết (Xem, Thêm, Sửa, Xóa) cho từng vai trò |
| 4 | `TaiKhoan` | Người dùng | Tài khoản đăng nhập hệ thống, mật khẩu hash BCrypt |
| 5 | `NhanVien` | Nhân sự | Hồ sơ nhân viên, bộ phận, chức vụ |
| 6 | `KhachHang` | Khách hàng | Thông tin khách hàng, số điện thoại định danh |
| 7 | `LoaiSan` | Quản lý sân | Loại sân (Sân 5 người, Sân 7 người) |
| 8 | `San` | Quản lý sân | Danh sách sân bóng cụ thể, trạng thái vận hành |
| 9 | `KhungGio` | Khung giờ | Khung giờ cố định theo ca |
| 10 | `GiaTheoCa` | Giá giờ tự do | Bảng giá theo ca sáng/chiều/tối phục vụ đặt giờ linh hoạt (Phase 5.1A) |
| 11 | `BangGia` | Bảng giá cố định | Bảng giá theo khung giờ cố định và loại ngày |
| 12 | `KhuyenMai` | Khuyến mãi | Danh mục mã giảm giá, voucher theo số tiền hoặc phần trăm |
| 13 | `DatSan` | Đặt sân | Phiếu đặt sân trọng tâm, hỗ trợ cả giờ khung và giờ tự do, cột tính toán PERSISTED |
| 14 | `XacNhanSan` | Vận hành sân | Ghi nhận nhận sân, trả sân và tình trạng sân thực tế |
| 15 | `DichVu` | Dịch vụ | Danh mục dịch vụ nước uống, thuê bóng, giày, áo tập |
| 16 | `ChiTietDichVu` | Dịch vụ | Chi tiết dịch vụ sử dụng theo phiếu đặt sân, quy cách Đơn vị / Lốc 6 giảm 3% |
| 17 | `HoaDon` | Tài chính | Hóa đơn thanh toán, đóng băng snapshot tiền khi chốt trả sân |
| 18 | `ThanhToan` | Tài chính | Lịch sử các lần thanh toán (Tiền mặt / Chuyển khoản), bất biến |
| 19 | `HuyDatSan` | Hủy sân | Phiếu hủy đặt sân, tính tiền phạt và tiền hoàn theo quy định 10h/2h |
| 20 | `HoanTien` | Tài chính | Bản ghi hoàn trả tiền cho khách hàng khi hủy hoặc điều chỉnh |
| 21 | `YeuCauHuyDatSan` | Quy trình hủy | Quy trình khách gửi yêu cầu hủy và nhân viên/quản lý duyệt |
| 22 | `DanhGia` | Phản hồi | Khách hàng đánh giá chất lượng dịch vụ sau khi sử dụng sân |
| 23 | `TieuChiDanhGia` | Phản hồi | Tiêu chí đánh giá chất lượng (Mặt cỏ, Ánh sáng, Phục vụ, Vệ sinh,...) |
| 24 | `ChiTietDanhGia` | Phản hồi | Điểm chi tiết cho từng tiêu chí |
| 25 | `PhanHoi` | Phản hồi | Nhân viên/Quản lý phản hồi ý kiến đánh giá của khách hàng |
| 26 | `BaoCao` | Quản trị | Lưu trữ metadata các kỳ báo cáo định kỳ |
| 27 | `SaoLuu` | Hệ thống | Lịch sử sao lưu và phục hồi cơ sở dữ liệu |
| 28 | `NhatKyHeThong` | Bảo mật | Audit log bất biến, ghi nhận mọi thao tác đăng nhập, sửa đổi dữ liệu |

---

### 3.2. Danh mục 9 Khung nhìn (Views)
1. **`V_DoanhThuPhatSinhTheoNgay`**: Doanh thu ghi nhận tại thời điểm trả sân theo ngày.
2. **`V_DoanhThuTheoNgay`**: Tổng doanh thu từ các hóa đơn đã hoàn tất thanh toán theo ngày.
3. **`V_KhungGioTrong`**: Danh sách các khung giờ trống của từng sân phục vụ tìm kiếm nhanh.
4. **`V_Phase6_Revenue`**: Tổng hợp doanh thu chi tiết tiền sân, tiền dịch vụ, tiền giảm giá.
5. **`V_Phase6_UsageBooking`**: Thống kê số lượt đặt sân và tổng số giờ chơi.
6. **`V_ThuChiThucNhan`**: Báo cáo dòng tiền thực nhận (Tổng tiền thu từ thanh toán trừ tổng tiền hoàn trả).
7. **`V_ThuTienTheoNgay`**: Tổng tiền thực thu tiền mặt và chuyển khoản theo ngày.
8. **`V_TyLeLapDay`**: Tỷ lệ lấp đầy khung giờ của các sân bóng theo ngày.
9. **`V_TyLeSuDungTheoNgay`**: Tỷ lệ sử dụng thời gian sân thực tế theo ngày.

---

### 3.3. Danh mục 6 Hàm (User-Defined Functions)
1. **`fn_TyLeHoan(@BatDau, @Huy)`**: Trả về tỷ lệ hoàn tiền hủy sân (100% nếu hủy trước >= 10h, 50% nếu trước >= 2h, 0% nếu sát giờ).
2. **`fn_BookingNetCash(@MaDatSan)`**: Tính số tiền thực nhận của 1 phiếu đặt sân (Thực thu trừ Tiền đã hoàn).
3. **`fn_BookingReceipts(@MaDatSan)`**: Tính tổng số tiền đã thu thành công của 1 phiếu đặt sân.
4. **`fn_BookingRefunds(@MaDatSan)`**: Tính tổng số tiền đã hoàn trả của 1 phiếu đặt sân.
5. **`fn_KhungGioTrongTheoNgay(@NgayChoi)`**: Trả về bảng các khung giờ còn trống trong ngày cụ thể cho từng sân.
6. **`fn_ReportDays(@TuNgay, @DenNgay)`**: Sinh chuỗi ngày liên tục trong khoảng thời gian báo cáo.

---

### 3.4. Danh mục 5 Thủ tục lưu trữ báo cáo (Stored Procedures)
1. **`usp_ReportFinance`**: Báo cáo tài chính doanh thu phát sinh và đối chiếu thực nhận trong kỳ.
2. **`usp_ReportPaymentMethods`**: Phân tích cơ cấu thanh toán Tiền mặt vs Chuyển khoản ngân hàng.
3. **`usp_ReportReconciliation`**: Báo cáo đối soát công nợ hóa đơn (đã thanh toán đủ, thanh toán 1 phần, chưa thanh toán).
4. **`usp_ReportTopServices`**: Thống kê các dịch vụ có lượt tiêu thụ và doanh thu cao nhất.
5. **`usp_ReportUsage`**: Báo cáo chi tiết công suất hoạt động, số giờ sử dụng và tỷ lệ sử dụng sân.

---

### 3.5. Danh mục 5 Triggers bảo vệ toàn vẹn
1. **`TRG_AuditContentImmutable`**: Bắt buộc nhật ký hệ thống `NhatKyHeThong` là chỉ ghi thêm (append-only), chống sửa đổi nội dung.
2. **`TRG_CapNhatTienDatSan`**: Tự động tính tổng tiền dịch vụ `ChiTietDichVu` cập nhật vào `DatSan.TienDichVu`.
3. **`TRG_SealedInvoiceSnapshot`**: Khóa bất biến số tiền và thông tin hóa đơn khi đã chốt (`DaChot = 1`).
4. **`TRG_ServicePriceSnapshot`**: Bảo vệ snapshot đơn giá dịch vụ sau khi nạp, chỉ cho phép cập nhật số lượng trước khi chốt hóa đơn.
5. **`TRG_SuccessfulPaymentSnapshot`**: Bảo vệ giao dịch thanh toán thành công là bất biến, nghiêm cấm sửa số tiền đã thu.

---

## 4. Ghi Chú Kỹ Thuật
- Bộ script được thiết kế tương thích hoàn toàn với Microsoft SQL Server 2016, 2017, 2019, 2022 và Azure SQL Database.
- Mọi câu lệnh tạo view, hàm, thủ tục và trigger đều dùng cú pháp chuẩn hiện đại `CREATE OR ALTER`.
- Bảng mã UTF-8 có BOM đảm bảo tiếng Việt dấu không bị lỗi font khi mở trên bất kỳ môi trường nào.
"@

[System.IO.File]::WriteAllText((Join-Path $OutputDir 'README.md'), $readmeContent, $utf8Bom)
Write-Output "Generated README.md"

$conn.Close()
Write-Output "Export completed successfully to: $OutputDir"
