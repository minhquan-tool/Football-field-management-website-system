USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.V_ThuChiThucNhan AS
 SELECT MaTT MaGiaoDich,MaDatSan,NgayThanhToan ThoiDiem,PhuongThuc,SoTien SoTienThucNhan,N'Thu' Loai FROM dbo.ThanhToan WHERE TrangThai=N'Thành công'
 UNION ALL SELECT h.MaHT,t.MaDatSan,h.NgayXacNhan,h.PhuongThuc,-h.SoTienHoan,N'Hoàn' FROM dbo.HoanTien h
 JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE h.TrangThai=N'Đã hoàn';
GO
