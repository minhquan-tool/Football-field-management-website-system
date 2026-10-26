USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.V_DoanhThuPhatSinhTheoNgay AS
 SELECT Ngay,COUNT(*) SoHoaDon,SUM(TienSan) TienSan,SUM(TienDichVu) TienDichVu,
 SUM(TienGiam) TienGiam,SUM(DoanhThu) DoanhThu FROM dbo.V_Phase6_Revenue GROUP BY Ngay;
GO
