SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
DECLARE @expected TABLE(name sysname,kind varchar(2));
INSERT @expected VALUES
(N'BangGia','U'),
(N'BaoCao','U'),
(N'ChiTietDanhGia','U'),
(N'ChiTietDichVu','U'),
(N'ChucNang','U'),
(N'DanhGia','U'),
(N'DatSan','U'),
(N'DichVu','U'),
(N'GiaTheoCa','U'),
(N'HoaDon','U'),
(N'HoanTien','U'),
(N'HuyDatSan','U'),
(N'KhachHang','U'),
(N'KhungGio','U'),
(N'KhuyenMai','U'),
(N'LoaiSan','U'),
(N'NhanVien','U'),
(N'NhatKyHeThong','U'),
(N'PhanHoi','U'),
(N'PhanQuyen','U'),
(N'San','U'),
(N'SaoLuu','U'),
(N'TaiKhoan','U'),
(N'ThanhToan','U'),
(N'TieuChiDanhGia','U'),
(N'VaiTro','U'),
(N'XacNhanSan','U'),
(N'YeuCauHuyDatSan','U'),
(N'V_DoanhThuPhatSinhTheoNgay','V'),
(N'V_DoanhThuTheoNgay','V'),
(N'V_KhungGioTrong','V'),
(N'V_Phase6_Revenue','V'),
(N'V_Phase6_UsageBooking','V'),
(N'V_ThuChiThucNhan','V'),
(N'V_ThuTienTheoNgay','V'),
(N'V_TyLeLapDay','V'),
(N'V_TyLeSuDungTheoNgay','V'),
(N'usp_ReportFinance','P'),
(N'usp_ReportPaymentMethods','P'),
(N'usp_ReportReconciliation','P'),
(N'usp_ReportTopServices','P'),
(N'usp_ReportUsage','P'),
(N'TRG_AuditContentImmutable','TR'),
(N'TRG_CapNhatTienDatSan','TR'),
(N'TRG_SealedInvoiceSnapshot','TR'),
(N'TRG_ServicePriceSnapshot','TR'),
(N'TRG_SuccessfulPaymentSnapshot','TR');
IF EXISTS(SELECT 1 FROM @expected e WHERE NOT EXISTS(SELECT 1 FROM sys.objects o WHERE o.name COLLATE DATABASE_DEFAULT=e.name AND o.type COLLATE DATABASE_DEFAULT=e.kind AND o.schema_id=SCHEMA_ID('dbo'))) THROW 51412,'Required object missing',1;
IF OBJECT_ID(N'dbo.fn_BookingNetCash') IS NULL THROW 51412,'Required function missing: fn_BookingNetCash',1;
IF OBJECT_ID(N'dbo.fn_BookingReceipts') IS NULL THROW 51412,'Required function missing: fn_BookingReceipts',1;
IF OBJECT_ID(N'dbo.fn_BookingRefunds') IS NULL THROW 51412,'Required function missing: fn_BookingRefunds',1;
IF OBJECT_ID(N'dbo.fn_KhungGioTrongTheoNgay') IS NULL THROW 51412,'Required function missing: fn_KhungGioTrongTheoNgay',1;
IF OBJECT_ID(N'dbo.fn_ReportDays') IS NULL THROW 51412,'Required function missing: fn_ReportDays',1;
IF OBJECT_ID(N'dbo.fn_TyLeHoan') IS NULL THROW 51412,'Required function missing: fn_TyLeHoan',1;
SELECT type_desc,COUNT(*) AS Objects FROM sys.objects WHERE is_ms_shipped=0 GROUP BY type_desc; SELECT N'PASS' AS Structure;
