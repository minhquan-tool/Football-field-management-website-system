USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_BookingReceipts(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTien),0) thu FROM dbo.ThanhToan WHERE MaDatSan=@Booking AND TrangThai=N'Thành công');
GO
