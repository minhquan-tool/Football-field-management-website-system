USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[YeuCauHuyDatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[YeuCauHuyDatSan] (
        [MaYeuCau] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaTKGui] varchar(10) NOT NULL,
        [NgayGui] datetime2(7) NOT NULL,
        [LyDo] nvarchar(255) NOT NULL,
        [TrangThai] varchar(20) CONSTRAINT [DF__YeuCauHuy__Trang__0FEC5ADD] DEFAULT ('PENDING') NOT NULL,
        [TiLeHoanUocTinh] decimal(5, 2) NOT NULL,
        [ThucThuTaiGui] decimal(18, 2) NOT NULL,
        [TienHoanUocTinh] decimal(18, 2) NOT NULL,
        [MaTKXuLy] varchar(10) NULL,
        [NgayXuLy] datetime2(7) NULL,
        [GhiChuXuLy] nvarchar(255) NULL,
        [MaHuy] varchar(10) NULL,
        [PhienBan] timestamp NOT NULL,
        CONSTRAINT [PK__YeuCauHu__CFA5DF4E87A895D0] PRIMARY KEY CLUSTERED ([MaYeuCau] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_Tien')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_Tien] CHECK ([TiLeHoanUocTinh]>=(0) AND [TiLeHoanUocTinh]<=(100) AND [ThucThuTaiGui]>=(0) AND [TienHoanUocTinh]>=(0) AND [TienHoanUocTinh]<=[ThucThuTaiGui]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_TrangThai')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_TrangThai] CHECK ([TrangThai]='REJECTED' OR [TrangThai]='APPROVED' OR [TrangThai]='PENDING');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_XuLy')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_XuLy] CHECK ([TrangThai]='PENDING' AND [MaTKXuLy] IS NULL AND [NgayXuLy] IS NULL AND [MaHuy] IS NULL OR [TrangThai]='APPROVED' AND [MaTKXuLy] IS NOT NULL AND [NgayXuLy] IS NOT NULL AND [MaHuy] IS NOT NULL OR [TrangThai]='REJECTED' AND [MaTKXuLy] IS NOT NULL AND [NgayXuLy] IS NOT NULL AND [MaHuy] IS NULL);
END
GO
