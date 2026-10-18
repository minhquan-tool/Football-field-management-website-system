-- Phase 2: thêm quyền mặc định còn thiếu; không thay schema/reset dữ liệu.
USE QuanLySanBong;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO PhanQuyen (MaVaiTro,MaChucNang,Xem,Them,Sua,Xoa)
SELECT r.MaVaiTro,c.MaChucNang,1,1,1,1
FROM VaiTro r CROSS JOIN ChucNang c
WHERE r.MaVaiTro='VT04' AND NOT EXISTS (
    SELECT 1 FROM PhanQuyen p WHERE p.MaVaiTro=r.MaVaiTro AND p.MaChucNang=c.MaChucNang);
INSERT INTO PhanQuyen (MaVaiTro,MaChucNang,Xem,Them,Sua,Xoa)
SELECT v.MaVaiTro,v.MaChucNang,v.Xem,v.Them,v.Sua,v.Xoa
FROM (VALUES
 ('VT01','CN02',1,1,1,0), ('VT01','CN04',1,1,0,0), ('VT01','CN05',1,1,0,0),
 ('VT02','CN01',1,1,1,0), ('VT02','CN02',1,1,1,0), ('VT02','CN03',1,1,1,0),
 ('VT02','CN04',1,1,0,0), ('VT02','CN05',1,0,1,0),
 ('VT03','CN04',1,1,1,0), ('VT03','CN06',1,1,0,0)
) v(MaVaiTro,MaChucNang,Xem,Them,Sua,Xoa)
WHERE NOT EXISTS (SELECT 1 FROM PhanQuyen p WHERE p.MaVaiTro=v.MaVaiTro AND p.MaChucNang=v.MaChucNang);
COMMIT;
GO
