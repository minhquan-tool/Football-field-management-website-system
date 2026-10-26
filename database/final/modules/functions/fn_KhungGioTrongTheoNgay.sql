USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_KhungGioTrongTheoNgay(@Ngay date) RETURNS TABLE AS RETURN (
 SELECT s.MaSan,s.TenSan,l.TenLoaiSan,k.MaKhungGio,k.GioBatDau,k.GioKetThuc,@Ngay NgayChoi
 FROM dbo.San s JOIN dbo.LoaiSan l ON l.MaLoaiSan=s.MaLoaiSan CROSS JOIN dbo.KhungGio k
 WHERE @Ngay IS NOT NULL AND s.TrangThai<>N'Bảo trì'
 AND k.GioBatDau>='07:00' AND k.GioKetThuc<='22:00'
 AND NOT EXISTS(SELECT 1 FROM dbo.DatSan d WHERE d.MaSan=s.MaSan AND d.NgayChoi=@Ngay
 AND d.TrangThai<>N'Đã hủy' AND d.GioBatDau<k.GioKetThuc AND d.GioKetThuc>k.GioBatDau));
GO
