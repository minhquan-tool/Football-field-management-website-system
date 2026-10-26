USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
