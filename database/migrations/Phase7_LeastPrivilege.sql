-- Run as SQL administrator, AFTER creating a dedicated login privately.
DECLARE @login sysname='$(AppLogin)';
IF @login LIKE '%[^a-zA-Z0-9_]%' OR @login IN('sa','dbo') THROW 50710,'Invalid runtime login',1;
IF SUSER_ID(@login) IS NULL THROW 50711,'Create login through secure admin workflow first',1;
IF DATABASE_PRINCIPAL_ID('SanBongRuntime') IS NULL CREATE ROLE SanBongRuntime AUTHORIZATION dbo;
DECLARE @sql nvarchar(max);
IF DATABASE_PRINCIPAL_ID(@login) IS NULL BEGIN SET @sql=N'CREATE USER '+QUOTENAME(@login)+N' FOR LOGIN '+QUOTENAME(@login);EXEC(@sql);END;
IF IS_ROLEMEMBER('SanBongRuntime',@login)<>1 BEGIN SET @sql=N'ALTER ROLE SanBongRuntime ADD MEMBER '+QUOTENAME(@login);EXEC(@sql);END;
GRANT SELECT ON SCHEMA::dbo TO SanBongRuntime;
GRANT EXECUTE ON dbo.fn_TyLeHoan TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.TaiKhoan TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.NhanVien TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.KhachHang TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.PhanQuyen TO SanBongRuntime;
GRANT INSERT ON dbo.NhatKyHeThong TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.San TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.DatSan TO SanBongRuntime;
GRANT INSERT,UPDATE,DELETE ON dbo.ChiTietDichVu TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.XacNhanSan TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.HoaDon TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.ThanhToan TO SanBongRuntime;
GRANT INSERT ON dbo.HuyDatSan TO SanBongRuntime;
GRANT INSERT,UPDATE ON dbo.HoanTien TO SanBongRuntime;
GRANT UPDATE ON dbo.DichVu TO SanBongRuntime;
-- No db_owner/sysadmin, CREATE/ALTER/DROP, data cleanup DELETEs or audit mutation rights.
