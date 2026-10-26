USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[VaiTro]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[VaiTro] (
        [MaVaiTro] varchar(10) NOT NULL,
        [TenVaiTro] nvarchar(50) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_VaiTro] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC)
    );
END
GO

