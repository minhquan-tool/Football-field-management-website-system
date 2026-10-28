SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.DatSan') AND name=N'IX_DatSan_SanNgayBatDau' AND is_disabled=0) THROW 51422,'Index missing/disabled: IX_DatSan_SanNgayBatDau',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.DatSan') AND name=N'UX_DatSan_KhongTrungLich' AND is_disabled=0) THROW 51422,'Index missing/disabled: UX_DatSan_KhongTrungLich',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ChiTietDichVu') AND name=N'IX_CTDV_BookingSku' AND is_disabled=0) THROW 51422,'Index missing/disabled: IX_CTDV_BookingSku',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ThanhToan') AND name=N'IX_ThanhToan_BookingState' AND is_disabled=0) THROW 51422,'Index missing/disabled: IX_ThanhToan_BookingState',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ThanhToan') AND name=N'UX_ThanhToan_Idempotency' AND is_disabled=0) THROW 51422,'Index missing/disabled: UX_ThanhToan_Idempotency',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.HoanTien') AND name=N'UX_HoanTien_CancellationPayment' AND is_disabled=0) THROW 51422,'Index missing/disabled: UX_HoanTien_CancellationPayment',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.YeuCauHuyDatSan') AND name=N'IX_YeuCauHuy_Customer' AND is_disabled=0) THROW 51422,'Index missing/disabled: IX_YeuCauHuy_Customer',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.YeuCauHuyDatSan') AND name=N'IX_YeuCauHuy_Queue' AND is_disabled=0) THROW 51422,'Index missing/disabled: IX_YeuCauHuy_Queue',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.YeuCauHuyDatSan') AND name=N'UX_YeuCauHuy_Pending' AND is_disabled=0) THROW 51422,'Index missing/disabled: UX_YeuCauHuy_Pending',1;
SELECT OBJECT_NAME(object_id) AS TableName,name,is_unique FROM sys.indexes WHERE object_id IN(SELECT object_id FROM sys.tables) AND index_id>0; SELECT N'PASS' AS Indexes;
