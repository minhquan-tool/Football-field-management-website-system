"""Generate a matching, data-preserving rollback to the reviewed pre-normalization schema.
The rollback handles both early prototype and final migration; never DROP a table/DB.
"""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
meta=json.loads(((root/'exports/normalization-before-schema.json') if (root/'exports/normalization-before-schema.json').exists() else (root/'database/metadata/normalization-before-schema.json')).read_text(encoding='utf-8-sig'))
tables={t['name']:t for t in meta['tables']}
lit=lambda s:"N'"+s.replace("'","''")+"'"
out=["""/* REVIEWED ROLLBACK: retain current field values, no restore-overwrite or row deletion.
   Coordinate with old JAR. Test on a fixture before operational use. */
SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET NOCOUNT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51110,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51111,'DEV/test marker required',1;
IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TongTien','IsComputed')<>1 THROW 51112,'Not the normalized schema',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @lock bigint;
 SELECT @lock=COUNT_BIG(*) FROM dbo.San WITH(UPDLOCK,HOLDLOCK);
 SELECT @lock=COUNT_BIG(*) FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK);
 CREATE TABLE #Before(t sysname PRIMARY KEY,h varbinary(32));
"""
]
keys={'DatSan':'MaDatSan','HoaDon':'MaHoaDon','ChiTietDichVu':'MaChiTiet'}
queries={name:'SELECT '+','.join('['+c['name']+']' for c in tables[name]['columns'])+' FROM dbo.['+name+'] ORDER BY ['+key+'] FOR JSON PATH,INCLUDE_NULL_VALUES' for name,key in keys.items()}
for name,query in queries.items():out.append(f" INSERT #Before VALUES('{name}',HASHBYTES('SHA2_256',({query})));\n")
base={'DatSan':['TongTien'],'HoaDon':['TongTien'],'ChiTietDichVu':['DonGia','SoDonViMoiQuyCach']}
for name,cols in base.items():
    for col in cols:
        typ='int' if col=='SoDonViMoiQuyCach' else 'decimal(18,2)'
        out.append(' EXEC('+lit(f'ALTER TABLE dbo.{name} ADD [{col}_Rollback] {typ} NULL;')+');\n')
        out.append(' EXEC('+lit(f'UPDATE dbo.{name} SET [{col}_Rollback]=[{col}];')+');\n')
# Final migration converts two additional booking fields; initial prototype did not.
out.append(" IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TienSan','IsComputed')=1\n BEGIN\n")
for col,typ in [('ThoiLuong','decimal(4,2)'),('TienSan','decimal(18,2)')]:
    out.append(' EXEC('+lit(f'ALTER TABLE dbo.DatSan ADD [{col}_Rollback] {typ} NULL;')+');\n')
    out.append(' EXEC('+lit(f'UPDATE dbo.DatSan SET [{col}_Rollback]=[{col}];')+');\n')
out.append(' END;\n')
out.append("""
 ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_Tien;
 ALTER TABLE dbo.HoaDon DROP CONSTRAINT CK_HD_Money;
 ALTER TABLE dbo.HoaDon DROP COLUMN ConLai,HoanTatTaiChinh;
 ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT CK_CTDV_DonGia,CK_CTDV_QuyCach,CK_CTDV_Snapshot;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN ThanhTien;
 ALTER TABLE dbo.DatSan DROP COLUMN TongTien;
 ALTER TABLE dbo.HoaDon DROP COLUMN TongTien;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGia,SoDonViMoiQuyCach;
 IF COL_LENGTH('dbo.DatSan','ThoiLuong_Rollback') IS NOT NULL
 BEGIN
  ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_ThoiLuong,CK_DatSan_LegacySnapshots;
  ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuong,TienSan;
  EXEC sys.sp_rename N'dbo.DatSan.ThoiLuong_Rollback',N'ThoiLuong',N'COLUMN';
  EXEC sys.sp_rename N'dbo.DatSan.TienSan_Rollback',N'TienSan',N'COLUMN';
  EXEC(N'ALTER TABLE dbo.DatSan ALTER COLUMN ThoiLuong decimal(4,2) NOT NULL; ALTER TABLE dbo.DatSan ALTER COLUMN TienSan decimal(18,2) NOT NULL;');
  ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuongLegacySnapshot,TienSanLegacySnapshot;
 END;
"""
)
for name,cols in base.items():
    for col in cols:
        typ='int' if col=='SoDonViMoiQuyCach' else 'decimal(18,2)'
        out.append(f" EXEC sys.sp_rename N'dbo.{name}.{col}_Rollback',N'{col}',N'COLUMN';\n")
        out.append(' EXEC('+lit(f'ALTER TABLE dbo.{name} ALTER COLUMN [{col}] {typ} NOT NULL;')+');\n')
out.append(' ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGiaLegacySnapshot;\n')
for name in base:
    for c in tables[name]['columns']:
        if c.get('computed'):
            out.append(' EXEC('+lit(f"ALTER TABLE dbo.{name} ADD [{c['name']}] AS {c['computed']}"+(' PERSISTED' if c.get('is_persisted') else '')+';')+');\n')
    cks={'DatSan':['CK_DatSan_Tien','CK_DatSan_ThoiLuong'],'HoaDon':['CK_HD_Money'],'ChiTietDichVu':['CK_CTDV_DonGia','CK_CTDV_QuyCach','CK_CTDV_Snapshot']}[name]
    for ck in tables[name].get('checks',[]):
        if ck['name'] not in cks:continue
        if ck['name']=='CK_DatSan_ThoiLuong':out.append(" IF OBJECT_ID('dbo.CK_DatSan_ThoiLuong') IS NULL\n")
        out.append(' EXEC('+lit(f"ALTER TABLE dbo.{name} WITH CHECK ADD CONSTRAINT [{ck['name']}] CHECK {ck['definition']};")+');\n')
for name,col in [('DatSan','TongTien'),('DatSan','TienSan'),('ChiTietDichVu','SoDonViMoiQuyCach')]:
    c=next(c for c in tables[name]['columns'] if c['name']==col)
    if c.get('default_name'):
        out.append(f" IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.{name}') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.{name}'),'{col}','ColumnId'))\n")
        out.append(' EXEC('+lit(f"ALTER TABLE dbo.{name} ADD CONSTRAINT [{c['default_name']}] DEFAULT {c['default_definition']} FOR [{col}];")+');\n')
trigger=next(m['definition'] for m in meta['modules'] if m['name']=='TRG_CapNhatTienDatSan')
trigger=re.sub(r'\bCREATE(?:\s+OR\s+ALTER)?\s+TRIGGER\b','ALTER TRIGGER',trigger,count=1,flags=re.I)
out.append(' EXEC('+lit(trigger)+');\n')
for name,query in queries.items():out.append(' EXEC('+lit(f"IF (SELECT h FROM #Before WHERE t='{name}')<>HASHBYTES('SHA2_256',({query})) THROW 51113,'Rollback changed original projection: {name}',1;")+');\n')
out.append(' COMMIT;\nEND TRY\nBEGIN CATCH\n IF @@TRANCOUNT>0 ROLLBACK; THROW;\nEND CATCH;\n')
(root/'database/migrations/NormalizeFinancialDerivations_20261017_ROLLBACK.sql').write_text(''.join(out),encoding='utf-8')
print('Data-preserving rollback generated')
