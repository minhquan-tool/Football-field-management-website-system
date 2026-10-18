-- Phase 6 additive views only; preserve all existing views and rows.
SET XACT_ABORT ON;
IF DB_NAME()<>'QuanLySanBong' THROW 50630,'Wrong database',1;
IF OBJECT_ID('dbo.V_Phase6_UsageBooking') IS NOT NULL OR OBJECT_ID('dbo.V_Phase6_Revenue') IS NOT NULL
 THROW 50631,'Already migrated; inspect first',1;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC(N'CREATE VIEW dbo.V_Phase6_UsageBooking AS
 SELECT d.MaDatSan,d.MaSan,d.NgayChoi,d.TrangThai,
 CASE WHEN d.TrangThai=N''Đã hủy'' THEN 0 ELSE
 CASE WHEN d.GioKetThuc<=CONVERT(time,''07:00'') OR d.GioBatDau>=CONVERT(time,''22:00'') THEN 0 ELSE
 DATEDIFF(minute,CASE WHEN d.GioBatDau<CONVERT(time,''07:00'') THEN CONVERT(time,''07:00'') ELSE d.GioBatDau END,
 CASE WHEN d.GioKetThuc>CONVERT(time,''22:00'') THEN CONVERT(time,''22:00'') ELSE d.GioKetThuc END) END END PhutDat,
 CONVERT(int,CASE WHEN EXISTS(SELECT 1 FROM dbo.XacNhanSan x WHERE x.MaDatSan=d.MaDatSan AND x.ThoiGianKetThuc IS NOT NULL) THEN 1 ELSE 0 END) DaSuDung
 FROM dbo.DatSan d;');
 EXEC(N'CREATE VIEW dbo.V_Phase6_Revenue AS
 SELECT d.MaDatSan,d.MaSan,CAST(x.ThoiGianKetThuc AS date) Ngay,
 COALESCE(h.TienSan,d.TienSan) TienSan,COALESCE(h.TienDichVu,d.TienDichVu) TienDichVu,
 COALESCE(h.TienGiam,d.TienGiam) TienGiam,COALESCE(h.TongTien,d.TongTien) DoanhThu
 FROM dbo.DatSan d JOIN (SELECT MaDatSan,MAX(ThoiGianKetThuc) ThoiGianKetThuc FROM dbo.XacNhanSan
 WHERE ThoiGianKetThuc IS NOT NULL GROUP BY MaDatSan) x ON x.MaDatSan=d.MaDatSan
 LEFT JOIN dbo.HoaDon h ON h.MaDatSan=d.MaDatSan
 WHERE d.TrangThai<>N''Đã hủy'';');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
