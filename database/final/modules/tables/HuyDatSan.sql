USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[HuyDatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HuyDatSan] (
        [MaHuy] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [NgayHuy] datetime2(7) CONSTRAINT [DF__HuyDatSan__NgayH__160F4887] DEFAULT (getdate()) NOT NULL,
        [LyDo] nvarchar(255) NULL,
        [NguoiHuy] nvarchar(20) NOT NULL,
        [TiLeHoan] decimal(5, 2) CONSTRAINT [DF__HuyDatSan__TiLeH__17036CC0] DEFAULT ((0)) NOT NULL,
        [SoTienHoan] decimal(18, 2) CONSTRAINT [DF__HuyDatSan__SoTie__17F790F9] DEFAULT ((0)) NOT NULL,
        [SoTienThucThuSnapshot] decimal(18, 2) NULL,
        CONSTRAINT [PK_HuyDatSan] PRIMARY KEY CLUSTERED ([MaHuy] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Huy_ThucThu')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_Huy_ThucThu] CHECK ([SoTienThucThuSnapshot] IS NULL OR [SoTienThucThuSnapshot]>=(0) AND [SoTienHoan]<=round(([SoTienThucThuSnapshot]*[TiLeHoan])/(100),(2)));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_NguoiHuy')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_NguoiHuy] CHECK ([NguoiHuy]=N'Nhân viên' OR [NguoiHuy]=N'Khách hàng');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_SoTien')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_SoTien] CHECK ([SoTienHoan]>=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_TiLeHoan')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_TiLeHoan] CHECK ([TiLeHoan]>=(0) AND [TiLeHoan]<=(100));
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_HuyDatSan_DatSan' AND object_id = OBJECT_ID(N'dbo.[HuyDatSan]'))
BEGIN
    DROP INDEX [UQ_HuyDatSan_DatSan] ON dbo.[HuyDatSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_HuyDatSan_DatSan] ON dbo.[HuyDatSan] ([MaDatSan] ASC);
GO
