USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[DanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DanhGia] (
        [MaDanhGia] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaSan] varchar(10) NOT NULL,
        [NgayDanhGia] date CONSTRAINT [DF__DanhGia__NgayDan__2B0A656D] DEFAULT (getdate()) NOT NULL,
        [NoiDung] nvarchar(500) NULL,
        [DiemTrungBinh] decimal(3, 2) NULL,
        CONSTRAINT [PK_DanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DanhGia_Diem')
BEGIN
    ALTER TABLE dbo.[DanhGia] ADD CONSTRAINT [CK_DanhGia_Diem] CHECK ([DiemTrungBinh] IS NULL OR [DiemTrungBinh]>=(1) AND [DiemTrungBinh]<=(5));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_DanhGia_DatSan' AND object_id = OBJECT_ID('dbo.[DanhGia]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_DanhGia_DatSan] ON dbo.[DanhGia] ([MaDatSan] ASC);
END
GO
