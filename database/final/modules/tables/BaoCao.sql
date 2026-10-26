USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[BaoCao]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[BaoCao] (
        [MaBaoCao] varchar(10) NOT NULL,
        [LoaiBaoCao] nvarchar(50) NOT NULL,
        [NgayLap] date CONSTRAINT [DF__BaoCao__NgayLap__4A8310C6] DEFAULT (getdate()) NOT NULL,
        [TuNgay] date NOT NULL,
        [DenNgay] date NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [NoiDung] nvarchar(max) NULL,
        CONSTRAINT [PK_BaoCao] PRIMARY KEY CLUSTERED ([MaBaoCao] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BaoCao_ThoiGian')
BEGIN
    ALTER TABLE dbo.[BaoCao] ADD CONSTRAINT [CK_BaoCao_ThoiGian] CHECK ([DenNgay]>=[TuNgay]);
END
GO
