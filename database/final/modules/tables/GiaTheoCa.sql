USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[GiaTheoCa]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[GiaTheoCa] (
        [MaCa] varchar(10) NOT NULL,
        [GioBatDau] time(0) NOT NULL,
        [GioKetThuc] time(0) NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        CONSTRAINT [PK_GiaTheoCa] PRIMARY KEY CLUSTERED ([MaCa] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GiaTheoCa_Bien')
BEGIN
    ALTER TABLE dbo.[GiaTheoCa] ADD CONSTRAINT [CK_GiaTheoCa_Bien] CHECK ([MaCa]='SANG' AND [GioBatDau]='07:00:00' AND [GioKetThuc]='13:00:00' OR [MaCa]='CHIEU' AND [GioBatDau]='13:00:00' AND [GioKetThuc]='19:00:00' OR [MaCa]='TOI' AND [GioBatDau]='19:00:00' AND [GioKetThuc]='22:00:00');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GiaTheoCa_DonGia')
BEGIN
    ALTER TABLE dbo.[GiaTheoCa] ADD CONSTRAINT [CK_GiaTheoCa_DonGia] CHECK ([DonGia]>(0));
END
GO
