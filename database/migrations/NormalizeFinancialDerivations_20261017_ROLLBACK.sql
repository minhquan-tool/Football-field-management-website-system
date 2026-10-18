/* REVIEWED ROLLBACK: retain current field values, no restore-overwrite or row deletion.
   Coordinate with old JAR. Test on a fixture before operational use. */
SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET NOCOUNT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51110,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51111,'DEV/test marker required',1;
IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TongTien','IsComputed')<>1 THROW 51112,'Not the normalized schema',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @lock bigint;
 SELECT @lock=COUNT_BIG(*) FROM dbo.San WITH(UPDLOCK,HOLDLOCK);
 SELECT @lock=COUNT_BIG(*) FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK);
 CREATE TABLE #Before(t sysname PRIMARY KEY,h varbinary(32));
 INSERT #Before VALUES('DatSan',HASHBYTES('SHA2_256',(SELECT [MaDatSan],[MaKH],[MaSan],[MaKhungGio],[NgayChoi],[ThoiLuong],[DonGia],[TienSan],[TienDichVu],[MaKM],[TienGiam],[TongTien],[NgayDat],[MaNV],[TrangThai],[GhiChu],[GioBatDau],[GioKetThuc],[CheDoGia],[HinhThucDat] FROM dbo.[DatSan] ORDER BY [MaDatSan] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 INSERT #Before VALUES('HoaDon',HASHBYTES('SHA2_256',(SELECT [MaHoaDon],[MaDatSan],[MaTKLap],[TienSan],[TienDichVu],[TienGiam],[TongTien],[DaThanhToan],[TrangThai],[DaChot],[NgayLap],[ConLai],[HoanTatTaiChinh] FROM dbo.[HoaDon] ORDER BY [MaHoaDon] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 INSERT #Before VALUES('ChiTietDichVu',HASHBYTES('SHA2_256',(SELECT [MaDatSan],[MaDV],[SoLuong],[DonGia],[ThanhTien],[NgayGhiNhan],[MaNV],[MaChiTiet],[Nguon],[QuyCach],[SoDonViMoiQuyCach],[DonGiaDonViSnapshot] FROM dbo.[ChiTietDichVu] ORDER BY [MaChiTiet] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 EXEC(N'ALTER TABLE dbo.DatSan ADD [TongTien_Rollback] decimal(18,2) NULL;');
 EXEC(N'UPDATE dbo.DatSan SET [TongTien_Rollback]=[TongTien];');
 EXEC(N'ALTER TABLE dbo.HoaDon ADD [TongTien_Rollback] decimal(18,2) NULL;');
 EXEC(N'UPDATE dbo.HoaDon SET [TongTien_Rollback]=[TongTien];');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD [DonGia_Rollback] decimal(18,2) NULL;');
 EXEC(N'UPDATE dbo.ChiTietDichVu SET [DonGia_Rollback]=[DonGia];');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD [SoDonViMoiQuyCach_Rollback] int NULL;');
 EXEC(N'UPDATE dbo.ChiTietDichVu SET [SoDonViMoiQuyCach_Rollback]=[SoDonViMoiQuyCach];');
 IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TienSan','IsComputed')=1
 BEGIN
 EXEC(N'ALTER TABLE dbo.DatSan ADD [ThoiLuong_Rollback] decimal(4,2) NULL;');
 EXEC(N'UPDATE dbo.DatSan SET [ThoiLuong_Rollback]=[ThoiLuong];');
 EXEC(N'ALTER TABLE dbo.DatSan ADD [TienSan_Rollback] decimal(18,2) NULL;');
 EXEC(N'UPDATE dbo.DatSan SET [TienSan_Rollback]=[TienSan];');
 END;

 ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_Tien;
 ALTER TABLE dbo.HoaDon DROP CONSTRAINT CK_HD_Money;
 ALTER TABLE dbo.HoaDon DROP COLUMN ConLai,HoanTatTaiChinh;
 ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT CK_CTDV_DonGia,CK_CTDV_QuyCach,CK_CTDV_Snapshot;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN ThanhTien;
 ALTER TABLE dbo.DatSan DROP COLUMN TongTien;
 ALTER TABLE dbo.HoaDon DROP COLUMN TongTien;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGia,SoDonViMoiQuyCach;
 IF COL_LENGTH('dbo.DatSan','ThoiLuong_Rollback') IS NOT NULL
 BEGIN
  ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_ThoiLuong,CK_DatSan_LegacySnapshots;
  ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuong,TienSan;
  EXEC sys.sp_rename N'dbo.DatSan.ThoiLuong_Rollback',N'ThoiLuong',N'COLUMN';
  EXEC sys.sp_rename N'dbo.DatSan.TienSan_Rollback',N'TienSan',N'COLUMN';
  EXEC(N'ALTER TABLE dbo.DatSan ALTER COLUMN ThoiLuong decimal(4,2) NOT NULL; ALTER TABLE dbo.DatSan ALTER COLUMN TienSan decimal(18,2) NOT NULL;');
  ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuongLegacySnapshot,TienSanLegacySnapshot;
 END;
 EXEC sys.sp_rename N'dbo.DatSan.TongTien_Rollback',N'TongTien',N'COLUMN';
 EXEC(N'ALTER TABLE dbo.DatSan ALTER COLUMN [TongTien] decimal(18,2) NOT NULL;');
 EXEC sys.sp_rename N'dbo.HoaDon.TongTien_Rollback',N'TongTien',N'COLUMN';
 EXEC(N'ALTER TABLE dbo.HoaDon ALTER COLUMN [TongTien] decimal(18,2) NOT NULL;');
 EXEC sys.sp_rename N'dbo.ChiTietDichVu.DonGia_Rollback',N'DonGia',N'COLUMN';
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ALTER COLUMN [DonGia] decimal(18,2) NOT NULL;');
 EXEC sys.sp_rename N'dbo.ChiTietDichVu.SoDonViMoiQuyCach_Rollback',N'SoDonViMoiQuyCach',N'COLUMN';
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ALTER COLUMN [SoDonViMoiQuyCach] int NOT NULL;');
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGiaLegacySnapshot;
 IF OBJECT_ID('dbo.CK_DatSan_ThoiLuong') IS NULL
 EXEC(N'ALTER TABLE dbo.DatSan WITH CHECK ADD CONSTRAINT [CK_DatSan_ThoiLuong] CHECK ([ThoiLuong]>(0));');
 EXEC(N'ALTER TABLE dbo.DatSan WITH CHECK ADD CONSTRAINT [CK_DatSan_Tien] CHECK ([DonGia]>(0) AND [TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TongTien]>=(0));');
 EXEC(N'ALTER TABLE dbo.HoaDon ADD [ConLai] AS (case when [TrangThai]=''DA_HUY'' then CONVERT([decimal](18,2),(0)) else [TongTien]-[DaThanhToan] end) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.HoaDon ADD [HoanTatTaiChinh] AS (CONVERT([bit],case when [DaChot]=(1) AND [TongTien]=[DaThanhToan] AND [TrangThai]=''DA_THANH_TOAN'' then (1) else (0) end)) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.HoaDon WITH CHECK ADD CONSTRAINT [CK_HD_Money] CHECK ([TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TienGiam]<=[TienSan] AND [TongTien]=(([TienSan]+[TienDichVu])-[TienGiam]) AND [TongTien]>=(0) AND [DaThanhToan]>=(0) AND [DaThanhToan]<=[TongTien]);');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD [ThanhTien] AS ([SoLuong]*[DonGia]) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu WITH CHECK ADD CONSTRAINT [CK_CTDV_DonGia] CHECK ([DonGia]>(0));');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu WITH CHECK ADD CONSTRAINT [CK_CTDV_QuyCach] CHECK ([QuyCach]=''DON_VI'' AND [SoDonViMoiQuyCach]=(1) OR [QuyCach]=''LOC_6'' AND [SoDonViMoiQuyCach]=(6));');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu WITH CHECK ADD CONSTRAINT [CK_CTDV_Snapshot] CHECK ([Nguon]=''LEGACY'' AND ([DonGiaDonViSnapshot] IS NULL OR [DonGiaDonViSnapshot]>(0)) OR [Nguon]<>''LEGACY'' AND [DonGiaDonViSnapshot] IS NOT NULL AND [DonGiaDonViSnapshot]>(0) AND [DonGia]=round(([DonGiaDonViSnapshot]*[SoDonViMoiQuyCach])*case when [QuyCach]=''LOC_6'' then (0.97) else (1) end,(2)));');
 IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.DatSan') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TongTien','ColumnId'))
 EXEC(N'ALTER TABLE dbo.DatSan ADD CONSTRAINT [DF__DatSan__TongTien__6EF57B66] DEFAULT ((0)) FOR [TongTien];');
 IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.DatSan') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TienSan','ColumnId'))
 EXEC(N'ALTER TABLE dbo.DatSan ADD CONSTRAINT [DF__DatSan__TienSan__6C190EBB] DEFAULT ((0)) FOR [TienSan];');
 IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.ChiTietDichVu') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.ChiTietDichVu'),'SoDonViMoiQuyCach','ColumnId'))
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD CONSTRAINT [DF_CTDV_DonVi] DEFAULT ((1)) FOR [SoDonViMoiQuyCach];');
 EXEC(N'
/* ============================================================
   9. TRIGGER TỰ ĐỘNG TÍNH TIỀN CHO PHIẾU ĐẶT SÂN (RB5)
   ============================================================ */
ALTER TRIGGER TRG_CapNhatTienDatSan
ON ChiTietDichVu
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ds AS (
        SELECT MaDatSan FROM inserted
        UNION
        SELECT MaDatSan FROM deleted
    )
    UPDATE d
    SET    d.TienDichVu = ISNULL(ct.Tong, 0),
           d.TongTien   = d.TienSan + ISNULL(ct.Tong, 0) - d.TienGiam
    FROM   DatSan d
           JOIN ds ON ds.MaDatSan = d.MaDatSan
           OUTER APPLY (SELECT SUM(ThanhTien) AS Tong
                        FROM ChiTietDichVu c
                        WHERE c.MaDatSan = d.MaDatSan) ct;
END;
');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''DatSan'')<>HASHBYTES(''SHA2_256'',(SELECT [MaDatSan],[MaKH],[MaSan],[MaKhungGio],[NgayChoi],[ThoiLuong],[DonGia],[TienSan],[TienDichVu],[MaKM],[TienGiam],[TongTien],[NgayDat],[MaNV],[TrangThai],[GhiChu],[GioBatDau],[GioKetThuc],[CheDoGia],[HinhThucDat] FROM dbo.[DatSan] ORDER BY [MaDatSan] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51113,''Rollback changed original projection: DatSan'',1;');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''HoaDon'')<>HASHBYTES(''SHA2_256'',(SELECT [MaHoaDon],[MaDatSan],[MaTKLap],[TienSan],[TienDichVu],[TienGiam],[TongTien],[DaThanhToan],[TrangThai],[DaChot],[NgayLap],[ConLai],[HoanTatTaiChinh] FROM dbo.[HoaDon] ORDER BY [MaHoaDon] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51113,''Rollback changed original projection: HoaDon'',1;');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''ChiTietDichVu'')<>HASHBYTES(''SHA2_256'',(SELECT [MaDatSan],[MaDV],[SoLuong],[DonGia],[ThanhTien],[NgayGhiNhan],[MaNV],[MaChiTiet],[Nguon],[QuyCach],[SoDonViMoiQuyCach],[DonGiaDonViSnapshot] FROM dbo.[ChiTietDichVu] ORDER BY [MaChiTiet] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51113,''Rollback changed original projection: ChiTietDichVu'',1;');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK; THROW;
END CATCH;
