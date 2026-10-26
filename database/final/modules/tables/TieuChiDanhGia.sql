USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[TieuChiDanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[TieuChiDanhGia] (
        [MaTieuChi] varchar(10) NOT NULL,
        [TenTieuChi] nvarchar(100) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_TieuChiDanhGia] PRIMARY KEY CLUSTERED ([MaTieuChi] ASC)
    );
END
GO

