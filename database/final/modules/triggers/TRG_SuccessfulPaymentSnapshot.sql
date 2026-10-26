USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.TRG_SuccessfulPaymentSnapshot ON dbo.ThanhToan AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM deleted WHERE TrangThai=N'Thành công'
 EXCEPT SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM inserted)
 THROW 51025,'A received payment is immutable; record a separate authorized refund',1;
 END;
GO
