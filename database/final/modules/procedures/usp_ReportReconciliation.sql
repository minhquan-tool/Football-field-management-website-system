USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ReportReconciliation @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 SELECT d.MaDatSan maDatSan,s.TenSan tenSan,d.NgayChoi ngayChoi,d.TrangThai trangThai,h.MaHoaDon maHoaDon,h.DaChot daChot,d.TongTien tongBooking,h.TongTien tongHoaDon,h.DaThanhToan thuHoaDon,h.ConLai conLai,ISNULL(p.thu,0) tienThu,ISNULL(r.hoan,0) tienHoan,ISNULL(r.choHoan,0) choHoan,ISNULL(v.net,0) soThucNhan FROM DatSan d JOIN San s ON s.MaSan=d.MaSan LEFT JOIN HoaDon h ON h.MaDatSan=d.MaDatSan CROSS APPLY dbo.fn_BookingReceipts(d.MaDatSan) p CROSS APPLY dbo.fn_BookingRefunds(d.MaDatSan) r CROSS APPLY dbo.fn_BookingNetCash(d.MaDatSan) v WHERE d.NgayChoi>=@From AND d.NgayChoi<=@To AND (@Pitch='' OR d.MaSan=@Pitch) ORDER BY d.NgayChoi,d.MaDatSan;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO
