USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[KhungGio]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhungGio] (
        [MaKhungGio] varchar(10) NOT NULL,
        [GioBatDau] time(7) NOT NULL,
        [GioKetThuc] time(7) NOT NULL,
        [ThoiLuong] decimal(4, 2) NOT NULL,
        CONSTRAINT [PK_KhungGio] PRIMARY KEY CLUSTERED ([MaKhungGio] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhungGio_Gio')
BEGIN
    ALTER TABLE dbo.[KhungGio] ADD CONSTRAINT [CK_KhungGio_Gio] CHECK ([GioKetThuc]>[GioBatDau]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhungGio_ThoiLuong')
BEGIN
    ALTER TABLE dbo.[KhungGio] ADD CONSTRAINT [CK_KhungGio_ThoiLuong] CHECK ([ThoiLuong]>(0));
END
GO
