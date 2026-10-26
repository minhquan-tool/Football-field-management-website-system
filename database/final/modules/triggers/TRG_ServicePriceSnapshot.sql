USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.TRG_ServicePriceSnapshot ON dbo.ChiTietDichVu AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM inserted
 EXCEPT SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM deleted)
 THROW 51024,'Service SKU/price snapshot is immutable; only quantity may change before financial closing',1;
 END;
GO
