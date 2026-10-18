/* Read-only module upgrade. No tables, stored snapshots, passwords or grants are changed. */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51100,'Reviewed DEV/test database required',1;
BEGIN TRY
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.fn_KhungGioTrongTheoNgay') IS NOT NULL THROW 51101,'New module already exists; inspect before upgrading',1;
EXEC(N'CREATE FUNCTION dbo.fn_KhungGioTrongTheoNgay(@Ngay date) RETURNS TABLE AS RETURN (
 SELECT s.MaSan,s.TenSan,l.TenLoaiSan,k.MaKhungGio,k.GioBatDau,k.GioKetThuc,@Ngay NgayChoi
 FROM dbo.San s JOIN dbo.LoaiSan l ON l.MaLoaiSan=s.MaLoaiSan CROSS JOIN dbo.KhungGio k
 WHERE @Ngay IS NOT NULL AND s.TrangThai<>N''Bảo trì''
 AND k.GioBatDau>=''07:00'' AND k.GioKetThuc<=''22:00''
 AND NOT EXISTS(SELECT 1 FROM dbo.DatSan d WHERE d.MaSan=s.MaSan AND d.NgayChoi=@Ngay
 AND d.TrangThai<>N''Đã hủy'' AND d.GioBatDau<k.GioKetThuc AND d.GioKetThuc>k.GioBatDau));');
IF OBJECT_ID(N'dbo.V_ThuTienTheoNgay') IS NOT NULL THROW 51101,'New module already exists; inspect before upgrading',1;
EXEC(N'CREATE VIEW dbo.V_ThuTienTheoNgay AS
 SELECT CAST(NgayThanhToan AS date) Ngay,PhuongThuc,COUNT(*) SoGiaoDich,SUM(SoTien) TongTien
 FROM dbo.ThanhToan WHERE TrangThai=N''Thành công'' GROUP BY CAST(NgayThanhToan AS date),PhuongThuc;');
IF OBJECT_ID(N'dbo.V_DoanhThuPhatSinhTheoNgay') IS NOT NULL THROW 51101,'New module already exists; inspect before upgrading',1;
EXEC(N'CREATE VIEW dbo.V_DoanhThuPhatSinhTheoNgay AS
 SELECT Ngay,COUNT(*) SoHoaDon,SUM(TienSan) TienSan,SUM(TienDichVu) TienDichVu,
 SUM(TienGiam) TienGiam,SUM(DoanhThu) DoanhThu FROM dbo.V_Phase6_Revenue GROUP BY Ngay;');
IF OBJECT_ID(N'dbo.V_TyLeSuDungTheoNgay') IS NOT NULL THROW 51101,'New module already exists; inspect before upgrading',1;
EXEC(N'CREATE VIEW dbo.V_TyLeSuDungTheoNgay AS
 SELECT u.NgayChoi,COUNT(CASE WHEN u.TrangThai<>N''Đã hủy'' THEN 1 END) SoLuotDat,
 SUM(CONVERT(bigint,u.PhutDat)) PhutDat,
 (SELECT COUNT_BIG(*)*900 FROM dbo.San) PhutCongSuat,
 CAST(100.0*SUM(CONVERT(bigint,u.PhutDat))/NULLIF((SELECT COUNT_BIG(*)*900 FROM dbo.San),0) AS decimal(18,2)) TyLeLapDay
 FROM dbo.V_Phase6_UsageBooking u GROUP BY u.NgayChoi;');
EXEC(N'ALTER VIEW dbo.V_KhungGioTrong AS
 SELECT MaSan,TenSan,TenLoaiSan,MaKhungGio,GioBatDau,GioKetThuc,NgayChoi
 FROM dbo.fn_KhungGioTrongTheoNgay(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE ''SE Asia Standard Time''));');
EXEC(N'ALTER VIEW dbo.V_DoanhThuTheoNgay AS
 SELECT Ngay,PhuongThuc,SoGiaoDich,TongTien FROM dbo.V_ThuTienTheoNgay;');
EXEC(N'ALTER VIEW dbo.V_TyLeLapDay AS
 SELECT NgayChoi,SoLuotDat,(SELECT COUNT(*) FROM dbo.San)*(SELECT COUNT(*) FROM dbo.KhungGio) TongKhungGio,
 TyLeLapDay,PhutDat,PhutCongSuat FROM dbo.V_TyLeSuDungTheoNgay;');
EXEC sys.sp_addextendedproperty @name=N'SanBongContract',@value=N'Current Vietnam calendar day only; new NgayChoi column. For a selected date use fn_KhungGioTrongTheoNgay. Read-only candidate slots, never a reservation/lock.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_KhungGioTrong';
EXEC sys.sp_addextendedproperty @name=N'SanBongContract',@value=N'DEPRECATED NAME. Compatibility alias for gross successful receipts before refunds. Use V_ThuTienTheoNgay; accrued revenue is V_DoanhThuPhatSinhTheoNgay; net cash is V_ThuChiThucNhan.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_DoanhThuTheoNgay';
EXEC sys.sp_addextendedproperty @name=N'SanBongContract',@value=N'Ratio uses booked minutes within 07:00-22:00 / 900 minutes per current pitch, like usp_ReportUsage. TongKhungGio retained as legacy informational count, NOT the ratio denominator. No historical maintenance inventory; no cap hides overlaps.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_TyLeLapDay';
COMMIT;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
