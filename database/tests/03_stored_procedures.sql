SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
EXEC dbo.usp_ReportFinance @From='20261001',@To='20261028';
EXEC dbo.usp_ReportUsage @From='20261001',@To='20261028';
EXEC dbo.usp_ReportPaymentMethods @From='20261001',@To='20261028';
EXEC dbo.usp_ReportReconciliation @From='20261001',@To='20261028';
EXEC dbo.usp_ReportTopServices @Day='20261021';
DECLARE @rejected bit=0;
BEGIN TRY EXEC dbo.usp_ReportFinance @From='20261028',@To='20261001'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>51010 THROW; SET @rejected=1; END CATCH;
IF @rejected=0 THROW 51415,'Report accepted reversed dates',1;
SELECT N'PASS' AS StoredProcedures;
