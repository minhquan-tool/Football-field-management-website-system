USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.[HoaDon]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HoaDon] (
        [MaHoaDon] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaTKLap] varchar(10) NOT NULL,
        [TienSan] decimal(18, 2) NOT NULL,
        [TienDichVu] decimal(18, 2) NOT NULL,
        [TienGiam] decimal(18, 2) NOT NULL,
        [DaThanhToan] decimal(18, 2) CONSTRAINT [DF__HoaDon__DaThanhT__318258D2] DEFAULT ((0)) NOT NULL,
        [TrangThai] varchar(24) CONSTRAINT [DF__HoaDon__TrangTha__32767D0B] DEFAULT ('CHUA_THANH_TOAN') NOT NULL,
        [DaChot] bit CONSTRAINT [DF__HoaDon__DaChot__336AA144] DEFAULT ((0)) NOT NULL,
        [NgayLap] datetime2(7) CONSTRAINT [DF__HoaDon__NgayLap__345EC57D] DEFAULT (sysdatetime()) NOT NULL,
        [TongTien] AS (CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])) PERSISTED,
        [ConLai] AS (case when [TrangThai]='DA_HUY' then CONVERT([decimal](18,2),(0)) else CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])-[DaThanhToan] end) PERSISTED,
        [HoanTatTaiChinh] AS (CONVERT([bit],case when [DaChot]=(1) AND CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])=[DaThanhToan] AND [TrangThai]='DA_THANH_TOAN' then (1) else (0) end)) PERSISTED,
        CONSTRAINT [PK_HoaDon] PRIMARY KEY CLUSTERED ([MaHoaDon] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HD_Money')
BEGIN
    ALTER TABLE dbo.[HoaDon] ADD CONSTRAINT [CK_HD_Money] CHECK ([TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TienGiam]<=[TienSan] AND [TongTien]>=(0) AND [DaThanhToan]>=(0) AND [DaThanhToan]<=[TongTien]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HD_State')
BEGIN
    ALTER TABLE dbo.[HoaDon] ADD CONSTRAINT [CK_HD_State] CHECK ([TrangThai]='DA_HUY' OR [TrangThai]='DA_THANH_TOAN' OR [TrangThai]='THANH_TOAN_MOT_PHAN' OR [TrangThai]='CHUA_THANH_TOAN');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_HoaDon_DatSan' AND object_id = OBJECT_ID('dbo.[HoaDon]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_HoaDon_DatSan] ON dbo.[HoaDon] ([MaDatSan] ASC);
END
GO
