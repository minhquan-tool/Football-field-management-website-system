USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[SaoLuu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[SaoLuu] (
        [MaSaoLuu] varchar(10) NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [ThoiGian] datetime CONSTRAINT [DF__SaoLuu__ThoiGian__44CA3770] DEFAULT (getdate()) NOT NULL,
        [LoaiThaoTac] nvarchar(20) NOT NULL,
        [DuongDan] nvarchar(255) NULL,
        [KetQua] bit CONSTRAINT [DF__SaoLuu__KetQua__45BE5BA9] DEFAULT ((1)) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_SaoLuu] PRIMARY KEY CLUSTERED ([MaSaoLuu] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_SaoLuu_LoaiThaoTac')
BEGIN
    ALTER TABLE dbo.[SaoLuu] ADD CONSTRAINT [CK_SaoLuu_LoaiThaoTac] CHECK ([LoaiThaoTac]=N'Phục hồi' OR [LoaiThaoTac]=N'Sao lưu');
END
GO
