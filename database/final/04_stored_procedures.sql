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

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportFinance
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportFinance @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) , rev AS (SELECT Ngay,SUM(TienSan) san,SUM(TienDichVu) dv,SUM(TienGiam) giam,SUM(DoanhThu) doanhThu FROM V_Phase6_Revenue WHERE Ngay>=@From AND Ngay<DATEADD(day,1,@To) AND (@Pitch='' OR MaSan=@Pitch) GROUP BY Ngay), cash AS (SELECT CAST(v.ThoiDiem AS date) Ngay,SUM(CASE WHEN v.Loai=N'Thu' THEN v.SoTienThucNhan ELSE 0 END) thu,SUM(CASE WHEN v.Loai=N'Hoàn' THEN -v.SoTienThucNhan ELSE 0 END) hoan,SUM(v.SoTienThucNhan) net FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='' OR d.MaSan=@Pitch) GROUP BY CAST(v.ThoiDiem AS date)) SELECT z.Ngay ngay,ISNULL(r.san,0) tienSan,ISNULL(r.dv,0) tienDichVu,ISNULL(r.giam,0) tienGiam,ISNULL(r.doanhThu,0) doanhThu,ISNULL(c.thu,0) tienThu,ISNULL(c.hoan,0) tienHoan,ISNULL(c.net,0) thucNhan FROM days z LEFT JOIN rev r ON r.Ngay=z.Ngay LEFT JOIN cash c ON c.Ngay=z.Ngay ORDER BY z.Ngay OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportPaymentMethods
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportPaymentMethods @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 SELECT v.PhuongThuc phuongThuc,SUM(CASE WHEN v.Loai=N'Thu' THEN 1 ELSE 0 END) soGiaoDich,SUM(CASE WHEN v.Loai=N'Thu' THEN v.SoTienThucNhan ELSE 0 END) tienThu,SUM(CASE WHEN v.Loai=N'Hoàn' THEN 1 ELSE 0 END) soGiaoDichHoan,SUM(CASE WHEN v.Loai=N'Hoàn' THEN -v.SoTienThucNhan ELSE 0 END) tienHoan,SUM(v.SoTienThucNhan) thucNhan FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='' OR d.MaSan=@Pitch) GROUP BY v.PhuongThuc ORDER BY v.PhuongThuc;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportReconciliation
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportReconciliation @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 SELECT d.MaDatSan maDatSan,s.TenSan tenSan,d.NgayChoi ngayChoi,d.TrangThai trangThai,h.MaHoaDon maHoaDon,h.DaChot daChot,d.TongTien tongBooking,h.TongTien tongHoaDon,h.DaThanhToan thuHoaDon,h.ConLai conLai,ISNULL(p.thu,0) tienThu,ISNULL(r.hoan,0) tienHoan,ISNULL(r.choHoan,0) choHoan,ISNULL(v.net,0) soThucNhan FROM DatSan d JOIN San s ON s.MaSan=d.MaSan LEFT JOIN HoaDon h ON h.MaDatSan=d.MaDatSan CROSS APPLY dbo.fn_BookingReceipts(d.MaDatSan) p CROSS APPLY dbo.fn_BookingRefunds(d.MaDatSan) r CROSS APPLY dbo.fn_BookingNetCash(d.MaDatSan) v WHERE d.NgayChoi>=@From AND d.NgayChoi<=@To AND (@Pitch='' OR d.MaSan=@Pitch) ORDER BY d.NgayChoi,d.MaDatSan;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportTopServices
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportTopServices @Day date AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @Day IS NULL OR @Day='99991231' THROW 51010,'Invalid day',1;
 SELECT TOP(5) c.MaDV maDV,v.TenDV tenDV,SUM(c.SoLuong*c.SoDonViMoiQuyCach) soDonVi,SUM(c.ThanhTien) tienDichVu FROM ChiTietDichVu c JOIN DichVu v ON v.MaDV=c.MaDV JOIN V_Phase6_Revenue r ON r.MaDatSan=c.MaDatSan WHERE r.Ngay=@Day GROUP BY c.MaDV,v.TenDV ORDER BY SUM(c.SoLuong*c.SoDonViMoiQuyCach) DESC,c.MaDV;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportUsage
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportUsage @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) SELECT z.Ngay ngay,s.MaSan maSan,s.TenSan tenSan,COUNT(u.MaDatSan) soBooking,ISNULL(SUM(u.DaSuDung),0) soDaSuDung,ISNULL(SUM(CASE WHEN u.TrangThai=N'Đã hủy' THEN 1 ELSE 0 END),0) soDaHuy,ISNULL(SUM(u.PhutDat),0) phutDat,900 phutCongSuat,CAST(ISNULL(SUM(u.PhutDat),0)/60.0 AS decimal(18,2)) gioDat,CAST(ISNULL(SUM(u.PhutDat),0)*100.0/900 AS decimal(18,2)) tyLeLapDay FROM days z CROSS JOIN San s LEFT JOIN V_Phase6_UsageBooking u ON u.NgayChoi=z.Ngay AND u.MaSan=s.MaSan WHERE (@Pitch='' OR s.MaSan=@Pitch) GROUP BY z.Ngay,s.MaSan,s.TenSan ORDER BY z.Ngay,s.MaSan OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

