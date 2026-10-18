/* Review and deploy old backend together. Does not delete real service history.
   Verified full backup is fallback if this guarded schema rollback cannot run. */
DECLARE @ExecuteReviewedRollback bit=0;
IF @ExecuteReviewedRollback<>1 BEGIN PRINT 'Rollback disabled'; RETURN; END;
IF DB_NAME()<>'QuanLySanBong' THROW 50210,'Wrong database',1;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
IF EXISTS(SELECT MaDV,DonGia,TrangThai,HoTroLoc FROM dbo.DichVu WHERE MaDV IN ('SV01','SV02','SV03','SV04','SV05','SV06','SV07')
 EXCEPT SELECT * FROM (VALUES('SV01',50000,1,0),('SV02',5000,1,1),('SV03',10000,1,1),('SV04',10000,1,1),
 ('SV05',12000,1,1),('SV06',10000,1,1),('SV07',12000,1,1)) expected(MaDV,DonGia,TrangThai,HoTroLoc))
 OR EXISTS(SELECT 1 FROM dbo.DichVu WHERE MaDV NOT IN ('SV01','SV02','SV03','SV04','SV05','SV06','SV07') AND HoTroLoc=1)
 BEGIN ROLLBACK; THROW 50212,'Catalog changed after migration; review before rollback',1; END;
IF EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE Nguon<>'LEGACY' OR QuyCach<>'DON_VI')
 OR EXISTS(SELECT 1 FROM dbo.ChiTietDichVu GROUP BY MaDatSan,MaDV HAVING COUNT(*)>1)
 OR EXISTS(SELECT 1 FROM dbo.ChiTietDichVu WHERE MaDV IN ('SV01','SV02','SV03','SV04','SV05','SV06','SV07'))
 BEGIN ROLLBACK; THROW 50211,'New service history exists; rollback refused',1; END;
DELETE dbo.DichVu WHERE MaDV IN ('SV01','SV02','SV03','SV04','SV05','SV06','SV07');
ALTER TABLE dbo.ChiTietDichVu DROP CONSTRAINT CK_CTDV_Nguon,CK_CTDV_QuyCach,CK_CTDV_Snapshot,
 DF_CTDV_Nguon,DF_CTDV_QuyCach,DF_CTDV_DonVi,PK_ChiTietDichVu;
DROP INDEX IX_CTDV_BookingSku ON dbo.ChiTietDichVu;
ALTER TABLE dbo.ChiTietDichVu DROP COLUMN MaChiTiet,Nguon,QuyCach,SoDonViMoiQuyCach,DonGiaDonViSnapshot;
ALTER TABLE dbo.ChiTietDichVu ADD CONSTRAINT PK_ChiTietDichVu PRIMARY KEY(MaDatSan,MaDV);
ALTER TABLE dbo.DichVu DROP CONSTRAINT DF_DichVu_HoTroLoc;
ALTER TABLE dbo.DichVu DROP COLUMN HoTroLoc;
COMMIT;
