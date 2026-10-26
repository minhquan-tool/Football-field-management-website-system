USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[XacNhanSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[XacNhanSan] (
        [MaXacNhan] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaNV] varchar(10) NOT NULL,
        [ThoiGianNhan] datetime NOT NULL,
        [ThoiGianKetThuc] datetime NULL,
        [TinhTrangSan] nvarchar(255) NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_XacNhanSan] PRIMARY KEY CLUSTERED ([MaXacNhan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_XacNhanSan_ThoiGian')
BEGIN
    ALTER TABLE dbo.[XacNhanSan] ADD CONSTRAINT [CK_XacNhanSan_ThoiGian] CHECK ([ThoiGianKetThuc] IS NULL OR [ThoiGianKetThuc]>=[ThoiGianNhan]);
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_XacNhanSan_DatSan' AND object_id = OBJECT_ID(N'dbo.[XacNhanSan]'))
BEGIN
    DROP INDEX [UQ_XacNhanSan_DatSan] ON dbo.[XacNhanSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_XacNhanSan_DatSan] ON dbo.[XacNhanSan] ([MaDatSan] ASC);
GO
