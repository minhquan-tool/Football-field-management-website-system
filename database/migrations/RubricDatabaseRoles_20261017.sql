/* Four database roles, separate from web role rows. Demo users WITHOUT LOGIN:
   no passwords, server privileges, pool changes or membership for SanBongApp.
   Backend continues enforcing web role and row ownership on every request. */
SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' THROW 51030,'Wrong reviewed database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value) IN(N'dev',N'test')) THROW 51031,'DEV/test marker required',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF DATABASE_PRINCIPAL_ID(N'SB_Customer') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'SB_PitchStaff') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'SB_Accountant') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'SB_Manager') IS NOT NULL THROW 51032,'Roles already exist; no silent overwrite',1;
 CREATE ROLE SB_Customer;
 CREATE ROLE SB_PitchStaff;
 CREATE ROLE SB_Accountant;
 CREATE ROLE SB_Manager;
 CREATE USER SB_DemoCustomer WITHOUT LOGIN;
 CREATE USER SB_DemoPitchStaff WITHOUT LOGIN;
 CREATE USER SB_DemoAccountant WITHOUT LOGIN;
 CREATE USER SB_DemoManager WITHOUT LOGIN;
 ALTER ROLE SB_Customer ADD MEMBER SB_DemoCustomer;
 ALTER ROLE SB_PitchStaff ADD MEMBER SB_DemoPitchStaff;
 ALTER ROLE SB_Accountant ADD MEMBER SB_DemoAccountant;
 ALTER ROLE SB_Manager ADD MEMBER SB_DemoManager;
 GRANT SELECT ON dbo.San TO SB_Customer;
 GRANT SELECT ON dbo.LoaiSan TO SB_Customer;
 GRANT SELECT ON dbo.DichVu TO SB_Customer;
 DENY SELECT ON dbo.TaiKhoan TO SB_Customer;
 DENY SELECT ON dbo.ThanhToan TO SB_Customer;
 GRANT SELECT ON dbo.San TO SB_PitchStaff;
 GRANT SELECT ON dbo.LoaiSan TO SB_PitchStaff;
 GRANT SELECT ON dbo.DichVu TO SB_PitchStaff;
 GRANT EXECUTE ON dbo.usp_ReportUsage TO SB_PitchStaff;
 DENY EXECUTE ON dbo.usp_ReportFinance TO SB_PitchStaff;
 GRANT SELECT ON dbo.V_ThuChiThucNhan TO SB_Accountant;
 GRANT EXECUTE ON dbo.usp_ReportFinance TO SB_Accountant;
 GRANT EXECUTE ON dbo.usp_ReportPaymentMethods TO SB_Accountant;
 GRANT EXECUTE ON dbo.usp_ReportReconciliation TO SB_Accountant;
 GRANT EXECUTE ON dbo.usp_ReportTopServices TO SB_Accountant;
 GRANT EXECUTE ON dbo.fn_TyLeHoan TO SB_Accountant;
 GRANT EXECUTE ON dbo.usp_ReportUsage TO SB_Manager;
 GRANT EXECUTE ON dbo.usp_ReportFinance TO SB_Manager;
 GRANT EXECUTE ON dbo.usp_ReportPaymentMethods TO SB_Manager;
 GRANT EXECUTE ON dbo.usp_ReportReconciliation TO SB_Manager;
 GRANT EXECUTE ON dbo.usp_ReportTopServices TO SB_Manager;
 GRANT SELECT,INSERT,UPDATE ON dbo.San TO SB_Manager;
 GRANT SELECT ON dbo.NhatKyHeThong TO SB_Manager;
 DENY UPDATE,DELETE ON dbo.NhatKyHeThong TO SB_Manager;
 DENY DELETE ON dbo.ThanhToan TO SB_Manager;
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
