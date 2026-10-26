USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[HoanTien]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HoanTien] (
        [MaHT] varchar(10) NOT NULL,
        [MaTT] varchar(10) NOT NULL,
        [MaHuy] varchar(10) NOT NULL,
        [NgayHoan] datetime CONSTRAINT [DF__HoanTien__NgayHo__1EA48E88] DEFAULT (getdate()) NOT NULL,
        [SoTienHoan] decimal(18, 2) NOT NULL,
        [PhuongThuc] nvarchar(20) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__HoanTien__TrangT__1F98B2C1] DEFAULT (N'Chờ duyệt') NOT NULL,
        [MaNV] varchar(10) NULL,
        [NgayXacNhan] datetime2(7) NULL,
        [LyDo] nvarchar(255) NULL,
        CONSTRAINT [PK_HoanTien] PRIMARY KEY CLUSTERED ([MaHT] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_PhuongThuc')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_PhuongThuc] CHECK ([PhuongThuc]=N'Chuyển khoản' OR [PhuongThuc]=N'Tiền mặt');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_SoTien')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_SoTien] CHECK ([SoTienHoan]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_TrangThai')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_TrangThai] CHECK ([TrangThai]=N'Từ chối' OR [TrangThai]=N'Đã hoàn' OR [TrangThai]=N'Chờ duyệt');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HoanTien_CancellationPayment' AND object_id = OBJECT_ID('dbo.[HoanTien]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien] ([MaHuy] ASC, [MaTT] ASC);
END
GO
