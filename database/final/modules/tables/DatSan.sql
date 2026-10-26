USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[DatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DatSan] (
        [MaDatSan] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaSan] varchar(10) NOT NULL,
        [MaKhungGio] varchar(10) NULL,
        [NgayChoi] date NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [TienDichVu] decimal(18, 2) CONSTRAINT [DF__DatSan__TienDich__6D0D32F4] DEFAULT ((0)) NOT NULL,
        [MaKM] varchar(10) NULL,
        [TienGiam] decimal(18, 2) CONSTRAINT [DF__DatSan__TienGiam__6E01572D] DEFAULT ((0)) NOT NULL,
        [NgayDat] datetime CONSTRAINT [DF__DatSan__NgayDat__6FE99F9F] DEFAULT (getdate()) NOT NULL,
        [MaNV] varchar(10) NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__DatSan__TrangTha__70DDC3D8] DEFAULT (N'Chờ xác nhận') NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        [GioBatDau] time(0) NOT NULL,
        [GioKetThuc] time(0) NOT NULL,
        [CheDoGia] varchar(12) CONSTRAINT [DF_DatSan_CheDoGia] DEFAULT ('GIA_KHUNG') NOT NULL,
        [HinhThucDat] varchar(12) CONSTRAINT [DF_DatSan_HinhThucDat] DEFAULT ('KHONG_RO') NOT NULL,
        [ThoiLuongLegacySnapshot] decimal(4, 2) NULL,
        [TienSanLegacySnapshot] decimal(18, 2) NULL,
        [ThoiLuong] AS (CONVERT([decimal](4,2),case when [CheDoGia]='GIA_KHUNG' then [ThoiLuongLegacySnapshot] else round(datediff(minute,[GioBatDau],[GioKetThuc])/(60.0),(2)) end)) PERSISTED,
        [TienSan] AS (CONVERT([decimal](18,2),case when [CheDoGia]='GIA_KHUNG' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)) PERSISTED,
        [TongTien] AS (CONVERT([decimal](18,2),(CONVERT([decimal](18,2),case when [CheDoGia]='GIA_KHUNG' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)+[TienDichVu])-[TienGiam])) PERSISTED,
        CONSTRAINT [PK_DatSan] PRIMARY KEY CLUSTERED ([MaDatSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_CheDoGia')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_CheDoGia] CHECK ([CheDoGia]='GIA_GIO' OR [CheDoGia]='GIA_KHUNG');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_GioMoi')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_GioMoi] CHECK ([CheDoGia]='GIA_KHUNG' OR [GioBatDau]>='07:00:00' AND [GioKetThuc]<='22:00:00' AND datepart(second,[GioBatDau])=(0) AND datepart(second,[GioKetThuc])=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_HinhThucDat')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_HinhThucDat] CHECK ([HinhThucDat]='TAI_QUAY' OR [HinhThucDat]='TRUC_TUYEN' OR [HinhThucDat]='KHONG_RO');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_KhoangGio')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_KhoangGio] CHECK ([GioKetThuc]>[GioBatDau]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_LegacySnapshots')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_LegacySnapshots] CHECK ([CheDoGia]='GIA_KHUNG' AND [ThoiLuongLegacySnapshot] IS NOT NULL AND [ThoiLuongLegacySnapshot]>(0) AND [TienSanLegacySnapshot] IS NOT NULL AND [TienSanLegacySnapshot]>=(0) OR [CheDoGia]='GIA_GIO' AND [ThoiLuongLegacySnapshot] IS NULL AND [TienSanLegacySnapshot] IS NULL);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_ThoiLuong')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_ThoiLuong] CHECK ([ThoiLuong] IS NOT NULL AND [ThoiLuong]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_Tien')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_Tien] CHECK ([DonGia]>(0) AND [TienSan] IS NOT NULL AND [TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TongTien]>=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_TrangThai')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_TrangThai] CHECK ([TrangThai]=N'Đã hủy' OR [TrangThai]=N'Đã sử dụng' OR [TrangThai]=N'Đã xác nhận' OR [TrangThai]=N'Chờ xác nhận');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DatSan_SanNgayBatDau' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    DROP INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan];
END
GO
CREATE NONCLUSTERED INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [GioBatDau] ASC) INCLUDE ([GioKetThuc], [TrangThai]);
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DatSan_KhongTrungLich' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    DROP INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [MaKhungGio] ASC) WHERE ([TrangThai]<>N'Đã hủy' AND [MaKhungGio] IS NOT NULL);
GO
