USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[KhachHang]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhachHang] (
        [MaKH] varchar(10) NOT NULL,
        [HoTen] nvarchar(100) NOT NULL,
        [SoDienThoai] varchar(15) NOT NULL,
        [Email] varchar(100) NULL,
        [DiaChi] nvarchar(255) NULL,
        [NgayDangKy] date CONSTRAINT [DF__KhachHang__NgayD__440B1D61] DEFAULT (getdate()) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_KhachHang] PRIMARY KEY CLUSTERED ([MaKH] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_KhachHang_SDT' AND object_id = OBJECT_ID(N'dbo.[KhachHang]'))
BEGIN
    ALTER TABLE dbo.[KhachHang] ADD CONSTRAINT [UQ_KhachHang_SDT] UNIQUE NONCLUSTERED ([SoDienThoai] ASC);
END
GO
