SET NOCOUNT ON;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
IF (DB_NAME()<>N'QuanLySanBong_Test' AND DB_NAME() NOT LIKE N'QuanLySanBong[_]Fixtures[_]%')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongEnvironment' AND CONVERT(nvarchar(20),value)=N'test')
 THROW 51410,'Select a NEW test database created by the full installer; operating DB forbidden',1;
IF @@TRANCOUNT<>0 THROW 51411,'Close previous transaction',1;
IF dbo.fn_TyLeHoan('20261028 20:00','20261028 10:00')<>100
 OR dbo.fn_TyLeHoan('20261028 20:00','20261028 18:00')<>50
 OR dbo.fn_TyLeHoan('20261028 20:00','20261028 18:01')<>0 THROW 51416,'Refund boundaries incorrect',1;
IF (SELECT COUNT(*) FROM dbo.fn_ReportDays('20261001','20261003'))<>3 THROW 51417,'Inclusive report dates incorrect',1;
IF EXISTS(SELECT 1 FROM dbo.fn_ReportDays('20261003','20261001')) THROW 51418,'Reversed days accepted',1;
SELECT N'PASS' AS Functions;
