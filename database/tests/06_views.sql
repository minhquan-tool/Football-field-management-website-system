SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
SELECT TOP(1) * FROM dbo.[V_DoanhThuPhatSinhTheoNgay];
SELECT TOP(1) * FROM dbo.[V_DoanhThuTheoNgay];
SELECT TOP(1) * FROM dbo.[V_KhungGioTrong];
SELECT TOP(1) * FROM dbo.[V_Phase6_Revenue];
SELECT TOP(1) * FROM dbo.[V_Phase6_UsageBooking];
SELECT TOP(1) * FROM dbo.[V_ThuChiThucNhan];
SELECT TOP(1) * FROM dbo.[V_ThuTienTheoNgay];
SELECT TOP(1) * FROM dbo.[V_TyLeLapDay];
SELECT TOP(1) * FROM dbo.[V_TyLeSuDungTheoNgay];
SELECT N'PASS' AS Views;
