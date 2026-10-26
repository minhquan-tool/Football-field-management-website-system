USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[ChiTietDanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChiTietDanhGia] (
        [MaDanhGia] varchar(10) NOT NULL,
        [MaTieuChi] varchar(10) NOT NULL,
        [Diem] int NOT NULL,
        CONSTRAINT [PK_ChiTietDanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC, [MaTieuChi] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDG_Diem')
BEGIN
    ALTER TABLE dbo.[ChiTietDanhGia] ADD CONSTRAINT [CK_CTDG_Diem] CHECK ([Diem]>=(1) AND [Diem]<=(5));
END
GO
