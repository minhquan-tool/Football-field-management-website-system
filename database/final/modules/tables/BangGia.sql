USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[BangGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[BangGia] (
        [MaBangGia] varchar(10) NOT NULL,
        [MaLoaiSan] varchar(10) NOT NULL,
        [MaKhungGio] varchar(10) NOT NULL,
        [LoaiNgay] nvarchar(20) NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [NgayHieuLuc] date NOT NULL,
        [NgayHetHieuLuc] date NULL,
        CONSTRAINT [PK_BangGia] PRIMARY KEY CLUSTERED ([MaBangGia] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_DonGia')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_DonGia] CHECK ([DonGia]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_HieuLuc')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_HieuLuc] CHECK ([NgayHetHieuLuc] IS NULL OR [NgayHetHieuLuc]>=[NgayHieuLuc]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_LoaiNgay')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_LoaiNgay] CHECK ([LoaiNgay]=N'Ngày lễ' OR [LoaiNgay]=N'Cuối tuần' OR [LoaiNgay]=N'Ngày thường');
END
GO
