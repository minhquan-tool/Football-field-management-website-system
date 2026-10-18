-- Authorized medium-priority hardening; rehearse on a reviewed DEV/test copy first.
-- sqlcmd -b -d <reviewed DB> -v ReviewedDatabase=<same DB> -i <this file>
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 50860,'Unexpected reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 50861,'Reviewed DEV/test marker required',1;
IF DATABASE_PRINCIPAL_ID(N'SanBongApp') IS NULL THROW 50862,'Runtime user missing',1;
IF EXISTS(SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id WHERE m.member_principal_id=DATABASE_PRINCIPAL_ID(N'SanBongApp') AND r.name NOT IN(N'db_datareader',N'db_datawriter',N'SanBongRuntimeRole')) THROW 50863,'Unexpected runtime role; review before changing',1;
IF EXISTS(SELECT 1 FROM sys.database_role_members WHERE role_principal_id=DATABASE_PRINCIPAL_ID(N'SanBongRuntimeRole') AND member_principal_id<>DATABASE_PRINCIPAL_ID(N'SanBongApp')) THROW 50864,'Runtime role has other members',1;
IF EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'SanBongRuntimeRole') AND (class<>1 OR permission_name NOT IN(N'SELECT',N'INSERT',N'UPDATE',N'DELETE',N'EXECUTE'))) THROW 50865,'Unexpected existing role grants',1;

DECLARE @rights TABLE(tbl sysname PRIMARY KEY,canInsert bit,canUpdate bit,canDelete bit);
INSERT @rights VALUES
(N'BangGia',1,0,0),(N'ChiTietDanhGia',1,0,0),(N'ChiTietDichVu',1,1,1),(N'ChucNang',0,0,0),
(N'DanhGia',1,1,0),(N'DatSan',1,1,0),(N'DichVu',1,1,0),(N'GiaTheoCa',0,1,0),
(N'HoaDon',1,1,0),(N'HoanTien',1,1,0),(N'HuyDatSan',1,0,0),(N'KhachHang',1,1,0),
(N'KhungGio',1,1,0),(N'KhuyenMai',1,1,0),(N'LoaiSan',1,1,0),(N'NhanVien',1,1,0),
(N'NhatKyHeThong',1,0,0),(N'PhanHoi',1,1,0),(N'PhanQuyen',1,1,0),(N'San',1,1,0),
(N'TaiKhoan',1,1,0),(N'ThanhToan',1,1,0),(N'TieuChiDanhGia',0,0,0),(N'VaiTro',0,0,0),(N'XacNhanSan',1,1,0);
IF EXISTS(SELECT 1 FROM @rights WHERE OBJECT_ID(N'dbo.'+tbl,N'U') IS NULL) THROW 50866,'Expected business table missing',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF DATABASE_PRINCIPAL_ID(N'SanBongRuntimeRole') IS NULL EXEC(N'CREATE ROLE SanBongRuntimeRole AUTHORIZATION dbo');
 IF IS_ROLEMEMBER(N'db_datareader',N'SanBongApp')=1 ALTER ROLE db_datareader DROP MEMBER SanBongApp;
 IF IS_ROLEMEMBER(N'db_datawriter',N'SanBongApp')=1 ALTER ROLE db_datawriter DROP MEMBER SanBongApp;
 IF IS_ROLEMEMBER(N'SanBongRuntimeRole',N'SanBongApp')<>1 ALTER ROLE SanBongRuntimeRole ADD MEMBER SanBongApp;
 DECLARE @tbl sysname,@ins bit,@upd bit,@del bit,@sql nvarchar(max);
 DECLARE all_tables CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo');
 OPEN all_tables;FETCH NEXT FROM all_tables INTO @tbl;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @sql=N'REVOKE SELECT,INSERT'+CASE WHEN @tbl=N'NhatKyHeThong' THEN N'' ELSE N',UPDATE,DELETE' END+N' ON OBJECT::dbo.'+QUOTENAME(@tbl)+N' FROM SanBongApp; REVOKE SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.'+QUOTENAME(@tbl)+N' FROM SanBongRuntimeRole;';
  EXEC sys.sp_executesql @sql;FETCH NEXT FROM all_tables INTO @tbl;
 END;
 CLOSE all_tables;DEALLOCATE all_tables;
 DECLARE allowed_tables CURSOR LOCAL FAST_FORWARD FOR SELECT tbl,canInsert,canUpdate,canDelete FROM @rights;
 OPEN allowed_tables;FETCH NEXT FROM allowed_tables INTO @tbl,@ins,@upd,@del;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @sql=N'GRANT SELECT'+CASE WHEN @ins=1 THEN N',INSERT' ELSE N'' END+CASE WHEN @upd=1 THEN N',UPDATE' ELSE N'' END+CASE WHEN @del=1 THEN N',DELETE' ELSE N'' END+N' ON OBJECT::dbo.'+QUOTENAME(@tbl)+N' TO SanBongRuntimeRole;';
  EXEC sys.sp_executesql @sql;FETCH NEXT FROM allowed_tables INTO @tbl,@ins,@upd,@del;
 END;
 CLOSE allowed_tables;DEALLOCATE allowed_tables;
 GRANT SELECT ON OBJECT::dbo.V_ThuChiThucNhan TO SanBongRuntimeRole;
 GRANT SELECT ON OBJECT::dbo.V_Phase6_Revenue TO SanBongRuntimeRole;
 GRANT SELECT ON OBJECT::dbo.V_Phase6_UsageBooking TO SanBongRuntimeRole;
 GRANT EXECUTE ON OBJECT::dbo.fn_TyLeHoan TO SanBongRuntimeRole;
 DENY UPDATE,DELETE ON OBJECT::dbo.NhatKyHeThong TO SanBongApp;
 DECLARE @mismatch int;
 EXECUTE AS USER=N'SanBongApp';
 SELECT @mismatch=COUNT(*) FROM @rights WHERE ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+tbl,N'OBJECT',N'SELECT'),-1)<>1
 OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+tbl,N'OBJECT',N'INSERT'),-1)<>canInsert
 OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+tbl,N'OBJECT',N'UPDATE'),-1)<>canUpdate
 OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+tbl,N'OBJECT',N'DELETE'),-1)<>canDelete;
 SELECT @mismatch=@mismatch+COUNT(*) FROM (VALUES(N'V_ThuChiThucNhan'),(N'V_Phase6_Revenue'),(N'V_Phase6_UsageBooking')) v(name)
 WHERE ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+name,N'OBJECT',N'SELECT'),-1)<>1;
 REVERT;
 IF @mismatch<>0 THROW 50867,'Effective runtime rights differ from reviewed matrix; rolling back',1;
 COMMIT;
END TRY
BEGIN CATCH
 IF USER_NAME()=N'SanBongApp' REVERT;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
SELECT N'PASS' AS RuntimeWhitelist,DB_NAME() AS ReviewedDatabase,COUNT(*) AS ExplicitBusinessTables FROM @rights;
