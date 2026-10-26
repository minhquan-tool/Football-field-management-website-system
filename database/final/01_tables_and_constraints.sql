/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 01: CƠ SỞ DỮ LIỆU, BẢNG VÀ RÀNG BUỘC TOÀN VẸN (DDL)
   Bao gồm:
     - 28 Bảng nghiệp vụ chuẩn hóa (Phase 1 -> Phase 7)
     - Khóa chính (PK), Khóa ngoại (FK), Ràng buộc duy nhất (UQ)
     - Ràng buộc kiểm tra (CHECK), Giá trị mặc định (DEFAULT)
     - Chỉ mục tối ưu hóa truy vấn (Non-Clustered Indexes, Filtered Indexes)
   ========================================================================================= */

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLySanBong')
BEGIN
    CREATE DATABASE [QuanLySanBong];
END
GO

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ============================================================
-- BẢNG: VaiTro
-- ============================================================
IF OBJECT_ID(N'dbo.[VaiTro]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[VaiTro] (
        [MaVaiTro] varchar(10) NOT NULL,
        [TenVaiTro] nvarchar(50) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_VaiTro] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC)
    );
END
GO

-- ============================================================
-- BẢNG: ChucNang
-- ============================================================
IF OBJECT_ID(N'dbo.[ChucNang]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChucNang] (
        [MaChucNang] varchar(10) NOT NULL,
        [TenChucNang] nvarchar(100) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_ChucNang] PRIMARY KEY CLUSTERED ([MaChucNang] ASC)
    );
END
GO

-- ============================================================
-- BẢNG: LoaiSan
-- ============================================================
IF OBJECT_ID(N'dbo.[LoaiSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[LoaiSan] (
        [MaLoaiSan] varchar(10) NOT NULL,
        [TenLoaiSan] nvarchar(50) NOT NULL,
        [SoNguoi] int NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_LoaiSan] PRIMARY KEY CLUSTERED ([MaLoaiSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoaiSan_SoNguoi')
BEGIN
    ALTER TABLE dbo.[LoaiSan] ADD CONSTRAINT [CK_LoaiSan_SoNguoi] CHECK ([SoNguoi]>(0));
END
GO
-- ============================================================
-- BẢNG: KhungGio
-- ============================================================
IF OBJECT_ID(N'dbo.[KhungGio]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhungGio] (
        [MaKhungGio] varchar(10) NOT NULL,
        [GioBatDau] time(7) NOT NULL,
        [GioKetThuc] time(7) NOT NULL,
        [ThoiLuong] decimal(4, 2) NOT NULL,
        CONSTRAINT [PK_KhungGio] PRIMARY KEY CLUSTERED ([MaKhungGio] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhungGio_Gio')
BEGIN
    ALTER TABLE dbo.[KhungGio] ADD CONSTRAINT [CK_KhungGio_Gio] CHECK ([GioKetThuc]>[GioBatDau]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhungGio_ThoiLuong')
BEGIN
    ALTER TABLE dbo.[KhungGio] ADD CONSTRAINT [CK_KhungGio_ThoiLuong] CHECK ([ThoiLuong]>(0));
END
GO
-- ============================================================
-- BẢNG: KhachHang
-- ============================================================
IF OBJECT_ID(N'dbo.[KhachHang]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhachHang] (
        [MaKH] varchar(10) NOT NULL,
        [HoTen] nvarchar(100) NOT NULL,
        [SoDienThoai] varchar(15) NOT NULL,
        [Email] varchar(100) NULL,
        [DiaChi] nvarchar(255) NULL,
        [NgayDangKy] date CONSTRAINT [DF__KhachHang__NgayD__440B1D61] DEFAULT (getdate()) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_KhachHang] PRIMARY KEY CLUSTERED ([MaKH] ASC)
    );
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_KhachHang_SDT' AND object_id = OBJECT_ID(N'dbo.[KhachHang]'))
BEGIN
    DROP INDEX [UQ_KhachHang_SDT] ON dbo.[KhachHang];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_KhachHang_SDT] ON dbo.[KhachHang] ([SoDienThoai] ASC);
GO
-- ============================================================
-- BẢNG: NhanVien
-- ============================================================
IF OBJECT_ID(N'dbo.[NhanVien]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[NhanVien] (
        [MaNV] varchar(10) NOT NULL,
        [HoTen] nvarchar(100) NOT NULL,
        [SoDienThoai] varchar(15) NULL,
        [Email] varchar(100) NULL,
        [ChucVu] nvarchar(50) NULL,
        [BoPhan] nvarchar(50) NULL,
        [NgayVaoLam] date NULL,
        [TrangThai] bit CONSTRAINT [DF__NhanVien__TrangT__46E78A0C] DEFAULT ((1)) NOT NULL,
        CONSTRAINT [PK_NhanVien] PRIMARY KEY CLUSTERED ([MaNV] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_NhanVien_BoPhan')
BEGIN
    ALTER TABLE dbo.[NhanVien] ADD CONSTRAINT [CK_NhanVien_BoPhan] CHECK ([BoPhan]=N'Quản trị hệ thống' OR [BoPhan]=N'Kế toán' OR [BoPhan]=N'Nhân viên sân bóng');
END
GO
-- ============================================================
-- BẢNG: KhuyenMai
-- ============================================================
IF OBJECT_ID(N'dbo.[KhuyenMai]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[KhuyenMai] (
        [MaKM] varchar(10) NOT NULL,
        [TenKM] nvarchar(100) NOT NULL,
        [LoaiGiam] nvarchar(20) NOT NULL,
        [MucGiam] decimal(18, 2) NOT NULL,
        [DieuKien] nvarchar(255) NULL,
        [NgayBatDau] date NOT NULL,
        [NgayKetThuc] date NOT NULL,
        [TrangThai] bit CONSTRAINT [DF__KhuyenMai__Trang__66603565] DEFAULT ((1)) NOT NULL,
        CONSTRAINT [PK_KhuyenMai] PRIMARY KEY CLUSTERED ([MaKM] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_LoaiGiam')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_LoaiGiam] CHECK ([LoaiGiam]=N'Số tiền' OR [LoaiGiam]=N'Phần trăm');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_MucGiam')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_MucGiam] CHECK ([MucGiam]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_KhuyenMai_ThoiGian')
BEGIN
    ALTER TABLE dbo.[KhuyenMai] ADD CONSTRAINT [CK_KhuyenMai_ThoiGian] CHECK ([NgayKetThuc]>=[NgayBatDau]);
END
GO
-- ============================================================
-- BẢNG: DichVu
-- ============================================================
IF OBJECT_ID(N'dbo.[DichVu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DichVu] (
        [MaDV] varchar(10) NOT NULL,
        [TenDV] nvarchar(100) NOT NULL,
        [DonViTinh] nvarchar(20) NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [TrangThai] bit CONSTRAINT [DF__DichVu__TrangTha__7B5B524B] DEFAULT ((1)) NOT NULL,
        [HoTroLoc] bit CONSTRAINT [DF_DichVu_HoTroLoc] DEFAULT ((0)) NOT NULL,
        CONSTRAINT [PK_DichVu] PRIMARY KEY CLUSTERED ([MaDV] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DichVu_DonGia')
BEGIN
    ALTER TABLE dbo.[DichVu] ADD CONSTRAINT [CK_DichVu_DonGia] CHECK ([DonGia]>(0));
END
GO
-- ============================================================
-- BẢNG: TieuChiDanhGia
-- ============================================================
IF OBJECT_ID(N'dbo.[TieuChiDanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[TieuChiDanhGia] (
        [MaTieuChi] varchar(10) NOT NULL,
        [TenTieuChi] nvarchar(100) NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_TieuChiDanhGia] PRIMARY KEY CLUSTERED ([MaTieuChi] ASC)
    );
END
GO

-- ============================================================
-- BẢNG: GiaTheoCa
-- ============================================================
IF OBJECT_ID(N'dbo.[GiaTheoCa]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[GiaTheoCa] (
        [MaCa] varchar(10) NOT NULL,
        [GioBatDau] time(0) NOT NULL,
        [GioKetThuc] time(0) NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        CONSTRAINT [PK_GiaTheoCa] PRIMARY KEY CLUSTERED ([MaCa] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GiaTheoCa_Bien')
BEGIN
    ALTER TABLE dbo.[GiaTheoCa] ADD CONSTRAINT [CK_GiaTheoCa_Bien] CHECK ([MaCa]='SANG' AND [GioBatDau]='07:00:00' AND [GioKetThuc]='13:00:00' OR [MaCa]='CHIEU' AND [GioBatDau]='13:00:00' AND [GioKetThuc]='19:00:00' OR [MaCa]='TOI' AND [GioBatDau]='19:00:00' AND [GioKetThuc]='22:00:00');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GiaTheoCa_DonGia')
BEGIN
    ALTER TABLE dbo.[GiaTheoCa] ADD CONSTRAINT [CK_GiaTheoCa_DonGia] CHECK ([DonGia]>(0));
END
GO
-- ============================================================
-- BẢNG: BaoCao
-- ============================================================
IF OBJECT_ID(N'dbo.[BaoCao]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[BaoCao] (
        [MaBaoCao] varchar(10) NOT NULL,
        [LoaiBaoCao] nvarchar(50) NOT NULL,
        [NgayLap] date CONSTRAINT [DF__BaoCao__NgayLap__4A8310C6] DEFAULT (getdate()) NOT NULL,
        [TuNgay] date NOT NULL,
        [DenNgay] date NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [NoiDung] nvarchar(max) NULL,
        CONSTRAINT [PK_BaoCao] PRIMARY KEY CLUSTERED ([MaBaoCao] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BaoCao_ThoiGian')
BEGIN
    ALTER TABLE dbo.[BaoCao] ADD CONSTRAINT [CK_BaoCao_ThoiGian] CHECK ([DenNgay]>=[TuNgay]);
END
GO
-- ============================================================
-- BẢNG: SaoLuu
-- ============================================================
IF OBJECT_ID(N'dbo.[SaoLuu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[SaoLuu] (
        [MaSaoLuu] varchar(10) NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [ThoiGian] datetime CONSTRAINT [DF__SaoLuu__ThoiGian__44CA3770] DEFAULT (getdate()) NOT NULL,
        [LoaiThaoTac] nvarchar(20) NOT NULL,
        [DuongDan] nvarchar(255) NULL,
        [KetQua] bit CONSTRAINT [DF__SaoLuu__KetQua__45BE5BA9] DEFAULT ((1)) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_SaoLuu] PRIMARY KEY CLUSTERED ([MaSaoLuu] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_SaoLuu_LoaiThaoTac')
BEGIN
    ALTER TABLE dbo.[SaoLuu] ADD CONSTRAINT [CK_SaoLuu_LoaiThaoTac] CHECK ([LoaiThaoTac]=N'Phục hồi' OR [LoaiThaoTac]=N'Sao lưu');
END
GO
-- ============================================================
-- BẢNG: PhanQuyen
-- ============================================================
IF OBJECT_ID(N'dbo.[PhanQuyen]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[PhanQuyen] (
        [MaVaiTro] varchar(10) NOT NULL,
        [MaChucNang] varchar(10) NOT NULL,
        [Xem] bit CONSTRAINT [DF__PhanQuyen__Xem__3B75D760] DEFAULT ((0)) NOT NULL,
        [Them] bit CONSTRAINT [DF__PhanQuyen__Them__3C69FB99] DEFAULT ((0)) NOT NULL,
        [Sua] bit CONSTRAINT [DF__PhanQuyen__Sua__3D5E1FD2] DEFAULT ((0)) NOT NULL,
        [Xoa] bit CONSTRAINT [DF__PhanQuyen__Xoa__3E52440B] DEFAULT ((0)) NOT NULL,
        CONSTRAINT [PK_PhanQuyen] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC, [MaChucNang] ASC)
    );
END
GO

-- ============================================================
-- BẢNG: TaiKhoan
-- ============================================================
IF OBJECT_ID(N'dbo.[TaiKhoan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[TaiKhoan] (
        [MaTK] varchar(10) NOT NULL,
        [TenDangNhap] varchar(50) NOT NULL,
        [MatKhau] varchar(255) NOT NULL,
        [MaVaiTro] varchar(10) NOT NULL,
        [MaKH] varchar(10) NULL,
        [MaNV] varchar(10) NULL,
        [NgayTao] datetime CONSTRAINT [DF__TaiKhoan__NgayTa__4BAC3F29] DEFAULT (getdate()) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__TaiKhoan__TrangT__4CA06362] DEFAULT (N'Hoạt động') NOT NULL,
        CONSTRAINT [PK_TaiKhoan] PRIMARY KEY CLUSTERED ([MaTK] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TaiKhoan_ChuSoHuu')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] ADD CONSTRAINT [CK_TaiKhoan_ChuSoHuu] CHECK ([MaKH] IS NULL AND [MaNV] IS NOT NULL OR [MaKH] IS NOT NULL AND [MaNV] IS NULL);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TaiKhoan_TrangThai')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] ADD CONSTRAINT [CK_TaiKhoan_TrangThai] CHECK ([TrangThai]=N'Khóa' OR [TrangThai]=N'Hoạt động');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_TaiKhoan_TenDangNhap' AND object_id = OBJECT_ID(N'dbo.[TaiKhoan]'))
BEGIN
    DROP INDEX [UQ_TaiKhoan_TenDangNhap] ON dbo.[TaiKhoan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaiKhoan_TenDangNhap] ON dbo.[TaiKhoan] ([TenDangNhap] ASC);
GO
-- ============================================================
-- BẢNG: San
-- ============================================================
IF OBJECT_ID(N'dbo.[San]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[San] (
        [MaSan] varchar(10) NOT NULL,
        [TenSan] nvarchar(50) NOT NULL,
        [MaLoaiSan] varchar(10) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__San__TrangThai__571DF1D5] DEFAULT (N'Trống') NOT NULL,
        [MoTa] nvarchar(255) NULL,
        CONSTRAINT [PK_San] PRIMARY KEY CLUSTERED ([MaSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_San_TrangThai')
BEGIN
    ALTER TABLE dbo.[San] ADD CONSTRAINT [CK_San_TrangThai] CHECK ([TrangThai]=N'Bảo trì' OR [TrangThai]=N'Đang sử dụng' OR [TrangThai]=N'Trống');
END
GO
-- ============================================================
-- BẢNG: BangGia
-- ============================================================
IF OBJECT_ID(N'dbo.[BangGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[BangGia] (
        [MaBangGia] varchar(10) NOT NULL,
        [MaLoaiSan] varchar(10) NOT NULL,
        [MaKhungGio] varchar(10) NOT NULL,
        [LoaiNgay] nvarchar(20) NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [NgayHieuLuc] date NOT NULL,
        [NgayHetHieuLuc] date NULL,
        CONSTRAINT [PK_BangGia] PRIMARY KEY CLUSTERED ([MaBangGia] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_DonGia')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_DonGia] CHECK ([DonGia]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_HieuLuc')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_HieuLuc] CHECK ([NgayHetHieuLuc] IS NULL OR [NgayHetHieuLuc]>=[NgayHieuLuc]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_BangGia_LoaiNgay')
BEGIN
    ALTER TABLE dbo.[BangGia] ADD CONSTRAINT [CK_BangGia_LoaiNgay] CHECK ([LoaiNgay]=N'Ngày lễ' OR [LoaiNgay]=N'Cuối tuần' OR [LoaiNgay]=N'Ngày thường');
END
GO
-- ============================================================
-- BẢNG: DatSan
-- ============================================================
IF OBJECT_ID(N'dbo.[DatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DatSan] (
        [MaDatSan] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaSan] varchar(10) NOT NULL,
        [MaKhungGio] varchar(10) NULL,
        [NgayChoi] date NOT NULL,
        [DonGia] decimal(18, 2) NOT NULL,
        [TienDichVu] decimal(18, 2) CONSTRAINT [DF__DatSan__TienDich__6D0D32F4] DEFAULT ((0)) NOT NULL,
        [MaKM] varchar(10) NULL,
        [TienGiam] decimal(18, 2) CONSTRAINT [DF__DatSan__TienGiam__6E01572D] DEFAULT ((0)) NOT NULL,
        [NgayDat] datetime CONSTRAINT [DF__DatSan__NgayDat__6FE99F9F] DEFAULT (getdate()) NOT NULL,
        [MaNV] varchar(10) NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__DatSan__TrangTha__70DDC3D8] DEFAULT (N'Chờ xác nhận') NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        [GioBatDau] time(0) NOT NULL,
        [GioKetThuc] time(0) NOT NULL,
        [CheDoGia] varchar(12) CONSTRAINT [DF_DatSan_CheDoGia] DEFAULT ('GIA_KHUNG') NOT NULL,
        [HinhThucDat] varchar(12) CONSTRAINT [DF_DatSan_HinhThucDat] DEFAULT ('KHONG_RO') NOT NULL,
        [ThoiLuongLegacySnapshot] decimal(4, 2) NULL,
        [TienSanLegacySnapshot] decimal(18, 2) NULL,
        [ThoiLuong] AS (CONVERT([decimal](4,2),case when [CheDoGia]='GIA_KHUNG' then [ThoiLuongLegacySnapshot] else round(datediff(minute,[GioBatDau],[GioKetThuc])/(60.0),(2)) end)) PERSISTED,
        [TienSan] AS (CONVERT([decimal](18,2),case when [CheDoGia]='GIA_KHUNG' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)) PERSISTED,
        [TongTien] AS (CONVERT([decimal](18,2),(CONVERT([decimal](18,2),case when [CheDoGia]='GIA_KHUNG' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)+[TienDichVu])-[TienGiam])) PERSISTED,
        CONSTRAINT [PK_DatSan] PRIMARY KEY CLUSTERED ([MaDatSan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_CheDoGia')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_CheDoGia] CHECK ([CheDoGia]='GIA_GIO' OR [CheDoGia]='GIA_KHUNG');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_GioMoi')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_GioMoi] CHECK ([CheDoGia]='GIA_KHUNG' OR [GioBatDau]>='07:00:00' AND [GioKetThuc]<='22:00:00' AND datepart(second,[GioBatDau])=(0) AND datepart(second,[GioKetThuc])=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_HinhThucDat')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_HinhThucDat] CHECK ([HinhThucDat]='TAI_QUAY' OR [HinhThucDat]='TRUC_TUYEN' OR [HinhThucDat]='KHONG_RO');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_KhoangGio')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_KhoangGio] CHECK ([GioKetThuc]>[GioBatDau]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_LegacySnapshots')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_LegacySnapshots] CHECK ([CheDoGia]='GIA_KHUNG' AND [ThoiLuongLegacySnapshot] IS NOT NULL AND [ThoiLuongLegacySnapshot]>(0) AND [TienSanLegacySnapshot] IS NOT NULL AND [TienSanLegacySnapshot]>=(0) OR [CheDoGia]='GIA_GIO' AND [ThoiLuongLegacySnapshot] IS NULL AND [TienSanLegacySnapshot] IS NULL);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_ThoiLuong')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_ThoiLuong] CHECK ([ThoiLuong] IS NOT NULL AND [ThoiLuong]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_Tien')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_Tien] CHECK ([DonGia]>(0) AND [TienSan] IS NOT NULL AND [TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TongTien]>=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatSan_TrangThai')
BEGIN
    ALTER TABLE dbo.[DatSan] ADD CONSTRAINT [CK_DatSan_TrangThai] CHECK ([TrangThai]=N'Đã hủy' OR [TrangThai]=N'Đã sử dụng' OR [TrangThai]=N'Đã xác nhận' OR [TrangThai]=N'Chờ xác nhận');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DatSan_SanNgayBatDau' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    DROP INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan];
END
GO
CREATE NONCLUSTERED INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [GioBatDau] ASC) INCLUDE ([GioKetThuc], [TrangThai]);
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_DatSan_KhongTrungLich' AND object_id = OBJECT_ID(N'dbo.[DatSan]'))
BEGIN
    DROP INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan] ([MaSan] ASC, [NgayChoi] ASC, [MaKhungGio] ASC) WHERE ([TrangThai]<>N'Đã hủy' AND [MaKhungGio] IS NOT NULL);
GO
-- ============================================================
-- BẢNG: NhatKyHeThong
-- ============================================================
IF OBJECT_ID(N'dbo.[NhatKyHeThong]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[NhatKyHeThong] (
        [MaNhatKy] varchar(15) NOT NULL,
        [MaTK] varchar(10) NOT NULL,
        [ThoiGian] datetime CONSTRAINT [DF__NhatKyHeT__ThoiG__3F115E1A] DEFAULT (getdate()) NOT NULL,
        [ChucNang] nvarchar(100) NULL,
        [ThaoTac] nvarchar(20) NOT NULL,
        [DoiTuong] nvarchar(100) NULL,
        [NoiDungThayDoi] nvarchar(500) NULL,
        [KetQua] bit CONSTRAINT [DF__NhatKyHeT__KetQu__40058253] DEFAULT ((1)) NOT NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_NhatKyHeThong] PRIMARY KEY CLUSTERED ([MaNhatKy] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_NhatKy_ThaoTac')
BEGIN
    ALTER TABLE dbo.[NhatKyHeThong] ADD CONSTRAINT [CK_NhatKy_ThaoTac] CHECK ([ThaoTac]=N'Đăng xuất' OR [ThaoTac]=N'Đăng nhập' OR [ThaoTac]=N'Xóa' OR [ThaoTac]=N'Sửa' OR [ThaoTac]=N'Thêm');
END
GO
-- ============================================================
-- BẢNG: XacNhanSan
-- ============================================================
IF OBJECT_ID(N'dbo.[XacNhanSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[XacNhanSan] (
        [MaXacNhan] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaNV] varchar(10) NOT NULL,
        [ThoiGianNhan] datetime NOT NULL,
        [ThoiGianKetThuc] datetime NULL,
        [TinhTrangSan] nvarchar(255) NULL,
        [GhiChu] nvarchar(255) NULL,
        CONSTRAINT [PK_XacNhanSan] PRIMARY KEY CLUSTERED ([MaXacNhan] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_XacNhanSan_ThoiGian')
BEGIN
    ALTER TABLE dbo.[XacNhanSan] ADD CONSTRAINT [CK_XacNhanSan_ThoiGian] CHECK ([ThoiGianKetThuc] IS NULL OR [ThoiGianKetThuc]>=[ThoiGianNhan]);
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_XacNhanSan_DatSan' AND object_id = OBJECT_ID(N'dbo.[XacNhanSan]'))
BEGIN
    DROP INDEX [UQ_XacNhanSan_DatSan] ON dbo.[XacNhanSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_XacNhanSan_DatSan] ON dbo.[XacNhanSan] ([MaDatSan] ASC);
GO
-- ============================================================
-- BẢNG: ChiTietDichVu
-- ============================================================
IF OBJECT_ID(N'dbo.[ChiTietDichVu]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChiTietDichVu] (
        [MaDatSan] varchar(10) NOT NULL,
        [MaDV] varchar(10) NOT NULL,
        [SoLuong] int NOT NULL,
        [NgayGhiNhan] datetime CONSTRAINT [DF__ChiTietDi__NgayG__7F2BE32F] DEFAULT (getdate()) NOT NULL,
        [MaNV] varchar(10) NULL,
        [MaChiTiet] bigint IDENTITY(1,1) NOT NULL,
        [Nguon] varchar(12) CONSTRAINT [DF_CTDV_Nguon] DEFAULT ('LEGACY') NOT NULL,
        [QuyCach] varchar(10) CONSTRAINT [DF_CTDV_QuyCach] DEFAULT ('DON_VI') NOT NULL,
        [DonGiaDonViSnapshot] decimal(18, 2) NULL,
        [DonGiaLegacySnapshot] decimal(18, 2) NULL,
        [SoDonViMoiQuyCach] AS (CONVERT([int],case when [QuyCach]='LOC_6' then (6) else (1) end)) PERSISTED,
        [DonGia] AS (CONVERT([decimal](18,2),case when [Nguon]='LEGACY' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]='LOC_6' then (6) else (1) end)*case when [QuyCach]='LOC_6' then (0.97) else (1) end,(2)) end)) PERSISTED,
        [ThanhTien] AS ([SoLuong]*CONVERT([decimal](18,2),case when [Nguon]='LEGACY' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]='LOC_6' then (6) else (1) end)*case when [QuyCach]='LOC_6' then (0.97) else (1) end,(2)) end)) PERSISTED,
        CONSTRAINT [PK_ChiTietDichVu] PRIMARY KEY CLUSTERED ([MaChiTiet] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_DonGia')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_DonGia] CHECK ([DonGia] IS NOT NULL AND [DonGia]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_Nguon')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_Nguon] CHECK ([Nguon]='PHAT_SINH' OR [Nguon]='DAT_TRUOC' OR [Nguon]='LEGACY');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_QuyCach')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_QuyCach] CHECK ([QuyCach]='LOC_6' OR [QuyCach]='DON_VI');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_Snapshot')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_Snapshot] CHECK ([Nguon]='LEGACY' AND [DonGiaLegacySnapshot] IS NOT NULL AND [DonGiaLegacySnapshot]>(0) AND ([DonGiaDonViSnapshot] IS NULL OR [DonGiaDonViSnapshot]>(0)) OR [Nguon]<>'LEGACY' AND [DonGiaLegacySnapshot] IS NULL AND [DonGiaDonViSnapshot] IS NOT NULL AND [DonGiaDonViSnapshot]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDV_SoLuong')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] ADD CONSTRAINT [CK_CTDV_SoLuong] CHECK ([SoLuong]>(0));
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CTDV_BookingSku' AND object_id = OBJECT_ID(N'dbo.[ChiTietDichVu]'))
BEGIN
    DROP INDEX [IX_CTDV_BookingSku] ON dbo.[ChiTietDichVu];
END
GO
CREATE NONCLUSTERED INDEX [IX_CTDV_BookingSku] ON dbo.[ChiTietDichVu] ([MaDatSan] ASC, [MaDV] ASC);
GO
-- ============================================================
-- BẢNG: HoaDon
-- ============================================================
IF OBJECT_ID(N'dbo.[HoaDon]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HoaDon] (
        [MaHoaDon] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaTKLap] varchar(10) NOT NULL,
        [TienSan] decimal(18, 2) NOT NULL,
        [TienDichVu] decimal(18, 2) NOT NULL,
        [TienGiam] decimal(18, 2) NOT NULL,
        [DaThanhToan] decimal(18, 2) CONSTRAINT [DF__HoaDon__DaThanhT__318258D2] DEFAULT ((0)) NOT NULL,
        [TrangThai] varchar(24) CONSTRAINT [DF__HoaDon__TrangTha__32767D0B] DEFAULT ('CHUA_THANH_TOAN') NOT NULL,
        [DaChot] bit CONSTRAINT [DF__HoaDon__DaChot__336AA144] DEFAULT ((0)) NOT NULL,
        [NgayLap] datetime2(7) CONSTRAINT [DF__HoaDon__NgayLap__345EC57D] DEFAULT (sysdatetime()) NOT NULL,
        [TongTien] AS (CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])) PERSISTED,
        [ConLai] AS (case when [TrangThai]='DA_HUY' then CONVERT([decimal](18,2),(0)) else CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])-[DaThanhToan] end) PERSISTED,
        [HoanTatTaiChinh] AS (CONVERT([bit],case when [DaChot]=(1) AND CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])=[DaThanhToan] AND [TrangThai]='DA_THANH_TOAN' then (1) else (0) end)) PERSISTED,
        CONSTRAINT [PK_HoaDon] PRIMARY KEY CLUSTERED ([MaHoaDon] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HD_Money')
BEGIN
    ALTER TABLE dbo.[HoaDon] ADD CONSTRAINT [CK_HD_Money] CHECK ([TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TienGiam]<=[TienSan] AND [TongTien]>=(0) AND [DaThanhToan]>=(0) AND [DaThanhToan]<=[TongTien]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HD_State')
BEGIN
    ALTER TABLE dbo.[HoaDon] ADD CONSTRAINT [CK_HD_State] CHECK ([TrangThai]='DA_HUY' OR [TrangThai]='DA_THANH_TOAN' OR [TrangThai]='THANH_TOAN_MOT_PHAN' OR [TrangThai]='CHUA_THANH_TOAN');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_HoaDon_DatSan' AND object_id = OBJECT_ID(N'dbo.[HoaDon]'))
BEGIN
    DROP INDEX [UQ_HoaDon_DatSan] ON dbo.[HoaDon];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_HoaDon_DatSan] ON dbo.[HoaDon] ([MaDatSan] ASC);
GO
-- ============================================================
-- BẢNG: ThanhToan
-- ============================================================
IF OBJECT_ID(N'dbo.[ThanhToan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ThanhToan] (
        [MaTT] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [NgayThanhToan] datetime CONSTRAINT [DF__ThanhToan__NgayT__0C85DE4D] DEFAULT (getdate()) NOT NULL,
        [SoTien] decimal(18, 2) NOT NULL,
        [PhuongThuc] nvarchar(20) NOT NULL,
        [MaGiaoDich] varchar(50) NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__ThanhToan__Trang__0D7A0286] DEFAULT (N'Chờ xử lý') NOT NULL,
        [MaNV] varchar(10) NULL,
        CONSTRAINT [PK_ThanhToan] PRIMARY KEY CLUSTERED ([MaTT] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_PhuongThuc')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_PhuongThuc] CHECK ([PhuongThuc]=N'Chuyển khoản' OR [PhuongThuc]=N'Tiền mặt');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_SoTien')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_SoTien] CHECK ([SoTien]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ThanhToan_TrangThai')
BEGIN
    ALTER TABLE dbo.[ThanhToan] ADD CONSTRAINT [CK_ThanhToan_TrangThai] CHECK ([TrangThai]=N'Thất bại' OR [TrangThai]=N'Thành công' OR [TrangThai]=N'Chờ xử lý');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ThanhToan_BookingState' AND object_id = OBJECT_ID(N'dbo.[ThanhToan]'))
BEGIN
    DROP INDEX [IX_ThanhToan_BookingState] ON dbo.[ThanhToan];
END
GO
CREATE NONCLUSTERED INDEX [IX_ThanhToan_BookingState] ON dbo.[ThanhToan] ([MaDatSan] ASC, [TrangThai] ASC) INCLUDE ([SoTien]);
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_ThanhToan_Idempotency' AND object_id = OBJECT_ID(N'dbo.[ThanhToan]'))
BEGIN
    DROP INDEX [UX_ThanhToan_Idempotency] ON dbo.[ThanhToan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ThanhToan_Idempotency] ON dbo.[ThanhToan] ([MaGiaoDich] ASC) WHERE ([MaGiaoDich] IS NOT NULL);
GO
-- ============================================================
-- BẢNG: HuyDatSan
-- ============================================================
IF OBJECT_ID(N'dbo.[HuyDatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HuyDatSan] (
        [MaHuy] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [NgayHuy] datetime2(7) CONSTRAINT [DF__HuyDatSan__NgayH__160F4887] DEFAULT (getdate()) NOT NULL,
        [LyDo] nvarchar(255) NULL,
        [NguoiHuy] nvarchar(20) NOT NULL,
        [TiLeHoan] decimal(5, 2) CONSTRAINT [DF__HuyDatSan__TiLeH__17036CC0] DEFAULT ((0)) NOT NULL,
        [SoTienHoan] decimal(18, 2) CONSTRAINT [DF__HuyDatSan__SoTie__17F790F9] DEFAULT ((0)) NOT NULL,
        [SoTienThucThuSnapshot] decimal(18, 2) NULL,
        CONSTRAINT [PK_HuyDatSan] PRIMARY KEY CLUSTERED ([MaHuy] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Huy_ThucThu')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_Huy_ThucThu] CHECK ([SoTienThucThuSnapshot] IS NULL OR [SoTienThucThuSnapshot]>=(0) AND [SoTienHoan]<=round(([SoTienThucThuSnapshot]*[TiLeHoan])/(100),(2)));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_NguoiHuy')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_NguoiHuy] CHECK ([NguoiHuy]=N'Nhân viên' OR [NguoiHuy]=N'Khách hàng');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_SoTien')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_SoTien] CHECK ([SoTienHoan]>=(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HuyDatSan_TiLeHoan')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] ADD CONSTRAINT [CK_HuyDatSan_TiLeHoan] CHECK ([TiLeHoan]>=(0) AND [TiLeHoan]<=(100));
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_HuyDatSan_DatSan' AND object_id = OBJECT_ID(N'dbo.[HuyDatSan]'))
BEGIN
    DROP INDEX [UQ_HuyDatSan_DatSan] ON dbo.[HuyDatSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_HuyDatSan_DatSan] ON dbo.[HuyDatSan] ([MaDatSan] ASC);
GO
-- ============================================================
-- BẢNG: DanhGia
-- ============================================================
IF OBJECT_ID(N'dbo.[DanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[DanhGia] (
        [MaDanhGia] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaSan] varchar(10) NOT NULL,
        [NgayDanhGia] date CONSTRAINT [DF__DanhGia__NgayDan__2B0A656D] DEFAULT (getdate()) NOT NULL,
        [NoiDung] nvarchar(500) NULL,
        [DiemTrungBinh] decimal(3, 2) NULL,
        CONSTRAINT [PK_DanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DanhGia_Diem')
BEGIN
    ALTER TABLE dbo.[DanhGia] ADD CONSTRAINT [CK_DanhGia_Diem] CHECK ([DiemTrungBinh] IS NULL OR [DiemTrungBinh]>=(1) AND [DiemTrungBinh]<=(5));
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_DanhGia_DatSan' AND object_id = OBJECT_ID(N'dbo.[DanhGia]'))
BEGIN
    DROP INDEX [UQ_DanhGia_DatSan] ON dbo.[DanhGia];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DanhGia_DatSan] ON dbo.[DanhGia] ([MaDatSan] ASC);
GO
-- ============================================================
-- BẢNG: PhanHoi
-- ============================================================
IF OBJECT_ID(N'dbo.[PhanHoi]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[PhanHoi] (
        [MaPhanHoi] varchar(10) NOT NULL,
        [MaKH] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NULL,
        [NgayGui] datetime CONSTRAINT [DF__PhanHoi__NgayGui__367C1819] DEFAULT (getdate()) NOT NULL,
        [LoaiPhanHoi] nvarchar(50) NULL,
        [NoiDung] nvarchar(500) NOT NULL,
        [TrangThaiXuLy] nvarchar(20) CONSTRAINT [DF__PhanHoi__TrangTh__37703C52] DEFAULT (N'Chờ xử lý') NOT NULL,
        [MaNV] varchar(10) NULL,
        [NgayXuLy] datetime NULL,
        [KetQuaXuLy] nvarchar(500) NULL,
        CONSTRAINT [PK_PhanHoi] PRIMARY KEY CLUSTERED ([MaPhanHoi] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PhanHoi_NgayXuLy')
BEGIN
    ALTER TABLE dbo.[PhanHoi] ADD CONSTRAINT [CK_PhanHoi_NgayXuLy] CHECK ([NgayXuLy] IS NULL OR [NgayXuLy]>=[NgayGui]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PhanHoi_TrangThai')
BEGIN
    ALTER TABLE dbo.[PhanHoi] ADD CONSTRAINT [CK_PhanHoi_TrangThai] CHECK ([TrangThaiXuLy]=N'Đã xử lý' OR [TrangThaiXuLy]=N'Đang xử lý' OR [TrangThaiXuLy]=N'Chờ xử lý');
END
GO
-- ============================================================
-- BẢNG: HoanTien
-- ============================================================
IF OBJECT_ID(N'dbo.[HoanTien]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[HoanTien] (
        [MaHT] varchar(10) NOT NULL,
        [MaTT] varchar(10) NOT NULL,
        [MaHuy] varchar(10) NOT NULL,
        [NgayHoan] datetime CONSTRAINT [DF__HoanTien__NgayHo__1EA48E88] DEFAULT (getdate()) NOT NULL,
        [SoTienHoan] decimal(18, 2) NOT NULL,
        [PhuongThuc] nvarchar(20) NOT NULL,
        [TrangThai] nvarchar(20) CONSTRAINT [DF__HoanTien__TrangT__1F98B2C1] DEFAULT (N'Chờ duyệt') NOT NULL,
        [MaNV] varchar(10) NULL,
        [NgayXacNhan] datetime2(7) NULL,
        [LyDo] nvarchar(255) NULL,
        CONSTRAINT [PK_HoanTien] PRIMARY KEY CLUSTERED ([MaHT] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_PhuongThuc')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_PhuongThuc] CHECK ([PhuongThuc]=N'Chuyển khoản' OR [PhuongThuc]=N'Tiền mặt');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_SoTien')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_SoTien] CHECK ([SoTienHoan]>(0));
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoanTien_TrangThai')
BEGIN
    ALTER TABLE dbo.[HoanTien] ADD CONSTRAINT [CK_HoanTien_TrangThai] CHECK ([TrangThai]=N'Từ chối' OR [TrangThai]=N'Đã hoàn' OR [TrangThai]=N'Chờ duyệt');
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_HoanTien_CancellationPayment' AND object_id = OBJECT_ID(N'dbo.[HoanTien]'))
BEGIN
    DROP INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien] ([MaHuy] ASC, [MaTT] ASC);
GO
-- ============================================================
-- BẢNG: YeuCauHuyDatSan
-- ============================================================
IF OBJECT_ID(N'dbo.[YeuCauHuyDatSan]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[YeuCauHuyDatSan] (
        [MaYeuCau] varchar(10) NOT NULL,
        [MaDatSan] varchar(10) NOT NULL,
        [MaTKGui] varchar(10) NOT NULL,
        [NgayGui] datetime2(7) NOT NULL,
        [LyDo] nvarchar(255) NOT NULL,
        [TrangThai] varchar(20) CONSTRAINT [DF__YeuCauHuy__Trang__0FEC5ADD] DEFAULT ('PENDING') NOT NULL,
        [TiLeHoanUocTinh] decimal(5, 2) NOT NULL,
        [ThucThuTaiGui] decimal(18, 2) NOT NULL,
        [TienHoanUocTinh] decimal(18, 2) NOT NULL,
        [MaTKXuLy] varchar(10) NULL,
        [NgayXuLy] datetime2(7) NULL,
        [GhiChuXuLy] nvarchar(255) NULL,
        [MaHuy] varchar(10) NULL,
        [PhienBan] timestamp NOT NULL,
        CONSTRAINT [PK__YeuCauHu__CFA5DF4E87A895D0] PRIMARY KEY CLUSTERED ([MaYeuCau] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_Tien')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_Tien] CHECK ([TiLeHoanUocTinh]>=(0) AND [TiLeHoanUocTinh]<=(100) AND [ThucThuTaiGui]>=(0) AND [TienHoanUocTinh]>=(0) AND [TienHoanUocTinh]<=[ThucThuTaiGui]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_TrangThai')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_TrangThai] CHECK ([TrangThai]='REJECTED' OR [TrangThai]='APPROVED' OR [TrangThai]='PENDING');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_YeuCauHuy_XuLy')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] ADD CONSTRAINT [CK_YeuCauHuy_XuLy] CHECK ([TrangThai]='PENDING' AND [MaTKXuLy] IS NULL AND [NgayXuLy] IS NULL AND [MaHuy] IS NULL OR [TrangThai]='APPROVED' AND [MaTKXuLy] IS NOT NULL AND [NgayXuLy] IS NOT NULL AND [MaHuy] IS NOT NULL OR [TrangThai]='REJECTED' AND [MaTKXuLy] IS NOT NULL AND [NgayXuLy] IS NOT NULL AND [MaHuy] IS NULL);
END
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_YeuCauHuy_Customer' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    DROP INDEX [IX_YeuCauHuy_Customer] ON dbo.[YeuCauHuyDatSan];
END
GO
CREATE NONCLUSTERED INDEX [IX_YeuCauHuy_Customer] ON dbo.[YeuCauHuyDatSan] ([MaTKGui] ASC, [NgayGui] ASC);
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_YeuCauHuy_Queue' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    DROP INDEX [IX_YeuCauHuy_Queue] ON dbo.[YeuCauHuyDatSan];
END
GO
CREATE NONCLUSTERED INDEX [IX_YeuCauHuy_Queue] ON dbo.[YeuCauHuyDatSan] ([TrangThai] ASC, [NgayGui] ASC) INCLUDE ([MaDatSan], [MaTKGui]);
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_YeuCauHuy_Pending' AND object_id = OBJECT_ID(N'dbo.[YeuCauHuyDatSan]'))
BEGIN
    DROP INDEX [UX_YeuCauHuy_Pending] ON dbo.[YeuCauHuyDatSan];
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_YeuCauHuy_Pending] ON dbo.[YeuCauHuyDatSan] ([MaDatSan] ASC) WHERE ([TrangThai]='PENDING');
GO
-- ============================================================
-- BẢNG: ChiTietDanhGia
-- ============================================================
IF OBJECT_ID(N'dbo.[ChiTietDanhGia]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[ChiTietDanhGia] (
        [MaDanhGia] varchar(10) NOT NULL,
        [MaTieuChi] varchar(10) NOT NULL,
        [Diem] int NOT NULL,
        CONSTRAINT [PK_ChiTietDanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC, [MaTieuChi] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CTDG_Diem')
BEGIN
    ALTER TABLE dbo.[ChiTietDanhGia] ADD CONSTRAINT [CK_CTDG_Diem] CHECK ([Diem]>=(1) AND [Diem]<=(5));
END
GO
-- ============================================================
-- KHÓA NGOẠI (FOREIGN KEY CONSTRAINTS)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_BangGia_KhungGio')
BEGIN
    ALTER TABLE dbo.[BangGia] WITH CHECK ADD CONSTRAINT [FK_BangGia_KhungGio] FOREIGN KEY ([MaKhungGio]) REFERENCES dbo.[KhungGio] ([MaKhungGio]);
    ALTER TABLE dbo.[BangGia] CHECK CONSTRAINT [FK_BangGia_KhungGio];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_BangGia_LoaiSan')
BEGIN
    ALTER TABLE dbo.[BangGia] WITH CHECK ADD CONSTRAINT [FK_BangGia_LoaiSan] FOREIGN KEY ([MaLoaiSan]) REFERENCES dbo.[LoaiSan] ([MaLoaiSan]);
    ALTER TABLE dbo.[BangGia] CHECK CONSTRAINT [FK_BangGia_LoaiSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_BaoCao_TaiKhoan')
BEGIN
    ALTER TABLE dbo.[BaoCao] WITH CHECK ADD CONSTRAINT [FK_BaoCao_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[BaoCao] CHECK CONSTRAINT [FK_BaoCao_TaiKhoan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CTDG_DanhGia')
BEGIN
    ALTER TABLE dbo.[ChiTietDanhGia] WITH CHECK ADD CONSTRAINT [FK_CTDG_DanhGia] FOREIGN KEY ([MaDanhGia]) REFERENCES dbo.[DanhGia] ([MaDanhGia]);
    ALTER TABLE dbo.[ChiTietDanhGia] CHECK CONSTRAINT [FK_CTDG_DanhGia];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CTDG_TieuChi')
BEGIN
    ALTER TABLE dbo.[ChiTietDanhGia] WITH CHECK ADD CONSTRAINT [FK_CTDG_TieuChi] FOREIGN KEY ([MaTieuChi]) REFERENCES dbo.[TieuChiDanhGia] ([MaTieuChi]);
    ALTER TABLE dbo.[ChiTietDanhGia] CHECK CONSTRAINT [FK_CTDG_TieuChi];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CTDV_DatSan')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[ChiTietDichVu] CHECK CONSTRAINT [FK_CTDV_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CTDV_DichVu')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_DichVu] FOREIGN KEY ([MaDV]) REFERENCES dbo.[DichVu] ([MaDV]);
    ALTER TABLE dbo.[ChiTietDichVu] CHECK CONSTRAINT [FK_CTDV_DichVu];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CTDV_NhanVien')
BEGIN
    ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[ChiTietDichVu] CHECK CONSTRAINT [FK_CTDV_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DanhGia_DatSan')
BEGIN
    ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[DanhGia] CHECK CONSTRAINT [FK_DanhGia_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DanhGia_KhachHang')
BEGIN
    ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang] ([MaKH]);
    ALTER TABLE dbo.[DanhGia] CHECK CONSTRAINT [FK_DanhGia_KhachHang];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DanhGia_San')
BEGIN
    ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_San] FOREIGN KEY ([MaSan]) REFERENCES dbo.[San] ([MaSan]);
    ALTER TABLE dbo.[DanhGia] CHECK CONSTRAINT [FK_DanhGia_San];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DatSan_KhachHang')
BEGIN
    ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang] ([MaKH]);
    ALTER TABLE dbo.[DatSan] CHECK CONSTRAINT [FK_DatSan_KhachHang];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DatSan_KhungGio')
BEGIN
    ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhungGio] FOREIGN KEY ([MaKhungGio]) REFERENCES dbo.[KhungGio] ([MaKhungGio]);
    ALTER TABLE dbo.[DatSan] CHECK CONSTRAINT [FK_DatSan_KhungGio];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DatSan_KhuyenMai')
BEGIN
    ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhuyenMai] FOREIGN KEY ([MaKM]) REFERENCES dbo.[KhuyenMai] ([MaKM]);
    ALTER TABLE dbo.[DatSan] CHECK CONSTRAINT [FK_DatSan_KhuyenMai];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DatSan_NhanVien')
BEGIN
    ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[DatSan] CHECK CONSTRAINT [FK_DatSan_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DatSan_San')
BEGIN
    ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_San] FOREIGN KEY ([MaSan]) REFERENCES dbo.[San] ([MaSan]);
    ALTER TABLE dbo.[DatSan] CHECK CONSTRAINT [FK_DatSan_San];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HD_DatSan')
BEGIN
    ALTER TABLE dbo.[HoaDon] WITH CHECK ADD CONSTRAINT [FK_HD_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[HoaDon] CHECK CONSTRAINT [FK_HD_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HD_TaiKhoan')
BEGIN
    ALTER TABLE dbo.[HoaDon] WITH CHECK ADD CONSTRAINT [FK_HD_TaiKhoan] FOREIGN KEY ([MaTKLap]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[HoaDon] CHECK CONSTRAINT [FK_HD_TaiKhoan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HoanTien_HuyDatSan')
BEGIN
    ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_HuyDatSan] FOREIGN KEY ([MaHuy]) REFERENCES dbo.[HuyDatSan] ([MaHuy]);
    ALTER TABLE dbo.[HoanTien] CHECK CONSTRAINT [FK_HoanTien_HuyDatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HoanTien_NhanVien')
BEGIN
    ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[HoanTien] CHECK CONSTRAINT [FK_HoanTien_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HoanTien_ThanhToan')
BEGIN
    ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_ThanhToan] FOREIGN KEY ([MaTT]) REFERENCES dbo.[ThanhToan] ([MaTT]);
    ALTER TABLE dbo.[HoanTien] CHECK CONSTRAINT [FK_HoanTien_ThanhToan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HuyDatSan_DatSan')
BEGIN
    ALTER TABLE dbo.[HuyDatSan] WITH CHECK ADD CONSTRAINT [FK_HuyDatSan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[HuyDatSan] CHECK CONSTRAINT [FK_HuyDatSan_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_NhatKy_TaiKhoan')
BEGIN
    ALTER TABLE dbo.[NhatKyHeThong] WITH CHECK ADD CONSTRAINT [FK_NhatKy_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[NhatKyHeThong] CHECK CONSTRAINT [FK_NhatKy_TaiKhoan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhanHoi_DatSan')
BEGIN
    ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[PhanHoi] CHECK CONSTRAINT [FK_PhanHoi_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhanHoi_KhachHang')
BEGIN
    ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang] ([MaKH]);
    ALTER TABLE dbo.[PhanHoi] CHECK CONSTRAINT [FK_PhanHoi_KhachHang];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhanHoi_NhanVien')
BEGIN
    ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[PhanHoi] CHECK CONSTRAINT [FK_PhanHoi_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhanQuyen_ChucNang')
BEGIN
    ALTER TABLE dbo.[PhanQuyen] WITH CHECK ADD CONSTRAINT [FK_PhanQuyen_ChucNang] FOREIGN KEY ([MaChucNang]) REFERENCES dbo.[ChucNang] ([MaChucNang]);
    ALTER TABLE dbo.[PhanQuyen] CHECK CONSTRAINT [FK_PhanQuyen_ChucNang];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhanQuyen_VaiTro')
BEGIN
    ALTER TABLE dbo.[PhanQuyen] WITH CHECK ADD CONSTRAINT [FK_PhanQuyen_VaiTro] FOREIGN KEY ([MaVaiTro]) REFERENCES dbo.[VaiTro] ([MaVaiTro]);
    ALTER TABLE dbo.[PhanQuyen] CHECK CONSTRAINT [FK_PhanQuyen_VaiTro];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_San_LoaiSan')
BEGIN
    ALTER TABLE dbo.[San] WITH CHECK ADD CONSTRAINT [FK_San_LoaiSan] FOREIGN KEY ([MaLoaiSan]) REFERENCES dbo.[LoaiSan] ([MaLoaiSan]);
    ALTER TABLE dbo.[San] CHECK CONSTRAINT [FK_San_LoaiSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SaoLuu_TaiKhoan')
BEGIN
    ALTER TABLE dbo.[SaoLuu] WITH CHECK ADD CONSTRAINT [FK_SaoLuu_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[SaoLuu] CHECK CONSTRAINT [FK_SaoLuu_TaiKhoan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TaiKhoan_KhachHang')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang] ([MaKH]);
    ALTER TABLE dbo.[TaiKhoan] CHECK CONSTRAINT [FK_TaiKhoan_KhachHang];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TaiKhoan_NhanVien')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[TaiKhoan] CHECK CONSTRAINT [FK_TaiKhoan_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TaiKhoan_VaiTro')
BEGIN
    ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_VaiTro] FOREIGN KEY ([MaVaiTro]) REFERENCES dbo.[VaiTro] ([MaVaiTro]);
    ALTER TABLE dbo.[TaiKhoan] CHECK CONSTRAINT [FK_TaiKhoan_VaiTro];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ThanhToan_DatSan')
BEGIN
    ALTER TABLE dbo.[ThanhToan] WITH CHECK ADD CONSTRAINT [FK_ThanhToan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[ThanhToan] CHECK CONSTRAINT [FK_ThanhToan_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ThanhToan_NhanVien')
BEGIN
    ALTER TABLE dbo.[ThanhToan] WITH CHECK ADD CONSTRAINT [FK_ThanhToan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[ThanhToan] CHECK CONSTRAINT [FK_ThanhToan_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_XacNhanSan_DatSan')
BEGIN
    ALTER TABLE dbo.[XacNhanSan] WITH CHECK ADD CONSTRAINT [FK_XacNhanSan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[XacNhanSan] CHECK CONSTRAINT [FK_XacNhanSan_DatSan];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_XacNhanSan_NhanVien')
BEGIN
    ALTER TABLE dbo.[XacNhanSan] WITH CHECK ADD CONSTRAINT [FK_XacNhanSan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien] ([MaNV]);
    ALTER TABLE dbo.[XacNhanSan] CHECK CONSTRAINT [FK_XacNhanSan_NhanVien];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__YeuCauHuy__MaDat__0E04126B')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] WITH CHECK ADD CONSTRAINT [FK__YeuCauHuy__MaDat__0E04126B] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan] ([MaDatSan]);
    ALTER TABLE dbo.[YeuCauHuyDatSan] CHECK CONSTRAINT [FK__YeuCauHuy__MaDat__0E04126B];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__YeuCauHuy__MaHuy__11D4A34F')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] WITH CHECK ADD CONSTRAINT [FK__YeuCauHuy__MaHuy__11D4A34F] FOREIGN KEY ([MaHuy]) REFERENCES dbo.[HuyDatSan] ([MaHuy]);
    ALTER TABLE dbo.[YeuCauHuyDatSan] CHECK CONSTRAINT [FK__YeuCauHuy__MaHuy__11D4A34F];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__YeuCauHuy__MaTKG__0EF836A4')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] WITH CHECK ADD CONSTRAINT [FK__YeuCauHuy__MaTKG__0EF836A4] FOREIGN KEY ([MaTKGui]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[YeuCauHuyDatSan] CHECK CONSTRAINT [FK__YeuCauHuy__MaTKG__0EF836A4];
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__YeuCauHuy__MaTKX__10E07F16')
BEGIN
    ALTER TABLE dbo.[YeuCauHuyDatSan] WITH CHECK ADD CONSTRAINT [FK__YeuCauHuy__MaTKX__10E07F16] FOREIGN KEY ([MaTKXuLy]) REFERENCES dbo.[TaiKhoan] ([MaTK]);
    ALTER TABLE dbo.[YeuCauHuyDatSan] CHECK CONSTRAINT [FK__YeuCauHuy__MaTKX__10E07F16];
END
GO
