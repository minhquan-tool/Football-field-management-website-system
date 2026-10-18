-- Separate approval required for creating service SKUs. No DELETE or price history rewrites.
:ON ERROR EXIT
SET XACT_ABORT ON;
IF DB_NAME() IN ('master','model','msdb','tempdb') THROW 50800,'Select application database explicitly',1;
IF DATABASE_PRINCIPAL_ID('SanBongApp') IS NULL THROW 50801,'Expected runtime user is missing',1;
GRANT INSERT ON dbo.DichVu TO SanBongApp;
