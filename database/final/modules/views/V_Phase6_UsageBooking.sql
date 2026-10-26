USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.V_Phase6_UsageBooking AS
 SELECT d.MaDatSan,d.MaSan,d.NgayChoi,d.TrangThai,
 CASE WHEN d.TrangThai=N'Đã hủy' THEN 0 ELSE
 CASE WHEN d.GioKetThuc<=CONVERT(time,'07:00') OR d.GioBatDau>=CONVERT(time,'22:00') THEN 0 ELSE
 DATEDIFF(minute,CASE WHEN d.GioBatDau<CONVERT(time,'07:00') THEN CONVERT(time,'07:00') ELSE d.GioBatDau END,
 CASE WHEN d.GioKetThuc>CONVERT(time,'22:00') THEN CONVERT(time,'22:00') ELSE d.GioKetThuc END) END END PhutDat,
 CONVERT(int,CASE WHEN EXISTS(SELECT 1 FROM dbo.XacNhanSan x WHERE x.MaDatSan=d.MaDatSan AND x.ThoiGianKetThuc IS NOT NULL) THEN 1 ELSE 0 END) DaSuDung
 FROM dbo.DatSan d;
GO
