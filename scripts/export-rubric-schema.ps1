param([Parameter(Mandatory=$true)][ValidatePattern('^QuanLySanBong(?:_Fixtures_[A-Za-z0-9_]+)?$')][string]$Database,[string]$Server='tcp:localhost,1433',[string]$OutputFile=(Join-Path (Split-Path $PSScriptRoot -Parent) 'exports/rubric-schema.json'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data.SqlClient
$qaConnection=[System.Data.SqlClient.SqlConnection]::new("Data Source=$Server;Initial Catalog=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True")
$qaSql=@'
SET NOCOUNT ON;
SELECT
 (SELECT t.name,
   JSON_QUERY((SELECT c.name,ty.name type,c.max_length,c.precision,c.scale,c.collation_name,c.is_nullable,c.is_identity,CONVERT(varchar(50),ic.seed_value) identity_seed,CONVERT(varchar(50),ic.increment_value) identity_increment,cc.definition computed,cc.is_persisted,dc.name default_name,dc.definition default_definition
    FROM sys.columns c JOIN sys.types ty ON ty.user_type_id=c.user_type_id
    LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
    LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
    LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id
    WHERE c.object_id=t.object_id ORDER BY c.column_id FOR JSON PATH)) columns,
   JSON_QUERY((SELECT i.name,i.type_desc,i.is_primary_key,i.is_unique,i.is_unique_constraint,i.filter_definition,
      JSON_QUERY((SELECT c.name,ix.is_descending_key,ix.is_included_column FROM sys.index_columns ix JOIN sys.columns c ON c.object_id=ix.object_id AND c.column_id=ix.column_id WHERE ix.object_id=i.object_id AND ix.index_id=i.index_id ORDER BY ix.is_included_column,ix.key_ordinal,ix.index_column_id FOR JSON PATH)) columns
      FROM sys.indexes i WHERE i.object_id=t.object_id AND i.index_id>0 AND i.is_hypothetical=0 FOR JSON PATH)) indexes,
   JSON_QUERY((SELECT k.name,k.definition,k.is_disabled,k.is_not_trusted FROM sys.check_constraints k WHERE k.parent_object_id=t.object_id FOR JSON PATH)) checks
 FROM sys.tables t WHERE t.schema_id=SCHEMA_ID('dbo') AND t.name<>'sysdiagrams' ORDER BY t.name FOR JSON PATH) tables,
 (SELECT k.name,OBJECT_NAME(k.parent_object_id) child,OBJECT_NAME(k.referenced_object_id) parent,k.delete_referential_action_desc on_delete,k.update_referential_action_desc on_update,k.is_disabled,k.is_not_trusted,
   JSON_QUERY((SELECT COL_NAME(f.parent_object_id,f.parent_column_id) child,COL_NAME(f.referenced_object_id,f.referenced_column_id) parent FROM sys.foreign_key_columns f WHERE f.constraint_object_id=k.object_id ORDER BY f.constraint_column_id FOR JSON PATH)) columns
 FROM sys.foreign_keys k WHERE OBJECT_NAME(k.parent_object_id)<>'sysdiagrams' ORDER BY k.name FOR JSON PATH) foreign_keys,
 (SELECT o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,
   JSON_QUERY((SELECT DISTINCT OBJECT_NAME(d.referenced_id) name FROM sys.sql_expression_dependencies d WHERE d.referencing_id=o.object_id AND d.referenced_id IS NOT NULL FOR JSON PATH)) dependencies
 FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID('dbo') AND o.type IN('V','FN','IF','TF','P','TR') AND o.name NOT LIKE 'sp[_]%diagram%' AND o.name<>'fn_diagramobjects' ORDER BY o.type,o.name FOR JSON PATH) modules
FOR JSON PATH,WITHOUT_ARRAY_WRAPPER;
'@
try{
 $qaConnection.Open();$qaCommand=$qaConnection.CreateCommand();$qaCommand.CommandText=$qaSql
 $qaReader=$qaCommand.ExecuteReader();$qaJson=[Text.StringBuilder]::new()
 try{while($qaReader.Read()){$null=$qaJson.Append($qaReader.GetString(0))}}finally{$qaReader.Dispose()}
 $qaRecord=$qaJson.ToString() | ConvertFrom-Json
 $qaCommand.CommandText="SELECT CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation'))"
 $qaResult=[ordered]@{database=$Database;collation=$qaCommand.ExecuteScalar();capturedAt=[DateTimeOffset]::Now.ToString('o');tables=$qaRecord.tables;foreignKeys=$qaRecord.foreign_keys;modules=$qaRecord.modules}
 $qaPath=[IO.Path]::GetFullPath($OutputFile)
 $qaParent=[IO.Path]::GetDirectoryName($qaPath)
 if(-not(Test-Path -LiteralPath $qaParent)){New-Item -ItemType Directory -Path $qaParent | Out-Null}
 $qaResult | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $qaPath -Encoding utf8
 Write-Output "Schema-only metadata saved: $qaPath. No application rows, hashes or secrets exported."
}finally{$qaConnection.Dispose()}
