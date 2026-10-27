/* FILE 08: CHỈ MỤC (INDEXES) - chạy sau 01_tables_and_constraints.sql, trước các module và dữ liệu. */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO



IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DatSan_SanNgayBatDau' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [GioBatDau] ASC) INCLUDE ([GioKetThuc], [TrangThai]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DatSan_KhongTrungLich' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [MaKhungGio] ASC) WHERE ([TrangThai]<>N'Đã hủy' AND [MaKhungGio] IS NOT NULL);
END
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CTDV_BookingSku' AND object_id = OBJECT_ID(N'dbo.[ChiTietDichVu]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CTDV_BookingSku] ON dbo.[ChiTietDichVu] ([MaDatSan] ASC, [MaDV] ASC);
END
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ThanhToan_BookingState' AND object_id = OBJECT_ID(N'dbo.[ThanhToan]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ThanhToan_BookingState] ON dbo.[ThanhToan] ([MaDatSan] ASC, [TrangThai] ASC) INCLUDE ([SoTien]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_ThanhToan_Idempotency' AND object_id = OBJECT_ID(N'dbo.[ThanhToan]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_ThanhToan_Idempotency] ON dbo.[ThanhToan] ([MaGiaoDich] ASC) WHERE ([MaGiaoDich] IS NOT NULL);
END
GO



IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HoanTien_CancellationPayment' AND object_id = OBJECT_ID(N'dbo.[HoanTien]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien] ([MaHuy] ASC, [MaTT] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_YeuCauHuy_Customer' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_YeuCauHuy_Customer] ON dbo.[YeuCauHuyDatSan] ([MaTKGui] ASC, [NgayGui] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_YeuCauHuy_Queue' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_YeuCauHuy_Queue] ON dbo.[YeuCauHuyDatSan] ([TrangThai] ASC, [NgayGui] ASC) INCLUDE ([MaDatSan], [MaTKGui]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_YeuCauHuy_Pending' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_YeuCauHuy_Pending] ON dbo.[YeuCauHuyDatSan] ([MaDatSan] ASC) WHERE ([TrangThai]='PENDING');
END
GO
