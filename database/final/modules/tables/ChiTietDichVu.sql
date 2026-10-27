USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[ChiTietDichVu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChiTietDichVu] (
        [MaDatSan] varchar(10) NOT NULL,
        [MaDV] varchar(10) NOT NULL,
        [SoLuong] int NOT NULL,
        [NgayGhiNhan] datetime CONSTRAINT [DF__ChiTietDi__NgayG__7F2BE32F] DEFAULT (getdate()) NOT NULL,
        [MaNV] varchar(10) NULL,
        [MaChiTiet] bigint IDENTITY(1,1) NOT NULL,
        [Nguon] varchar(12) CONSTRAINT [DF_CTDV_Nguon] DEFAULT ('LEGACY') NOT NULL,
        [QuyCach] varchar(10) CONSTRAINT [DF_CTDV_QuyCach] DEFAULT ('DON_VI') NOT NULL,
        [DonGiaDonViSnapshot] decimal(18, 2) NULL,
        [DonGiaLegacySnapshot] decimal(18, 2) NULL,
        [SoDonViMoiQuyCach] AS (CONVERT([int],case when [QuyCach]='LOC_6' then (6) else (1) end)) PERSISTED,
        [DonGia] AS (CONVERT([decimal](18,2),case when [Nguon]='LEGACY' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]='LOC_6' then (6) else (1) end)*case when [QuyCach]='LOC_6' then (0.97) else (1) end,(2)) end)) PERSISTED,
        [ThanhTien] AS ([SoLuong]*CONVERT([decimal](18,2),case when [Nguon]='LEGACY' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]='LOC_6' then (6) else (1) end)*case when [QuyCach]='LOC_6' then (0.97) else (1) end,(2)) end)) PERSISTED,
        CONSTRAINT [PK_ChiTietDichVu] PRIMARY KEY CLUSTERED ([MaChiTiet] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_DonGia')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_DonGia] CHECK ([DonGia] IS NOT NULL AND [DonGia]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_Nguon')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_Nguon] CHECK ([Nguon]='PHAT_SINH' OR [Nguon]='DAT_TRUOC' OR [Nguon]='LEGACY');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_QuyCach')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_QuyCach] CHECK ([QuyCach]='LOC_6' OR [QuyCach]='DON_VI');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_Snapshot')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_Snapshot] CHECK ([Nguon]='LEGACY' AND [DonGiaLegacySnapshot] IS NOT NULL AND [DonGiaLegacySnapshot]>(0) AND ([DonGiaDonViSnapshot] IS NULL OR [DonGiaDonViSnapshot]>(0)) OR [Nguon]<>'LEGACY' AND [DonGiaLegacySnapshot] IS NULL AND [DonGiaDonViSnapshot] IS NOT NULL AND [DonGiaDonViSnapshot]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_SoLuong')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_SoLuong] CHECK ([SoLuong]>(0));
END
GO
