USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[ChucNang]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChucNang] (
        [MaChucNang] varchar(10) NOT NULL,
        [TenChucNang] nvarchar(100) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_ChucNang] PRIMARY KEY CLUSTERED ([MaChucNang] ASC)
    );
END
GO

