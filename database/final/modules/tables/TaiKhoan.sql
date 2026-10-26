USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[TaiKhoan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[TaiKhoan] (
        [MaTK] varchar(10) NOT NULL,
        [TenDangNhap] varchar(50) NOT NULL,
        [MatKhau] varchar(255) NOT NULL,
        [MaVaiTro] varchar(10) NOT NULL,
        [MaKH] varchar(10) NULL,
        [MaNV] varchar(10) NULL,
        [NgayTao] datetime CONSTRAINT [DF__TaiKhoan__NgayTa__4BAC3F29] DEFAULT (getdate()) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__TaiKhoan__TrangT__4CA06362] DEFAULT (N'Hoạt động') NOT NULL,
        CONSTRAINT [PK_TaiKhoan] PRIMARY KEY CLUSTERED ([MaTK] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TaiKhoan_ChuSoHuu')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] ADD CONSTRAINT [CK_TaiKhoan_ChuSoHuu] CHECK ([MaKH] IS NULL AND [MaNV] IS NOT NULL OR [MaKH] IS NOT NULL AND [MaNV] IS NULL);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TaiKhoan_TrangThai')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] ADD CONSTRAINT [CK_TaiKhoan_TrangThai] CHECK ([TrangThai]=N'Khóa' OR [TrangThai]=N'Hoạt động');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_TaiKhoan_TenDangNhap' AND object_id = OBJECT_ID(N'dbo.[TaiKhoan]'))
BEGIN
    DROP INDEX [UQ_TaiKhoan_TenDangNhap] ON dbo.[TaiKhoan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaiKhoan_TenDangNhap] ON dbo.[TaiKhoan] ([TenDangNhap] ASC);
GO
