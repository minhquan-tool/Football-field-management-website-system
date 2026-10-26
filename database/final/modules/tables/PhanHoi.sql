USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[PhanHoi]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[PhanHoi] (
        [MaPhanHoi] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NULL,
        [NgayGui] datetime CONSTRAINT [DF__PhanHoi__NgayGui__367C1819] DEFAULT (getdate()) NOT NULL,
        [LoaiPhanHoi] nvarchar(50) NULL,
        [NoiDung] nvarchar(500) NOT NULL,
        [TrangThaiXuLy] nvarchar(20) CONSTRAINT [DF__PhanHoi__TrangTh__37703C52] DEFAULT (N'Chờ xử lý') NOT NULL,
        [MaNV] varchar(10) NULL,
        [NgayXuLy] datetime NULL,
        [KetQuaXuLy] nvarchar(500) NULL,
        CONSTRAINT [PK_PhanHoi] PRIMARY KEY CLUSTERED ([MaPhanHoi] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PhanHoi_NgayXuLy')
BEGIN
    ALTER TABLE dbo.[PhanHoi] ADD CONSTRAINT [CK_PhanHoi_NgayXuLy] CHECK ([NgayXuLy] IS NULL OR [NgayXuLy]>=[NgayGui]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PhanHoi_TrangThai')
BEGIN
    ALTER TABLE dbo.[PhanHoi] ADD CONSTRAINT [CK_PhanHoi_TrangThai] CHECK ([TrangThaiXuLy]=N'Đã xử lý' OR [TrangThaiXuLy]=N'Đang xử lý' OR [TrangThaiXuLy]=N'Chờ xử lý');
END
GO
