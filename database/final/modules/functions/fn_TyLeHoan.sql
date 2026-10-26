USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_TyLeHoan
(
    @BatDau datetime2(7),
    @Huy datetime2(7)
)
RETURNS decimal(5,2)
AS
BEGIN
    RETURN
        CASE
            WHEN @Huy <= DATEADD(hour,-10,@BatDau) THEN 100
            WHEN @Huy <= DATEADD(hour,-2,@BatDau) THEN 50
            ELSE 0
        END;
END;
GO
