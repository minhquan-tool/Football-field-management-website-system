/* Approved by user 21/10/2026: add cancellation request queue. No legacy backfill.
   Run after verified backup, using DBA identity and sqlcmd -b -f 65001.
   Existing bookings and finance snapshots remain unchanged. */
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME()<>'QuanLySanBong' THROW 51001,'Wrong database',1;
IF OBJECT_ID('dbo.YeuCauHuyDatSan','U') IS NOT NULL THROW 51002,'Already migrated; inspect before retry',1;
IF OBJECT_ID('dbo.fn_TyLeHoan') IS NULL OR COL_LENGTH('dbo.HuyDatSan','SoTienThucThuSnapshot') IS NULL
 THROW 51003,'Finance schema prerequisite missing',1;
BEGIN TRY
 BEGIN TRANSACTION;
CREATE TABLE dbo.YeuCauHuyDatSan (
 MaYeuCau VARCHAR(10) NOT NULL PRIMARY KEY,
 MaDatSan VARCHAR(10) NOT NULL REFERENCES dbo.DatSan(MaDatSan),
 MaTKGui VARCHAR(10) NOT NULL REFERENCES dbo.TaiKhoan(MaTK),
 NgayGui DATETIME2(7) NOT NULL,
 LyDo NVARCHAR(255) NOT NULL,
 TrangThai VARCHAR(20) NOT NULL DEFAULT 'PENDING',
 TiLeHoanUocTinh DECIMAL(5,2) NOT NULL,
 ThucThuTaiGui DECIMAL(18,2) NOT NULL,
 TienHoanUocTinh DECIMAL(18,2) NOT NULL,
 MaTKXuLy VARCHAR(10) NULL REFERENCES dbo.TaiKhoan(MaTK),
 NgayXuLy DATETIME2(7) NULL,
 GhiChuXuLy NVARCHAR(255) NULL,
 MaHuy VARCHAR(10) NULL REFERENCES dbo.HuyDatSan(MaHuy),
 PhienBan ROWVERSION,
 CONSTRAINT CK_YeuCauHuy_TrangThai CHECK(TrangThai IN('PENDING','APPROVED','REJECTED')),
 CONSTRAINT CK_YeuCauHuy_Tien CHECK(TiLeHoanUocTinh BETWEEN 0 AND 100 AND ThucThuTaiGui>=0 AND TienHoanUocTinh>=0 AND TienHoanUocTinh<=ThucThuTaiGui),
 CONSTRAINT CK_YeuCauHuy_XuLy CHECK(
  (TrangThai='PENDING' AND MaTKXuLy IS NULL AND NgayXuLy IS NULL AND MaHuy IS NULL) OR
  (TrangThai='APPROVED' AND MaTKXuLy IS NOT NULL AND NgayXuLy IS NOT NULL AND MaHuy IS NOT NULL) OR
  (TrangThai='REJECTED' AND MaTKXuLy IS NOT NULL AND NgayXuLy IS NOT NULL AND MaHuy IS NULL))
);
CREATE UNIQUE INDEX UX_YeuCauHuy_Pending ON dbo.YeuCauHuyDatSan(MaDatSan) WHERE TrangThai='PENDING';

 CREATE INDEX IX_YeuCauHuy_Queue ON dbo.YeuCauHuyDatSan(TrangThai,NgayGui DESC) INCLUDE(MaDatSan,MaTKGui);
 CREATE INDEX IX_YeuCauHuy_Customer ON dbo.YeuCauHuyDatSan(MaTKGui,NgayGui DESC);
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
