/* FILE 08: CHỈ MỤC (INDEXES) - chạy sau 01_tables_and_constraints.sql, trước các module và dữ liệu. */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HoanTien_CancellationPayment' AND object_id = OBJECT_ID(N'dbo.[HoanTien]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien] ([MaHuy] ASC, [MaTT] ASC);
END
GO
