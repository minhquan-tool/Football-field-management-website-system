"""Build reviewed financial-derivation migration from the pre-change metadata.
No database connection and no application records or secrets are read.
"""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
meta=json.loads(((root/'exports/normalization-before-schema.json') if (root/'exports/normalization-before-schema.json').exists() else (root/'database/metadata/normalization-before-schema.json')).read_text(encoding='utf-8-sig'))
tables={t['name']:t for t in meta['tables']}
q=lambda s:'['+s.replace(']',']]')+']'
lit=lambda s:"N'"+s.replace("'","''")+"'"
original={name:[c['name'] for c in tables[name]['columns']] for name in ['DatSan','HoaDon','ChiTietDichVu']}
out=["""/* REVIEW REQUIRED: financial schema change; stop the old JAR before deployment.
   Moves only deterministic derivations to persisted computed columns.
   Original legacy service price is preserved in DonGiaLegacySnapshot.
   All original financial fields are SHA256-compared before COMMIT.
   Requires the matching backend (no INSERT/UPDATE of computed columns).
   sqlcmd -b -f 65001 -v ReviewedDatabase=<reviewed dev/test DB> -i <file> */
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51100,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51101,'DEV/test marker required',1;
IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TongTien','IsComputed')<>0 OR COL_LENGTH('dbo.ChiTietDichVu','DonGiaLegacySnapshot') IS NOT NULL THROW 51102,'Unexpected/already migrated schema',1;
BEGIN TRY
 BEGIN TRANSACTION;
 -- Lock order matches application writes. Migration also acquires schema locks.
 DECLARE @locked bigint;
 SELECT @locked=COUNT_BIG(*) FROM dbo.San WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.HoaDon WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.ChiTietDichVu WITH(UPDLOCK,HOLDLOCK);
 IF EXISTS(SELECT 1 FROM dbo.DatSan WHERE TongTien<>TienSan+TienDichVu-TienGiam) OR EXISTS(SELECT 1 FROM dbo.HoaDon WHERE TongTien<>TienSan+TienDichVu-TienGiam) THROW 51103,'Totals differ; review legacy data, never silently repair it',1;
 IF EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE SoDonViMoiQuyCach<>CASE WHEN QuyCach='LOC_6' THEN 6 ELSE 1 END OR (Nguon<>'LEGACY' AND DonGia<>ROUND(DonGiaDonViSnapshot*SoDonViMoiQuyCach*CASE WHEN QuyCach='LOC_6' THEN 0.97 ELSE 1 END,2))) THROW 51104,'Service derivation mismatch; review without repricing',1;
 CREATE TABLE #Before(t sysname PRIMARY KEY,h varbinary(32));
"""
]
keys={'DatSan':'MaDatSan','HoaDon':'MaHoaDon','ChiTietDichVu':'MaChiTiet'}
for name,cols in original.items():
    query='SELECT '+','.join(q(c) for c in cols)+' FROM dbo.'+q(name)+' ORDER BY '+q(keys[name])+' FOR JSON PATH,INCLUDE_NULL_VALUES'
    out.append(f" INSERT #Before VALUES('{name}',HASHBYTES('SHA2_256',({query})));\n")
for table,col in [('DatSan','TongTien'),('DatSan','TienSan'),('ChiTietDichVu','SoDonViMoiQuyCach')]:
    default=next(c for c in tables[table]['columns'] if c['name']==col).get('default_name')
    if default:out.append(f' ALTER TABLE dbo.{q(table)} DROP CONSTRAINT {q(default)};\n')
out.append("""
 ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_Tien,CK_DatSan_ThoiLuong;
 ALTER TABLE dbo.HoaDon DROP CONSTRAINT CK_HD_Money;
 ALTER TABLE dbo.HoaDon DROP COLUMN ConLai,HoanTatTaiChinh;
 ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT CK_CTDV_DonGia,CK_CTDV_QuyCach,CK_CTDV_Snapshot;
 ALTER TABLE dbo.ChiTietDichVu ADD DonGiaLegacySnapshot decimal(18,2) NULL;
 ALTER TABLE dbo.DatSan ADD ThoiLuongLegacySnapshot decimal(4,2) NULL,TienSanLegacySnapshot decimal(18,2) NULL;
 -- Dynamic compilation after adding the column; do not touch new-sale unit snapshots.
 EXEC(N'UPDATE dbo.ChiTietDichVu SET DonGiaLegacySnapshot=DonGia WHERE Nguon=''LEGACY'';');
 EXEC(N'UPDATE dbo.DatSan SET ThoiLuongLegacySnapshot=ThoiLuong,TienSanLegacySnapshot=TienSan WHERE CheDoGia=''GIA_KHUNG'';');
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN ThanhTien;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGia,SoDonViMoiQuyCach;
 ALTER TABLE dbo.DatSan DROP COLUMN TongTien;
 ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuong,TienSan;
 ALTER TABLE dbo.HoaDon DROP COLUMN TongTien;
"""
)
total='CONVERT(decimal(18,2),TienSan+TienDichVu-TienGiam)'
duration="CONVERT(decimal(4,2),CASE WHEN CheDoGia='GIA_KHUNG' THEN ThoiLuongLegacySnapshot ELSE ROUND(DATEDIFF(minute,GioBatDau,GioKetThuc)/60.0,2) END)"
pitch="CONVERT(decimal(18,2),CASE WHEN CheDoGia='GIA_KHUNG' THEN TienSanLegacySnapshot ELSE ROUND(DonGia*DATEDIFF(minute,GioBatDau,GioKetThuc)/60.0,2) END)"
booking_total=f'CONVERT(decimal(18,2),{pitch}+TienDichVu-TienGiam)'
price="CONVERT(decimal(18,2),CASE WHEN Nguon='LEGACY' THEN DonGiaLegacySnapshot ELSE ROUND(DonGiaDonViSnapshot*CASE WHEN QuyCach='LOC_6' THEN 6 ELSE 1 END*CASE WHEN QuyCach='LOC_6' THEN 0.97 ELSE 1 END,2) END)"
ddl=f"""
ALTER TABLE dbo.DatSan ADD ThoiLuong AS ({duration}) PERSISTED,TienSan AS ({pitch}) PERSISTED,TongTien AS ({booking_total}) PERSISTED;
ALTER TABLE dbo.DatSan WITH CHECK ADD CONSTRAINT CK_DatSan_Tien CHECK(DonGia>0 AND TienSan IS NOT NULL AND TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0 AND TongTien>=0),
 CONSTRAINT CK_DatSan_ThoiLuong CHECK(ThoiLuong IS NOT NULL AND ThoiLuong>0),
 CONSTRAINT CK_DatSan_LegacySnapshots CHECK((CheDoGia='GIA_KHUNG' AND ThoiLuongLegacySnapshot IS NOT NULL AND ThoiLuongLegacySnapshot>0 AND TienSanLegacySnapshot IS NOT NULL AND TienSanLegacySnapshot>=0) OR (CheDoGia='GIA_GIO' AND ThoiLuongLegacySnapshot IS NULL AND TienSanLegacySnapshot IS NULL));
ALTER TABLE dbo.HoaDon ADD TongTien AS ({total}) PERSISTED,
 ConLai AS (CASE WHEN TrangThai='DA_HUY' THEN CONVERT(decimal(18,2),0) ELSE {total}-DaThanhToan END) PERSISTED,
 HoanTatTaiChinh AS CONVERT(bit,CASE WHEN DaChot=1 AND {total}=DaThanhToan AND TrangThai='DA_THANH_TOAN' THEN 1 ELSE 0 END) PERSISTED;
ALTER TABLE dbo.HoaDon WITH CHECK ADD CONSTRAINT CK_HD_Money CHECK(TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0 AND TienGiam<=TienSan AND TongTien>=0 AND DaThanhToan>=0 AND DaThanhToan<=TongTien);
ALTER TABLE dbo.ChiTietDichVu ADD SoDonViMoiQuyCach AS (CONVERT(int,CASE WHEN QuyCach='LOC_6' THEN 6 ELSE 1 END)) PERSISTED,
 DonGia AS ({price}) PERSISTED,
 ThanhTien AS (SoLuong*{price}) PERSISTED;
ALTER TABLE dbo.ChiTietDichVu WITH CHECK ADD CONSTRAINT CK_CTDV_QuyCach CHECK(QuyCach IN('DON_VI','LOC_6')),
 CONSTRAINT CK_CTDV_DonGia CHECK(DonGia IS NOT NULL AND DonGia>0),
 CONSTRAINT CK_CTDV_Snapshot CHECK((Nguon='LEGACY' AND DonGiaLegacySnapshot IS NOT NULL AND DonGiaLegacySnapshot>0 AND (DonGiaDonViSnapshot IS NULL OR DonGiaDonViSnapshot>0)) OR (Nguon<>'LEGACY' AND DonGiaLegacySnapshot IS NULL AND DonGiaDonViSnapshot IS NOT NULL AND DonGiaDonViSnapshot>0));
"""
for statement in ddl.strip().split(';\n'):
    if statement.strip():out.append(' EXEC('+lit(statement.strip().rstrip(';')+';')+');\n')
trigger=next(m['definition'] for m in meta['modules'] if m['name']=='TRG_CapNhatTienDatSan')
# Only remove the redundant total assignment; retain the one trigger that SUMs service lines.
trigger=re.sub(r'\bCREATE(?:\s+OR\s+ALTER)?\s+TRIGGER\b','ALTER TRIGGER',trigger,count=1,flags=re.I)
trigger=re.sub(r',\s*(?:d\.)?TongTien\s*=.*?(?=\n\s*FROM)', '',trigger, flags=re.I|re.S)
if re.search(r'\bTongTien\s*=',trigger,re.I):raise RuntimeError('Review actual trigger total assignment')
out.append(' EXEC('+lit(trigger)+');\n')
for name,cols in original.items():
    query='SELECT '+','.join(q(c) for c in cols)+' FROM dbo.'+q(name)+' ORDER BY '+q(keys[name])+' FOR JSON PATH,INCLUDE_NULL_VALUES'
    out.append(' EXEC('+lit(f"IF (SELECT h FROM #Before WHERE t='{name}')<>HASHBYTES('SHA2_256',({query})) THROW 51105,'Original financial projection changed: {name}',1;")+');\n')
out.append(" COMMIT;\nEND TRY\nBEGIN CATCH\n IF @@TRANCOUNT>0 ROLLBACK; THROW;\nEND CATCH;\n")
(root/'database/migrations/NormalizeFinancialDerivations_20261017_PROPOSAL.sql').write_text(''.join(out),encoding='utf-8')
fingerprints=['/* Read-only: same ordered pre-migration projection on both schemas. */','SET NOCOUNT ON;']
for name in ['DatSan','HoaDon','ChiTietDichVu','ThanhToan','HoanTien','HuyDatSan','XacNhanSan','DichVu','GiaTheoCa']:
    table=tables[name]
    key=next(i for i in table['indexes'] if i['is_primary_key'])
    order=','.join(q(c['name']) for c in key['columns'] if not c['is_included_column'])
    fields=','.join(q(c['name']) for c in table['columns'])
    fingerprints.append(f"SELECT '{name}' AS tableName,COUNT_BIG(*) AS [rowCount],CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT {fields} FROM dbo.{q(name)} ORDER BY {order} FOR JSON PATH,INCLUDE_NULL_VALUES)),2) AS sha256 FROM dbo.{q(name)};")
(root/'database/migrations/legacy/normalization-original-fingerprints.sql').write_text('\n'.join(fingerprints)+'\n',encoding='utf-8')
print('Proposal generated; no database was modified')
