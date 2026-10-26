USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[DichVu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DichVu] (
        [MaDV] varchar(10) NOT NULL,
        [TenDV] nvarchar(100) NOT NULL,
        [DonViTinh] nvarchar(20) NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [TrangThai] bit CONSTRAINT [DF__DichVu__TrangTha__7B5B524B] DEFAULT ((1)) NOT NULL,
        [HoTroLoc] bit CONSTRAINT [DF_DichVu_HoTroLoc] DEFAULT ((0)) NOT NULL,
        CONSTRAINT [PK_DichVu] PRIMARY KEY CLUSTERED ([MaDV] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DichVu_DonGia')
BEGIN
    ALTER TABLE dbo.[DichVu] ADD CONSTRAINT [CK_DichVu_DonGia] CHECK ([DonGia]>(0));
END
GO
