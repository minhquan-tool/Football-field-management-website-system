/* APPROVED PHASE 5.1A MIGRATION — applied after verified COPY_ONLY backup.
   Part 1 of Phase 5.1: booking time snapshots and hourly price bands.
   Does NOT implement services, finance or functions/procedures.
   Deploy only with the Phase 5.1A backend supporting nullable legacy slots.
   Existing money/date/status/slot values are preserved. No DROP/reset of business data.
   Review backup, dependency checks and the full rollout plan before enabling execution.
*/
DECLARE @ExecuteReviewedProposal bit = 1;
IF @ExecuteReviewedProposal <> 1
BEGIN
    PRINT N'PROPOSAL ONLY. No schema or data changes executed.';
    RETURN;
END;

IF DB_NAME() <> N'QuanLySanBong'
    THROW 50101, 'Wrong database. Select QuanLySanBong explicitly.', 1;
IF OBJECT_ID(N'dbo.DatSan', N'U') IS NULL OR OBJECT_ID(N'dbo.KhungGio', N'U') IS NULL
    THROW 50102, 'Required tables are missing.', 1;
IF COL_LENGTH(N'dbo.DatSan', N'GioBatDau') IS NOT NULL
   OR COL_LENGTH(N'dbo.DatSan', N'GioKetThuc') IS NOT NULL
   OR COL_LENGTH(N'dbo.DatSan', N'CheDoGia') IS NOT NULL
   OR COL_LENGTH(N'dbo.DatSan', N'HinhThucDat') IS NOT NULL
   OR OBJECT_ID(N'dbo.GiaTheoCa', N'U') IS NOT NULL
    THROW 50103, 'Target columns/table already exist. Inspect schema before resuming.', 1;
IF EXISTS (SELECT 1 FROM dbo.DatSan d LEFT JOIN dbo.KhungGio k
           ON k.MaKhungGio=d.MaKhungGio
           WHERE k.MaKhungGio IS NULL OR k.GioKetThuc <= k.GioBatDau)
    THROW 50104, 'Legacy time backfill cannot be verified.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id=OBJECT_ID(N'dbo.DatSan')
                 AND name=N'UX_DatSan_KhongTrungLich' AND is_unique=1 AND has_filter=1)
    THROW 50105, 'Expected legacy unique filtered index missing. Review dependencies.', 1;

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

    -- Dynamic batches intentionally compile references AFTER columns are added.
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DatSan ADD
            GioBatDau time(0) NULL,
            GioKetThuc time(0) NULL,
            CheDoGia varchar(12) NOT NULL
                CONSTRAINT DF_DatSan_CheDoGia DEFAULT ''GIA_KHUNG'',
            HinhThucDat varchar(12) NOT NULL
                CONSTRAINT DF_DatSan_HinhThucDat DEFAULT ''KHONG_RO'';';

    EXEC sys.sp_executesql N'
        UPDATE d SET GioBatDau=CONVERT(time(0),k.GioBatDau),
                     GioKetThuc=CONVERT(time(0),k.GioKetThuc)
        FROM dbo.DatSan d JOIN dbo.KhungGio k ON k.MaKhungGio=d.MaKhungGio;
        IF EXISTS(SELECT 1 FROM dbo.DatSan
                  WHERE GioBatDau IS NULL OR GioKetThuc IS NULL
                     OR GioKetThuc<=GioBatDau)
            THROW 50106, ''Time backfill failed.'', 1;
        ALTER TABLE dbo.DatSan ALTER COLUMN GioBatDau time(0) NOT NULL;
        ALTER TABLE dbo.DatSan ALTER COLUMN GioKetThuc time(0) NOT NULL;';

    -- Replace only the obsolete slot uniqueness rule, not any table/business row.
    DROP INDEX UX_DatSan_KhongTrungLich ON dbo.DatSan;
    ALTER TABLE dbo.DatSan ALTER COLUMN MaKhungGio varchar(10) NULL;
    CREATE UNIQUE INDEX UX_DatSan_KhongTrungLich
        ON dbo.DatSan(MaSan,NgayChoi,MaKhungGio)
        WHERE TrangThai<>N'Đã hủy' AND MaKhungGio IS NOT NULL;

    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DatSan ADD
            CONSTRAINT CK_DatSan_KhoangGio CHECK (GioKetThuc>GioBatDau),
            CONSTRAINT CK_DatSan_CheDoGia CHECK
                (CheDoGia IN (''GIA_KHUNG'',''GIA_GIO'')),
            CONSTRAINT CK_DatSan_HinhThucDat CHECK
                (HinhThucDat IN (''KHONG_RO'',''TRUC_TUYEN'',''TAI_QUAY'')),
            CONSTRAINT CK_DatSan_GioMoi CHECK
                (CheDoGia=''GIA_KHUNG'' OR
                 (GioBatDau>=''07:00:00'' AND GioKetThuc<=''22:00:00''
                  AND DATEPART(SECOND,GioBatDau)=0
                  AND DATEPART(SECOND,GioKetThuc)=0));
        CREATE INDEX IX_DatSan_SanNgayBatDau
            ON dbo.DatSan(MaSan,NgayChoi,GioBatDau)
            INCLUDE(GioKetThuc,TrangThai);';

    CREATE TABLE dbo.GiaTheoCa (
        MaCa varchar(10) NOT NULL CONSTRAINT PK_GiaTheoCa PRIMARY KEY,
        GioBatDau time(0) NOT NULL,
        GioKetThuc time(0) NOT NULL,
        DonGia decimal(18,2) NOT NULL,
        CONSTRAINT CK_GiaTheoCa_DonGia CHECK (DonGia>0),
        CONSTRAINT CK_GiaTheoCa_Bien CHECK (
            (MaCa='SANG' AND GioBatDau='07:00:00' AND GioKetThuc='13:00:00') OR
            (MaCa='CHIEU' AND GioBatDau='13:00:00' AND GioKetThuc='19:00:00') OR
            (MaCa='TOI' AND GioBatDau='19:00:00' AND GioKetThuc='22:00:00'))
    );
    INSERT INTO dbo.GiaTheoCa(MaCa,GioBatDau,GioKetThuc,DonGia) VALUES
        ('SANG','07:00:00','13:00:00',90000),
        ('CHIEU','13:00:00','19:00:00',130000),
        ('TOI','19:00:00','22:00:00',180000);

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;

/* Rollout requirements, NOT implemented by this proposal:
   - use new times as snapshots, preserve GIA_KHUNG historical monetary values;
   - incoming legacy slot requests can resolve slot times, but NEW bookings use
     GIA_GIO official pricing; do not keep selling old prices after the transition;
   - mandatory San write lock -> interval conflict read -> booking insert in one
     transaction, shared by Java/procedures. This ordinary index is not an
     exclusion constraint and cannot prevent overlaps by itself;
   - all DTO/view/check-in/cancel/calendar mappings must use time snapshots;
   - preserve source values and verify pre/post snapshots in the rollout;
   - rollback deployment only after reviewing NEW free-time bookings; do not
     delete them or invent a slot in order to restore NOT NULL.
*/
