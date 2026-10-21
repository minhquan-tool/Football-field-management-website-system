/* PROPOSAL ONLY. Not applied by the app or by this task.
   Requires review/approval and verification against the target schema.
   Keep DatSan occupied until approval; do not turn a request into a cancellation.
   Proposed refund policy: snapshot rate at request time, cap final refund to actual
   confirmed net receipts at approval; keep existing legacy cancellation snapshots.
*/
THROW 51000, 'Proposal only: review and explicitly approve before applying.', 1;
GO
CREATE TABLE dbo.YeuCauHuyDatSan (
 MaYeuCau VARCHAR(10) NOT NULL PRIMARY KEY,
 MaDatSan VARCHAR(10) NOT NULL REFERENCES dbo.DatSan(MaDatSan),
 MaTKGui VARCHAR(10) NOT NULL REFERENCES dbo.TaiKhoan(MaTK),
 NgayGui DATETIME2(7) NOT NULL,
 LyDo NVARCHAR(255) NOT NULL,
 TrangThai VARCHAR(20) NOT NULL DEFAULT 'PENDING',
 TiLeHoanUocTinh DECIMAL(5,2) NOT NULL,
 ThucThuTaiGui DECIMAL(18,2) NOT NULL,
 TienHoanUocTinh DECIMAL(18,2) NOT NULL,
 MaTKXuLy VARCHAR(10) NULL REFERENCES dbo.TaiKhoan(MaTK),
 NgayXuLy DATETIME2(7) NULL,
 GhiChuXuLy NVARCHAR(255) NULL,
 MaHuy VARCHAR(10) NULL REFERENCES dbo.HuyDatSan(MaHuy),
 PhienBan ROWVERSION,
 CONSTRAINT CK_YeuCauHuy_TrangThai CHECK(TrangThai IN('PENDING','APPROVED','REJECTED')),
 CONSTRAINT CK_YeuCauHuy_Tien CHECK(TiLeHoanUocTinh BETWEEN 0 AND 100 AND ThucThuTaiGui>=0 AND TienHoanUocTinh>=0 AND TienHoanUocTinh<=ThucThuTaiGui),
 CONSTRAINT CK_YeuCauHuy_XuLy CHECK(
  (TrangThai='PENDING' AND MaTKXuLy IS NULL AND NgayXuLy IS NULL AND MaHuy IS NULL) OR
  (TrangThai='APPROVED' AND MaTKXuLy IS NOT NULL AND NgayXuLy IS NOT NULL AND MaHuy IS NOT NULL) OR
  (TrangThai='REJECTED' AND MaTKXuLy IS NOT NULL AND NgayXuLy IS NOT NULL AND MaHuy IS NULL))
);
CREATE UNIQUE INDEX UX_YeuCauHuy_Pending ON dbo.YeuCauHuyDatSan(MaDatSan) WHERE TrangThai='PENDING';
/* Approval and cancellation must share a San -> DatSan transaction, recheck
   check-in/time/payment states, create HuyDatSan/HoanTien through audited services,
   handle retries idempotently, and close stale requests if staff cancels elsewhere.
   Review changes to CN02/CN04 endpoint permissions separately; do not grant by UI.
*/
