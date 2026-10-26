USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[LoaiSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[LoaiSan] (
        [MaLoaiSan] varchar(10) NOT NULL,
        [TenLoaiSan] nvarchar(50) NOT NULL,
        [SoNguoi] int NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_LoaiSan] PRIMARY KEY CLUSTERED ([MaLoaiSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoaiSan_SoNguoi')
BEGIN
    ALTER TABLE dbo.[LoaiSan] ADD CONSTRAINT [CK_LoaiSan_SoNguoi] CHECK ([SoNguoi]>(0));
END
GO
