/* Reviewed rollback template; NOT EXECUTED.
   Restore original backend only together with this rollback.
   Refuses to discard any new hourly booking or changed price configuration.
   Verified COPY_ONLY backup is the fallback for a separately reviewed recovery.
*/
DECLARE @ExecuteRollback bit=0;
IF @ExecuteRollback<>1 BEGIN PRINT 'Rollback disabled.'; RETURN; END;
IF DB_NAME()<>'QuanLySanBong' THROW 50200,'Wrong database',1;
IF EXISTS(SELECT 1 FROM DatSan WHERE CheDoGia<>'GIA_KHUNG' OR MaKhungGio IS NULL)
    THROW 50201,'New bookings exist: rollback requires a data-preserving plan',1;
IF EXISTS(SELECT 1 FROM GiaTheoCa WHERE
    (MaCa='SANG' AND DonGia<>90000) OR (MaCa='CHIEU' AND DonGia<>130000)
    OR (MaCa='TOI' AND DonGia<>180000)) OR (SELECT COUNT(*) FROM GiaTheoCa)<>3
    THROW 50202,'Price configuration changed: do not discard it',1;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    DROP INDEX IX_DatSan_SanNgayBatDau ON DatSan;
    DROP INDEX UX_DatSan_KhongTrungLich ON DatSan;
    ALTER TABLE DatSan ALTER COLUMN MaKhungGio varchar(10) NOT NULL;
    CREATE UNIQUE INDEX UX_DatSan_KhongTrungLich ON DatSan(MaSan,NgayChoi,MaKhungGio)
        WHERE TrangThai<>N'Đã hủy';
    ALTER TABLE DatSan DROP CONSTRAINT CK_DatSan_KhoangGio,CK_DatSan_CheDoGia,
        CK_DatSan_HinhThucDat,CK_DatSan_GioMoi,DF_DatSan_CheDoGia,DF_DatSan_HinhThucDat;
    ALTER TABLE DatSan DROP COLUMN GioBatDau,GioKetThuc,CheDoGia,HinhThucDat;
    DROP TABLE GiaTheoCa;
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
