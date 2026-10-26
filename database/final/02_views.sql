/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 02: CÁC KHUNG NHÌN DỮ LIỆU (VIEWS)
   Bao gồm 9 View:
     - V_DoanhThuPhatSinhTheoNgay: Doanh thu phát sinh tại thời điểm trả sân
     - V_DoanhThuTheoNgay: Tổng doanh thu các hóa đơn đã thanh toán theo ngày
     - V_KhungGioTrong: Danh sách các khung giờ trống của từng sân
     - V_Phase6_Revenue: Doanh thu theo hóa đơn, tiền sân, tiền dịch vụ, giảm giá
     - V_Phase6_UsageBooking: Thống kê số lượt và giờ sử dụng sân
     - V_ThuChiThucNhan: Dòng tiền thực nhận (Thu từ thanh toán trừ Hoàn tiền)
     - V_ThuTienTheoNgay: Tổng tiền thực thu từng ngày
     - V_TyLeLapDay: Tỷ lệ lấp đầy khung giờ theo ngày
     - V_TyLeSuDungTheoNgay: Tỷ lệ sử dụng thời gian sân thực tế theo ngày
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- VIEW: V_DoanhThuPhatSinhTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_DoanhThuPhatSinhTheoNgay AS
 SELECT Ngay,COUNT(*) SoHoaDon,SUM(TienSan) TienSan,SUM(TienDichVu) TienDichVu,
 SUM(TienGiam) TienGiam,SUM(DoanhThu) DoanhThu FROM dbo.V_Phase6_Revenue GROUP BY Ngay;
GO

-- ------------------------------------------------------------
-- VIEW: V_DoanhThuTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_DoanhThuTheoNgay AS
 SELECT Ngay,PhuongThuc,SoGiaoDich,TongTien FROM dbo.V_ThuTienTheoNgay;
GO

-- ------------------------------------------------------------
-- VIEW: V_KhungGioTrong
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_KhungGioTrong AS
 SELECT MaSan,TenSan,TenLoaiSan,MaKhungGio,GioBatDau,GioKetThuc,NgayChoi
 FROM dbo.fn_KhungGioTrongTheoNgay(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time'));
GO

-- ------------------------------------------------------------
-- VIEW: V_Phase6_Revenue
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_Phase6_Revenue AS
 SELECT d.MaDatSan,d.MaSan,CAST(x.ThoiGianKetThuc AS date) Ngay,
 COALESCE(h.TienSan,d.TienSan) TienSan,COALESCE(h.TienDichVu,d.TienDichVu) TienDichVu,
 COALESCE(h.TienGiam,d.TienGiam) TienGiam,COALESCE(h.TongTien,d.TongTien) DoanhThu
 FROM dbo.DatSan d JOIN (SELECT MaDatSan,MAX(ThoiGianKetThuc) ThoiGianKetThuc FROM dbo.XacNhanSan
 WHERE ThoiGianKetThuc IS NOT NULL GROUP BY MaDatSan) x ON x.MaDatSan=d.MaDatSan
 LEFT JOIN dbo.HoaDon h ON h.MaDatSan=d.MaDatSan
 WHERE d.TrangThai<>N'Đã hủy';
GO

-- ------------------------------------------------------------
-- VIEW: V_Phase6_UsageBooking
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_Phase6_UsageBooking AS
 SELECT d.MaDatSan,d.MaSan,d.NgayChoi,d.TrangThai,
 CASE WHEN d.TrangThai=N'Đã hủy' THEN 0 ELSE
 CASE WHEN d.GioKetThuc<=CONVERT(time,'07:00') OR d.GioBatDau>=CONVERT(time,'22:00') THEN 0 ELSE
 DATEDIFF(minute,CASE WHEN d.GioBatDau<CONVERT(time,'07:00') THEN CONVERT(time,'07:00') ELSE d.GioBatDau END,
 CASE WHEN d.GioKetThuc>CONVERT(time,'22:00') THEN CONVERT(time,'22:00') ELSE d.GioKetThuc END) END END PhutDat,
 CONVERT(int,CASE WHEN EXISTS(SELECT 1 FROM dbo.XacNhanSan x WHERE x.MaDatSan=d.MaDatSan AND x.ThoiGianKetThuc IS NOT NULL) THEN 1 ELSE 0 END) DaSuDung
 FROM dbo.DatSan d;
GO

-- ------------------------------------------------------------
-- VIEW: V_ThuChiThucNhan
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_ThuChiThucNhan AS
 SELECT MaTT MaGiaoDich,MaDatSan,NgayThanhToan ThoiDiem,PhuongThuc,SoTien SoTienThucNhan,N'Thu' Loai FROM dbo.ThanhToan WHERE TrangThai=N'Thành công'
 UNION ALL SELECT h.MaHT,t.MaDatSan,h.NgayXacNhan,h.PhuongThuc,-h.SoTienHoan,N'Hoàn' FROM dbo.HoanTien h
 JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE h.TrangThai=N'Đã hoàn';
GO

-- ------------------------------------------------------------
-- VIEW: V_ThuTienTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_ThuTienTheoNgay AS
 SELECT CAST(NgayThanhToan AS date) Ngay,PhuongThuc,COUNT(*) SoGiaoDich,SUM(SoTien) TongTien
 FROM dbo.ThanhToan WHERE TrangThai=N'Thành công' GROUP BY CAST(NgayThanhToan AS date),PhuongThuc;
GO

-- ------------------------------------------------------------
-- VIEW: V_TyLeLapDay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_TyLeLapDay AS
 SELECT NgayChoi,SoLuotDat,(SELECT COUNT(*) FROM dbo.San)*(SELECT COUNT(*) FROM dbo.KhungGio) TongKhungGio,
 TyLeLapDay,PhutDat,PhutCongSuat FROM dbo.V_TyLeSuDungTheoNgay;
GO

-- ------------------------------------------------------------
-- VIEW: V_TyLeSuDungTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_TyLeSuDungTheoNgay AS
 SELECT u.NgayChoi,COUNT(CASE WHEN u.TrangThai<>N'Đã hủy' THEN 1 END) SoLuotDat,
 SUM(CONVERT(bigint,u.PhutDat)) PhutDat,
 (SELECT COUNT_BIG(*)*900 FROM dbo.San) PhutCongSuat,
 CAST(100.0*SUM(CONVERT(bigint,u.PhutDat))/NULLIF((SELECT COUNT_BIG(*)*900 FROM dbo.San),0) AS decimal(18,2)) TyLeLapDay
 FROM dbo.V_Phase6_UsageBooking u GROUP BY u.NgayChoi;
GO

