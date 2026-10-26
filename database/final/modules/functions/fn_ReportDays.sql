USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_ReportDays(@From date,@To date) RETURNS TABLE AS RETURN (WITH digits(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))x(n)) SELECT DATEADD(day,a.n+10*b.n+100*c.n,@From) Ngay FROM digits a CROSS JOIN digits b CROSS JOIN digits c WHERE @From IS NOT NULL AND @To>=@From AND DATEDIFF(day,@From,@To)<=366 AND a.n+10*b.n+100*c.n<=DATEDIFF(day,@From,@To));
GO
