USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[San]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[San] (
        [MaSan] varchar(10) NOT NULL,
        [TenSan] nvarchar(50) NOT NULL,
        [MaLoaiSan] varchar(10) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__San__TrangThai__571DF1D5] DEFAULT (N'Trống') NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_San] PRIMARY KEY CLUSTERED ([MaSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_San_TrangThai')
BEGIN
    ALTER TABLE dbo.[San] ADD CONSTRAINT [CK_San_TrangThai] CHECK ([TrangThai]=N'Bảo trì' OR [TrangThai]=N'Đang sử dụng' OR [TrangThai]=N'Trống');
END
GO
