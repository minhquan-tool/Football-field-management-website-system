USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.TRG_SealedInvoiceSnapshot ON dbo.HoaDon AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM deleted WHERE DaChot=1
 EXCEPT SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM inserted)
 THROW 51026,'Sealed invoice identity and amounts cannot change; received total/status may be synchronized',1;
 END;
GO
