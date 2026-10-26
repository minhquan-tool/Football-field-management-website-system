USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.V_DoanhThuTheoNgay AS
 SELECT Ngay,PhuongThuc,SoGiaoDich,TongTien FROM dbo.V_ThuTienTheoNgay;
GO
