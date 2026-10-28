-- Catalog update authorized by user on 2026-10-19; preserve all booking snapshots.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'QuanLySanBong' THROW 50901,'Unexpected database',1;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=N'KM02' AND TenKM LIKE N'%Giờ vàng thứ Tư%') THROW 50902,'Wednesday promotion differs',1;
IF EXISTS(SELECT 1 FROM dbo.KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=N'SAN20' AND (MucGiam<>20 OR LoaiGiam<>N'Phần trăm' OR NgayBatDau<>'20261019' OR NgayKetThuc<>'20261231')) THROW 50903,'SAN20 exists with another policy',1;
UPDATE dbo.KhuyenMai SET TrangThai=0 WHERE MaKM IN(N'KM01',N'KM03') AND TrangThai=1;
IF NOT EXISTS(SELECT 1 FROM dbo.KhuyenMai WHERE MaKM=N'SAN20')
 INSERT dbo.KhuyenMai(MaKM,TenKM,LoaiGiam,MucGiam,DieuKien,NgayBatDau,NgayKetThuc,TrangThai)
 VALUES(N'SAN20',N'Ưu đãi sân bóng giảm 20%',N'Phần trăm',20,N'','20261019','20261231',1);
INSERT dbo.NhatKyHeThong(MaNhatKy,MaTK,ThaoTac,ChucNang,DoiTuong,NoiDungThayDoi)
 VALUES(LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),15),N'TK01',N'Sửa',N'Khuyến mãi',N'SAN20',N'Tác vụ bảo trì Codex theo yêu cầu người dùng; nhật ký gắn tài khoản quản trị TK01 (không phải phiên đăng nhập TK01): ngừng KM01/KM03, giữ KM02, thêm SAN20 giảm 20% tiền sân từ 19/10/2026 đến 31/12/2026. Không sửa snapshot booking hoặc lịch sử tài chính.');
COMMIT;
SELECT MaKM,TenKM,MucGiam,NgayBatDau,NgayKetThuc,TrangThai FROM dbo.KhuyenMai ORDER BY MaKM;
