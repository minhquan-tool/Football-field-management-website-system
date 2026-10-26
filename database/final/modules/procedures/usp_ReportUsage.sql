USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
