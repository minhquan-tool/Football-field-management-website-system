/* FILE 08: CHỈ MỤC (INDEXES) - chạy sau 01_tables_and_constraints.sql, trước các module và dữ liệu. */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CTDV_BookingSku' AND object_id = OBJECT_ID(N'dbo.[ChiTietDichVu]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CTDV_BookingSku] ON dbo.[ChiTietDichVu] ([MaDatSan] ASC, [MaDV] ASC);
END
GO
