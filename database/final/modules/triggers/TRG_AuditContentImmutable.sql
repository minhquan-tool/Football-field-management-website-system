USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.TRG_AuditContentImmutable ON dbo.NhatKyHeThong AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT * FROM inserted EXCEPT SELECT * FROM deleted)
 THROW 51023,'Audit records are append-only; content cannot be rewritten',1;
 END;
GO
