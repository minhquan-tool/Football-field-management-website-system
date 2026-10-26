/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 03: HÀM NGƯỜI DÙNG ĐỊNH NGHĨA (USER-DEFINED FUNCTIONS)
   Bao gồm 6 hàm:
     - fn_TyLeHoan: Tính tỷ lệ hoàn tiền hủy sân theo mốc 10h / 2h (Phase 5.1C)
     - fn_BookingNetCash: Thực nhận theo mã đặt sân (Thu trừ Hoàn)
     - fn_BookingReceipts: Tổng tiền đã thực thu theo mã đặt sân
     - fn_BookingRefunds: Tổng tiền đã hoàn theo mã đặt sân
     - fn_KhungGioTrongTheoNgay: Tra cứu các khung giờ còn trống trong ngày của sân
     - fn_ReportDays: Bảng các ngày trong khoảng thời gian báo cáo
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- HÀM: fn_TyLeHoan
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_TyLeHoan
(
    @BatDau datetime2(7),
    @Huy datetime2(7)
)
RETURNS decimal(5,2)
AS
BEGIN
    RETURN
        CASE
            WHEN @Huy <= DATEADD(hour,-10,@BatDau) THEN 100
            WHEN @Huy <= DATEADD(hour,-2,@BatDau) THEN 50
            ELSE 0
        END;
END;
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingNetCash
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingNetCash(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTienThucNhan),0) net FROM dbo.V_ThuChiThucNhan WHERE MaDatSan=@Booking);
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingReceipts
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingReceipts(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTien),0) thu FROM dbo.ThanhToan WHERE MaDatSan=@Booking AND TrangThai=N'Thành công');
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingRefunds
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingRefunds(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(CASE WHEN h.TrangThai=N'Đã hoàn' THEN h.SoTienHoan ELSE 0 END),0) hoan,ISNULL(SUM(CASE WHEN h.TrangThai=N'Chờ duyệt' THEN h.SoTienHoan ELSE 0 END),0) choHoan FROM dbo.HoanTien h JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=@Booking);
GO

-- ------------------------------------------------------------
-- HÀM: fn_KhungGioTrongTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_KhungGioTrongTheoNgay(@Ngay date) RETURNS TABLE AS RETURN (
 SELECT s.MaSan,s.TenSan,l.TenLoaiSan,k.MaKhungGio,k.GioBatDau,k.GioKetThuc,@Ngay NgayChoi
 FROM dbo.San s JOIN dbo.LoaiSan l ON l.MaLoaiSan=s.MaLoaiSan CROSS JOIN dbo.KhungGio k
 WHERE @Ngay IS NOT NULL AND s.TrangThai<>N'Bảo trì'
 AND k.GioBatDau>='07:00' AND k.GioKetThuc<='22:00'
 AND NOT EXISTS(SELECT 1 FROM dbo.DatSan d WHERE d.MaSan=s.MaSan AND d.NgayChoi=@Ngay
 AND d.TrangThai<>N'Đã hủy' AND d.GioBatDau<k.GioKetThuc AND d.GioKetThuc>k.GioBatDau));
GO

-- ------------------------------------------------------------
-- HÀM: fn_ReportDays
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_ReportDays(@From date,@To date) RETURNS TABLE AS RETURN (WITH digits(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))x(n)) SELECT DATEADD(day,a.n+10*b.n+100*c.n,@From) Ngay FROM digits a CROSS JOIN digits b CROSS JOIN digits c WHERE @From IS NOT NULL AND @To>=@From AND DATEDIFF(day,@From,@To)<=366 AND a.n+10*b.n+100*c.n<=DATEDIFF(day,@From,@To));
GO

