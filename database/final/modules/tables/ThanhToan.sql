USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[ThanhToan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ThanhToan] (
        [MaTT] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [NgayThanhToan] datetime CONSTRAINT [DF__ThanhToan__NgayT__0C85DE4D] DEFAULT (getdate()) NOT NULL,
        [SoTien] decimal(18, 2) NOT NULL,
        [PhuongThuc] nvarchar(20) NOT NULL,
        [MaGiaoDich] varchar(50) NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__ThanhToan__Trang__0D7A0286] DEFAULT (N'Chờ xử lý') NOT NULL,
        [MaNV] varchar(10) NULL,
        CONSTRAINT [PK_ThanhToan] PRIMARY KEY CLUSTERED ([MaTT] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_PhuongThuc')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_PhuongThuc] CHECK ([PhuongThuc]=N'Chuyển khoản' OR [PhuongThuc]=N'Tiền mặt');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_SoTien')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_SoTien] CHECK ([SoTien]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_TrangThai')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_TrangThai] CHECK ([TrangThai]=N'Thất bại' OR [TrangThai]=N'Thành công' OR [TrangThai]=N'Chờ xử lý');
END
GO
