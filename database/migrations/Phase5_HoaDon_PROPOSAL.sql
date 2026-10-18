/* PROPOSAL ONLY — NOT EXECUTED.
   Review/approve invoice lifecycle before changing @ExecuteReviewedProposal.
   This creates ONE empty table, no DROP/reset/backfill/update of existing financial data.
   No change to DatSan, ChiTietDichVu, trigger, ThanhToan, HuyDatSan or HoanTien.
   Payments continue to link by MaDatSan; application transactions lock San -> DatSan -> HoaDon.
*/
USE QuanLySanBong;
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
DECLARE @ExecuteReviewedProposal bit=0;
IF @ExecuteReviewedProposal<>1
    THROW 50001,'Proposal only: explicit user review/approval required before execution',1;
IF OBJECT_ID(N'dbo.HoaDon',N'U') IS NOT NULL
    THROW 50002,'HoaDon already exists; inspect real schema rather than overwrite it',1;
IF OBJECT_ID(N'dbo.DatSan',N'U') IS NULL OR OBJECT_ID(N'dbo.KhachHang',N'U') IS NULL
    OR OBJECT_ID(N'dbo.NhanVien',N'U') IS NULL
    THROW 50003,'Required existing dependencies missing',1;
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE TABLE dbo.HoaDon (
        MaHoaDon varchar(10) NOT NULL,
        MaDatSan varchar(10) NOT NULL,
        MaKH varchar(10) NOT NULL,
        MaNVLap varchar(10) NOT NULL,
        NgayLap datetime NOT NULL DEFAULT GETDATE(),
        TienSan decimal(18,2) NOT NULL,
        TienDichVu decimal(18,2) NOT NULL,
        TienGiam decimal(18,2) NOT NULL,
        TongTien decimal(18,2) NOT NULL,
        TrangThai nvarchar(20) NOT NULL DEFAULT N'Chưa thanh toán',
        CONSTRAINT PK_HoaDon PRIMARY KEY (MaHoaDon),
        CONSTRAINT UQ_HoaDon_DatSan UNIQUE (MaDatSan),
        CONSTRAINT FK_HoaDon_DatSan FOREIGN KEY (MaDatSan) REFERENCES dbo.DatSan(MaDatSan),
        CONSTRAINT FK_HoaDon_KhachHang FOREIGN KEY (MaKH) REFERENCES dbo.KhachHang(MaKH),
        CONSTRAINT FK_HoaDon_NhanVien FOREIGN KEY (MaNVLap) REFERENCES dbo.NhanVien(MaNV),
        CONSTRAINT CK_HoaDon_Tien CHECK (TienSan>=0 AND TienDichVu>=0 AND TienGiam>=0
            AND TongTien>=0 AND TongTien=TienSan+TienDichVu-TienGiam),
        CONSTRAINT CK_HoaDon_TrangThai CHECK (TrangThai IN (N'Chưa thanh toán',N'Đã thanh toán',N'Đã hủy'))
    );
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
GO
/* After approval, implement and test BEFORE enabling financial UI:
   - snapshot under existing pitch/booking locks; validate MaKH agrees with the booking;
   - prohibit changing service/discount after issuance, return the existing invoice on retries;
   - no automatic inference/backfill of historical invoices or payments;
   - define one-full-payment versus installments explicitly; no pretend bank gateway;
   - preserve original ThanhToan rows on cancellation/refund; authorized staff record actual handling;
   - approve refund eligibility/rate/authority, calculate amounts server-side and lock/refuse repeats.
*/
