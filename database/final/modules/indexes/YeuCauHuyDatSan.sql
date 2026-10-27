/* FILE 08: CHỈ MỤC (INDEXES) - chạy sau 01_tables_and_constraints.sql, trước các module và dữ liệu. */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
