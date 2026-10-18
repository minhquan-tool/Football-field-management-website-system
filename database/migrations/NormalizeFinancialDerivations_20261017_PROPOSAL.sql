/* REVIEW REQUIRED: financial schema change; stop the old JAR before deployment.
   Moves only deterministic derivations to persisted computed columns.
   Original legacy service price is preserved in DonGiaLegacySnapshot.
   All original financial fields are SHA256-compared before COMMIT.
   Requires the matching backend (no INSERT/UPDATE of computed columns).
   sqlcmd -b -f 65001 -v ReviewedDatabase=<reviewed dev/test DB> -i <file> */
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON; SET NOCOUNT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51100,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51101,'DEV/test marker required',1;
IF COLUMNPROPERTY(OBJECT_ID('dbo.DatSan'),'TongTien','IsComputed')<>0 OR COL_LENGTH('dbo.ChiTietDichVu','DonGiaLegacySnapshot') IS NOT NULL THROW 51102,'Unexpected/already migrated schema',1;
BEGIN TRY
 BEGIN TRANSACTION;
 -- Lock order matches application writes. Migration also acquires schema locks.
 DECLARE @locked bigint;
 SELECT @locked=COUNT_BIG(*) FROM dbo.San WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.HoaDon WITH(UPDLOCK,HOLDLOCK);
 SELECT @locked=COUNT_BIG(*) FROM dbo.ChiTietDichVu WITH(UPDLOCK,HOLDLOCK);
 IF EXISTS(SELECT 1 FROM dbo.DatSan WHERE TongTien<>TienSan+TienDichVu-TienGiam) OR EXISTS(SELECT 1 FROM dbo.HoaDon WHERE TongTien<>TienSan+TienDichVu-TienGiam) THROW 51103,'Totals differ; review legacy data, never silently repair it',1;
 IF EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE SoDonViMoiQuyCach<>CASE WHEN QuyCach='LOC_6' THEN 6 ELSE 1 END OR (Nguon<>'LEGACY' AND DonGia<>ROUND(DonGiaDonViSnapshot*SoDonViMoiQuyCach*CASE WHEN QuyCach='LOC_6' THEN 0.97 ELSE 1 END,2))) THROW 51104,'Service derivation mismatch; review without repricing',1;
 CREATE TABLE #Before(t sysname PRIMARY KEY,h varbinary(32));
 INSERT #Before VALUES('DatSan',HASHBYTES('SHA2_256',(SELECT [MaDatSan],[MaKH],[MaSan],[MaKhungGio],[NgayChoi],[ThoiLuong],[DonGia],[TienSan],[TienDichVu],[MaKM],[TienGiam],[TongTien],[NgayDat],[MaNV],[TrangThai],[GhiChu],[GioBatDau],[GioKetThuc],[CheDoGia],[HinhThucDat] FROM dbo.[DatSan] ORDER BY [MaDatSan] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 INSERT #Before VALUES('HoaDon',HASHBYTES('SHA2_256',(SELECT [MaHoaDon],[MaDatSan],[MaTKLap],[TienSan],[TienDichVu],[TienGiam],[TongTien],[DaThanhToan],[TrangThai],[DaChot],[NgayLap],[ConLai],[HoanTatTaiChinh] FROM dbo.[HoaDon] ORDER BY [MaHoaDon] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 INSERT #Before VALUES('ChiTietDichVu',HASHBYTES('SHA2_256',(SELECT [MaDatSan],[MaDV],[SoLuong],[DonGia],[ThanhTien],[NgayGhiNhan],[MaNV],[MaChiTiet],[Nguon],[QuyCach],[SoDonViMoiQuyCach],[DonGiaDonViSnapshot] FROM dbo.[ChiTietDichVu] ORDER BY [MaChiTiet] FOR JSON PATH,INCLUDE_NULL_VALUES)));
 ALTER TABLE dbo.[DatSan] DROP CONSTRAINT [DF__DatSan__TongTien__6EF57B66];
 ALTER TABLE dbo.[DatSan] DROP CONSTRAINT [DF__DatSan__TienSan__6C190EBB];
 ALTER TABLE dbo.[ChiTietDichVu] DROP CONSTRAINT [DF_CTDV_DonVi];

 ALTER TABLE dbo.DatSan DROP CONSTRAINT CK_DatSan_Tien,CK_DatSan_ThoiLuong;
 ALTER TABLE dbo.HoaDon DROP CONSTRAINT CK_HD_Money;
 ALTER TABLE dbo.HoaDon DROP COLUMN ConLai,HoanTatTaiChinh;
 ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT CK_CTDV_DonGia,CK_CTDV_QuyCach,CK_CTDV_Snapshot;
 ALTER TABLE dbo.ChiTietDichVu ADD DonGiaLegacySnapshot decimal(18,2) NULL;
 ALTER TABLE dbo.DatSan ADD ThoiLuongLegacySnapshot decimal(4,2) NULL,TienSanLegacySnapshot decimal(18,2) NULL;
 -- Dynamic compilation after adding the column; do not touch new-sale unit snapshots.
 EXEC(N'UPDATE dbo.ChiTietDichVu SET DonGiaLegacySnapshot=DonGia WHERE Nguon=''LEGACY'';');
 EXEC(N'UPDATE dbo.DatSan SET ThoiLuongLegacySnapshot=ThoiLuong,TienSanLegacySnapshot=TienSan WHERE CheDoGia=''GIA_KHUNG'';');
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN ThanhTien;
 ALTER TABLE dbo.ChiTietDichVu DROP COLUMN DonGia,SoDonViMoiQuyCach;
 ALTER TABLE dbo.DatSan DROP COLUMN TongTien;
 ALTER TABLE dbo.DatSan DROP COLUMN ThoiLuong,TienSan;
 ALTER TABLE dbo.HoaDon DROP COLUMN TongTien;
 EXEC(N'ALTER TABLE dbo.DatSan ADD ThoiLuong AS (CONVERT(decimal(4,2),CASE WHEN CheDoGia=''GIA_KHUNG'' THEN ThoiLuongLegacySnapshot ELSE ROUND(DATEDIFF(minute,GioBatDau,GioKetThuc)/60.0,2) END)) PERSISTED,TienSan AS (CONVERT(decimal(18,2),CASE WHEN CheDoGia=''GIA_KHUNG'' THEN TienSanLegacySnapshot ELSE ROUND(DonGia*DATEDIFF(minute,GioBatDau,GioKetThuc)/60.0,2) END)) PERSISTED,TongTien AS (CONVERT(decimal(18,2),CONVERT(decimal(18,2),CASE WHEN CheDoGia=''GIA_KHUNG'' THEN TienSanLegacySnapshot ELSE ROUND(DonGia*DATEDIFF(minute,GioBatDau,GioKetThuc)/60.0,2) END)+TienDichVu-TienGiam)) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.DatSan WITH CHECK ADD CONSTRAINT CK_DatSan_Tien CHECK(DonGia>0 AND TienSan IS NOT NULL AND TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0 AND TongTien>=0),
 CONSTRAINT CK_DatSan_ThoiLuong CHECK(ThoiLuong IS NOT NULL AND ThoiLuong>0),
 CONSTRAINT CK_DatSan_LegacySnapshots CHECK((CheDoGia=''GIA_KHUNG'' AND ThoiLuongLegacySnapshot IS NOT NULL AND ThoiLuongLegacySnapshot>0 AND TienSanLegacySnapshot IS NOT NULL AND TienSanLegacySnapshot>=0) OR (CheDoGia=''GIA_GIO'' AND ThoiLuongLegacySnapshot IS NULL AND TienSanLegacySnapshot IS NULL));');
 EXEC(N'ALTER TABLE dbo.HoaDon ADD TongTien AS (CONVERT(decimal(18,2),TienSan+TienDichVu-TienGiam)) PERSISTED,
 ConLai AS (CASE WHEN TrangThai=''DA_HUY'' THEN CONVERT(decimal(18,2),0) ELSE CONVERT(decimal(18,2),TienSan+TienDichVu-TienGiam)-DaThanhToan END) PERSISTED,
 HoanTatTaiChinh AS CONVERT(bit,CASE WHEN DaChot=1 AND CONVERT(decimal(18,2),TienSan+TienDichVu-TienGiam)=DaThanhToan AND TrangThai=''DA_THANH_TOAN'' THEN 1 ELSE 0 END) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.HoaDon WITH CHECK ADD CONSTRAINT CK_HD_Money CHECK(TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0 AND TienGiam<=TienSan AND TongTien>=0 AND DaThanhToan>=0 AND DaThanhToan<=TongTien);');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD SoDonViMoiQuyCach AS (CONVERT(int,CASE WHEN QuyCach=''LOC_6'' THEN 6 ELSE 1 END)) PERSISTED,
 DonGia AS (CONVERT(decimal(18,2),CASE WHEN Nguon=''LEGACY'' THEN DonGiaLegacySnapshot ELSE ROUND(DonGiaDonViSnapshot*CASE WHEN QuyCach=''LOC_6'' THEN 6 ELSE 1 END*CASE WHEN QuyCach=''LOC_6'' THEN 0.97 ELSE 1 END,2) END)) PERSISTED,
 ThanhTien AS (SoLuong*CONVERT(decimal(18,2),CASE WHEN Nguon=''LEGACY'' THEN DonGiaLegacySnapshot ELSE ROUND(DonGiaDonViSnapshot*CASE WHEN QuyCach=''LOC_6'' THEN 6 ELSE 1 END*CASE WHEN QuyCach=''LOC_6'' THEN 0.97 ELSE 1 END,2) END)) PERSISTED;');
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu WITH CHECK ADD CONSTRAINT CK_CTDV_QuyCach CHECK(QuyCach IN(''DON_VI'',''LOC_6'')),
 CONSTRAINT CK_CTDV_DonGia CHECK(DonGia IS NOT NULL AND DonGia>0),
 CONSTRAINT CK_CTDV_Snapshot CHECK((Nguon=''LEGACY'' AND DonGiaLegacySnapshot IS NOT NULL AND DonGiaLegacySnapshot>0 AND (DonGiaDonViSnapshot IS NULL OR DonGiaDonViSnapshot>0)) OR (Nguon<>''LEGACY'' AND DonGiaLegacySnapshot IS NULL AND DonGiaDonViSnapshot IS NOT NULL AND DonGiaDonViSnapshot>0));');
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
    SET    d.TienDichVu = ISNULL(ct.Tong, 0)
    FROM   DatSan d
           JOIN ds ON ds.MaDatSan = d.MaDatSan
           OUTER APPLY (SELECT SUM(ThanhTien) AS Tong
                        FROM ChiTietDichVu c
                        WHERE c.MaDatSan = d.MaDatSan) ct;
END;
');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''DatSan'')<>HASHBYTES(''SHA2_256'',(SELECT [MaDatSan],[MaKH],[MaSan],[MaKhungGio],[NgayChoi],[ThoiLuong],[DonGia],[TienSan],[TienDichVu],[MaKM],[TienGiam],[TongTien],[NgayDat],[MaNV],[TrangThai],[GhiChu],[GioBatDau],[GioKetThuc],[CheDoGia],[HinhThucDat] FROM dbo.[DatSan] ORDER BY [MaDatSan] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51105,''Original financial projection changed: DatSan'',1;');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''HoaDon'')<>HASHBYTES(''SHA2_256'',(SELECT [MaHoaDon],[MaDatSan],[MaTKLap],[TienSan],[TienDichVu],[TienGiam],[TongTien],[DaThanhToan],[TrangThai],[DaChot],[NgayLap],[ConLai],[HoanTatTaiChinh] FROM dbo.[HoaDon] ORDER BY [MaHoaDon] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51105,''Original financial projection changed: HoaDon'',1;');
 EXEC(N'IF (SELECT h FROM #Before WHERE t=''ChiTietDichVu'')<>HASHBYTES(''SHA2_256'',(SELECT [MaDatSan],[MaDV],[SoLuong],[DonGia],[ThanhTien],[NgayGhiNhan],[MaNV],[MaChiTiet],[Nguon],[QuyCach],[SoDonViMoiQuyCach],[DonGiaDonViSnapshot] FROM dbo.[ChiTietDichVu] ORDER BY [MaChiTiet] FOR JSON PATH,INCLUDE_NULL_VALUES)) THROW 51105,''Original financial projection changed: ChiTietDichVu'',1;');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK; THROW;
END CATCH;
