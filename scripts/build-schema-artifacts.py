"""Schema-only ERD, dictionary and safe empty-database snapshot from verified metadata.
Never reads environment files or exports application records/password hashes.
"""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
data=json.loads(((root/'exports/rubric-schema.json') if (root/'exports/rubric-schema.json').exists() else (root/'database/metadata/current-schema.json')).read_text(encoding='utf-8-sig'))
def ident(s):return '['+s.replace(']',']]')+']'
def literal(s):return "N'"+s.replace("'","''")+"'"
def dtype(c):
 t=c['type']
 if t in ('nvarchar','nchar','varchar','char','varbinary','binary'):
  n=c['max_length']; t+='('+('max' if n==-1 else str(n//2 if t.startswith('n') else n))+')'
 elif t in ('decimal','numeric'):t+=f"({c['precision']},{c['scale']})"
 elif t in ('datetime2','time','datetimeoffset'):t+=f"({c['scale']})"
 return t
def keys(t):return [[c['name'] for c in i['columns'] if not c['is_included_column']] for i in t['indexes'] if i['is_unique']]
sql=[];md=['# Từ điển dữ liệu và ERD triển khai DBMS\n',f"Metadata chụp lúc {data['capturedAt']} từ bản sao đã cài bổ sung. Không có dữ liệu người dùng/mật khẩu.\n",'## ERD theo khóa ngoại hiện hành\n','```mermaid','erDiagram']
for t in data['tables']:
 pk={c['name'] for i in t['indexes'] if i['is_primary_key'] for c in i['columns']}
 fks={c['child'] for fk in data['foreignKeys'] if fk['child']==t['name'] for c in fk['columns']}
 md.append('    '+t['name']+' {')
 for c in t['columns']:
  flags=' PK' if c['name'] in pk else ' FK' if c['name'] in fks else ''
  md.append(f"        {c['type']} {c['name']}{flags}")
 md.append('    }')
 for fk in [f for f in data['foreignKeys'] if f['child']==t['name']]:
  childcols={c['child'] for c in fk['columns']}
  unique=any(set(k)==childcols for k in keys(t))
  nullable=any(c['is_nullable'] for c in t['columns'] if c['name'] in childcols)
  md.append(f"    {fk['parent']} "+('o|' if nullable else '||')+'--'+('o|' if unique else 'o{')+f" {t['name']} : {fk['name']}")
md+=['```','\nCardinality suy từ FK/nullability và unique key, không suy từ số dòng hiện có. Một cha có thể chưa có con; tham chiếu nullable cho phép con chưa liên kết cha.\n','## Bảng và ràng buộc\n']
for t in data['tables']:
 md+=['### '+t['name'],'','Khóa duy nhất: '+ '; '.join('('+', '.join(k)+')' for k in keys(t))+'.','', '| Cột | Kiểu | NULL | Định nghĩa / ràng buộc |','|---|---|---|---|']
 cols=[]
 for c in t['columns']:
  default=c.get('default_definition',''); expr=c.get('computed','')
  info=('Computed: '+expr) if expr else ('Default: '+default) if default else ''
  refs=[f"FK → {f['parent']}."+','.join(x['parent'] for x in f['columns']) for f in data['foreignKeys'] if f['child']==t['name'] and c['name'] in [x['child'] for x in f['columns']]]
  info+='; '.join(refs)
  md.append(f"| {c['name']} | {dtype(c)} | {'Có' if c['is_nullable'] else 'Không'} | {info.replace('|','/')} |")
  if expr:
   ddl=ident(c['name'])+' AS '+expr+(' PERSISTED' if c.get('is_persisted') else '')
  else:
   ddl=ident(c['name'])+' '+dtype(c)
   if c.get('collation_name'):ddl+=' COLLATE '+c['collation_name']
   if c['is_identity']:ddl+=f" IDENTITY({c['identity_seed']},{c['identity_increment']})"
   ddl+=' NULL' if c['is_nullable'] else ' NOT NULL'
   if default:ddl+=' CONSTRAINT '+ident(c['default_name'])+' DEFAULT '+default
  cols.append(ddl)
 for i in t['indexes']:
  if i['is_primary_key'] or i['is_unique_constraint']:
   k=','.join(ident(c['name'])+(' DESC' if c['is_descending_key'] else ' ASC') for c in i['columns'] if not c['is_included_column'])
   cols.append('CONSTRAINT '+ident(i['name'])+(' PRIMARY KEY ' if i['is_primary_key'] else ' UNIQUE ')+i['type_desc']+' ('+k+')')
 for ck in t.get('checks',[]):
  cols.append('CONSTRAINT '+ident(ck['name'])+' CHECK '+ck['definition'])
  md.append('\n- '+ck['name']+': `'+ck['definition']+'`'+(' **CẦN KIỂM TRA TRUST/ENABLE**' if ck['is_disabled'] or ck['is_not_trusted'] else ''))
 sql.append('CREATE TABLE dbo.'+ident(t['name'])+'(\n '+',\n '.join(cols)+'\n);')
 md.append('')
for f in data['foreignKeys']:
 child=','.join(ident(c['child']) for c in f['columns']); parent=','.join(ident(c['parent']) for c in f['columns'])
 sql.append(f"ALTER TABLE dbo.{ident(f['child'])} WITH CHECK ADD CONSTRAINT {ident(f['name'])} FOREIGN KEY ({child}) REFERENCES dbo.{ident(f['parent'])}({parent}) ON DELETE {f['on_delete'].replace('_',' ')} ON UPDATE {f['on_update'].replace('_',' ')};")
for t in data['tables']:
 for i in t['indexes']:
  if i['is_primary_key'] or i['is_unique_constraint']:continue
  ks=','.join(ident(c['name'])+(' DESC' if c['is_descending_key'] else ' ASC') for c in i['columns'] if not c['is_included_column'])
  included=','.join(ident(c['name']) for c in i['columns'] if c['is_included_column'])
  sql.append('CREATE '+('UNIQUE ' if i['is_unique'] else '')+i['type_desc']+' INDEX '+ident(i['name'])+' ON dbo.'+ident(t['name'])+'('+ks+')'+(' INCLUDE('+included+')' if included else '')+(' WHERE '+i['filter_definition'] if i.get('filter_definition') else '')+';')
pending={m['name']:m for m in data['modules']};done={t['name'] for t in data['tables']}
while pending:
 ready=[m for m in pending.values() if all(d['name'] not in pending or d['name']==m['name'] for d in m.get('dependencies',[]))]
 if not ready:raise RuntimeError('Module dependency cycle, review manually')
 for m in ready:
  definition=re.sub(r'^\s*(CREATE\s+OR\s+ALTER|ALTER)\b','CREATE',m['definition'],count=1,flags=re.I)
  sql.append('EXEC('+literal(definition)+');');done.add(m['name']);del pending[m['name']]
payload='SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;\nBEGIN TRY\nBEGIN TRANSACTION;\n'+'\n'.join(sql)+"\nEXEC sys.sp_addextendedproperty @name=N'SanBongEnvironment',@value=N'test';\nCOMMIT;\nEND TRY\nBEGIN CATCH\nIF @@TRANCOUNT>0 ROLLBACK; THROW;\nEND CATCH;"
header="""/* SCHEMA ONLY. No user/customer/account records, passwords, bank details, grants or logins.
   Contains reviewed-on-fixture financial guards; review before deployment.
   sqlcmd -b -f 65001 -d master -v NewDatabase=SanBong_SchemaDemo_YYYYMMDD -i <file>
   Will NEVER USE, overwrite, DROP, or restore an existing database. */
SET NOCOUNT ON;
DECLARE @name sysname=N'$(NewDatabase)';
IF @name NOT LIKE N'SanBong_SchemaDemo[_]%' OR @name LIKE N'%[^A-Za-z0-9_]%' OR LEN(@name)>100 THROW 51070,'Use a new SanBong_SchemaDemo_... name',1;
IF DB_ID(@name) IS NOT NULL THROW 51071,'Database exists; no changes performed',1;
DECLARE @create nvarchar(max)=N'CREATE DATABASE '+QUOTENAME(@name)+N' COLLATE __COLLATION__;';
EXEC(@create);
DECLARE @ddl nvarchar(max)=N'USE '+QUOTENAME(@name)+N'; '+__PAYLOAD__;
EXEC(@ddl);
PRINT 'New empty schema created; reference/demo data and private runtime user must be provisioned separately.';
"""
(root/'database/rubric-schema-new-only.sql').write_text(header.replace('__COLLATION__',data['collation']).replace('__PAYLOAD__',literal(payload)),encoding='utf-8')
(root/'docs/DBMS_SCHEMA_DICTIONARY.md').write_text('\n'.join(md),encoding='utf-8')
print(f"Generated ERD/dictionary for {len(data['tables'])} tables and schema-only snapshot with {len(data['modules'])} business modules")
