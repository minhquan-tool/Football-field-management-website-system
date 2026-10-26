/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 05: CÁC TRIGGER NGHIỆP VỤ & BẢO VỆ SNAPSHOT (TRIGGERS)
   Bao gồm 5 Trigger:
     - TRG_AuditContentImmutable: Nhật ký hệ thống chỉ được ghi thêm, chống sửa/xóa log
     - TRG_CapNhatTienDatSan: Tự động tổng hợp tiền dịch vụ vào đặt sân (DatSan.TienDichVu)
     - TRG_SealedInvoiceSnapshot: Hóa đơn đã chốt (DaChot=1) không được thay đổi snapshot tiền
     - TRG_ServicePriceSnapshot: Chi tiết dịch vụ không được sửa đơn giá sau khi đã lưu
     - TRG_SuccessfulPaymentSnapshot: Thanh toán thành công là bất biến, muốn trả lại phải qua HoanTien
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- TRIGGER: TRG_AuditContentImmutable
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_AuditContentImmutable ON dbo.NhatKyHeThong AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT * FROM inserted EXCEPT SELECT * FROM deleted)
 THROW 51023,'Audit records are append-only; content cannot be rewritten',1;
 END;
GO

-- ------------------------------------------------------------
-- TRIGGER: TRG_CapNhatTienDatSan
-- ------------------------------------------------------------
/* ============================================================
   9. TRIGGER TỰ ĐỘNG TÍNH TIỀN CHO PHIẾU ĐẶT SÂN (RB5)
   ============================================================ */
CREATE OR ALTER TRIGGER TRG_CapNhatTienDatSan
ON ChiTietDichVu
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ds AS (
        SELECT MaDatSan FROM inserted
        UNION
        SELECT MaDatSan FROM deleted
    )
    UPDATE d
    SET    d.TienDichVu = ISNULL(ct.Tong, 0)
    FROM   DatSan d
           JOIN ds ON ds.MaDatSan = d.MaDatSan
           OUTER APPLY (SELECT SUM(ThanhTien) AS Tong
                        FROM ChiTietDichVu c
                        WHERE c.MaDatSan = d.MaDatSan) ct;
END;
GO

-- ------------------------------------------------------------
-- TRIGGER: TRG_SealedInvoiceSnapshot
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_SealedInvoiceSnapshot ON dbo.HoaDon AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM deleted WHERE DaChot=1
 EXCEPT SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM inserted)
 THROW 51026,'Sealed invoice identity and amounts cannot change; received total/status may be synchronized',1;
 END;
GO

-- ------------------------------------------------------------
-- TRIGGER: TRG_ServicePriceSnapshot
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_ServicePriceSnapshot ON dbo.ChiTietDichVu AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM inserted
 EXCEPT SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM deleted)
 THROW 51024,'Service SKU/price snapshot is immutable; only quantity may change before financial closing',1;
 END;
GO

-- ------------------------------------------------------------
-- TRIGGER: TRG_SuccessfulPaymentSnapshot
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_SuccessfulPaymentSnapshot ON dbo.ThanhToan AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM deleted WHERE TrangThai=N'Thành công'
 EXCEPT SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM inserted)
 THROW 51025,'A received payment is immutable; record a separate authorized refund',1;
 END;
GO

