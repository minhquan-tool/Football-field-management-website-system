USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
