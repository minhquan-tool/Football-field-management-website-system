/* Guarded rollback. Coordinate pre-5.1C backend; do not discard real finance history. */
DECLARE @ExecuteReviewedRollback bit=0;
IF @ExecuteReviewedRollback<>1 BEGIN PRINT 'Rollback disabled'; RETURN; END;
IF DB_NAME()<>'QuanLySanBong' THROW 50510,'Wrong database',1;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM dbo.HoaDon) OR EXISTS(SELECT 1 FROM dbo.HuyDatSan WHERE SoTienThucThuSnapshot IS NOT NULL)
 OR EXISTS(SELECT 1 FROM dbo.HoanTien WHERE NgayXacNhan IS NOT NULL OR LyDo IS NOT NULL)
 OR EXISTS(SELECT 1 FROM dbo.ThanhToan WHERE MaGiaoDich IS NOT NULL)
 BEGIN ROLLBACK; THROW 50511,'New financial history exists; rollback refused',1; END;
DROP VIEW dbo.V_ThuChiThucNhan;
DROP FUNCTION dbo.fn_TyLeHoan;
DROP TABLE dbo.HoaDon;
DROP INDEX IX_ThanhToan_BookingState ON dbo.ThanhToan;
DROP INDEX UX_ThanhToan_Idempotency ON dbo.ThanhToan;
DROP INDEX UX_HoanTien_CancellationPayment ON dbo.HoanTien;
ALTER TABLE dbo.HoanTien DROP COLUMN NgayXacNhan,LyDo;
ALTER TABLE dbo.HuyDatSan DROP CONSTRAINT CK_Huy_ThucThu;
ALTER TABLE dbo.HuyDatSan DROP COLUMN SoTienThucThuSnapshot;
DECLARE @df sysname=(SELECT name FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('dbo.HuyDatSan') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.HuyDatSan'),'NgayHuy','ColumnId'));
DECLARE @ddl nvarchar(max);
 IF @df IS NOT NULL BEGIN SET @ddl=N'ALTER TABLE dbo.HuyDatSan DROP CONSTRAINT '+QUOTENAME(@df); EXEC(@ddl); END;
ALTER TABLE dbo.HuyDatSan ALTER COLUMN NgayHuy datetime NOT NULL;
IF @df IS NOT NULL BEGIN SET @ddl=N'ALTER TABLE dbo.HuyDatSan ADD CONSTRAINT '+QUOTENAME(@df)+N' DEFAULT GETDATE() FOR NgayHuy'; EXEC(@ddl); END;
COMMIT;
