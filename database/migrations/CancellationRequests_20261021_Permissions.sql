/* Cancellation queue: object-scoped permissions only; no DELETE or role changes. */
SET XACT_ABORT ON;
IF DB_NAME()<>'QuanLySanBong' THROW 51001,'Wrong database',1;
IF OBJECT_ID('dbo.YeuCauHuyDatSan','U') IS NULL THROW 51004,'Apply cancellation queue migration first',1;
BEGIN TRANSACTION;
IF DATABASE_PRINCIPAL_ID('SanBongRuntimeRole') IS NOT NULL
 GRANT SELECT,INSERT,UPDATE ON dbo.YeuCauHuyDatSan TO SanBongRuntimeRole;
IF DATABASE_PRINCIPAL_ID('SanBongRuntime') IS NOT NULL
 GRANT SELECT,INSERT,UPDATE ON dbo.YeuCauHuyDatSan TO SanBongRuntime;
COMMIT TRANSACTION;
