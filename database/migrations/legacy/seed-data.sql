USE QuanLySanBong;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thêm nhân viên mẫu nếu chưa có
IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNV = 'NV01')
INSERT INTO NhanVien (MaNV, HoTen, SoDienThoai, Email, ChucVu, BoPhan, NgayVaoLam, TrangThai) VALUES
('NV01', N'Võ Minh Quân (Admin)', '0901000001', 'admin@fcute.vn', N'Quản trị viên', N'Quản trị hệ thống', '2025-01-01', 1),
('NV02', N'Văn Ngọc Hữu', '0901000002', 'huu.van@fcute.vn', N'Nhân viên vận hành', N'Nhân viên sân bóng', '2025-02-01', 1),
('NV03', N'Trần Thị Mai', '0901000003', 'mai.tran@fcute.vn', N'Kế toán trưởng', N'Kế toán', '2025-02-15', 1);
GO

-- 2. Thêm khách hàng mẫu nếu chưa có
IF NOT EXISTS (SELECT 1 FROM KhachHang WHERE MaKH = 'KH01')
INSERT INTO KhachHang (MaKH, HoTen, SoDienThoai, Email, DiaChi, NgayDangKy, GhiChu) VALUES
('KH01', N'Võ Minh Quân', '0987654321', 'quan.vo@student.hcmute.edu.vn', N'01 Võ Văn Ngân, TP. Thủ Đức', '2026-01-10', N'Thành viên Bạc'),
('KH02', N'Nguyễn Văn An', '0912345678', 'an.nguyen@gmail.com', N'Lê Văn Việt, TP. Thủ Đức', '2026-02-01', N'Khách vãng lai'),
('KH03', N'Lê Hoàng Long', '0909112233', 'long.le@gmail.com', N'Đỗ Xuân Hợp, Quận 9', '2026-02-10', N'Khách cố định tối thứ 4');
GO

-- 3. Tài khoản mẫu dùng BCrypt; chỉ phục vụ dữ liệu demo.
IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = 'admin')
INSERT INTO TaiKhoan (MaTK, TenDangNhap, MatKhau, MaVaiTro, MaKH, MaNV, NgayTao, TrangThai) VALUES
('TK01', 'admin', '$2a$12$vekZmQ3WbxsLYYYnCwLPcOi375AbgvLyUgrjm4l3rbKrDVfmtcFLW', 'VT04', NULL, 'NV01', GETDATE(), N'Hoạt động');

IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = 'nvsan')
INSERT INTO TaiKhoan (MaTK, TenDangNhap, MatKhau, MaVaiTro, MaKH, MaNV, NgayTao, TrangThai) VALUES
('TK02', 'nvsan', '$2a$12$vekZmQ3WbxsLYYYnCwLPcOi375AbgvLyUgrjm4l3rbKrDVfmtcFLW', 'VT02', NULL, 'NV02', GETDATE(), N'Hoạt động');

IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = 'ketoan')
INSERT INTO TaiKhoan (MaTK, TenDangNhap, MatKhau, MaVaiTro, MaKH, MaNV, NgayTao, TrangThai) VALUES
('TK03', 'ketoan', '$2a$12$vekZmQ3WbxsLYYYnCwLPcOi375AbgvLyUgrjm4l3rbKrDVfmtcFLW', 'VT03', NULL, 'NV03', GETDATE(), N'Hoạt động');

IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = 'khachhang')
INSERT INTO TaiKhoan (MaTK, TenDangNhap, MatKhau, MaVaiTro, MaKH, MaNV, NgayTao, TrangThai) VALUES
('TK04', 'khachhang', '$2a$12$vekZmQ3WbxsLYYYnCwLPcOi375AbgvLyUgrjm4l3rbKrDVfmtcFLW', 'VT01', 'KH01', NULL, GETDATE(), N'Hoạt động');
GO

-- 4. Bổ sung các sân còn thiếu (S04, S05, S06)
IF NOT EXISTS (SELECT 1 FROM San WHERE MaSan = 'S04')
INSERT INTO San (MaSan, TenSan, MaLoaiSan, TrangThai, MoTa) VALUES
('S04', N'Sân A4', 'LS01', N'Trống', N'Sân cỏ nhân tạo 5 người, có mái che');

IF NOT EXISTS (SELECT 1 FROM San WHERE MaSan = 'S05')
INSERT INTO San (MaSan, TenSan, MaLoaiSan, TrangThai, MoTa) VALUES
('S05', N'Sân B1', 'LS02', N'Trống', N'Sân 7 người, hệ thống đèn chuẩn thi đấu');

IF NOT EXISTS (SELECT 1 FROM San WHERE MaSan = 'S06')
INSERT INTO San (MaSan, TenSan, MaLoaiSan, TrangThai, MoTa) VALUES
('S06', N'Sân B2', 'LS02', N'Bảo trì', N'Sân 7 người, đang bảo dưỡng mặt cỏ');
GO

-- Cập nhật tên sân S01, S02, S03 đồng bộ với UI
UPDATE San SET TenSan = N'Sân A1', MoTa = N'Sân cỏ nhân tạo 5 người - Đèn LED' WHERE MaSan = 'S01';
UPDATE San SET TenSan = N'Sân A2', MoTa = N'Sân cỏ nhân tạo 5 người - Đèn LED' WHERE MaSan = 'S02';
UPDATE San SET TenSan = N'Sân A3', TrangThai = N'Bảo trì', MoTa = N'Sân cỏ nhân tạo 5 người - Đang bảo trì' WHERE MaSan = 'S03';
GO

-- 5. Bổ sung bảng giá đầy đủ cho các khung giờ
IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG05')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG05', 'LS01', 'KG02', N'Ngày thường', 200000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG06')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG06', 'LS01', 'KG03', N'Ngày thường', 250000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG07')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG07', 'LS01', 'KG05', N'Ngày thường', 200000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG08')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG08', 'LS02', 'KG01', N'Ngày thường', 250000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG09')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG09', 'LS02', 'KG02', N'Ngày thường', 350000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG10')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG10', 'LS02', 'KG03', N'Ngày thường', 400000, '2026-01-01');

IF NOT EXISTS (SELECT 1 FROM BangGia WHERE MaBangGia = 'BG11')
INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
('BG11', 'LS02', 'KG05', N'Ngày thường', 300000, '2026-01-01');
GO

-- 6. Bổ sung chương trình khuyến mãi
IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE MaKM = 'KM01')
INSERT INTO KhuyenMai (MaKM, TenKM, LoaiGiam, MucGiam, DieuKien, NgayBatDau, NgayKetThuc, TrangThai) VALUES
('KM01', N'Ưu đãi sinh viên UTE (UTE2026)', N'Số tiền', 20000, N'Dành cho sinh viên có thẻ SV', '2026-01-01', '2026-12-31', 1);

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE MaKM = 'KM02')
INSERT INTO KhuyenMai (MaKM, TenKM, LoaiGiam, MucGiam, DieuKien, NgayBatDau, NgayKetThuc, TrangThai) VALUES
('KM02', N'Giờ vàng thứ Tư (VIP10)', N'Phần trăm', 10, N'Áp dụng ngày trong tuần', '2026-01-01', '2026-12-31', 1);

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE MaKM = 'KM03')
INSERT INTO KhuyenMai (MaKM, TenKM, LoaiGiam, MucGiam, DieuKien, NgayBatDau, NgayKetThuc, TrangThai) VALUES
('KM03', N'Chào bạn mới (CHAOSAN)', N'Số tiền', 30000, N'Dành cho khách hàng mới', '2026-01-01', '2026-12-31', 1);
GO

-- 7. Thêm lịch đặt sân mẫu
IF NOT EXISTS (SELECT 1 FROM DatSan WHERE MaDatSan = 'DS01')
INSERT INTO DatSan (MaDatSan, MaKH, MaSan, MaKhungGio, NgayChoi, ThoiLuong, DonGia, TienSan, TienDichVu, MaKM, TienGiam, TongTien, NgayDat, MaNV, TrangThai, GhiChu) VALUES
('DS01', 'KH01', 'S01', 'KG03', CAST(GETDATE() AS DATE), 1.5, 250000, 250000, 0, 'KM01', 20000, 230000, GETDATE(), 'NV02', N'Đã xác nhận', N'Đặt trực tuyến');

IF NOT EXISTS (SELECT 1 FROM DatSan WHERE MaDatSan = 'DS02')
INSERT INTO DatSan (MaDatSan, MaKH, MaSan, MaKhungGio, NgayChoi, ThoiLuong, DonGia, TienSan, TienDichVu, MaKM, TienGiam, TongTien, NgayDat, MaNV, TrangThai, GhiChu) VALUES
('DS02', 'KH02', 'S02', 'KG04', CAST(GETDATE() AS DATE), 1.5, 300000, 300000, 0, NULL, 0, 300000, GETDATE(), NULL, N'Đã xác nhận', N'Đặt trực tuyến');
GO

PRINT N'Hoàn tất nạp dữ liệu mẫu.';
GO

