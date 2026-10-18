/* Approved Phase 5.1B. Run only after dependency check and verified backup.
   UTF-8: sqlcmd -f 65001 -b -d QuanLySanBong -i <this file> */
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME() <> 'QuanLySanBong' THROW 50201, 'Wrong database', 1;
IF COL_LENGTH('dbo.ChiTietDichVu','MaChiTiet') IS NOT NULL THROW 50202, 'Already migrated', 1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id=OBJECT_ID('dbo.ChiTietDichVu'))
 THROW 50203, 'Incoming FK requires separate review', 1;
IF EXISTS(SELECT 1 FROM dbo.DichVu WHERE MaDV IN ('SV01','SV02','SV03','SV04','SV05','SV06','SV07'))
 THROW 50204, 'Seed SKU collision', 1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.DichVu ADD HoTroLoc bit NOT NULL CONSTRAINT DF_DichVu_HoTroLoc DEFAULT 0;
 ALTER TABLE dbo.ChiTietDichVu ADD MaChiTiet bigint IDENTITY(1,1) NOT NULL,
  Nguon varchar(12) NOT NULL CONSTRAINT DF_CTDV_Nguon DEFAULT 'LEGACY',
  QuyCach varchar(10) NOT NULL CONSTRAINT DF_CTDV_QuyCach DEFAULT 'DON_VI',
  SoDonViMoiQuyCach int NOT NULL CONSTRAINT DF_CTDV_DonVi DEFAULT 1,
  DonGiaDonViSnapshot decimal(18,2) NULL;
 EXEC(N'UPDATE dbo.ChiTietDichVu SET DonGiaDonViSnapshot=DonGia;');
 ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT PK_ChiTietDichVu;
 EXEC(N'ALTER TABLE dbo.ChiTietDichVu ADD CONSTRAINT PK_ChiTietDichVu PRIMARY KEY(MaChiTiet);
 CREATE INDEX IX_CTDV_BookingSku ON dbo.ChiTietDichVu(MaDatSan,MaDV);
 ALTER TABLE dbo.ChiTietDichVu ADD CONSTRAINT CK_CTDV_Nguon CHECK(Nguon IN (''LEGACY'',''DAT_TRUOC'',''PHAT_SINH'')),
 CONSTRAINT CK_CTDV_QuyCach CHECK((QuyCach=''DON_VI'' AND SoDonViMoiQuyCach=1) OR (QuyCach=''LOC_6'' AND SoDonViMoiQuyCach=6)),
 CONSTRAINT CK_CTDV_Snapshot CHECK((Nguon=''LEGACY'' AND (DonGiaDonViSnapshot IS NULL OR DonGiaDonViSnapshot>0)) OR
 (Nguon<>''LEGACY'' AND DonGiaDonViSnapshot IS NOT NULL AND DonGiaDonViSnapshot>0 AND
 DonGia=ROUND(DonGiaDonViSnapshot*SoDonViMoiQuyCach*CASE WHEN QuyCach=''LOC_6'' THEN 0.97 ELSE 1 END,2)));');
 EXEC(N'INSERT dbo.DichVu(MaDV,TenDV,DonViTinh,DonGia,TrangThai,HoTroLoc) VALUES
 (''SV01'',N''Trà đá'',N''Thùng'',50000,1,0),
 (''SV02'',N''Nước suối'',N''Chai'',5000,1,1),
 (''SV03'',N''Coca'',N''Lon'',10000,1,1),
 (''SV04'',N''Pepsi'',N''Lon'',10000,1,1),
 (''SV05'',N''Revive chanh muối'',N''Chai'',12000,1,1),
 (''SV06'',N''Revive'',N''Chai'',10000,1,1),
 (''SV07'',N''Aquarius'',N''Chai'',12000,1,1);');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
