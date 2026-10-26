USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[KhuyenMai]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhuyenMai] (
        [MaKM] varchar(10) NOT NULL,
        [TenKM] nvarchar(100) NOT NULL,
        [LoaiGiam] nvarchar(20) NOT NULL,
        [MucGiam] decimal(18, 2) NOT NULL,
        [DieuKien] nvarchar(255) NULL,
        [NgayBatDau] date NOT NULL,
        [NgayKetThuc] date NOT NULL,
        [TrangThai] bit CONSTRAINT [DF__KhuyenMai__Trang__66603565] DEFAULT ((1)) NOT NULL,
        CONSTRAINT [PK_KhuyenMai] PRIMARY KEY CLUSTERED ([MaKM] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_LoaiGiam')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_LoaiGiam] CHECK ([LoaiGiam]=N'Số tiền' OR [LoaiGiam]=N'Phần trăm');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_MucGiam')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_MucGiam] CHECK ([MucGiam]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_ThoiGian')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_ThoiGian] CHECK ([NgayKetThuc]>=[NgayBatDau]);
END
GO
