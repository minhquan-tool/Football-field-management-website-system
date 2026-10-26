USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.V_Phase6_Revenue AS
 SELECT d.MaDatSan,d.MaSan,CAST(x.ThoiGianKetThuc AS date) Ngay,
 COALESCE(h.TienSan,d.TienSan) TienSan,COALESCE(h.TienDichVu,d.TienDichVu) TienDichVu,
 COALESCE(h.TienGiam,d.TienGiam) TienGiam,COALESCE(h.TongTien,d.TongTien) DoanhThu
 FROM dbo.DatSan d JOIN (SELECT MaDatSan,MAX(ThoiGianKetThuc) ThoiGianKetThuc FROM dbo.XacNhanSan
 WHERE ThoiGianKetThuc IS NOT NULL GROUP BY MaDatSan) x ON x.MaDatSan=d.MaDatSan
 LEFT JOIN dbo.HoaDon h ON h.MaDatSan=d.MaDatSan
 WHERE d.TrangThai<>N'Đã hủy';
GO
