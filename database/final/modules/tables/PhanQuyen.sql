USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[PhanQuyen]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[PhanQuyen] (
        [MaVaiTro] varchar(10) NOT NULL,
        [MaChucNang] varchar(10) NOT NULL,
        [Xem] bit CONSTRAINT [DF__PhanQuyen__Xem__3B75D760] DEFAULT ((0)) NOT NULL,
        [Them] bit CONSTRAINT [DF__PhanQuyen__Them__3C69FB99] DEFAULT ((0)) NOT NULL,
        [Sua] bit CONSTRAINT [DF__PhanQuyen__Sua__3D5E1FD2] DEFAULT ((0)) NOT NULL,
        [Xoa] bit CONSTRAINT [DF__PhanQuyen__Xoa__3E52440B] DEFAULT ((0)) NOT NULL,
        CONSTRAINT [PK_PhanQuyen] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC, [MaChucNang] ASC)
    );
END
GO

