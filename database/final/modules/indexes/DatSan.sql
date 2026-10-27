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
