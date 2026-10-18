SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51100,'Reviewed DEV/test database required',1;
BEGIN TRY
BEGIN TRANSACTION;

EXEC(N'
/* ============================================================
   8. MỘT SỐ TRUY VẤN / VIEW MINH HỌA
   ============================================================ */

-- 8.1 Danh sách khung giờ còn trống của một ngày (KH_QĐ 1)
ALTER VIEW V_KhungGioTrong AS
SELECT  s.MaSan, s.TenSan, ls.TenLoaiSan, kg.MaKhungGio, kg.GioBatDau, kg.GioKetThuc
FROM    San s
        JOIN LoaiSan ls  ON ls.MaLoaiSan = s.MaLoaiSan
        CROSS JOIN KhungGio kg
WHERE   s.TrangThai <> N''Bảo trì'';
');
EXEC sys.sp_dropextendedproperty @name=N'SanBongContract',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_KhungGioTrong';
EXEC(N'
-- 8.2 Doanh thu theo ngày và phương thức thanh toán (KT_BM 2)
ALTER VIEW V_DoanhThuTheoNgay AS
SELECT  CAST(tt.NgayThanhToan AS DATE) AS Ngay,
        tt.PhuongThuc,
        COUNT(*)          AS SoGiaoDich,
        SUM(tt.SoTien)    AS TongTien
FROM    ThanhToan tt
WHERE   tt.TrangThai = N''Thành công''
GROUP BY CAST(tt.NgayThanhToan AS DATE), tt.PhuongThuc;
');
EXEC sys.sp_dropextendedproperty @name=N'SanBongContract',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_DoanhThuTheoNgay';
EXEC(N'
-- 8.3 Tỷ lệ lấp đầy sân theo ngày
ALTER VIEW V_TyLeLapDay AS
SELECT  d.NgayChoi,
        COUNT(*) AS SoLuotDat,
        (SELECT COUNT(*) FROM San WHERE TrangThai <> N''Bảo trì'')
            * (SELECT COUNT(*) FROM KhungGio) AS TongKhungGio,
        CAST(100.0 * COUNT(*) /
            NULLIF((SELECT COUNT(*) FROM San WHERE TrangThai <> N''Bảo trì'')
                 * (SELECT COUNT(*) FROM KhungGio), 0) AS DECIMAL(5,2)) AS TyLeLapDay
FROM    DatSan d
WHERE   d.TrangThai <> N''Đã hủy''
GROUP BY d.NgayChoi;
');
EXEC sys.sp_dropextendedproperty @name=N'SanBongContract',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'VIEW',@level1name=N'V_TyLeLapDay';
DROP VIEW dbo.V_TyLeSuDungTheoNgay;
DROP VIEW dbo.V_DoanhThuPhatSinhTheoNgay;
DROP VIEW dbo.V_ThuTienTheoNgay;
DROP FUNCTION dbo.fn_KhungGioTrongTheoNgay;
COMMIT;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
