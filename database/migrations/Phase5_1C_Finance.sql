/* Approved Phase 5.1C; reviewed against live schema. Verified backup required.
   Run UTF-8 sqlcmd -f 65001 -b. No legacy money backfill or database reset. */
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME()<>'QuanLySanBong' THROW 50501,'Wrong database',1;
IF OBJECT_ID('dbo.HoaDon') IS NOT NULL OR OBJECT_ID('dbo.fn_TyLeHoan') IS NOT NULL
 OR COL_LENGTH('dbo.HoanTien','NgayXacNhan') IS NOT NULL THROW 50502,'Already migrated; inspect before retry',1;
IF EXISTS(SELECT MaGiaoDich FROM dbo.ThanhToan WHERE MaGiaoDich IS NOT NULL GROUP BY MaGiaoDich HAVING COUNT(*)>1)
 OR EXISTS(SELECT MaHuy,MaTT FROM dbo.HoanTien GROUP BY MaHuy,MaTT HAVING COUNT(*)>1)
 THROW 50503,'Duplicate legacy keys; review without deleting history',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.HoaDon(
  MaHoaDon varchar(10) NOT NULL CONSTRAINT PK_HoaDon PRIMARY KEY,
  MaDatSan varchar(10) NOT NULL CONSTRAINT UQ_HoaDon_DatSan UNIQUE CONSTRAINT FK_HD_DatSan REFERENCES dbo.DatSan(MaDatSan),
  MaTKLap varchar(10) NOT NULL CONSTRAINT FK_HD_TaiKhoan REFERENCES dbo.TaiKhoan(MaTK),
  TienSan decimal(18,2) NOT NULL,TienDichVu decimal(18,2) NOT NULL,TienGiam decimal(18,2) NOT NULL,TongTien decimal(18,2) NOT NULL,
  DaThanhToan decimal(18,2) NOT NULL DEFAULT 0,
  TrangThai varchar(24) NOT NULL DEFAULT 'CHUA_THANH_TOAN',
  DaChot bit NOT NULL DEFAULT 0,NgayLap datetime2(7) NOT NULL DEFAULT SYSDATETIME(),
  ConLai AS (CASE WHEN TrangThai='DA_HUY' THEN CONVERT(decimal(18,2),0) ELSE TongTien-DaThanhToan END) PERSISTED,
  HoanTatTaiChinh AS CONVERT(bit,CASE WHEN DaChot=1 AND TongTien=DaThanhToan AND TrangThai='DA_THANH_TOAN' THEN 1 ELSE 0 END) PERSISTED,
  CONSTRAINT CK_HD_Money CHECK(TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0 AND TienGiam<=TienSan AND TongTien=TienSan+TienDichVu-TienGiam AND TongTien>=0 AND DaThanhToan>=0 AND DaThanhToan<=TongTien),
  CONSTRAINT CK_HD_State CHECK(TrangThai IN ('CHUA_THANH_TOAN','THANH_TOAN_MOT_PHAN','DA_THANH_TOAN','DA_HUY'))
 );
 CREATE INDEX IX_ThanhToan_BookingState ON dbo.ThanhToan(MaDatSan,TrangThai) INCLUDE(SoTien);
 CREATE UNIQUE INDEX UX_ThanhToan_Idempotency ON dbo.ThanhToan(MaGiaoDich) WHERE MaGiaoDich IS NOT NULL;
 CREATE UNIQUE INDEX UX_HoanTien_CancellationPayment ON dbo.HoanTien(MaHuy,MaTT);
 ALTER TABLE dbo.HoanTien ADD NgayXacNhan datetime2(7) NULL,LyDo nvarchar(255) NULL;
 DECLARE @df sysname=(SELECT name FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.HuyDatSan') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.HuyDatSan'),'NgayHuy','ColumnId'));
 DECLARE @ddl nvarchar(max);
 IF @df IS NOT NULL BEGIN SET @ddl=N'ALTER TABLE dbo.HuyDatSan DROP CONSTRAINT '+QUOTENAME(@df); EXEC(@ddl); END;
 ALTER TABLE dbo.HuyDatSan ALTER COLUMN NgayHuy datetime2(7) NOT NULL;
 IF @df IS NOT NULL BEGIN SET @ddl=N'ALTER TABLE dbo.HuyDatSan ADD CONSTRAINT '+QUOTENAME(@df)+N' DEFAULT GETDATE() FOR NgayHuy'; EXEC(@ddl); END;
 ALTER TABLE dbo.HuyDatSan ADD SoTienThucThuSnapshot decimal(18,2) NULL;
 EXEC(N'ALTER TABLE dbo.HuyDatSan ADD CONSTRAINT CK_Huy_ThucThu CHECK(SoTienThucThuSnapshot IS NULL OR
 (SoTienThucThuSnapshot>=0 AND SoTienHoan<=ROUND(SoTienThucThuSnapshot*TiLeHoan/100,2)));');
 EXEC(N'CREATE FUNCTION dbo.fn_TyLeHoan(@BatDau datetime2(7),@Huy datetime2(7)) RETURNS decimal(5,2) AS
 BEGIN RETURN CASE WHEN @Huy<=DATEADD(hour,-10,@BatDau) THEN 100 WHEN @Huy<=DATEADD(hour,-2,@BatDau) THEN 50 ELSE 0 END; END;');
 EXEC(N'CREATE VIEW dbo.V_ThuChiThucNhan AS
 SELECT MaTT MaGiaoDich,MaDatSan,NgayThanhToan ThoiDiem,PhuongThuc,SoTien SoTienThucNhan,N''Thu'' Loai FROM dbo.ThanhToan WHERE TrangThai=N''Thành công''
 UNION ALL SELECT h.MaHT,t.MaDatSan,h.NgayXacNhan,h.PhuongThuc,-h.SoTienHoan,N''Hoàn'' FROM dbo.HoanTien h
 JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE h.TrangThai=N''Đã hoàn'';');
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
