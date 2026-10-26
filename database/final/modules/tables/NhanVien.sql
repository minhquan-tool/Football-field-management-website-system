USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[NhanVien]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[NhanVien] (
        [MaNV] varchar(10) NOT NULL,
        [HoTen] nvarchar(100) NOT NULL,
        [SoDienThoai] varchar(15) NULL,
        [Email] varchar(100) NULL,
        [ChucVu] nvarchar(50) NULL,
        [BoPhan] nvarchar(50) NULL,
        [NgayVaoLam] date NULL,
        [TrangThai] bit CONSTRAINT [DF__NhanVien__TrangT__46E78A0C] DEFAULT ((1)) NOT NULL,
        CONSTRAINT [PK_NhanVien] PRIMARY KEY CLUSTERED ([MaNV] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_NhanVien_BoPhan')
BEGIN
    ALTER TABLE dbo.[NhanVien] ADD CONSTRAINT [CK_NhanVien_BoPhan] CHECK ([BoPhan]=N'Quản trị hệ thống' OR [BoPhan]=N'Kế toán' OR [BoPhan]=N'Nhân viên sân bóng');
END
GO
