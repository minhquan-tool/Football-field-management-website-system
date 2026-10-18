-- User selected Wednesday-only on 2026-10-17. No schema or historical snapshot changes.
-- Invoke sqlcmd with -f 65001 so Vietnamese policy guards are decoded as UTF-8.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'QuanLySanBong' THROW 50850,'Unexpected database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 50851,'Reviewed DEV/test target required',1;
IF (SELECT COUNT(*) FROM dbo.KhuyenMai WHERE MaKM=N'KM02' AND TenKM LIKE N'%(VIP10)' AND LoaiGiam=N'Phần trăm' AND MucGiam=10)<>1 THROW 50852,'VIP10 catalog differs; review before changing',1;
BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM dbo.KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=N'KM02' AND DieuKien=N'Áp dụng ngày trong tuần')
 AND EXISTS(SELECT 1 FROM dbo.DatSan WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=N'KM02')
BEGIN
 ROLLBACK;
 THROW 50854,'VIP10 already used; preserve historical policy and review a versioned promotion',1;
END;
IF EXISTS(SELECT 1 FROM dbo.KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=N'KM02' AND DieuKien NOT IN(N'Áp dụng ngày trong tuần',N'Chỉ áp dụng thứ Tư'))
BEGIN
 ROLLBACK;
 THROW 50853,'VIP10 condition differs from reviewed policy',1;
END;
UPDATE dbo.KhuyenMai SET DieuKien=N'Chỉ áp dụng thứ Tư' WHERE MaKM=N'KM02' AND DieuKien=N'Áp dụng ngày trong tuần';
COMMIT;
SELECT MaKM,TenKM,LoaiGiam,MucGiam,DieuKien FROM dbo.KhuyenMai WHERE MaKM=N'KM02';
