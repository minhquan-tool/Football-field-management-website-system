USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_BookingRefunds(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(CASE WHEN h.TrangThai=N'Đã hoàn' THEN h.SoTienHoan ELSE 0 END),0) hoan,ISNULL(SUM(CASE WHEN h.TrangThai=N'Chờ duyệt' THEN h.SoTienHoan ELSE 0 END),0) choHoan FROM dbo.HoanTien h JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=@Booking);
GO
