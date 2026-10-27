/* FILE 08: CHỈ MỤC (INDEXES) - chạy sau 01_tables_and_constraints.sql, trước các module và dữ liệu. */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
