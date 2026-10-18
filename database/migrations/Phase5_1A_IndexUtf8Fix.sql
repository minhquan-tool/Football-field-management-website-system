-- Apply with sqlcmd -f 65001 -b. Preserve Vietnamese cancelled status literally.
-- Repairs the initial migration invocation's codepage; no business rows change.
IF DB_NAME()<>'QuanLySanBong' THROW 50210,'Wrong database',1;
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
    DROP INDEX UX_DatSan_KhongTrungLich ON dbo.DatSan;
    CREATE UNIQUE INDEX UX_DatSan_KhongTrungLich ON dbo.DatSan(MaSan,NgayChoi,MaKhungGio)
        WHERE TrangThai<>N'Đã hủy' AND MaKhungGio IS NOT NULL;
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
