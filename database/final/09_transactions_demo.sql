/* MODULE 09 - TRANSACTION DEMO (run separately in SSMS).
   Reused from database/report-demo/02_Fixture_and_Five_Transactions.sql.
   NOT part of 00_full_database.sql or the database installation sequence.
   Select an existing disposable fixture DB with dev/test markers first.
   Run report-demo/01_Preflight.sql before this file; set EnableDemo=1 below.
   Never add fixture markers to an operating database to bypass the guards.

   Scenarios: 1 booking; 2 service insert/update; 3 checkout + sealed invoice;
              4 payment; 5 cancellation + refund.
   Each scenario runs once with COMMIT and once with an injected error/ROLLBACK.
   Expected: five COMMIT_PASS and five ROLLBACK_PASS results.
   COMMIT retains synthetic records. Re-running creates additional records.
   This is a teaching demonstration, not a replacement for backend validation,
   payment idempotency, authorization, or concurrent API booking tests.
   Concurrent lock demonstration remains in report-demo/70A and 70B.
*/
-- SSMS thường, KHÔNG cần SQLCMD Mode. Chạy CẢ FILE, không bỏ đoạn chặn môi trường.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @EnableDemo bit=0; -- Chủ động đổi thành 1 CHỈ trên bản sao demo.
IF @EnableDemo<>1 THROW 51200,'Opt-in required: set EnableDemo=1 on a disposable copy',1;
IF DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test'))
 THROW 51201,'Disposable fixture name AND test/dev markers required. Never mark the operating DB.',1;
IF @@TRANCOUNT<>0 THROW 51202,'Close existing transaction before demonstration',1;
SELECT @@SERVERNAME AS ServerName,DB_NAME() AS DemoDatabase;
/* Executable T-SQL teaching scenarios on a disposable DEV/test database ONLY.
   Five business units, each exercised with COMMIT and forced failure/ROLLBACK.
   Successful synthetic records are retained for inspection, never cleaned from a live DB.
   This demonstrates transactions, not an alternative public financial API. */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF DB_NAME() NOT LIKE 'QuanLySanBong[_]Fixtures[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1)
 THROW 51049,'Disposable fixture required',1;
DECLARE @case int=1,@fail int,@id varchar(10),@pitch varchar(10),@payment varchar(10),@cancel varchar(10),@refund varchar(10),@invoice varchar(10),@audit varchar(10),@visit varchar(10);
DECLARE @customer varchar(10)=(SELECT TOP(1) MaKH FROM dbo.KhachHang ORDER BY MaKH),@actor varchar(10)=(SELECT TOP(1) MaTK FROM dbo.TaiKhoan WHERE MaVaiTro='VT04' ORDER BY MaTK),@employee varchar(10)=(SELECT TOP(1) MaNV FROM dbo.NhanVien ORDER BY MaNV),@type varchar(10)=(SELECT TOP(1) MaLoaiSan FROM dbo.LoaiSan ORDER BY MaLoaiSan),@day date=DATEADD(day,30,CONVERT(date,GETDATE())),@price decimal(18,2),@sku varchar(10),@servicePrice decimal(18,2);
SELECT TOP(1) @price=DonGia FROM dbo.GiaTheoCa ORDER BY GioBatDau;
SELECT TOP(1) @sku=MaDV,@servicePrice=DonGia FROM dbo.DichVu WHERE TrangThai=1 ORDER BY MaDV;
IF @price IS NULL OR @sku IS NULL OR @actor IS NULL OR @customer IS NULL THROW 51048,'Missing reviewed catalog/test identities',1;
WHILE @case<=5
BEGIN
 SET @fail=0;
 WHILE @fail<=1
 BEGIN
  SET @id='RT'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @pitch='RS'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @payment='RP'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @cancel='RC'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @refund='RR'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @invoice='RH'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @audit='RA'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  SET @visit='RV'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),8);
  BEGIN TRY
   BEGIN TRANSACTION;
   INSERT dbo.San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(@pitch,N'Rubric transaction fixture',@type,N'Trống',N'Isolated synthetic transaction demonstration');
   -- Same San -> DatSan lock order as the application, before any dependent writes.
   SELECT MaSan FROM dbo.San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@pitch;
   IF EXISTS(SELECT 1 FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@pitch AND NgayChoi=@day AND TrangThai<>N'Đã hủy' AND GioBatDau<'09:00' AND GioKetThuc>'08:00') THROW 51047,'Overlapping booking',1;
   INSERT dbo.DatSan(MaDatSan,MaKH,MaSan,MaKhungGio,NgayChoi,DonGia,TienDichVu,TienGiam,MaNV,TrangThai,GhiChu,GioBatDau,GioKetThuc,CheDoGia,HinhThucDat)
   VALUES(@id,@customer,@pitch,NULL,@day,@price,0,0,@employee,N'Đã xác nhận',N'Rubric transaction fixture','08:00','09:00','GIA_GIO','TAI_QUAY');
   SELECT MaDatSan FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK) WHERE MaDatSan=@id;
   IF @case=2
   BEGIN
    INSERT dbo.ChiTietDichVu(MaDatSan,MaDV,SoLuong,MaNV,Nguon,QuyCach,DonGiaDonViSnapshot) VALUES(@id,@sku,1,@employee,'DAT_TRUOC','DON_VI',@servicePrice);
    UPDATE dbo.ChiTietDichVu SET SoLuong=2 WHERE MaDatSan=@id;
    IF NOT EXISTS(SELECT 1 FROM dbo.DatSan WHERE MaDatSan=@id AND TienDichVu=2*@servicePrice AND TongTien=@price+2*@servicePrice) THROW 51046,'Service trigger did not synchronize totals',1;
   END;
   IF @case=3
   BEGIN
    INSERT dbo.XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan,ThoiGianKetThuc) VALUES(@visit,@id,@employee,DATEADD(hour,8,CAST(@day AS datetime2)),DATEADD(hour,9,CAST(@day AS datetime2)));
    UPDATE dbo.DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=@id;
    INSERT dbo.HoaDon(MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,DaChot) VALUES(@invoice,@id,@actor,@price,0,0,1);
   END;
   IF @case IN(4,5)
   BEGIN
    INSERT dbo.HoaDon(MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam) VALUES(@invoice,@id,@actor,@price,0,0);
    INSERT dbo.ThanhToan(MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,MaNV) VALUES(@payment,@id,@price,N'Tiền mặt','rubric-'+@payment,N'Thành công',@employee);
    UPDATE dbo.HoaDon SET DaThanhToan=@price,TrangThai='DA_THANH_TOAN' WHERE MaDatSan=@id;
   END;
   IF @case=5
   BEGIN
    DECLARE @rate decimal(5,2)=dbo.fn_TyLeHoan(DATEADD(hour,8,CAST(@day AS datetime2)),SYSDATETIME());
    INSERT dbo.HuyDatSan(MaHuy,MaDatSan,LyDo,NguoiHuy,TiLeHoan,SoTienHoan,SoTienThucThuSnapshot) VALUES(@cancel,@id,N'Rubric rollback demonstration',N'Nhân viên',@rate,@price*@rate/100,@price);
    INSERT dbo.HoanTien(MaHT,MaTT,MaHuy,SoTienHoan,PhuongThuc,TrangThai,MaNV,NgayXacNhan) VALUES(@refund,@payment,@cancel,@price*@rate/100,N'Tiền mặt',N'Đã hoàn',@employee,SYSDATETIME());
    UPDATE dbo.DatSan SET TrangThai=N'Đã hủy' WHERE MaDatSan=@id;
    UPDATE dbo.HoaDon SET TrangThai='DA_HUY' WHERE MaDatSan=@id;
    IF EXISTS(SELECT 1 FROM dbo.fn_BookingNetCash(@id) WHERE net<>0) THROW 51045,'Refund reconciliation mismatch',1;
   END;
   INSERT dbo.NhatKyHeThong(MaNhatKy,MaTK,ChucNang,ThaoTac,DoiTuong,NoiDungThayDoi,KetQua) VALUES(@audit,@actor,N'Rubric fixture',N'Thêm',@id,CONCAT(N'Transaction case ',@case),1);
   IF @fail=1 THROW 51050,'EXPECTED injected failure after all related writes',1;
   COMMIT;
   IF NOT EXISTS(SELECT 1 FROM dbo.DatSan WHERE MaDatSan=@id) OR NOT EXISTS(SELECT 1 FROM dbo.NhatKyHeThong WHERE MaNhatKy=@audit) THROW 51044,'Commit not observable',1;
   SELECT @case scenario,'COMMIT_PASS' result,@id booking,@pitch pitch;
  END TRY
  BEGIN CATCH
   DECLARE @error int=ERROR_NUMBER();
   IF @@TRANCOUNT>0 ROLLBACK;
   IF @fail=0 OR @error<>51050 THROW;
   IF EXISTS(SELECT 1 FROM dbo.San WHERE MaSan=@pitch) OR EXISTS(SELECT 1 FROM dbo.DatSan WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.HoaDon WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.ThanhToan WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.HuyDatSan WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.HoanTien WHERE MaHT=@refund) OR EXISTS(SELECT 1 FROM dbo.XacNhanSan WHERE MaDatSan=@id) OR EXISTS(SELECT 1 FROM dbo.NhatKyHeThong WHERE MaNhatKy=@audit)
    THROW 51043,'Partial data survived rollback',1;
   SELECT @case scenario,'ROLLBACK_PASS' result,@id booking,@pitch pitch;
  END CATCH;
  SET @fail+=1;
 END;
 SET @case+=1;
END;

