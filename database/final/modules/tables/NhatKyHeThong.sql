USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[NhatKyHeThong]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[NhatKyHeThong] (
        [MaNhatKy] varchar(15) NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [ThoiGian] datetime CONSTRAINT [DF__NhatKyHeT__ThoiG__3F115E1A] DEFAULT (getdate()) NOT NULL,
        [ChucNang] nvarchar(100) NULL,
        [ThaoTac] nvarchar(20) NOT NULL,
        [DoiTuong] nvarchar(100) NULL,
        [NoiDungThayDoi] nvarchar(500) NULL,
        [KetQua] bit CONSTRAINT [DF__NhatKyHeT__KetQu__40058253] DEFAULT ((1)) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_NhatKyHeThong] PRIMARY KEY CLUSTERED ([MaNhatKy] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_NhatKy_ThaoTac')
BEGIN
    ALTER TABLE dbo.[NhatKyHeThong] ADD CONSTRAINT [CK_NhatKy_ThaoTac] CHECK ([ThaoTac]=N'Đăng xuất' OR [ThaoTac]=N'Đăng nhập' OR [ThaoTac]=N'Xóa' OR [ThaoTac]=N'Sửa' OR [ThaoTac]=N'Thêm');
END
GO
