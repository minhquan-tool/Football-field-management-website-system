-- Read-only additions rollback; coordinate backend version first. No data changes.
DECLARE @Reviewed bit=0;
IF @Reviewed<>1 BEGIN PRINT 'Rollback disabled'; RETURN; END;
IF DB_NAME()<>'QuanLySanBong' THROW 50630,'Wrong database',1;
BEGIN TRANSACTION;
DROP VIEW dbo.V_Phase6_Revenue;
DROP VIEW dbo.V_Phase6_UsageBooking;
COMMIT;
