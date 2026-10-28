/* Read-only fingerprints, no row payload or credentials exported. */
SET NOCOUNT ON;
DECLARE @objects TABLE(t sysname,k sysname);
INSERT @objects VALUES('DatSan','MaDatSan'),('HoaDon','MaHoaDon'),('ChiTietDichVu','MaChiTiet'),('ThanhToan','MaTT'),('HoanTien','MaHT'),('HuyDatSan','MaHuy'),('XacNhanSan','MaXacNhan'),('DichVu','MaDV'),('GiaTheoCa','MaCa');
DECLARE @table sysname,@key sysname,@sql nvarchar(max);
DECLARE obj CURSOR LOCAL FAST_FORWARD FOR SELECT t,k FROM @objects ORDER BY t;
OPEN obj;FETCH NEXT FROM obj INTO @table,@key;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @sql=N'SELECT N'''+@table+N''' AS tableName,COUNT_BIG(*) AS [rowCount],CONVERT(varchar(64),HASHBYTES(''SHA2_256'',(SELECT * FROM dbo.'+QUOTENAME(@table)+N' ORDER BY '+QUOTENAME(@key)+N' FOR JSON PATH,INCLUDE_NULL_VALUES)),2) AS sha256 FROM dbo.'+QUOTENAME(@table)+N';';
 EXEC sys.sp_executesql @sql;
 FETCH NEXT FROM obj INTO @table,@key;
END;
CLOSE obj;DEALLOCATE obj;
