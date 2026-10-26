/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 00: TOÀN BỘ CƠ SỞ DỮ LIỆU TỰ ĐỘNG (MASTER ALL-IN-ONE SCRIPT)
   Script này chạy độc lập, tự động tạo cơ sở dữ liệu QuanLySanBong từ đầu đến cuối:
     1. Khởi tạo Database và các Bảng chuẩn hóa (28 bảng, PK, FK, CHECK, DEFAULT, INDEX)
     2. Tạo các Hàm người dùng (6 UDF)
     3. Tạo các Khung nhìn dữ liệu (9 Views)
     4. Tạo các Thủ tục lưu trữ báo cáo (5 Stored Procedures)
     5. Tạo các Trigger bảo vệ toàn vẹn (5 Triggers)
     6. Nạp toàn bộ dữ liệu chuẩn & lịch sử vận hành
   Chỉ cần mở file này trong SSMS (SQL Server Management Studio) và nhấn F5 (Execute)!
   ========================================================================================= */

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

/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 03: HÀM NGƯỜI DÙNG ĐỊNH NGHĨA (USER-DEFINED FUNCTIONS)
   Bao gồm 6 hàm:
     - fn_TyLeHoan: Tính tỷ lệ hoàn tiền hủy sân theo mốc 10h / 2h (Phase 5.1C)
     - fn_BookingNetCash: Thực nhận theo mã đặt sân (Thu trừ Hoàn)
     - fn_BookingReceipts: Tổng tiền đã thực thu theo mã đặt sân
     - fn_BookingRefunds: Tổng tiền đã hoàn theo mã đặt sân
     - fn_KhungGioTrongTheoNgay: Tra cứu các khung giờ còn trống trong ngày của sân
     - fn_ReportDays: Bảng các ngày trong khoảng thời gian báo cáo
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- HÀM: fn_TyLeHoan
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_TyLeHoan
(
    @BatDau datetime2(7),
    @Huy datetime2(7)
)
RETURNS decimal(5,2)
AS
BEGIN
    RETURN
        CASE
            WHEN @Huy <= DATEADD(hour,-10,@BatDau) THEN 100
            WHEN @Huy <= DATEADD(hour,-2,@BatDau) THEN 50
            ELSE 0
        END;
END;
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingNetCash
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingNetCash(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTienThucNhan),0) net FROM dbo.V_ThuChiThucNhan WHERE MaDatSan=@Booking);
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingReceipts
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingReceipts(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTien),0) thu FROM dbo.ThanhToan WHERE MaDatSan=@Booking AND TrangThai=N'Thành công');
GO

-- ------------------------------------------------------------
-- HÀM: fn_BookingRefunds
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_BookingRefunds(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(CASE WHEN h.TrangThai=N'Đã hoàn' THEN h.SoTienHoan ELSE 0 END),0) hoan,ISNULL(SUM(CASE WHEN h.TrangThai=N'Chờ duyệt' THEN h.SoTienHoan ELSE 0 END),0) choHoan FROM dbo.HoanTien h JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=@Booking);
GO

-- ------------------------------------------------------------
-- HÀM: fn_KhungGioTrongTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_KhungGioTrongTheoNgay(@Ngay date) RETURNS TABLE AS RETURN (
 SELECT s.MaSan,s.TenSan,l.TenLoaiSan,k.MaKhungGio,k.GioBatDau,k.GioKetThuc,@Ngay NgayChoi
 FROM dbo.San s JOIN dbo.LoaiSan l ON l.MaLoaiSan=s.MaLoaiSan CROSS JOIN dbo.KhungGio k
 WHERE @Ngay IS NOT NULL AND s.TrangThai<>N'Bảo trì'
 AND k.GioBatDau>='07:00' AND k.GioKetThuc<='22:00'
 AND NOT EXISTS(SELECT 1 FROM dbo.DatSan d WHERE d.MaSan=s.MaSan AND d.NgayChoi=@Ngay
 AND d.TrangThai<>N'Đã hủy' AND d.GioBatDau<k.GioKetThuc AND d.GioKetThuc>k.GioBatDau));
GO

-- ------------------------------------------------------------
-- HÀM: fn_ReportDays
-- ------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_ReportDays(@From date,@To date) RETURNS TABLE AS RETURN (WITH digits(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))x(n)) SELECT DATEADD(day,a.n+10*b.n+100*c.n,@From) Ngay FROM digits a CROSS JOIN digits b CROSS JOIN digits c WHERE @From IS NOT NULL AND @To>=@From AND DATEDIFF(day,@From,@To)<=366 AND a.n+10*b.n+100*c.n<=DATEDIFF(day,@From,@To));
GO


/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 02: CÁC KHUNG NHÌN DỮ LIỆU (VIEWS)
   Bao gồm 9 View:
     - V_DoanhThuPhatSinhTheoNgay: Doanh thu phát sinh tại thời điểm trả sân
     - V_DoanhThuTheoNgay: Tổng doanh thu các hóa đơn đã thanh toán theo ngày
     - V_KhungGioTrong: Danh sách các khung giờ trống của từng sân
     - V_Phase6_Revenue: Doanh thu theo hóa đơn, tiền sân, tiền dịch vụ, giảm giá
     - V_Phase6_UsageBooking: Thống kê số lượt và giờ sử dụng sân
     - V_ThuChiThucNhan: Dòng tiền thực nhận (Thu từ thanh toán trừ Hoàn tiền)
     - V_ThuTienTheoNgay: Tổng tiền thực thu từng ngày
     - V_TyLeLapDay: Tỷ lệ lấp đầy khung giờ theo ngày
     - V_TyLeSuDungTheoNgay: Tỷ lệ sử dụng thời gian sân thực tế theo ngày
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- VIEW: V_DoanhThuPhatSinhTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_DoanhThuPhatSinhTheoNgay AS
 SELECT Ngay,COUNT(*) SoHoaDon,SUM(TienSan) TienSan,SUM(TienDichVu) TienDichVu,
 SUM(TienGiam) TienGiam,SUM(DoanhThu) DoanhThu FROM dbo.V_Phase6_Revenue GROUP BY Ngay;
GO

-- ------------------------------------------------------------
-- VIEW: V_DoanhThuTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_DoanhThuTheoNgay AS
 SELECT Ngay,PhuongThuc,SoGiaoDich,TongTien FROM dbo.V_ThuTienTheoNgay;
GO

-- ------------------------------------------------------------
-- VIEW: V_KhungGioTrong
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_KhungGioTrong AS
 SELECT MaSan,TenSan,TenLoaiSan,MaKhungGio,GioBatDau,GioKetThuc,NgayChoi
 FROM dbo.fn_KhungGioTrongTheoNgay(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time'));
GO

-- ------------------------------------------------------------
-- VIEW: V_Phase6_Revenue
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_Phase6_Revenue AS
 SELECT d.MaDatSan,d.MaSan,CAST(x.ThoiGianKetThuc AS date) Ngay,
 COALESCE(h.TienSan,d.TienSan) TienSan,COALESCE(h.TienDichVu,d.TienDichVu) TienDichVu,
 COALESCE(h.TienGiam,d.TienGiam) TienGiam,COALESCE(h.TongTien,d.TongTien) DoanhThu
 FROM dbo.DatSan d JOIN (SELECT MaDatSan,MAX(ThoiGianKetThuc) ThoiGianKetThuc FROM dbo.XacNhanSan
 WHERE ThoiGianKetThuc IS NOT NULL GROUP BY MaDatSan) x ON x.MaDatSan=d.MaDatSan
 LEFT JOIN dbo.HoaDon h ON h.MaDatSan=d.MaDatSan
 WHERE d.TrangThai<>N'Đã hủy';
GO

-- ------------------------------------------------------------
-- VIEW: V_Phase6_UsageBooking
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_Phase6_UsageBooking AS
 SELECT d.MaDatSan,d.MaSan,d.NgayChoi,d.TrangThai,
 CASE WHEN d.TrangThai=N'Đã hủy' THEN 0 ELSE
 CASE WHEN d.GioKetThuc<=CONVERT(time,'07:00') OR d.GioBatDau>=CONVERT(time,'22:00') THEN 0 ELSE
 DATEDIFF(minute,CASE WHEN d.GioBatDau<CONVERT(time,'07:00') THEN CONVERT(time,'07:00') ELSE d.GioBatDau END,
 CASE WHEN d.GioKetThuc>CONVERT(time,'22:00') THEN CONVERT(time,'22:00') ELSE d.GioKetThuc END) END END PhutDat,
 CONVERT(int,CASE WHEN EXISTS(SELECT 1 FROM dbo.XacNhanSan x WHERE x.MaDatSan=d.MaDatSan AND x.ThoiGianKetThuc IS NOT NULL) THEN 1 ELSE 0 END) DaSuDung
 FROM dbo.DatSan d;
GO

-- ------------------------------------------------------------
-- VIEW: V_ThuChiThucNhan
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_ThuChiThucNhan AS
 SELECT MaTT MaGiaoDich,MaDatSan,NgayThanhToan ThoiDiem,PhuongThuc,SoTien SoTienThucNhan,N'Thu' Loai FROM dbo.ThanhToan WHERE TrangThai=N'Thành công'
 UNION ALL SELECT h.MaHT,t.MaDatSan,h.NgayXacNhan,h.PhuongThuc,-h.SoTienHoan,N'Hoàn' FROM dbo.HoanTien h
 JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE h.TrangThai=N'Đã hoàn';
GO

-- ------------------------------------------------------------
-- VIEW: V_ThuTienTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_ThuTienTheoNgay AS
 SELECT CAST(NgayThanhToan AS date) Ngay,PhuongThuc,COUNT(*) SoGiaoDich,SUM(SoTien) TongTien
 FROM dbo.ThanhToan WHERE TrangThai=N'Thành công' GROUP BY CAST(NgayThanhToan AS date),PhuongThuc;
GO

-- ------------------------------------------------------------
-- VIEW: V_TyLeLapDay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_TyLeLapDay AS
 SELECT NgayChoi,SoLuotDat,(SELECT COUNT(*) FROM dbo.San)*(SELECT COUNT(*) FROM dbo.KhungGio) TongKhungGio,
 TyLeLapDay,PhutDat,PhutCongSuat FROM dbo.V_TyLeSuDungTheoNgay;
GO

-- ------------------------------------------------------------
-- VIEW: V_TyLeSuDungTheoNgay
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_TyLeSuDungTheoNgay AS
 SELECT u.NgayChoi,COUNT(CASE WHEN u.TrangThai<>N'Đã hủy' THEN 1 END) SoLuotDat,
 SUM(CONVERT(bigint,u.PhutDat)) PhutDat,
 (SELECT COUNT_BIG(*)*900 FROM dbo.San) PhutCongSuat,
 CAST(100.0*SUM(CONVERT(bigint,u.PhutDat))/NULLIF((SELECT COUNT_BIG(*)*900 FROM dbo.San),0) AS decimal(18,2)) TyLeLapDay
 FROM dbo.V_Phase6_UsageBooking u GROUP BY u.NgayChoi;
GO


/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 04: THỦ TỤC LƯU TRỮ BÁO CÁO (STORED PROCEDURES)
   Bao gồm 5 Stored Procedure báo cáo:
     - usp_ReportFinance: Báo cáo tài chính doanh thu phát sinh và thực nhận
     - usp_ReportPaymentMethods: Phân tích cơ cấu phương thức thanh toán (Tiền mặt / Chuyển khoản)
     - usp_ReportReconciliation: Báo cáo đối soát công nợ & trạng thái thanh toán hóa đơn
     - usp_ReportTopServices: Thống kê top dịch vụ bán chạy nhất và doanh thu
     - usp_ReportUsage: Báo cáo công suất, số lượt đặt và tỷ lệ sử dụng sân
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportFinance
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportFinance @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) , rev AS (SELECT Ngay,SUM(TienSan) san,SUM(TienDichVu) dv,SUM(TienGiam) giam,SUM(DoanhThu) doanhThu FROM V_Phase6_Revenue WHERE Ngay>=@From AND Ngay<DATEADD(day,1,@To) AND (@Pitch='' OR MaSan=@Pitch) GROUP BY Ngay), cash AS (SELECT CAST(v.ThoiDiem AS date) Ngay,SUM(CASE WHEN v.Loai=N'Thu' THEN v.SoTienThucNhan ELSE 0 END) thu,SUM(CASE WHEN v.Loai=N'Hoàn' THEN -v.SoTienThucNhan ELSE 0 END) hoan,SUM(v.SoTienThucNhan) net FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='' OR d.MaSan=@Pitch) GROUP BY CAST(v.ThoiDiem AS date)) SELECT z.Ngay ngay,ISNULL(r.san,0) tienSan,ISNULL(r.dv,0) tienDichVu,ISNULL(r.giam,0) tienGiam,ISNULL(r.doanhThu,0) doanhThu,ISNULL(c.thu,0) tienThu,ISNULL(c.hoan,0) tienHoan,ISNULL(c.net,0) thucNhan FROM days z LEFT JOIN rev r ON r.Ngay=z.Ngay LEFT JOIN cash c ON c.Ngay=z.Ngay ORDER BY z.Ngay OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportPaymentMethods
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportPaymentMethods @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 SELECT v.PhuongThuc phuongThuc,SUM(CASE WHEN v.Loai=N'Thu' THEN 1 ELSE 0 END) soGiaoDich,SUM(CASE WHEN v.Loai=N'Thu' THEN v.SoTienThucNhan ELSE 0 END) tienThu,SUM(CASE WHEN v.Loai=N'Hoàn' THEN 1 ELSE 0 END) soGiaoDichHoan,SUM(CASE WHEN v.Loai=N'Hoàn' THEN -v.SoTienThucNhan ELSE 0 END) tienHoan,SUM(v.SoTienThucNhan) thucNhan FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='' OR d.MaSan=@Pitch) GROUP BY v.PhuongThuc ORDER BY v.PhuongThuc;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportReconciliation
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportReconciliation @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 SELECT d.MaDatSan maDatSan,s.TenSan tenSan,d.NgayChoi ngayChoi,d.TrangThai trangThai,h.MaHoaDon maHoaDon,h.DaChot daChot,d.TongTien tongBooking,h.TongTien tongHoaDon,h.DaThanhToan thuHoaDon,h.ConLai conLai,ISNULL(p.thu,0) tienThu,ISNULL(r.hoan,0) tienHoan,ISNULL(r.choHoan,0) choHoan,ISNULL(v.net,0) soThucNhan FROM DatSan d JOIN San s ON s.MaSan=d.MaSan LEFT JOIN HoaDon h ON h.MaDatSan=d.MaDatSan CROSS APPLY dbo.fn_BookingReceipts(d.MaDatSan) p CROSS APPLY dbo.fn_BookingRefunds(d.MaDatSan) r CROSS APPLY dbo.fn_BookingNetCash(d.MaDatSan) v WHERE d.NgayChoi>=@From AND d.NgayChoi<=@To AND (@Pitch='' OR d.MaSan=@Pitch) ORDER BY d.NgayChoi,d.MaDatSan;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportTopServices
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportTopServices @Day date AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @Day IS NULL OR @Day='99991231' THROW 51010,'Invalid day',1;
 SELECT TOP(5) c.MaDV maDV,v.TenDV tenDV,SUM(c.SoLuong*c.SoDonViMoiQuyCach) soDonVi,SUM(c.ThanhTien) tienDichVu FROM ChiTietDichVu c JOIN DichVu v ON v.MaDV=c.MaDV JOIN V_Phase6_Revenue r ON r.MaDatSan=c.MaDatSan WHERE r.Ngay=@Day GROUP BY c.MaDV,v.TenDV ORDER BY SUM(c.SoLuong*c.SoDonViMoiQuyCach) DESC,c.MaDV;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO

-- ------------------------------------------------------------
-- THỦ TỤC: usp_ReportUsage
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_ReportUsage @From date,@To date,@Pitch varchar(10)='' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To='99991231' OR @Pitch IS NULL THROW 51010,'Invalid report range or pitch',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) SELECT z.Ngay ngay,s.MaSan maSan,s.TenSan tenSan,COUNT(u.MaDatSan) soBooking,ISNULL(SUM(u.DaSuDung),0) soDaSuDung,ISNULL(SUM(CASE WHEN u.TrangThai=N'Đã hủy' THEN 1 ELSE 0 END),0) soDaHuy,ISNULL(SUM(u.PhutDat),0) phutDat,900 phutCongSuat,CAST(ISNULL(SUM(u.PhutDat),0)/60.0 AS decimal(18,2)) gioDat,CAST(ISNULL(SUM(u.PhutDat),0)*100.0/900 AS decimal(18,2)) tyLeLapDay FROM days z CROSS JOIN San s LEFT JOIN V_Phase6_UsageBooking u ON u.NgayChoi=z.Ngay AND u.MaSan=s.MaSan WHERE (@Pitch='' OR s.MaSan=@Pitch) GROUP BY z.Ngay,s.MaSan,s.TenSan ORDER BY z.Ngay,s.MaSan OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;
GO


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


/* =========================================================================================
   HỆ THỐNG QUẢN LÝ SÂN BÓNG - FC UTE
   FILE 06: DỮ LIỆU CƠ SỞ (DATA INSERTION)
   Chứa toàn bộ dữ liệu hiện tại từ cơ sở dữ liệu QuanLySanBong.
   Thứ tự nạp tuân thủ chặt chẽ khóa ngoại. Triggers và Foreign Key checks được tạm ngưng
   trong lúc import để đảm bảo tính toàn vẹn snapshot lịch sử, sau đó bật lại ngay lập tức.
   ========================================================================================= */

USE [QuanLySanBong];
GO

SET NOCOUNT ON;
GO

-- Vô hiệu hóa kiểm tra khóa ngoại và trigger tạm thời để nạp dữ liệu sạch
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
GO
EXEC sp_msforeachtable "DISABLE TRIGGER ALL ON ?";
GO
-- ------------------------------------------------------------
-- BẢNG: VaiTro (4 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[VaiTro] ([MaVaiTro], [TenVaiTro], [MoTa]) VALUES (N'VT01', N'Khách hàng', N'Đặt sân, thanh toán, đánh giá');
INSERT INTO dbo.[VaiTro] ([MaVaiTro], [TenVaiTro], [MoTa]) VALUES (N'VT02', N'Nhân viên sân bóng', N'Tiếp nhận và vận hành sân');
INSERT INTO dbo.[VaiTro] ([MaVaiTro], [TenVaiTro], [MoTa]) VALUES (N'VT03', N'Nhân viên kế toán', N'Đối soát doanh thu, hoàn tiền');
INSERT INTO dbo.[VaiTro] ([MaVaiTro], [TenVaiTro], [MoTa]) VALUES (N'VT04', N'Quản trị hệ thống', N'Toàn quyền quản trị');
GO

-- ------------------------------------------------------------
-- BẢNG: ChucNang (8 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN01', N'Quản lý khách hàng', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN02', N'Quản lý đặt sân', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN03', N'Quản lý dịch vụ', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN04', N'Quản lý thanh toán', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN05', N'Quản lý phản hồi', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN06', N'Tra cứu / lập báo cáo', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN07', N'Quản lý tài khoản', NULL);
INSERT INTO dbo.[ChucNang] ([MaChucNang], [TenChucNang], [MoTa]) VALUES (N'CN08', N'Phân quyền người dùng', NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: LoaiSan (2 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[LoaiSan] ([MaLoaiSan], [TenLoaiSan], [SoNguoi], [MoTa]) VALUES (N'LS01', N'Sân 5 người', 5, NULL);
INSERT INTO dbo.[LoaiSan] ([MaLoaiSan], [TenLoaiSan], [SoNguoi], [MoTa]) VALUES (N'LS02', N'Sân 7 người', 7, NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: KhungGio (5 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[KhungGio] ([MaKhungGio], [GioBatDau], [GioKetThuc], [ThoiLuong]) VALUES (N'KG01', CAST(N'06:00:00' AS Time), CAST(N'07:30:00' AS Time), 1.50);
INSERT INTO dbo.[KhungGio] ([MaKhungGio], [GioBatDau], [GioKetThuc], [ThoiLuong]) VALUES (N'KG02', CAST(N'16:00:00' AS Time), CAST(N'17:30:00' AS Time), 1.50);
INSERT INTO dbo.[KhungGio] ([MaKhungGio], [GioBatDau], [GioKetThuc], [ThoiLuong]) VALUES (N'KG03', CAST(N'17:30:00' AS Time), CAST(N'19:00:00' AS Time), 1.50);
INSERT INTO dbo.[KhungGio] ([MaKhungGio], [GioBatDau], [GioKetThuc], [ThoiLuong]) VALUES (N'KG04', CAST(N'19:00:00' AS Time), CAST(N'20:30:00' AS Time), 1.50);
INSERT INTO dbo.[KhungGio] ([MaKhungGio], [GioBatDau], [GioKetThuc], [ThoiLuong]) VALUES (N'KG05', CAST(N'20:30:00' AS Time), CAST(N'22:00:00' AS Time), 1.50);
GO

-- ------------------------------------------------------------
-- BẢNG: KhachHang (9 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH01', N'VĂµ Minh QuĂ¢n', N'0987654321', N'quan.vo@student.hcmute.edu.vn', N'01 VĂµ VÄƒn NgĂ¢n, TP. Thá»§ Äá»©c', CAST(N'2026-01-10' AS Date), N'ThĂ nh viĂªn Báº¡c');
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH02', N'Nguyá»…n VÄƒn An', N'0912345678', N'an.nguyen@gmail.com', N'LĂª VÄƒn Viá»‡t, TP. Thá»§ Äá»©c', CAST(N'2026-02-01' AS Date), N'KhĂ¡ch vĂ£ng lai');
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH03', N'LĂª HoĂ ng Long', N'0909112233', N'long.le@gmail.com', N'Äá»— XuĂ¢n Há»£p, Quáº­n 9', CAST(N'2026-02-10' AS Date), N'KhĂ¡ch cá»‘ Ä‘á»‹nh tá»‘i thá»© 4');
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH0f8b5de4', N'gydvglidha jdbnc', N'0356295278', N'wfdbgwd@gamil.com', NULL, CAST(N'2026-10-16' AS Date), NULL);
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH20e39c83', N'Vsdsfb', N'0903169018', NULL, NULL, CAST(N'2026-10-19' AS Date), NULL);
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KH8ae19d2f', N'Minh Quân', N'+84373855657', NULL, NULL, CAST(N'2026-10-20' AS Date), NULL);
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KHc64de18c', N'Võ Minh Quân', N'0373855657', N'gflkndvf@gamil.com', NULL, CAST(N'2026-10-14' AS Date), NULL);
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KHdaefec74', N'Võ Thành tuấn', N'0748392342', N'phuawjof@gamil.com', NULL, CAST(N'2026-10-20' AS Date), NULL);
INSERT INTO dbo.[KhachHang] ([MaKH], [HoTen], [SoDienThoai], [Email], [DiaChi], [NgayDangKy], [GhiChu]) VALUES (N'KHe7347f1e', N'abcd', N'0123456789', NULL, NULL, CAST(N'2026-10-26' AS Date), NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: NhanVien (3 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[NhanVien] ([MaNV], [HoTen], [SoDienThoai], [Email], [ChucVu], [BoPhan], [NgayVaoLam], [TrangThai]) VALUES (N'NV01', N'Võ Minh Quân (Admin)', N'0901000001', N'admin@fcute.vn', N'Quản trị viên', N'Quản trị hệ thống', CAST(N'2025-01-01' AS Date), 1);
INSERT INTO dbo.[NhanVien] ([MaNV], [HoTen], [SoDienThoai], [Email], [ChucVu], [BoPhan], [NgayVaoLam], [TrangThai]) VALUES (N'NV02', N'Văn Ngọc Hữu', N'0901000002', N'huu.van@fcute.vn', N'Nhân viên vận hành', N'Nhân viên sân bóng', CAST(N'2025-02-01' AS Date), 1);
INSERT INTO dbo.[NhanVien] ([MaNV], [HoTen], [SoDienThoai], [Email], [ChucVu], [BoPhan], [NgayVaoLam], [TrangThai]) VALUES (N'NV03', N'Trần Thị Mai', N'0901000003', N'mai.tran@fcute.vn', N'Kế toán trưởng', N'Kế toán', CAST(N'2025-02-15' AS Date), 1);
GO

-- ------------------------------------------------------------
-- BẢNG: KhuyenMai (4 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[KhuyenMai] ([MaKM], [TenKM], [LoaiGiam], [MucGiam], [DieuKien], [NgayBatDau], [NgayKetThuc], [TrangThai]) VALUES (N'KM01', N'Ưu đãi sinh viên UTE (UTE2026)', N'Số tiền', 20000.00, N'Dành cho sinh viên có thẻ SV', CAST(N'2026-01-01' AS Date), CAST(N'2026-12-31' AS Date), 0);
INSERT INTO dbo.[KhuyenMai] ([MaKM], [TenKM], [LoaiGiam], [MucGiam], [DieuKien], [NgayBatDau], [NgayKetThuc], [TrangThai]) VALUES (N'KM02', N'Giờ vàng thứ Tư (VIP10)', N'Phần trăm', 10.00, N'Chỉ áp dụng thứ Tư', CAST(N'2026-01-01' AS Date), CAST(N'2026-12-31' AS Date), 1);
INSERT INTO dbo.[KhuyenMai] ([MaKM], [TenKM], [LoaiGiam], [MucGiam], [DieuKien], [NgayBatDau], [NgayKetThuc], [TrangThai]) VALUES (N'KM03', N'Chào bạn mới (CHAOSAN)', N'Số tiền', 30000.00, N'Dành cho khách hàng mới', CAST(N'2026-01-01' AS Date), CAST(N'2026-12-31' AS Date), 0);
INSERT INTO dbo.[KhuyenMai] ([MaKM], [TenKM], [LoaiGiam], [MucGiam], [DieuKien], [NgayBatDau], [NgayKetThuc], [TrangThai]) VALUES (N'SAN20', N'Ưu đãi sân bóng giảm 20%', N'Phần trăm', 20.00, N'', CAST(N'2026-10-19' AS Date), CAST(N'2026-12-31' AS Date), 0);
GO

-- ------------------------------------------------------------
-- BẢNG: DichVu (13 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV01', N'Nước suối', N'Chai', 5000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV02', N'Nước ngọt', N'Lon', 15000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV03', N'Thuê bóng', N'Quả', 30000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV04', N'Thuê giày', N'Đôi', 40000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV05', N'Thuê áo bib', N'Bộ', 50000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'DV06', N'Khăn lạnh', N'Cái', 5000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV01', N'Trà đá', N'Thùng', 50000.00, 1, 0);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV02', N'Nước suối', N'Chai', 5000.00, 1, 1);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV03', N'Coca', N'Lon', 10000.00, 1, 1);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV04', N'Pepsi', N'Lon', 10000.00, 1, 1);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV05', N'Revive chanh muối', N'Chai', 12000.00, 1, 1);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV06', N'Revive', N'Chai', 10000.00, 1, 1);
INSERT INTO dbo.[DichVu] ([MaDV], [TenDV], [DonViTinh], [DonGia], [TrangThai], [HoTroLoc]) VALUES (N'SV07', N'Aquarius', N'Chai', 12000.00, 1, 1);
GO

-- ------------------------------------------------------------
-- BẢNG: TieuChiDanhGia (6 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC01', N'Chất lượng mặt sân', NULL);
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC02', N'Cơ sở vật chất', NULL);
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC03', N'Vệ sinh sân', NULL);
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC04', N'Thái độ phục vụ của nhân viên', NULL);
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC05', N'Mức giá dịch vụ', NULL);
INSERT INTO dbo.[TieuChiDanhGia] ([MaTieuChi], [TenTieuChi], [MoTa]) VALUES (N'TC06', N'Mức độ hài lòng chung', NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: GiaTheoCa (3 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[GiaTheoCa] ([MaCa], [GioBatDau], [GioKetThuc], [DonGia]) VALUES (N'CHIEU', CAST(N'13:00:00' AS Time), CAST(N'19:00:00' AS Time), 130000.00);
INSERT INTO dbo.[GiaTheoCa] ([MaCa], [GioBatDau], [GioKetThuc], [DonGia]) VALUES (N'SANG', CAST(N'07:00:00' AS Time), CAST(N'13:00:00' AS Time), 90000.00);
INSERT INTO dbo.[GiaTheoCa] ([MaCa], [GioBatDau], [GioKetThuc], [DonGia]) VALUES (N'TOI', CAST(N'19:00:00' AS Time), CAST(N'22:00:00' AS Time), 180000.00);
GO

-- ------------------------------------------------------------
-- BẢNG: BaoCao (0 dòng)
-- ------------------------------------------------------------
-- (Bảng không có dữ liệu)

-- ------------------------------------------------------------
-- BẢNG: SaoLuu (0 dòng)
-- ------------------------------------------------------------
-- (Bảng không có dữ liệu)

-- ------------------------------------------------------------
-- BẢNG: PhanQuyen (19 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT01', N'CN02', 1, 1, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT01', N'CN04', 1, 1, 0, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT01', N'CN05', 1, 1, 0, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN01', 1, 1, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN02', 1, 1, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN03', 1, 1, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN04', 1, 1, 0, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN05', 1, 0, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT02', N'CN06', 1, 1, 0, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT03', N'CN04', 1, 1, 1, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT03', N'CN06', 1, 1, 0, 0);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN01', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN02', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN03', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN04', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN05', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN06', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN07', 1, 1, 1, 1);
INSERT INTO dbo.[PhanQuyen] ([MaVaiTro], [MaChucNang], [Xem], [Them], [Sua], [Xoa]) VALUES (N'VT04', N'CN08', 1, 1, 1, 1);
GO

-- ------------------------------------------------------------
-- BẢNG: TaiKhoan (7 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK01', N'admin', N'$2a$12$vekZmQ3WbxsLYYYnCwLPcOi375AbgvLyUgrjm4l3rbKrDVfmtcFLW', N'VT04', NULL, N'NV01', CAST(N'2026-10-01 21:11:52' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK02', N'nvsan', N'$2a$12$FATIYfJ0MTdHw97aIjYetul1Z7qAMbzU/lT2ElVK86hfu7Uus3eqa', N'VT02', NULL, N'NV02', CAST(N'2026-10-01 21:11:52' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK03', N'ketoan', N'$2a$12$MGfMeod.k8Z6RocUc/QFJeY8KfE0j3uP9StrTeTC/XFS4TZQYJpbW', N'VT03', NULL, N'NV03', CAST(N'2026-10-01 21:11:52' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK04', N'khachhang', N'$2a$12$FXt.u8cEtAFFqN06e5ZGpeALECPNWEj4Hb3ynJk9oRr6YYn0R5xkS', N'VT01', N'KH01', NULL, CAST(N'2026-10-01 21:11:52' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK69aa3723', N'quan_da', N'$2a$12$ipu.7VSx038bgy1QtYwPHe7uORhi17nRgPPs6vG9SWdeDtw3KAIMi', N'VT01', N'KHc64de18c', NULL, CAST(N'2026-10-14 15:37:42' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TK6b09c7f7', N'vgd_vgdsd', N'$2a$12$iM19VdmciTJPI8QcDc3HluwXee5go7qBfv37X.PztS4uMIJXWexDK', N'VT01', N'KH0f8b5de4', NULL, CAST(N'2026-10-16 22:07:47' AS DateTime), N'Hoạt động');
INSERT INTO dbo.[TaiKhoan] ([MaTK], [TenDangNhap], [MatKhau], [MaVaiTro], [MaKH], [MaNV], [NgayTao], [TrangThai]) VALUES (N'TKe09ddb74', N'phong_fs', N'$2a$12$dkOmz3eG3hQ5FimGfoYX5e698SKw2QtF6kkJTh.rEaVPN0CyqFYkW', N'VT01', N'KHdaefec74', NULL, CAST(N'2026-10-20 21:09:22' AS DateTime), N'Hoạt động');
GO

-- ------------------------------------------------------------
-- BẢNG: San (7 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S01', N'Sân A1', N'LS01', N'Đang sử dụng', N'Sân cỏ nhân tạo 5 người - Đèn LED');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S02', N'Sân A2', N'LS01', N'Đang sử dụng', N'Sân cỏ nhân tạo 5 người - Đèn LED');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S03', N'Sân A3', N'LS02', N'Đang sử dụng', N'Sân cỏ nhân tạo 5 người - Đang bảo trì');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S04', N'Sân A4', N'LS01', N'Trống', N'Sân cỏ nhân tạo 5 người, có mái che');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S05', N'Sân B1', N'LS02', N'Trống', N'Sân 7 người, hệ thống đèn chuẩn thi đấu');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N'S06', N'Sân B2', N'LS02', N'Bảo trì', N'Sân 7 người, đang bảo dưỡng mặt cỏ');
INSERT INTO dbo.[San] ([MaSan], [TenSan], [MaLoaiSan], [TrangThai], [MoTa]) VALUES (N's08', N'Sân08', N'LS02', N'Đang sử dụng', N'');
GO

-- ------------------------------------------------------------
-- BẢNG: BangGia (11 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG01', N'LS01', N'KG01', N'Ngày thường', 150000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG02', N'LS01', N'KG04', N'Ngày thường', 300000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG03', N'LS02', N'KG04', N'Ngày thường', 450000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG04', N'LS02', N'KG04', N'Cuối tuần', 500000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG05', N'LS01', N'KG02', N'Ngày thường', 200000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG06', N'LS01', N'KG03', N'Ngày thường', 250000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG07', N'LS01', N'KG05', N'Ngày thường', 200000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG08', N'LS02', N'KG01', N'Ngày thường', 250000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG09', N'LS02', N'KG02', N'Ngày thường', 350000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG10', N'LS02', N'KG03', N'Ngày thường', 400000.00, CAST(N'2026-01-01' AS Date), NULL);
INSERT INTO dbo.[BangGia] ([MaBangGia], [MaLoaiSan], [MaKhungGio], [LoaiNgay], [DonGia], [NgayHieuLuc], [NgayHetHieuLuc]) VALUES (N'BG11', N'LS02', N'KG05', N'Ngày thường', 300000.00, CAST(N'2026-01-01' AS Date), NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: DatSan (43 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS01', N'KH01', N'S01', N'KG03', CAST(N'2026-10-01' AS Date), 250000.00, 0.00, N'KM01', 20000.00, CAST(N'2026-10-01 21:11:52' AS DateTime), N'NV02', N'Đã xác nhận', N'Đặt trực tuyến', CAST(N'17:30:00' AS Time), CAST(N'19:00:00' AS Time), N'GIA_KHUNG', N'KHONG_RO', 1.50, 250000.00);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS02', N'KH02', N'S02', N'KG04', CAST(N'2026-10-01' AS Date), 300000.00, 0.00, NULL, 0.00, CAST(N'2026-10-01 21:11:52' AS DateTime), NULL, N'Đã xác nhận', N'Đặt trực tuyến', CAST(N'19:00:00' AS Time), CAST(N'20:30:00' AS Time), N'GIA_KHUNG', N'KHONG_RO', 1.50, 300000.00);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS15a5d94d', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-23' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 10:35:26' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'10:33:00' AS Time), CAST(N'11:33:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS1be023c7', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:39:45' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS2993f383', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:21:40' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS30a6aed0', N'KHe7347f1e', N'S01', NULL, CAST(N'2026-10-26' AS Date), 130000.00, 0.00, NULL, 0.00, CAST(N'2026-10-26 14:10:55' AS DateTime), N'NV02', N'Chờ xác nhận', NULL, CAST(N'15:10:00' AS Time), CAST(N'17:11:00' AS Time), N'GIA_GIO', N'TAI_QUAY', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS361bb875', N'KHc64de18c', N'S04', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 03:28:10' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS367339f9', N'KH8ae19d2f', N'S04', NULL, CAST(N'2026-10-20' AS Date), 130000.00, 0.00, NULL, 0.00, CAST(N'2026-10-20 13:55:21' AS DateTime), N'NV02', N'Chờ xác nhận', NULL, CAST(N'13:56:00' AS Time), CAST(N'14:56:00' AS Time), N'GIA_GIO', N'TAI_QUAY', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS3b97491a', N'KH01', N'S01', N'KG02', CAST(N'2026-10-16' AS Date), 200000.00, 0.00, NULL, 0.00, CAST(N'2026-10-02 22:58:05' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'16:00:00' AS Time), CAST(N'17:30:00' AS Time), N'GIA_KHUNG', N'KHONG_RO', 1.50, 200000.00);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS3c7fd553', N'KHc64de18c', N'S03', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 09:13:28' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'09:14:00' AS Time), CAST(N'10:14:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS419d883b', N'KHc64de18c', N'S02', NULL, CAST(N'2026-10-16' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-15 13:47:12' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:00:00' AS Time), CAST(N'09:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS4a8d412e', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 02:38:03' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS583ac166', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-17' AS Date), 130000.00, 0.00, NULL, 0.00, CAST(N'2026-10-17 13:56:35' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'14:56:00' AS Time), CAST(N'19:56:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS5b17fa31', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-18' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-18 08:50:25' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'08:51:00' AS Time), CAST(N'09:54:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS5bf454b0', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-20' AS Date), 130000.00, 0.00, NULL, 0.00, CAST(N'2026-10-20 16:55:33' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'16:56:00' AS Time), CAST(N'17:56:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS5c92b544', N'KH0f8b5de4', N's08', NULL, CAST(N'2026-10-18' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-16 22:08:11' AS DateTime), NULL, N'Đã xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS5f4f261a', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-18' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-18 08:51:05' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:52:00' AS Time), CAST(N'09:52:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS622125ef', N'KHc64de18c', N'S02', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 03:22:23' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:00:00' AS Time), CAST(N'10:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS6ae185a3', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-16' AS Date), 90000.00, 10000.00, NULL, 0.00, CAST(N'2026-10-16 08:57:47' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:58:00' AS Time), CAST(N'09:58:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS6dc55d36', N'KHc64de18c', N'S04', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:20:28' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS776a68a8', N'KHc64de18c', N'S04', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 30000.00, NULL, 0.00, CAST(N'2026-10-21 09:09:11' AS DateTime), NULL, N'Đã sử dụng', NULL, CAST(N'09:10:00' AS Time), CAST(N'10:10:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS7c177524', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 5000.00, N'KM02', 7500.00, CAST(N'2026-10-21 09:44:35' AS DateTime), NULL, N'Đã sử dụng', NULL, CAST(N'09:54:00' AS Time), CAST(N'10:44:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS805518a4', N'KHc64de18c', N'S03', NULL, CAST(N'2026-10-22' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 08:32:11' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:33:00' AS Time), CAST(N'09:33:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS81dd06cc', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:33:56' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DS99d5359e', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:26:58' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSa3a1e2ae', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-14' AS Date), 130000.00, 25000.00, NULL, 0.00, CAST(N'2026-10-14 15:40:51' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'16:00:00' AS Time), CAST(N'22:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSa49269f6', N'KHc64de18c', N'S02', NULL, CAST(N'2026-10-19' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:16:46' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSa5f0cc04', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 02:40:40' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSa9914634', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-22' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-22 11:37:49' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'11:55:00' AS Time), CAST(N'12:37:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSac2992e9', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-20' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 00:13:20' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSaf089e4f', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 08:43:29' AS DateTime), NULL, N'Đã xác nhận', NULL, CAST(N'08:44:00' AS Time), CAST(N'09:44:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSb3294259', N'KHdaefec74', N'S05', NULL, CAST(N'2026-10-21' AS Date), 130000.00, 5000.00, NULL, 0.00, CAST(N'2026-10-20 21:10:19' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'16:10:00' AS Time), CAST(N'22:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSb5fc0559', N'KHc64de18c', N'S02', NULL, CAST(N'2026-10-20' AS Date), 130000.00, 120000.00, NULL, 0.00, CAST(N'2026-10-20 13:26:35' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'13:27:00' AS Time), CAST(N'14:27:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSb8e725ef', N'KHc64de18c', N'S02', NULL, CAST(N'2026-10-17' AS Date), 180000.00, 0.00, NULL, 0.00, CAST(N'2026-10-16 19:09:34' AS DateTime), NULL, N'Đã hủy', NULL, CAST(N'19:10:00' AS Time), CAST(N'20:10:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSb9d7bd29', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-22' AS Date), 130000.00, 0.00, NULL, 0.00, CAST(N'2026-10-22 11:33:07' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'13:00:00' AS Time), CAST(N'15:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DScbe204c4', N'KHc64de18c', N'S05', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 08:41:31' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:44:00' AS Time), CAST(N'09:42:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSd5f58794', N'KHc64de18c', N's08', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 03:27:09' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSde60d0ed', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-15' AS Date), 180000.00, 0.00, NULL, 0.00, CAST(N'2026-10-15 19:41:43' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'19:42:00' AS Time), CAST(N'20:42:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSe2413eca', N'KHc64de18c', N'S03', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-20 22:32:29' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSe4899600', N'KHc64de18c', N'S04', NULL, CAST(N'2026-10-22' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-22 11:45:32' AS DateTime), NULL, N'Đã xác nhận', NULL, CAST(N'11:46:00' AS Time), CAST(N'12:46:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSebc7066e', N'KHc64de18c', N'S04', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 03:28:40' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSee55c36a', N'KH20e39c83', N'S02', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-19 02:24:00' AS DateTime), N'NV02', N'Chờ xác nhận', NULL, CAST(N'07:00:00' AS Time), CAST(N'08:00:00' AS Time), N'GIA_GIO', N'TAI_QUAY', NULL, NULL);
INSERT INTO dbo.[DatSan] ([MaDatSan], [MaKH], [MaSan], [MaKhungGio], [NgayChoi], [DonGia], [TienDichVu], [MaKM], [TienGiam], [NgayDat], [MaNV], [TrangThai], [GhiChu], [GioBatDau], [GioKetThuc], [CheDoGia], [HinhThucDat], [ThoiLuongLegacySnapshot], [TienSanLegacySnapshot]) VALUES (N'DSfd1965b2', N'KHc64de18c', N'S01', NULL, CAST(N'2026-10-21' AS Date), 90000.00, 0.00, NULL, 0.00, CAST(N'2026-10-21 08:28:40' AS DateTime), NULL, N'Chờ xác nhận', NULL, CAST(N'08:29:00' AS Time), CAST(N'09:29:00' AS Time), N'GIA_GIO', N'TRUC_TUYEN', NULL, NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: NhatKyHeThong (2149 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'00186fb058f9404', N'TK01', CAST(N'2026-10-08 13:22:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'006281d27160479', N'TK01', CAST(N'2026-10-08 09:00:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0075e85b9877468', N'TK02', CAST(N'2026-10-17 13:37:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'00a46e91e111461', N'TK01', CAST(N'2026-10-16 08:56:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'00c080376d0e4c3', N'TK69aa3723', CAST(N'2026-10-22 11:36:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'00cb7ad15f6540d', N'TK01', CAST(N'2026-10-08 08:59:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'00ded51de86b476', N'TK01', CAST(N'2026-10-08 12:03:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'011fb904c6f04ea', N'TK01', CAST(N'2026-10-16 23:59:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'012bb58c24ad4c3', N'TK01', CAST(N'2026-10-08 13:08:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'012e60f10bf0468', N'TK04', CAST(N'2026-10-02 22:57:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01374a5692e54e0', N'TK01', CAST(N'2026-10-08 23:18:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'014400b688f7466', N'TK01', CAST(N'2026-10-02 19:55:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01bdabac480c41c', N'TK02', CAST(N'2026-10-09 16:15:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01bf7daf8627448', N'TK02', CAST(N'2026-10-09 17:38:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01dd15d213b84a8', N'TK04', CAST(N'2026-10-15 23:38:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01f435b8ecce462', N'TK01', CAST(N'2026-10-08 12:05:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'01fedc33536a4b6', N'TK03', CAST(N'2026-10-21 03:35:08' AS DateTime), N'Tài chính', N'Sửa', N'DSa5f0cc04', N'Nhân viên xác nhận đã hoàn thực tế HT80fe36cd; 45000.00; Chuyển khoản', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'020bd9517628469', N'TK01', CAST(N'2026-10-08 17:18:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0241e92c6ce741c', N'TK69aa3723', CAST(N'2026-10-21 03:16:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0243fab2074949f', N'TK01', CAST(N'2026-10-08 09:03:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'024985a271f5415', N'TK69aa3723', CAST(N'2026-10-21 07:13:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'026777b7df9347f', N'TK04', CAST(N'2026-10-08 12:05:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0276178a4acd45d', N'TK69aa3723', CAST(N'2026-10-21 03:28:32' AS DateTime), N'Đặt sân', N'Sửa', N'DS361bb875', N'Hủy booking: dằ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'02ad470cb2f64be', N'TK01', CAST(N'2026-10-08 13:08:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'02ba69c8549f42a', N'TK01', CAST(N'2026-10-08 13:05:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'02be62084ec1417', N'TK01', CAST(N'2026-10-09 06:49:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'02f67d61ced6425', N'TK01', CAST(N'2026-10-08 13:08:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'03037e332f8544a', N'TK02', CAST(N'2026-10-09 17:40:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0303ad94e86e474', N'TK01', CAST(N'2026-10-08 09:05:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0343680f063047a', N'TK01', CAST(N'2026-10-08 17:18:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0349e8287251489', N'TK01', CAST(N'2026-10-09 16:15:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'03649821fe0347a', N'TK01', CAST(N'2026-10-09 06:09:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'03ac3553221149e', N'TK01', CAST(N'2026-10-09 06:48:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'03ddbd5ce520455', N'TK01', CAST(N'2026-10-09 06:50:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'03fa4f20c573428', N'TK02', CAST(N'2026-10-19 02:23:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04110d928b5b46b', N'TK69aa3723', CAST(N'2026-10-19 00:21:06' AS DateTime), N'Tài chính', N'Thêm', N'DS6dc55d36', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04186d65deba4d2', N'TK01', CAST(N'2026-10-08 13:05:14' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04199f95cee94c2', N'TK01', CAST(N'2026-10-08 09:00:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0424ba1f5d13464', N'TK01', CAST(N'2026-10-08 13:23:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0445224a7e7d4a2', N'TK02', CAST(N'2026-10-09 16:10:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'046b7cca250644d', N'TK01', CAST(N'2026-10-08 12:03:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0480cee41b0a47d', N'TK03', CAST(N'2026-10-15 23:39:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'049436d2bef4454', N'TK01', CAST(N'2026-10-08 12:05:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'049cc63d85d2460', N'TK04', CAST(N'2026-10-16 23:58:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04b46858c712464', N'TK01', CAST(N'2026-10-08 12:03:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04dedd7e1582471', N'TK69aa3723', CAST(N'2026-10-21 02:41:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'04ef351aca06442', N'TK04', CAST(N'2026-10-15 19:07:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0511187866e24ff', N'TK01', CAST(N'2026-10-09 06:10:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'051f548d7b6b4a7', N'TK04', CAST(N'2026-10-08 06:26:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0559341900b5454', N'TK01', CAST(N'2026-10-08 09:10:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'056812a7f006487', N'TK01', CAST(N'2026-10-08 06:08:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'05697156458b472', N'TK69aa3723', CAST(N'2026-10-21 08:41:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'057025beebc54c2', N'TK01', CAST(N'2026-10-09 16:12:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0570eddcfc804bd', N'TK01', CAST(N'2026-10-08 08:24:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0580bda7fb0b4c4', N'TK03', CAST(N'2026-10-09 06:09:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'05918b74993e413', N'TK01', CAST(N'2026-10-08 06:20:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'05b4886ca7a14cd', N'TK01', CAST(N'2026-10-09 17:38:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'05e52148acc5426', N'TK01', CAST(N'2026-10-09 06:11:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'05e81669921d439', N'TK01', CAST(N'2026-10-08 23:17:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0629fe24e02744b', N'TK01', CAST(N'2026-10-09 06:48:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'06318f8cb3054e2', N'TK02', CAST(N'2026-10-09 06:46:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'065eefd9ce9641d', N'TK02', CAST(N'2026-10-09 17:40:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'067191f1a049477', N'TK03', CAST(N'2026-10-17 18:22:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0681bca79432430', N'TK01', CAST(N'2026-10-09 06:10:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0699ec43a2514a9', N'TK69aa3723', CAST(N'2026-10-18 11:05:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'06a46bdb9ec749f', N'TK01', CAST(N'2026-10-08 13:05:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0745a1febbe144a', N'TK01', CAST(N'2026-10-02 23:29:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0792c3d497d347a', N'TK03', CAST(N'2026-10-09 06:49:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'07a1794739a5410', N'TK01', CAST(N'2026-10-08 13:07:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'07c1d2d67b03426', N'TK02', CAST(N'2026-10-19 02:29:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'07dff39d972442a', N'TK04', CAST(N'2026-10-17 18:42:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'07e705a68baa4d9', N'TK01', CAST(N'2026-10-19 14:08:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08479936949a497', N'TK69aa3723', CAST(N'2026-10-21 03:27:57' AS DateTime), N'Tài chính', N'Thêm', N'DSa5f0cc04', N'Hủy; tỷ lệ hoàn 50.00; thực thu 90000.00; yêu cầu hoàn 45000.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08685db4226c46d', N'TK01', CAST(N'2026-10-08 13:21:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0869be1353e84f4', N'TK04', CAST(N'2026-10-08 13:22:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'089771f6de004ad', N'TK03', CAST(N'2026-10-17 20:35:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08b906dedc8f42a', N'TK01', CAST(N'2026-10-09 17:38:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08d17ac40180459', N'TK01', CAST(N'2026-10-08 08:21:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08d75dd1a8094fa', N'TK03', CAST(N'2026-10-21 09:41:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08ed1f1d005042f', N'TK03', CAST(N'2026-10-09 17:38:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'08f741a7c56f490', N'TK01', CAST(N'2026-10-17 18:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'09b4fc9b16074db', N'TK69aa3723', CAST(N'2026-10-20 17:24:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'09bed55799544cd', N'TK01', CAST(N'2026-10-09 06:30:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'09f708ae1a8d4c0', N'TK01', CAST(N'2026-10-09 16:11:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0a2f18c684754b2', N'TK01', CAST(N'2026-10-08 06:21:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0a4607bbe14e498', N'TK01', CAST(N'2026-10-16 23:59:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0a7a64aca8db483', N'TK03', CAST(N'2026-10-08 13:08:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0a7f60a928d047d', N'TK01', CAST(N'2026-10-08 13:08:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b00ed7ba57841e', N'TK69aa3723', CAST(N'2026-10-21 09:09:13' AS DateTime), N'Tài chính', N'Thêm', N'DS776a68a8', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b122438cb4c4ef', N'TK02', CAST(N'2026-10-09 17:38:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b214243331a405', N'TK69aa3723', CAST(N'2026-10-16 08:17:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b2975150d214e1', N'TK01', CAST(N'2026-10-15 20:12:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b40fd6b99d543a', N'TK01', CAST(N'2026-10-17 18:20:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0b76bbd76086472', N'TK01', CAST(N'2026-10-09 17:39:26' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0bb272bebfe1444', N'TK02', CAST(N'2026-10-21 04:09:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0bc7e6888e8249e', N'TK01', CAST(N'2026-10-08 09:09:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0bcbef2c766e442', N'TK03', CAST(N'2026-10-17 16:43:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0bd6a905e23b4c9', N'TK01', CAST(N'2026-10-09 17:38:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0be845e7733146e', N'TK01', CAST(N'2026-10-09 06:48:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0c0addb31bee4af', N'TK01', CAST(N'2026-10-09 06:09:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0c1757b622de423', N'TK03', CAST(N'2026-10-08 13:12:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0caec0f51f9f45b', N'TK01', CAST(N'2026-10-09 06:50:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0cd1490991264c2', N'TK01', CAST(N'2026-10-08 17:19:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0cf0f6c08c554a7', N'TK02', CAST(N'2026-10-09 17:38:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0d0803252e154cf', N'TK04', CAST(N'2026-10-15 20:10:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0d2e3103a0a948e', N'TK03', CAST(N'2026-10-22 11:47:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0d407fcd40804eb', N'TK01', CAST(N'2026-10-15 23:43:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0d70665731fc4cb', N'TK01', CAST(N'2026-10-09 16:14:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0d9faf6f37924d9', N'TK03', CAST(N'2026-10-08 09:10:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0dbb330566984e4', N'TK01', CAST(N'2026-10-02 23:27:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0dc671020b2e414', N'TK69aa3723', CAST(N'2026-10-19 00:27:51' AS DateTime), N'Tài chính', N'Thêm', N'DS99d5359e', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0dc7395f575a44d', N'TK01', CAST(N'2026-10-08 23:16:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0df71d7d2522440', N'TK03', CAST(N'2026-10-08 23:17:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0e0ec65ae47f486', N'TK04', CAST(N'2026-10-16 23:59:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0e70680905494a1', N'TK03', CAST(N'2026-10-09 06:09:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0e73bcb675a44c5', N'TK01', CAST(N'2026-10-08 06:26:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0e76060cb3494ee', N'TK01', CAST(N'2026-10-08 08:17:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0e7dd2ebe997404', N'TK01', CAST(N'2026-10-09 16:14:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0ea547ebc0c443b', N'TK01', CAST(N'2026-10-09 06:50:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0ed8aa11ee7b42b', N'TK01', CAST(N'2026-10-09 06:48:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0edc9aac7fe1487', N'TK01', CAST(N'2026-10-09 17:38:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0f15c762fc3d492', N'TK01', CAST(N'2026-10-08 13:04:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0f232d60111349e', N'TK04', CAST(N'2026-10-08 08:26:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0f3efea4d26c4fe', N'TK01', CAST(N'2026-10-08 13:22:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0f64b74bac2747c', N'TK01', CAST(N'2026-10-09 17:38:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0fd0c6f2cef944c', N'TK01', CAST(N'2026-10-08 09:10:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'0fd969a9e195412', N'TK04', CAST(N'2026-10-17 17:18:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1000092fc6b94d5', N'TK02', CAST(N'2026-10-15 20:10:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'100a4887dbfa4bc', N'TK01', CAST(N'2026-10-08 12:02:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'100d3c66977b4d0', N'TK02', CAST(N'2026-10-09 17:40:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'101e3d39dfb5492', N'TK01', CAST(N'2026-10-08 08:17:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1046d1b7850f4c3', N'TK01', CAST(N'2026-10-08 06:19:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'104eb85ac5ce4bd', N'TK01', CAST(N'2026-10-08 12:03:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'109533c17975458', N'TK01', CAST(N'2026-10-08 09:05:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'109e28d03f44465', N'TK01', CAST(N'2026-10-02 22:40:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'10aff0d0fe224e7', N'TK01', CAST(N'2026-10-08 06:20:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'10b61eebcb93440', N'TK69aa3723', CAST(N'2026-10-22 11:40:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'10c113806bee416', N'TK03', CAST(N'2026-10-15 23:39:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'10c18cb7da214eb', N'TK01', CAST(N'2026-10-09 17:38:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'10c791f55dbc405', N'TK69aa3723', CAST(N'2026-10-20 16:55:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1103b2af013b42d', N'TK01', CAST(N'2026-10-09 17:39:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1122a4f00f26409', N'TK01', CAST(N'2026-10-08 09:06:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'112d100a31df437', N'TK69aa3723', CAST(N'2026-10-20 16:05:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1159735d80a24c0', N'TK01', CAST(N'2026-10-08 06:21:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'116c147d795145f', N'TK01', CAST(N'2026-10-09 17:37:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'116dd9c6d4a347a', N'TK6b09c7f7', CAST(N'2026-10-16 22:08:11' AS DateTime), N'Đặt sân', N'Thêm', N'DS5c92b544', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1181d4e0e6a04ce', N'TK03', CAST(N'2026-10-17 15:25:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'11893d26aee04d7', N'TK01', CAST(N'2026-10-09 17:38:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'119b4d6418824b2', N'TK01', CAST(N'2026-10-20 14:00:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'11cbf3aaa47a45a', N'TK69aa3723', CAST(N'2026-10-15 20:17:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'11d9bf86cfeb41e', N'TK69aa3723', CAST(N'2026-10-17 13:53:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'122c0e236c594e3', N'TK02', CAST(N'2026-10-15 23:38:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'122e60d9b4694bc', N'TK04', CAST(N'2026-10-09 06:48:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1245cd0ba7bc4bf', N'TK01', CAST(N'2026-10-08 09:03:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1247523cb27e475', N'TK01', CAST(N'2026-10-08 12:06:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'12486887c70044b', N'TK02', CAST(N'2026-10-09 16:13:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'12528ce3a32e47b', N'TK01', CAST(N'2026-10-09 06:09:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'12e67824f1b24cf', N'TK01', CAST(N'2026-10-08 23:16:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'12ea4baf64a5459', N'TK03', CAST(N'2026-10-15 23:41:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'134959cdb967473', N'TK01', CAST(N'2026-10-09 06:09:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'135005283c9f468', N'TK02', CAST(N'2026-10-09 16:15:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1367dc664ce849e', N'TK69aa3723', CAST(N'2026-10-21 02:39:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'13709acdba6f486', N'TK69aa3723', CAST(N'2026-10-21 08:41:36' AS DateTime), N'Tài chính', N'Thêm', N'DScbe204c4', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'13b57a832214492', N'TK03', CAST(N'2026-10-17 18:43:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'13c93c72f15d400', N'TK02', CAST(N'2026-10-20 21:39:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1415b1a68d8940a', N'TK03', CAST(N'2026-10-09 17:38:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'141c27759103497', N'TK01', CAST(N'2026-10-02 23:22:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'142fc7329cc041d', N'TK01', CAST(N'2026-10-09 06:50:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1482812110b6409', N'TK02', CAST(N'2026-10-17 16:49:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'14a9476ac04f4f8', N'TK01', CAST(N'2026-10-08 12:03:30' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'14dab09e38504c3', N'TK02', CAST(N'2026-10-21 08:47:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'150d29bb117f44f', N'TK02', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'152567d5444b431', N'TK01', CAST(N'2026-10-09 16:12:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1543b6e3a4814dc', N'TK01', CAST(N'2026-10-08 13:04:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'157559cc9154431', N'TK01', CAST(N'2026-10-08 13:08:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'15b3fbd32c664c3', N'TK04', CAST(N'2026-10-08 13:12:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'15c7a229ab16461', N'TK02', CAST(N'2026-10-09 06:46:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'15d80ce41531446', N'TK01', CAST(N'2026-10-08 17:19:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'15f3286285934fb', N'TK04', CAST(N'2026-10-17 00:01:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1645b526f5d94c8', N'TK69aa3723', CAST(N'2026-10-14 18:22:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'164fe333e52243a', N'TK02', CAST(N'2026-10-21 07:03:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'16926f94b621415', N'TK02', CAST(N'2026-10-09 06:49:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'16efc5548d7e454', N'TK01', CAST(N'2026-10-08 17:18:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1710c04d3b9e46f', N'TK01', CAST(N'2026-10-08 06:22:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'173fffc856dd465', N'TK01', CAST(N'2026-10-08 13:04:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'178082beaa8d40e', N'TK01', CAST(N'2026-10-09 17:38:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'179a03e3449d466', N'TK69aa3723', CAST(N'2026-10-19 00:21:40' AS DateTime), N'Đặt sân', N'Thêm', N'DS2993f383', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'17a8e71bfb4d481', N'TK01', CAST(N'2026-10-08 17:18:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'17b6fb50defd45f', N'TK03', CAST(N'2026-10-09 06:48:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'180a6f54bbc34fa', N'TK69aa3723', CAST(N'2026-10-15 20:17:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'180e24622f76420', N'TK01', CAST(N'2026-10-08 13:07:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'183b5527befd4d9', N'TK02', CAST(N'2026-10-16 19:43:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'184a050c69974cf', N'TK04', CAST(N'2026-10-15 18:54:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'184dacb2c9854b3', N'TK01', CAST(N'2026-10-08 09:10:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'18530a096f51414', N'TK01', CAST(N'2026-10-21 04:01:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1858c7af57134d5', N'TK01', CAST(N'2026-10-09 16:13:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'186ac3ae0dd0497', N'TK01', CAST(N'2026-10-02 23:22:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'186af7099e44493', N'TK02', CAST(N'2026-10-09 06:49:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'18c50e64131f45e', N'TK69aa3723', CAST(N'2026-10-21 08:31:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'18f072baf1c0477', N'TK01', CAST(N'2026-10-08 09:06:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'18fc0f3117f44f7', N'TK01', CAST(N'2026-10-08 17:18:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19013f093039445', N'TK01', CAST(N'2026-10-08 13:05:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1925f0c6085e424', N'TK01', CAST(N'2026-10-08 09:03:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1929261e7fc545b', N'TK01', CAST(N'2026-10-02 22:34:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'192c2b05db60445', N'TK01', CAST(N'2026-10-08 13:22:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1931c06461d3413', N'TK04', CAST(N'2026-10-17 17:18:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1934dc37f821428', N'TK01', CAST(N'2026-10-08 12:01:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19851cac06f441e', N'TK01', CAST(N'2026-10-09 06:10:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19968eb66e25424', N'TK04', CAST(N'2026-10-16 23:59:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1997dab161e846d', N'TK02', CAST(N'2026-10-21 08:41:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'199adf459206427', N'TK01', CAST(N'2026-10-09 06:09:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19b3357ffbf94a1', N'TK01', CAST(N'2026-10-09 06:48:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19dc0cd8df2547f', N'TK01', CAST(N'2026-10-09 16:14:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'19e55c8a0dee41c', N'TK01', CAST(N'2026-10-08 12:05:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1a0d8def4d3d4e4', N'TK02', CAST(N'2026-10-09 16:13:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1a3bd3e0b05247d', N'TK01', CAST(N'2026-10-09 16:12:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1a3cdc14300b4dc', N'TK01', CAST(N'2026-10-08 09:00:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1a61e8905bd8494', N'TK01', CAST(N'2026-10-09 06:08:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1a838352a5e0498', N'TK01', CAST(N'2026-10-09 06:50:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ab00913bdae482', N'TK01', CAST(N'2026-10-08 09:05:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ab1f57d5edb443', N'TK01', CAST(N'2026-10-08 17:18:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ab7bcb239a345f', N'TK01', CAST(N'2026-10-08 12:06:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ab9c2e94512484', N'TK01', CAST(N'2026-10-08 09:10:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ac9366fbf234ca', N'TK01', CAST(N'2026-10-08 12:03:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1af4b3f481ac447', N'TK02', CAST(N'2026-10-19 01:30:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1af9be8bab4c467', N'TK01', CAST(N'2026-10-02 21:09:55' AS DateTime), N'Quản lý sân', N'Thêm', N's08', N'Thêm sân Sân08', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b05c78f6cc84f8', N'TK03', CAST(N'2026-10-17 20:33:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b23d9a3accd47d', N'TK01', CAST(N'2026-10-09 06:49:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b26a0c7907b471', N'TK01', CAST(N'2026-10-08 06:21:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b43fab3b5c5453', N'TK69aa3723', CAST(N'2026-10-21 02:38:03' AS DateTime), N'Đặt sân', N'Thêm', N'DS4a8d412e', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b4c5f07f458480', N'TK01', CAST(N'2026-10-09 16:14:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1b501ccc12104e6', N'TK01', CAST(N'2026-10-08 12:01:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ba8d2a417304b8', N'TK01', CAST(N'2026-10-02 19:55:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1bb6d957eb254d6', N'TK01', CAST(N'2026-10-09 06:10:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1be050f29d3141b', N'TK01', CAST(N'2026-10-09 17:38:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1be35420ee95404', N'TK01', CAST(N'2026-10-08 13:04:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c0c8c85ddc444f', N'TK04', CAST(N'2026-10-09 06:50:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c0cd6a0dcd74a3', N'TK01', CAST(N'2026-10-09 17:38:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c1acffbb792425', N'TK03', CAST(N'2026-10-08 12:08:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c419b48d5b1463', N'TK04', CAST(N'2026-10-17 18:20:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c4557236948428', N'TK69aa3723', CAST(N'2026-10-20 13:26:35' AS DateTime), N'Đặt sân', N'Thêm', N'DSb5fc0559', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 250000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c4fa08402fb4fb', N'TK01', CAST(N'2026-10-08 12:03:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1c55d0cc15904ee', N'TK03', CAST(N'2026-10-09 16:57:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1cea812db6b34d2', N'TK04', CAST(N'2026-10-15 23:41:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d0862823977496', N'TK01', CAST(N'2026-10-08 13:21:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d20a0310ac945f', N'TK69aa3723', CAST(N'2026-10-19 00:59:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d282869ed294e9', N'TK04', CAST(N'2026-10-17 13:38:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d3fa753ae38402', N'TK01', CAST(N'2026-10-08 12:06:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d75e312d6a7466', N'TK01', CAST(N'2026-10-08 12:02:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1d8a915c842e462', N'TK01', CAST(N'2026-10-16 17:09:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1dba8ba6bf6a490', N'TK01', CAST(N'2026-10-08 13:04:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1dce477333ac454', N'TK03', CAST(N'2026-10-08 13:04:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ddfb2230c05471', N'TK01', CAST(N'2026-10-08 13:05:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1dfc3d9e4dda492', N'TK69aa3723', CAST(N'2026-10-16 10:10:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1e0af9022c3d4dc', N'TK01', CAST(N'2026-10-08 13:04:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1e52cb0013b940e', N'TK02', CAST(N'2026-10-20 14:15:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1e8b9dd4c47d4c9', N'TK01', CAST(N'2026-10-09 06:48:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1e9636f20e8745c', N'TK02', CAST(N'2026-10-15 20:12:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ec143de21fe457', N'TK01', CAST(N'2026-10-08 12:05:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1ed6371e2373421', N'TK02', CAST(N'2026-10-09 16:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f05c922d5cb4e4', N'TK01', CAST(N'2026-10-09 06:50:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f16c8faf481435', N'TK01', CAST(N'2026-10-09 06:30:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f2d6a116998475', N'TK01', CAST(N'2026-10-09 17:37:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f2e07fefe3748b', N'TK03', CAST(N'2026-10-16 19:43:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f3dfa74225f425', N'TK02', CAST(N'2026-10-15 23:41:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f41f7f89951401', N'TK03', CAST(N'2026-10-08 13:22:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'1f8611908e7041d', N'TK01', CAST(N'2026-10-08 12:06:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'202c3ad212d6437', N'TK69aa3723', CAST(N'2026-10-16 19:09:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20379dc419224d6', N'TK02', CAST(N'2026-10-09 16:16:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'206e7ef7b0db436', N'TK02', CAST(N'2026-10-08 12:05:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'207df6c50ecf4f1', N'TK02', CAST(N'2026-10-16 17:09:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2089d2bb938e46f', N'TK01', CAST(N'2026-10-08 17:19:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20a466290a374b8', N'TK01', CAST(N'2026-10-08 23:18:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20a9326d4aab4f9', N'TK01', CAST(N'2026-10-08 13:34:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20af20b85bcb440', N'TK01', CAST(N'2026-10-08 13:05:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20c41128347241c', N'TK01', CAST(N'2026-10-21 04:08:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20e0e9dca1da454', N'TK01', CAST(N'2026-10-08 08:21:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'20e4000fbb38437', N'TK03', CAST(N'2026-10-15 18:55:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'210a09402ab848a', N'TK01', CAST(N'2026-10-17 13:39:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'210d51691d144eb', N'TK69aa3723', CAST(N'2026-10-21 09:43:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'212480832313466', N'TK69aa3723', CAST(N'2026-10-21 02:37:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'21848af7bd074d4', N'TK03', CAST(N'2026-10-19 02:43:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2195dafcec81409', N'TK01', CAST(N'2026-10-08 08:17:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'21beb5be6c934a1', N'TK04', CAST(N'2026-10-18 00:04:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'21d136fd66e14e0', N'TK01', CAST(N'2026-10-08 12:06:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'21f5c91554b0488', N'TK02', CAST(N'2026-10-20 22:07:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'21fe8c20a0d04db', N'TK01', CAST(N'2026-10-14 18:35:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2238f7bcbc6e477', N'TK02', CAST(N'2026-10-21 09:11:10' AS DateTime), N'Nhận sân / Dịch vụ', N'Sửa', N'DS776a68a8', N'Trả sân; chốt snapshot hóa đơn, chưa tự thu tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'22397c79b5cf40b', N'TK69aa3723', CAST(N'2026-10-20 21:39:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'22b51e77625c4db', N'TK01', CAST(N'2026-10-09 06:10:48' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'22c7af0e8fdd498', N'TK02', CAST(N'2026-10-17 13:37:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'22ca92e0493146f', N'TK02', CAST(N'2026-10-09 17:40:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'22d0218f3b4347b', N'TK01', CAST(N'2026-10-08 13:23:05' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2301a729983a4b3', N'TK69aa3723', CAST(N'2026-10-17 14:02:27' AS DateTime), N'Đặt sân', N'Sửa', N'DS583ac166', N'Hủy booking: gzx', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'23033dd67d5a412', N'TK69aa3723', CAST(N'2026-10-18 08:50:58' AS DateTime), N'Đặt sân', N'Sửa', N'DS5b17fa31', N'Hủy booking: edfgh', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'23127acd222140d', N'TK69aa3723', CAST(N'2026-10-20 13:26:35' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DSb5fc0559', N'Dịch vụ đặt trước; 1 dòng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'232fdfaeccb2494', N'TK01', CAST(N'2026-10-08 13:07:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'23a6722a07b3459', N'TK01', CAST(N'2026-10-09 06:09:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'242dcc0369934a7', N'TK01', CAST(N'2026-10-08 23:16:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'24689b75372f40e', N'TK01', CAST(N'2026-10-08 06:22:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'246e83512fc347c', N'TK01', CAST(N'2026-10-08 06:20:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2478a633c02744c', N'TK03', CAST(N'2026-10-15 23:43:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2498dc88c50049e', N'TK03', CAST(N'2026-10-17 14:22:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'24d5935ebaad44e', N'TK03', CAST(N'2026-10-15 19:09:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'24d6760ea92a4dc', N'TK02', CAST(N'2026-10-19 02:24:00' AS DateTime), N'Đặt sân', N'Thêm', N'DSee55c36a', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'24f227e4b055444', N'TK69aa3723', CAST(N'2026-10-20 13:27:32' AS DateTime), N'Tài chính', N'Thêm', N'DSb5fc0559', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2510338d93494ef', N'TK01', CAST(N'2026-10-17 17:17:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'25131e8e3e554e4', N'TK01', CAST(N'2026-10-09 06:48:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'254b3a69ee19411', N'TK01', CAST(N'2026-10-08 12:05:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2555a04115104bb', N'TK03', CAST(N'2026-10-21 10:45:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2585f5a0376b475', N'TK04', CAST(N'2026-10-15 23:38:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'25898bc3a5bf476', N'TK03', CAST(N'2026-10-09 17:37:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'258d535b7596465', N'TK02', CAST(N'2026-10-17 15:24:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'25b4a0270b6341f', N'TK01', CAST(N'2026-10-08 09:10:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'25f41763d0ba432', N'TK01', CAST(N'2026-10-08 13:08:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2607e2d5be33480', N'TK01', CAST(N'2026-10-08 17:18:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'26133636c5424e7', N'TK01', CAST(N'2026-10-08 12:05:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'261360fbe8b1486', N'TK02', CAST(N'2026-10-21 09:08:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2629058f471d4d0', N'TK01', CAST(N'2026-10-08 12:06:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'264338d33799415', N'TK69aa3723', CAST(N'2026-10-19 01:13:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'265a523dd0bb473', N'TK69aa3723', CAST(N'2026-10-21 09:44:35' AS DateTime), N'Đặt sân', N'Thêm', N'DS7c177524', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 75000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'265b5df1ae1a4dc', N'TK01', CAST(N'2026-10-08 23:18:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2669e12fecb84e7', N'TK01', CAST(N'2026-10-02 23:27:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'268d0f2ef1ea45c', N'TK02', CAST(N'2026-10-21 08:47:42' AS DateTime), N'Đặt sân', N'Sửa', N'DSaf089e4f', N'Xác nhận booking', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2692b66603cc497', N'TK01', CAST(N'2026-10-08 23:17:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'26c22529dff6464', N'TK01', CAST(N'2026-10-02 22:38:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'26e6be312def48d', N'TK01', CAST(N'2026-10-08 09:10:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2717697b84dc40c', N'TK02', CAST(N'2026-10-09 17:38:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'273365a382104c1', N'TK01', CAST(N'2026-10-08 06:20:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'27c7b1de909c4f2', N'TK02', CAST(N'2026-10-21 09:03:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'27ea1264a9504aa', N'TK69aa3723', CAST(N'2026-10-16 17:00:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'27fffe2414b446c', N'TK01', CAST(N'2026-10-09 06:09:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28790994c14a464', N'TK01', CAST(N'2026-10-08 09:09:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'287f505d87404ba', N'TK01', CAST(N'2026-10-09 06:48:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28d22cb685854e4', N'TK04', CAST(N'2026-10-18 10:50:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28d8389ac13d428', N'TK01', CAST(N'2026-10-09 17:37:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28e6848ba42b484', N'TK01', CAST(N'2026-10-16 17:09:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28f0ca649527442', N'TK01', CAST(N'2026-10-09 17:39:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'28fbf776a0a844f', N'TK01', CAST(N'2026-10-09 17:38:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'291af341b58d4ad', N'TK01', CAST(N'2026-10-08 13:23:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'291bde4ee788421', N'TK69aa3723', CAST(N'2026-10-21 08:41:31' AS DateTime), N'Đặt sân', N'Thêm', N'DScbe204c4', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 87000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'291f8a7cc3384ef', N'TK01', CAST(N'2026-10-08 13:08:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2994073129f24d9', N'TK01', CAST(N'2026-10-08 09:10:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2a3ab96e33244a7', N'TK69aa3723', CAST(N'2026-10-18 23:29:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2a5185f691904a4', N'TK01', CAST(N'2026-10-09 06:48:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2a99e78d1caf4d5', N'TK01', CAST(N'2026-10-09 06:49:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2aa22f45bdbf4c5', N'TK01', CAST(N'2026-10-08 23:18:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2aaf2bc2ec2f4b3', N'TK03', CAST(N'2026-10-09 06:09:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2acbbce785324c3', N'TK01', CAST(N'2026-10-09 06:11:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ae326ad533542c', N'TK01', CAST(N'2026-10-09 17:39:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2af9def83b1943b', N'TK01', CAST(N'2026-10-17 18:42:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2aff144ffc70475', N'TK01', CAST(N'2026-10-15 19:07:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2b2a0dd04fca49d', N'TK02', CAST(N'2026-10-09 16:15:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2b4a15c508eb4bc', N'TK69aa3723', CAST(N'2026-10-22 11:38:39' AS DateTime), N'Tài chính', N'Thêm', N'DSa9914634', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2b65a2f76a10421', N'TK01', CAST(N'2026-10-08 17:18:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2b76d5c114dd478', N'TK69aa3723', CAST(N'2026-10-20 13:24:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2b9eeb4acefa40b', N'TK04', CAST(N'2026-10-17 00:51:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2bbf1845f73244d', N'TK01', CAST(N'2026-10-15 19:37:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2bfb0f1f4abf428', N'TK03', CAST(N'2026-10-21 09:25:08' AS DateTime), N'Tài chính', N'Thêm', N'DS3c7fd553', N'Ghi nhận thực thu 90000', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2bfd2cdb4d884d2', N'TK69aa3723', CAST(N'2026-10-21 03:28:14' AS DateTime), N'Tài chính', N'Thêm', N'DS361bb875', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2c0e37046d35415', N'TK02', CAST(N'2026-10-19 02:24:00' AS DateTime), N'Đặt sân', N'Thêm', N'KH20e39c83', N'Tạo hồ sơ khách tại quầy', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2c0f407f7ced48c', N'TK01', CAST(N'2026-10-08 13:05:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2c3df7bc95a9441', N'TK69aa3723', CAST(N'2026-10-19 00:27:51' AS DateTime), N'Tài chính', N'Thêm', N'DS99d5359e', N'Hủy; tỷ lệ hoàn 50.00; thực thu 0.00; yêu cầu hoàn 0.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2c5732a63fad4f0', N'TK02', CAST(N'2026-10-09 16:10:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2c5b4fc7c46e420', N'TK01', CAST(N'2026-10-15 18:55:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2cc59ca3c11c489', N'TK02', CAST(N'2026-10-09 16:07:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2cd6a4dbd8e14d9', N'TK03', CAST(N'2026-10-08 09:10:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2cd8c8532192400', N'TK01', CAST(N'2026-10-08 13:03:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2cdf1eec5e6b4e7', N'TK04', CAST(N'2026-10-17 18:22:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ce5599bb3024e1', N'TK04', CAST(N'2026-10-09 16:15:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2d128f1b9f77469', N'TK69aa3723', CAST(N'2026-10-18 08:58:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2d18b5964730428', N'TK69aa3723', CAST(N'2026-10-21 03:27:20' AS DateTime), N'Tài chính', N'Thêm', N'DSd5f58794', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2d2749b21821403', N'TK02', CAST(N'2026-10-20 21:39:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2d52015d520e492', N'TK02', CAST(N'2026-10-09 06:51:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2d5d3c8dc9cf4d5', N'TK02', CAST(N'2026-10-17 14:22:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2dbb5c591263460', N'TK01', CAST(N'2026-10-08 17:18:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2dd21f19e0114f8', N'TK01', CAST(N'2026-10-08 13:05:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2dd68354bfff4a3', N'TK01', CAST(N'2026-10-08 13:22:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ddbecabc416412', N'TK01', CAST(N'2026-10-09 06:51:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2dedf23375c94f0', N'TK04', CAST(N'2026-10-15 20:13:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2df15155163d43d', N'TK69aa3723', CAST(N'2026-10-26 14:03:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2e026667b6c148b', N'TK02', CAST(N'2026-10-09 06:49:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2e0fa973c7ed45d', N'TK01', CAST(N'2026-10-08 08:24:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2e32349811604e2', N'TK01', CAST(N'2026-10-09 06:49:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2e330093f98244e', N'TK01', CAST(N'2026-10-17 17:18:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ebfe35ce26c48f', N'TK01', CAST(N'2026-10-17 16:43:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ed15e0f75e34ed', N'TK01', CAST(N'2026-10-08 17:28:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2eddfb88f417495', N'TK01', CAST(N'2026-10-08 17:18:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2ee32081b852484', N'TK02', CAST(N'2026-10-19 02:24:13' AS DateTime), N'Quản lý sân', N'Sửa', N'S01', N'Trạng thái: Trống → Đang sử dụng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2f2fccd0b1f2444', N'TK04', CAST(N'2026-10-08 08:26:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2f3e9f37869f486', N'TK01', CAST(N'2026-10-09 06:09:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2f60b3f24583493', N'TK69aa3723', CAST(N'2026-10-16 19:10:04' AS DateTime), N'Tài chính', N'Thêm', N'DSb8e725ef', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2f9390200f6c47c', N'TK04', CAST(N'2026-10-08 13:22:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2fcd1303c2b8411', N'TK01', CAST(N'2026-10-08 13:13:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2fceb0d9344a41c', N'TK01', CAST(N'2026-10-08 08:18:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'2fe174f485f24d2', N'TK69aa3723', CAST(N'2026-10-15 23:25:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3055f96c90194a2', N'TK03', CAST(N'2026-10-21 03:34:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3097e1fa4ae9474', N'TK01', CAST(N'2026-10-14 18:38:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'30ae53e478ad498', N'TK03', CAST(N'2026-10-08 13:07:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'30b0fbcbd624477', N'TK01', CAST(N'2026-10-08 13:08:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'30b1b4978d1e4e1', N'TK03', CAST(N'2026-10-15 23:38:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'30d080c1e48d425', N'TK02', CAST(N'2026-10-09 17:38:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'30d1e967faf141a', N'TK02', CAST(N'2026-10-15 20:12:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'310025ecb62a4d6', N'TK01', CAST(N'2026-10-09 16:14:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3108adaaf91b476', N'TK01', CAST(N'2026-10-08 23:18:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'311da4af628e4a5', N'TK01', CAST(N'2026-10-09 06:06:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'311e55066c8c4e2', N'TK01', CAST(N'2026-10-08 09:10:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'31b33b135efc49f', N'TK01', CAST(N'2026-10-08 12:06:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'31b81673a4b0496', N'TK01', CAST(N'2026-10-09 16:13:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'31d3e097369e4be', N'TK04', CAST(N'2026-10-15 23:41:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'31e9bd9bd55b49e', N'TK03', CAST(N'2026-10-08 17:26:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'31e9bf6f76d044a', N'TK01', CAST(N'2026-10-08 13:23:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3225f98ebf454b8', N'TK01', CAST(N'2026-10-09 16:12:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'323075671686453', N'TK03', CAST(N'2026-10-08 13:11:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'323630eae79d4c5', N'TK01', CAST(N'2026-10-08 23:17:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'323fb0a8914b4b5', N'TK01', CAST(N'2026-10-08 13:07:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'324cb8580ae947a', N'TK69aa3723', CAST(N'2026-10-21 10:24:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32601146a8844fb', N'TK01', CAST(N'2026-10-09 17:37:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32609611bbbd471', N'TK03', CAST(N'2026-10-08 12:05:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3262e7ca48c645b', N'TK01', CAST(N'2026-10-08 13:04:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3286939f0d52481', N'TK69aa3723', CAST(N'2026-10-21 03:28:32' AS DateTime), N'Tài chính', N'Thêm', N'DS361bb875', N'Hủy; tỷ lệ hoàn 50.00; thực thu 0.00; yêu cầu hoàn 0.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'329a19a2846d4de', N'TK01', CAST(N'2026-10-08 23:17:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32f3afac33ef44b', N'TK01', CAST(N'2026-10-08 23:20:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32f4aa90940d40a', N'TK01', CAST(N'2026-10-08 09:03:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32fda2c78b7c45a', N'TK01', CAST(N'2026-10-09 16:12:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'32ff375fada54bc', N'TK03', CAST(N'2026-10-08 17:18:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3307ac29119d414', N'TK01', CAST(N'2026-10-08 09:03:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'330bbeed519d4ca', N'TK01', CAST(N'2026-10-08 06:19:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'333ce2dc44b44a6', N'TK02', CAST(N'2026-10-17 00:01:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'333e5644a59a4b5', N'TK69aa3723', CAST(N'2026-10-15 13:44:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'335e7634b1654d9', N'TK04', CAST(N'2026-10-15 19:00:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'337466595232470', N'TK03', CAST(N'2026-10-08 17:19:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'337a32aa87624c0', N'TK02', CAST(N'2026-10-09 16:18:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33853f1c59c24e4', N'TK02', CAST(N'2026-10-09 16:10:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33b008f431934ef', N'TK01', CAST(N'2026-10-09 06:10:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33d43929f7a14b1', N'TK01', CAST(N'2026-10-15 19:09:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33ddfa6e6b23447', N'TK03', CAST(N'2026-10-21 10:46:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33df6f570d3d453', N'TK03', CAST(N'2026-10-08 12:03:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'33e0dc0cc9e0492', N'TK04', CAST(N'2026-10-08 13:07:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'344dc0b50d6c4a2', N'TK02', CAST(N'2026-10-20 22:07:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'34508ee69fd745b', N'TK6b09c7f7', CAST(N'2026-10-16 22:07:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK6b09c7f7', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3455d42bebec433', N'TK01', CAST(N'2026-10-08 12:03:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3457bc6aa3fc4f4', N'TK02', CAST(N'2026-10-20 14:16:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'345bd7d4200540e', N'TK01', CAST(N'2026-10-08 08:21:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'34ba966a8a3d46c', N'TK01', CAST(N'2026-10-08 09:05:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'34c5d4fc5bd04ac', N'TK01', CAST(N'2026-10-09 06:49:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3544fcc0b6e4462', N'TK01', CAST(N'2026-10-08 12:01:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3548cfe34f894ca', N'TK01', CAST(N'2026-10-08 09:00:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3553634b666a40b', N'TK04', CAST(N'2026-10-15 20:14:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'35586cf9341f4c1', N'TK69aa3723', CAST(N'2026-10-18 19:04:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3564e70dee7f480', N'TK01', CAST(N'2026-10-09 16:14:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'35710a088317459', N'TK04', CAST(N'2026-10-09 16:12:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'35fff01e5fcd4af', N'TK01', CAST(N'2026-10-08 23:17:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'366570422c00443', N'TK6b09c7f7', CAST(N'2026-10-16 22:07:47' AS DateTime), N'Authentication / Phân quyền', N'Thêm', N'TK6b09c7f7', N'Đăng ký tài khoản khách hàng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'366f7409891b418', N'TK04', CAST(N'2026-10-17 15:24:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'367be174a8a3463', N'TK01', CAST(N'2026-10-09 16:12:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'368126d917654c9', N'TK01', CAST(N'2026-10-16 16:58:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'369b770f697d4c7', N'TK02', CAST(N'2026-10-15 23:38:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'36a500b8906b44a', N'TK04', CAST(N'2026-10-17 00:51:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'36e86e07002b498', N'TK01', CAST(N'2026-10-08 12:06:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37624e56aea341a', N'TK01', CAST(N'2026-10-08 09:03:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3793a852f7df48b', N'TK01', CAST(N'2026-10-21 03:45:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37940400dbed49b', N'TK01', CAST(N'2026-10-09 17:39:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37a06803a826435', N'TK04', CAST(N'2026-10-16 09:29:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37a1e4f70a7f45f', N'TK69aa3723', CAST(N'2026-10-21 10:36:03' AS DateTime), N'Tài chính', N'Thêm', N'DS15a5d94d', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37d33c6a624340b', N'TK01', CAST(N'2026-10-08 08:21:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'37fe5e6c6dc3490', N'TK03', CAST(N'2026-10-21 02:42:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3813d3cf0cf840f', N'TK02', CAST(N'2026-10-21 08:42:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3816dbc5c9df430', N'TK69aa3723', CAST(N'2026-10-17 13:58:00' AS DateTime), N'Tài chính', N'Thêm', N'DS583ac166', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38473d150ee8497', N'TK01', CAST(N'2026-10-08 06:23:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'385ccc2bcbbb4ee', N'TK03', CAST(N'2026-10-08 23:17:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38664f488c6b414', N'TK03', CAST(N'2026-10-09 17:40:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38941b36f8b2432', N'TK02', CAST(N'2026-10-09 16:13:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38a3fae6db1a4f9', N'TK01', CAST(N'2026-10-09 16:12:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38b2a1eb9cb140b', N'TK01', CAST(N'2026-10-08 13:04:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38d3e5d6fe99441', N'TK01', CAST(N'2026-10-08 17:18:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'38fc04890dcd4bb', N'TK69aa3723', CAST(N'2026-10-16 08:56:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3900e646fcb3441', N'TK01', CAST(N'2026-10-08 12:03:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'390a861d32e64fc', N'TK03', CAST(N'2026-10-17 18:20:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'39104b92adeb402', N'TK01', CAST(N'2026-10-09 16:12:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'39247c1dc08b405', N'TK01', CAST(N'2026-10-08 23:16:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'392b590ce67847c', N'TK02', CAST(N'2026-10-16 17:09:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3934a5dc1bce41b', N'TK01', CAST(N'2026-10-08 13:07:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'393cbf1579b3482', N'TK01', CAST(N'2026-10-08 17:18:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'394111239950491', N'TK01', CAST(N'2026-10-19 15:04:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'39921e235b564d5', N'TK04', CAST(N'2026-10-17 14:24:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'399bc655b4f8498', N'TK02', CAST(N'2026-10-21 04:08:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'39f07312298e4a9', N'TK01', CAST(N'2026-10-08 12:05:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'39f79eb8d212420', N'TK01', CAST(N'2026-10-08 09:06:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3a2bba0a9884456', N'TK01', CAST(N'2026-10-08 06:07:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3a30667192674ac', N'TK02', CAST(N'2026-10-21 03:47:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3a6ee1d9bcfa416', N'TK02', CAST(N'2026-10-22 11:34:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3a7eb5df29b3440', N'TK02', CAST(N'2026-10-21 07:01:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3ad5bfdd3ae741c', N'TK02', CAST(N'2026-10-20 13:31:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3b8ba93b5fa84bd', N'TK02', CAST(N'2026-10-20 13:55:38' AS DateTime), N'Quản lý sân', N'Sửa', N'S02', N'Trạng thái: Trống → Đang sử dụng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3b8ec175dd1e400', N'TK01', CAST(N'2026-10-09 17:38:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3bbf7d55a3c84f2', N'TK02', CAST(N'2026-10-09 06:46:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3bceefd7964e4b8', N'TK69aa3723', CAST(N'2026-10-21 08:32:21' AS DateTime), N'Tài chính', N'Thêm', N'DS805518a4', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3bed97cb2b744c5', N'TK01', CAST(N'2026-10-08 13:08:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3c145b8f2f3e42e', N'TK02', CAST(N'2026-10-08 13:11:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3c29bc0ce2054fe', N'TK69aa3723', CAST(N'2026-10-21 03:27:57' AS DateTime), N'Đặt sân', N'Sửa', N'DSa5f0cc04', N'Hủy booking: eaaarth', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3c64d3da917c4f8', N'TK01', CAST(N'2026-10-09 06:48:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3c6ab999f21d46c', N'TK01', CAST(N'2026-10-09 17:39:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3c9e2bff1d854e9', N'TK69aa3723', CAST(N'2026-10-18 08:50:36' AS DateTime), N'Tài chính', N'Thêm', N'DS5b17fa31', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3cb7f4ae35ee4ea', N'TK01', CAST(N'2026-10-09 06:51:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3cbbbbcbe409443', N'TK01', CAST(N'2026-10-08 09:10:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3cc99d3e93a0498', N'TK69aa3723', CAST(N'2026-10-22 12:08:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3cdde876168d48b', N'TK01', CAST(N'2026-10-08 13:08:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3d1a4fb8f15e4a1', N'TK69aa3723', CAST(N'2026-10-16 08:59:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3d62f966395148e', N'TK04', CAST(N'2026-10-08 17:19:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3d68500c33e94d1', N'TK01', CAST(N'2026-10-08 13:21:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3dbf4398c2504a5', N'TK01', CAST(N'2026-10-09 17:38:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3dcb25954fef4f4', N'TK04', CAST(N'2026-10-15 23:39:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3dce432a056b4b3', N'TK01', CAST(N'2026-10-09 06:09:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3dfb06ebf5b94d1', N'TK01', CAST(N'2026-10-09 06:08:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3e38d873fc7744b', N'TK03', CAST(N'2026-10-17 13:37:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3e410422f0134b7', N'TK69aa3723', CAST(N'2026-10-22 11:34:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3e6d924d7d60447', N'TK03', CAST(N'2026-10-09 17:38:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3e6e3afbddd14f5', N'TK02', CAST(N'2026-10-16 19:43:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3ec33484603b47b', N'TK01', CAST(N'2026-10-08 23:17:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3ee324604e2b42d', N'TK01', CAST(N'2026-10-09 06:10:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3ef80d67b8764fb', N'TK02', CAST(N'2026-10-08 12:08:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3f5127f91c824f9', N'TK03', CAST(N'2026-10-15 18:55:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3f7e64292a414bd', N'TK01', CAST(N'2026-10-08 17:19:33' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3f9ec5dd4745496', N'TK01', CAST(N'2026-10-08 12:05:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fbab959cbe2425', N'TK01', CAST(N'2026-10-08 12:03:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fc5f6ffb8544df', N'TK01', CAST(N'2026-10-08 09:10:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fd7cd9b2bf141e', N'TK69aa3723', CAST(N'2026-10-21 03:47:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fe35ac1f380419', N'TK01', CAST(N'2026-10-08 13:23:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fe9530d2c204b6', N'TK69aa3723', CAST(N'2026-10-18 22:43:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3ffadca6b9eb489', N'TK01', CAST(N'2026-10-08 13:04:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'3fffdc63c9724f9', N'TK01', CAST(N'2026-10-09 16:13:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4006b8d2696c469', N'TK02', CAST(N'2026-10-16 23:59:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4047e31b0e1c4b5', N'TK02', CAST(N'2026-10-09 16:10:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4093f1a8d31e46c', N'TK01', CAST(N'2026-10-08 06:19:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'409daf18ea62424', N'TK01', CAST(N'2026-10-09 17:37:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'40b2262c70634e7', N'TK01', CAST(N'2026-10-09 06:48:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'40b318c9476341d', N'TK01', CAST(N'2026-10-08 13:22:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'411ffe5cf796426', N'TK02', CAST(N'2026-10-09 06:49:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4137a3a7aab8486', N'TK02', CAST(N'2026-10-21 08:31:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'415ff8af94ca464', N'TK01', CAST(N'2026-10-09 06:09:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'41638938eb8b4f5', N'TK01', CAST(N'2026-10-08 17:19:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'416f52f700dd4f1', N'TK02', CAST(N'2026-10-09 16:13:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4194a999b49349b', N'TK01', CAST(N'2026-10-08 06:23:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'41ced7c58235417', N'TK69aa3723', CAST(N'2026-10-21 03:28:57' AS DateTime), N'Tài chính', N'Thêm', N'DSebc7066e', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'41d576374ec54b6', N'TK02', CAST(N'2026-10-08 12:07:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'41fcfa52c8f64a8', N'TK01', CAST(N'2026-10-21 04:02:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'424fa6a1324a48b', N'TK01', CAST(N'2026-10-09 06:48:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4252589de19f4a7', N'TK03', CAST(N'2026-10-17 20:32:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'42539fd786b34af', N'TK69aa3723', CAST(N'2026-10-16 10:11:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'42709bfa63a14df', N'TK01', CAST(N'2026-10-17 15:24:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'42836205c61d45e', N'TK01', CAST(N'2026-10-08 08:18:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'428e89fc02f5401', N'TK02', CAST(N'2026-10-09 06:46:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'42b4d072806d435', N'TK01', CAST(N'2026-10-08 12:06:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'42ef501b56ea4ad', N'TK03', CAST(N'2026-10-08 09:05:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43044be2c45a4a3', N'TK02', CAST(N'2026-10-20 21:53:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43296ba43ca54df', N'TK01', CAST(N'2026-10-09 06:48:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'433414c86d6841f', N'TK01', CAST(N'2026-10-09 06:09:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'433f1e39602f41b', N'TK03', CAST(N'2026-10-17 15:22:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43524d3ecc31424', N'TK01', CAST(N'2026-10-09 06:49:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'437a1f5ea37049e', N'TK01', CAST(N'2026-10-08 12:02:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43a714aa60374d9', N'TK01', CAST(N'2026-10-08 17:19:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43b3c17ad7fd458', N'TK69aa3723', CAST(N'2026-10-20 22:31:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'43f8071666eb4cb', N'TK03', CAST(N'2026-10-21 09:51:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'440e112827be473', N'TK02', CAST(N'2026-10-09 16:10:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'441ab0a5a4cf42c', N'TK01', CAST(N'2026-10-08 17:18:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4439ca627c4745e', N'TK02', CAST(N'2026-10-09 06:46:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'443b84c586e34c3', N'TK04', CAST(N'2026-10-15 19:06:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'445adceba788474', N'TK01', CAST(N'2026-10-08 23:18:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'44782bc4abba40d', N'TK03', CAST(N'2026-10-15 23:38:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'44c0a9c2609e40e', N'TK01', CAST(N'2026-10-08 06:07:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'44dab4d881f2425', N'TK01', CAST(N'2026-10-08 13:05:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'44ebe8e36c9641e', N'TK04', CAST(N'2026-10-17 14:22:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'44ebf9094a574b5', N'TK01', CAST(N'2026-10-08 09:03:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'450af70674244b2', N'TK03', CAST(N'2026-10-22 11:46:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'452ae847bb4d48a', N'TK01', CAST(N'2026-10-02 20:00:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'456a2798ad61442', N'TK04', CAST(N'2026-10-09 16:12:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4573d6447071440', N'TK01', CAST(N'2026-10-09 16:13:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'457e0a0470d84a3', N'TK02', CAST(N'2026-10-16 16:49:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'458042a4bb5148f', N'TK02', CAST(N'2026-10-20 21:40:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'45ab137d721044a', N'TK01', CAST(N'2026-10-19 13:13:50' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cấu hình promotion-status SAN20; giữ nguyên snapshot lịch sử', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'461a6829b6ec454', N'TK69aa3723', CAST(N'2026-10-15 23:24:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'465543bc38c644f', N'TK01', CAST(N'2026-10-08 23:18:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4681b85a9c934d7', N'TK02', CAST(N'2026-10-15 23:41:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'468293fed1df450', N'TK01', CAST(N'2026-10-08 13:22:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'468e8007c2cd420', N'TK01', CAST(N'2026-10-09 16:12:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46a56ee8df25462', N'TK01', CAST(N'2026-10-08 13:23:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46bb5344d3ce416', N'TK01', CAST(N'2026-10-08 12:06:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46be68157aa94d3', N'TK02', CAST(N'2026-10-08 13:34:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46c2ee5e33e5410', N'TK01', CAST(N'2026-10-08 17:18:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46cc4b0f40da4e4', N'TK01', CAST(N'2026-10-02 20:00:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'46de090064984fc', N'TK01', CAST(N'2026-10-09 16:12:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'471571a05cf64ef', N'TK02', CAST(N'2026-10-17 17:37:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4759d003e2f6441', N'TK02', CAST(N'2026-10-09 17:40:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'475ca2059a544be', N'TK01', CAST(N'2026-10-09 17:37:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'47609888cc81402', N'TK01', CAST(N'2026-10-08 23:18:37' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'476c5f0bdf80489', N'TK01', CAST(N'2026-10-08 17:18:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'477a744b373b46d', N'TK01', CAST(N'2026-10-09 17:38:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4789c4a49e8b401', N'TK04', CAST(N'2026-10-02 22:58:05' AS DateTime), N'Đặt sân', N'Thêm', N'DS3b97491a', N'Tạo booking; giá BG05; tổng 200000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'47d445985fb1431', N'TK02', CAST(N'2026-10-19 01:38:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'480a18a17660488', N'TK01', CAST(N'2026-10-09 16:12:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'484a3913e1264b2', N'TK01', CAST(N'2026-10-09 16:12:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'48ddf2bb4d084a5', N'TK69aa3723', CAST(N'2026-10-21 08:42:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'48e73412dfee439', N'TK04', CAST(N'2026-10-15 23:43:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4901c15318d2492', N'TK01', CAST(N'2026-10-08 13:07:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'493f331e004b470', N'TK03', CAST(N'2026-10-08 12:05:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4942ac7a17e1474', N'TK01', CAST(N'2026-10-08 13:04:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'496f25d751b64bb', N'TK01', CAST(N'2026-10-08 06:21:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'497d5626838e474', N'TK03', CAST(N'2026-10-15 19:00:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'497de9f15b07441', N'TK02', CAST(N'2026-10-08 17:18:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'497e99521b1c4cf', N'TK01', CAST(N'2026-10-02 22:40:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49ba5d596677428', N'TK04', CAST(N'2026-10-09 06:48:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49c4b4c3e2a443b', N'TK01', CAST(N'2026-10-08 12:05:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49dbf312d29c43e', N'TK03', CAST(N'2026-10-20 22:31:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49dc42ecc6d9486', N'TK03', CAST(N'2026-10-09 06:48:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49f258e5c4f9429', N'TK01', CAST(N'2026-10-09 06:50:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'49f4cc92b9f3447', N'TK01', CAST(N'2026-10-08 13:05:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4a2557bf6b58412', N'TK01', CAST(N'2026-10-09 06:10:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4a6700d66325426', N'TK01', CAST(N'2026-10-08 08:59:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4a6b3f01fcd445a', N'TK01', CAST(N'2026-10-20 14:03:03' AS DateTime), N'Quản trị', N'Sửa', N'TK02', N'Cập nhật trạng thái/role tài khoản: VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4a70e3d16119416', N'TK01', CAST(N'2026-10-08 09:17:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4aac2f745d984fd', N'TK01', CAST(N'2026-10-08 13:23:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4ac207b20c184a9', N'TK01', CAST(N'2026-10-08 09:03:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4adeb4b07ba14cf', N'TK01', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b035eecd71040e', N'TK02', CAST(N'2026-10-02 22:49:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b0629b4f2af436', N'TK01', CAST(N'2026-10-08 23:17:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b1ca329d3f649f', N'TK01', CAST(N'2026-10-17 13:37:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b23d1fc2b6444d', N'TK02', CAST(N'2026-10-08 13:04:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b3a95822a0c4c0', N'TK01', CAST(N'2026-10-09 06:09:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b3b01e17c5146e', N'TK01', CAST(N'2026-10-09 16:15:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b7097ce3a90426', N'TK69aa3723', CAST(N'2026-10-20 16:55:34' AS DateTime), N'Đặt sân', N'Thêm', N'DS5bf454b0', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 130000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b78bc938d214de', N'TK01', CAST(N'2026-10-08 17:18:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4b90d63f8f40439', N'TK69aa3723', CAST(N'2026-10-20 21:40:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4bbf8270ac474e9', N'TK69aa3723', CAST(N'2026-10-20 17:53:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4be9f7032e11499', N'TK01', CAST(N'2026-10-16 19:44:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c01a402a52b4fb', N'TK02', CAST(N'2026-10-20 13:52:40' AS DateTime), N'Tài chính', N'Thêm', N'DSb5fc0559', N'Ghi nhận thực thu 250000', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c0abb3eaee749e', N'TK01', CAST(N'2026-10-09 16:13:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c125ec473c0470', N'TK01', CAST(N'2026-10-08 17:19:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c3c407062e44f3', N'TK01', CAST(N'2026-10-08 06:07:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c51f725e9804f6', N'TK03', CAST(N'2026-10-08 09:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c54d5e8c73c4a5', N'TK01', CAST(N'2026-10-09 06:10:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c8e234e12c045a', N'TK01', CAST(N'2026-10-08 13:11:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4c96e2dacf8f4ad', N'TK69aa3723', CAST(N'2026-10-21 10:36:03' AS DateTime), N'Tài chính', N'Thêm', N'DS15a5d94d', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4ca7815f350a4bb', N'TK04', CAST(N'2026-10-17 17:37:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4cbc7346ec5a4ed', N'TK01', CAST(N'2026-10-09 06:48:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4cc599be7ebe455', N'TK01', CAST(N'2026-10-19 13:06:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4cf5b33a5176467', N'TK03', CAST(N'2026-10-17 18:20:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d023e5cb7d4489', N'TK01', CAST(N'2026-10-17 15:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d02d24511534a6', N'TK02', CAST(N'2026-10-17 15:15:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d31e7040d974c8', N'TK04', CAST(N'2026-10-09 16:13:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d35e16d2de344a', N'TK01', CAST(N'2026-10-08 13:21:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d4b925a864741e', N'TK01', CAST(N'2026-10-08 23:16:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d6ac0cee6864db', N'TK03', CAST(N'2026-10-19 13:06:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d9060f7e4374d7', N'TK01', CAST(N'2026-10-09 17:38:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d91c7ffe0ea4fb', N'TK01', CAST(N'2026-10-08 08:21:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4d9da33faaa6493', N'TK01', CAST(N'2026-10-08 13:07:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4da25214ee314bc', N'TK01', CAST(N'2026-10-08 12:06:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4db173f4fd7b483', N'TK01', CAST(N'2026-10-08 08:20:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4e102e4f90fe4f3', N'TK01', CAST(N'2026-10-08 12:05:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4e4303deae744e1', N'TK04', CAST(N'2026-10-15 23:41:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4e8a3fd5a6244fd', N'TK02', CAST(N'2026-10-22 11:45:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4e8d5b131af8495', N'TK01', CAST(N'2026-10-08 06:07:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4ea4dbb2ea72471', N'TK01', CAST(N'2026-10-09 06:09:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4eb067f15a6746a', N'TK01', CAST(N'2026-10-15 23:43:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4f0751a610f3418', N'TK01', CAST(N'2026-10-09 06:49:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4f1a6cf740b140a', N'TK01', CAST(N'2026-10-09 16:16:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4f395ef489e541f', N'TK03', CAST(N'2026-10-19 12:20:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4f40aadd21a84d7', N'TK01', CAST(N'2026-10-09 06:08:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4f7eeb57e6ff447', N'TK01', CAST(N'2026-10-08 13:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'4fa79330ecbf4dc', N'TK01', CAST(N'2026-10-08 13:07:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50650e6c5596499', N'TK03', CAST(N'2026-10-16 22:16:57' AS DateTime), N'Tài chính', N'Thêm', N'DS5c92b544', N'Ghi nhận thực thu 90000', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'506923451065455', N'TK01', CAST(N'2026-10-08 13:05:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'506fba7f9c0245c', N'TK01', CAST(N'2026-10-08 06:22:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'508e32e29ab742f', N'TK01', CAST(N'2026-10-09 06:09:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50a95c3605264a6', N'TK01', CAST(N'2026-10-08 09:09:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50ae03d86ec2413', N'TK69aa3723', CAST(N'2026-10-21 03:53:36' AS DateTime), N'Authentication / Phân quyền', N'Thêm', N'TK69aa3723', N'Gửi phản hồi', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50eb49e68402408', N'TK02', CAST(N'2026-10-15 19:00:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50eba037c3ef4c1', N'TK01', CAST(N'2026-10-09 06:09:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'50ec0f73e7d1436', N'TK01', CAST(N'2026-10-08 12:03:30' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5103583f6412460', N'TK01', CAST(N'2026-10-09 06:49:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5134c6b8209346c', N'TK01', CAST(N'2026-10-08 13:04:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'513f2162f7c9479', N'TK01', CAST(N'2026-10-09 06:51:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5145a1605f5447d', N'TK03', CAST(N'2026-10-14 18:35:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'515145c9617a4c9', N'TK01', CAST(N'2026-10-08 08:26:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'516b795a8c61429', N'TK01', CAST(N'2026-10-08 17:18:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'51ab11d8bedf46e', N'TK01', CAST(N'2026-10-08 17:19:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'51cbdc1fe60a488', N'TK01', CAST(N'2026-10-08 17:18:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'51f99a1c95af43d', N'TK01', CAST(N'2026-10-09 16:13:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5203fff9c1a6420', N'TK04', CAST(N'2026-10-09 16:16:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'520434eeeb8847b', N'TK01', CAST(N'2026-10-08 17:19:33' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5209ca0da737424', N'TK01', CAST(N'2026-10-08 08:26:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'523b2e357db2403', N'TK01', CAST(N'2026-10-08 23:18:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5261cb83f5c64b6', N'TK03', CAST(N'2026-10-20 14:01:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52624e36d7244c6', N'TK02', CAST(N'2026-10-15 18:41:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'526b2628dd44421', N'TK03', CAST(N'2026-10-08 17:18:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'528a6f07cac7406', N'TK01', CAST(N'2026-10-08 13:07:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'528d7a3780b04e9', N'TK01', CAST(N'2026-10-08 13:04:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5290bede6eb54a1', N'TK69aa3723', CAST(N'2026-10-18 08:50:25' AS DateTime), N'Đặt sân', N'Thêm', N'DS5b17fa31', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 94500.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52ae683c8ee549c', N'TK02', CAST(N'2026-10-17 18:20:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52bbbb7177ff46d', N'TK01', CAST(N'2026-10-09 06:49:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52ca76e421284a4', N'TK01', CAST(N'2026-10-08 13:04:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52f73a5f31ba4d0', N'TK01', CAST(N'2026-10-09 17:38:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'52fe78e3835b4e2', N'TK69aa3723', CAST(N'2026-10-22 11:38:39' AS DateTime), N'Tài chính', N'Thêm', N'DSa9914634', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'53152e7c6f6449c', N'TK01', CAST(N'2026-10-16 08:18:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'53205877066d436', N'TK02', CAST(N'2026-10-09 16:15:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5326ced4744246a', N'TK69aa3723', CAST(N'2026-10-21 08:41:36' AS DateTime), N'Tài chính', N'Thêm', N'DScbe204c4', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'53368c06e6c143b', N'TK02', CAST(N'2026-10-09 16:13:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5344f25c0657476', N'TK01', CAST(N'2026-10-09 06:10:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5348bbeeedf9462', N'TK01', CAST(N'2026-10-09 06:09:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'537ddab98918498', N'TK69aa3723', CAST(N'2026-10-21 09:45:28' AS DateTime), N'Tài chính', N'Thêm', N'DS7c177524', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'538a8633e59a47a', N'TK01', CAST(N'2026-10-08 13:04:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'538fc2a5349b401', N'TK03', CAST(N'2026-10-09 16:13:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'538fdb4b9a8c45e', N'TK69aa3723', CAST(N'2026-10-14 19:52:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5398c4ea3b9e449', N'TK01', CAST(N'2026-10-08 13:07:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'53fd3a0642c24df', N'TK01', CAST(N'2026-10-02 22:34:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54347c53a71141d', N'TK69aa3723', CAST(N'2026-10-21 03:28:40' AS DateTime), N'Đặt sân', N'Thêm', N'DSebc7066e', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5460033dbcdd4fb', N'TK02', CAST(N'2026-10-08 13:12:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54976421d193499', N'TK01', CAST(N'2026-10-09 06:09:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54bb1cb6043e4fb', N'TK01', CAST(N'2026-10-08 17:26:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54d09bdad8e240d', N'TK03', CAST(N'2026-10-17 00:53:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54da7a87ccd84b4', N'TK01', CAST(N'2026-10-08 08:21:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54efe002a96c486', N'TK02', CAST(N'2026-10-17 00:51:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'54f3f45863a540a', N'TK02', CAST(N'2026-10-21 09:13:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5520a597532d49d', N'TK01', CAST(N'2026-10-08 12:03:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5529976736994fd', N'TK02', CAST(N'2026-10-21 09:10:27' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DS776a68a8', N'Nhận sân', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'552b6d8e2f964f1', N'TK01', CAST(N'2026-10-08 12:05:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5534a1485f53430', N'TK01', CAST(N'2026-10-08 09:00:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'553d927a6f3d41e', N'TK01', CAST(N'2026-10-08 17:31:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5546bb61ad28450', N'TK01', CAST(N'2026-10-08 12:03:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'555113525da3494', N'TK01', CAST(N'2026-10-09 16:12:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5564dc247ff34f2', N'TK69aa3723', CAST(N'2026-10-21 10:29:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'557141786eeb4c6', N'TK03', CAST(N'2026-10-17 00:51:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55b9e5923b3843d', N'TK02', CAST(N'2026-10-09 16:13:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55c93ae1f79e462', N'TK02', CAST(N'2026-10-15 20:14:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55c955dbf8fc4a1', N'TK69aa3723', CAST(N'2026-10-16 10:14:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55CDCA05E91E479', N'TK01', CAST(N'2026-10-19 00:37:31' AS DateTime), N'Khuyến mãi', N'Sửa', N'SAN20', N'Tác vụ bảo trì Codex theo yêu cầu người dùng; nhật ký gắn tài khoản quản trị TK01 (không phải phiên đăng nhập TK01): ngừng KM01/KM03, giữ KM02, thêm SAN20 giảm 20% tiền sân từ 19/10/2026 đến 31/12/2026. Không sửa snapshot booking hoặc lịch sử tài chính.', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55dcfa2b4eff440', N'TK01', CAST(N'2026-10-08 23:17:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55de4224411e4ea', N'TK03', CAST(N'2026-10-17 00:53:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'55f9d8ae0b83426', N'TK01', CAST(N'2026-10-09 17:37:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5634f4597fe240f', N'TK01', CAST(N'2026-10-09 16:12:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'564c40407adb430', N'TK04', CAST(N'2026-10-17 18:22:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5651a24a76ca475', N'TK01', CAST(N'2026-10-08 12:06:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5677de193778496', N'TK03', CAST(N'2026-10-17 00:01:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'568154bc4ba843c', N'TK02', CAST(N'2026-10-09 16:10:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'56848157963748c', N'TK01', CAST(N'2026-10-15 14:41:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'568694f1107e48c', N'TK01', CAST(N'2026-10-09 06:48:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'56d7c4d4d129499', N'TK02', CAST(N'2026-10-09 06:49:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'56f5dc16216e4c3', N'TK01', CAST(N'2026-10-08 09:10:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5709f402209a42d', N'TK01', CAST(N'2026-10-08 09:03:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'57177a30801a4b9', N'TK01', CAST(N'2026-10-08 13:07:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5736eb0fcbc941d', N'TK69aa3723', CAST(N'2026-10-16 19:10:04' AS DateTime), N'Tài chính', N'Thêm', N'DSb8e725ef', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5757d7209f8d480', N'TK01', CAST(N'2026-10-09 17:39:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5773930e28da424', N'TK01', CAST(N'2026-10-15 23:41:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5793bd006ae8454', N'TK01', CAST(N'2026-10-08 12:02:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'57999da6b817493', N'TK02', CAST(N'2026-10-19 02:43:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'57d0e14f99d740a', N'TK01', CAST(N'2026-10-14 18:35:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'580d1755504d4fc', N'TK04', CAST(N'2026-10-08 12:05:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'581864126c8b428', N'TK01', CAST(N'2026-10-16 19:46:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'586e1c070030464', N'TK03', CAST(N'2026-10-08 09:03:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'58796f147718446', N'TK04', CAST(N'2026-10-17 18:22:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'587981eade774a9', N'TK01', CAST(N'2026-10-09 06:09:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'58ae179243e7475', N'TK02', CAST(N'2026-10-21 03:53:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59147f4484bd458', N'TK01', CAST(N'2026-10-09 06:09:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'594872966d344ef', N'TK01', CAST(N'2026-10-08 13:07:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'597a0b7ce1cb445', N'TK04', CAST(N'2026-10-02 22:49:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'599ab9b017f645b', N'TK69aa3723', CAST(N'2026-10-17 14:02:27' AS DateTime), N'Tài chính', N'Thêm', N'DS583ac166', N'Hủy; tỷ lệ hoàn 0.00; thực thu 0.00; yêu cầu hoàn 0.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59b2a5bf804c45c', N'TK02', CAST(N'2026-10-09 06:46:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59b9519aa0f94b2', N'TK01', CAST(N'2026-10-09 06:48:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59c705ef014245f', N'TK01', CAST(N'2026-10-08 23:17:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59cdaaa78cc84d7', N'TK01', CAST(N'2026-10-09 06:49:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'59e54093b6c0455', N'TK69aa3723', CAST(N'2026-10-19 00:58:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5a31ce248649482', N'TK03', CAST(N'2026-10-09 16:15:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5a59f56d88354bb', N'TK04', CAST(N'2026-10-17 15:22:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5a77215509c841b', N'TK01', CAST(N'2026-10-08 17:19:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5af367007d1948f', N'TK02', CAST(N'2026-10-09 06:49:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b11b714168b463', N'TK01', CAST(N'2026-10-08 23:17:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b33b37d2b0c48a', N'TK01', CAST(N'2026-10-08 13:07:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b36f0f81048497', N'TK01', CAST(N'2026-10-08 17:26:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b55bec00da04c8', N'TK01', CAST(N'2026-10-08 13:07:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b57dc31f3a04bd', N'TK02', CAST(N'2026-10-09 16:16:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b59e3c2df3740a', N'TK02', CAST(N'2026-10-09 17:38:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b5d1d558bbf46e', N'TK02', CAST(N'2026-10-17 20:33:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b7ae2a8b470440', N'TK01', CAST(N'2026-10-08 13:04:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b85741abdd04e5', N'TK01', CAST(N'2026-10-02 23:22:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b859ee305b548b', N'TK69aa3723', CAST(N'2026-10-16 19:10:23' AS DateTime), N'Đặt sân', N'Sửa', N'DSb8e725ef', N'Hủy booking: sdfghbmn,', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5b96f4923daf44c', N'TK04', CAST(N'2026-10-08 12:06:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5beb43e6e18c408', N'TK04', CAST(N'2026-10-08 17:26:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5c16afd4d36844d', N'TK01', CAST(N'2026-10-09 16:12:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5c3db8341c53441', N'TK03', CAST(N'2026-10-08 12:06:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5c6d904ff9654e4', N'TK01', CAST(N'2026-10-09 06:09:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5c7aeeb614be42e', N'TK01', CAST(N'2026-10-17 13:37:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5c965ee241c94e5', N'TK01', CAST(N'2026-10-08 09:00:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5ce3a274252a4d3', N'TK04', CAST(N'2026-10-08 09:13:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5cec5d5cfed24b3', N'TK01', CAST(N'2026-10-09 17:37:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d12320040c044a', N'TK04', CAST(N'2026-10-08 08:44:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d4fc1a08dd2436', N'TK01', CAST(N'2026-10-08 08:24:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d56dd048f5b43c', N'TK02', CAST(N'2026-10-16 16:48:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d6396cd9aae43f', N'TK01', CAST(N'2026-10-09 06:48:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d64fdc7d86744b', N'TK04', CAST(N'2026-10-16 09:32:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5d6cb2ec3e6e4fa', N'TK01', CAST(N'2026-10-09 17:38:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5dbba01974d1456', N'TK01', CAST(N'2026-10-08 13:22:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5dd4a660b486447', N'TK01', CAST(N'2026-10-08 08:17:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5e2aede83c414a1', N'TK01', CAST(N'2026-10-16 16:58:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5e42d24119d942b', N'TK04', CAST(N'2026-10-15 19:09:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5e66e100ba1444a', N'TK03', CAST(N'2026-10-21 04:01:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5e6fbf42c3c94fa', N'TK01', CAST(N'2026-10-08 13:05:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5e843b63232446d', N'TK01', CAST(N'2026-10-09 06:50:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5ea7a125b0d0434', N'TK03', CAST(N'2026-10-16 19:43:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5eb2ed71d02642b', N'TK01', CAST(N'2026-10-08 13:21:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5edcdd92b505490', N'TK01', CAST(N'2026-10-19 15:30:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5eeb0b0c8b0d48d', N'TK04', CAST(N'2026-10-08 13:04:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5ef9da6adc77405', N'TK01', CAST(N'2026-10-09 06:48:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f1e2f82bd7745f', N'TK01', CAST(N'2026-10-08 08:59:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f24a67a06a1414', N'TK03', CAST(N'2026-10-09 16:12:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f2f900489d247e', N'TK01', CAST(N'2026-10-08 23:17:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f3055b9e283473', N'TK01', CAST(N'2026-10-09 17:38:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f5f167c4d3147f', N'TK01', CAST(N'2026-10-09 17:37:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f612f33084d4ba', N'TK02', CAST(N'2026-10-09 16:15:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f7560aefb9b445', N'TK69aa3723', CAST(N'2026-10-17 13:58:00' AS DateTime), N'Tài chính', N'Thêm', N'DS583ac166', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5f8e24f7ee1740f', N'TK01', CAST(N'2026-10-09 06:09:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5fa7d76d918546a', N'TK01', CAST(N'2026-10-09 06:08:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5fb4aafce9914b4', N'TK01', CAST(N'2026-10-09 16:12:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5fcd3678c1424b0', N'TK03', CAST(N'2026-10-08 09:10:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'5fed925ea4bb496', N'TK04', CAST(N'2026-10-09 06:09:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6009427b89f6499', N'TK01', CAST(N'2026-10-08 17:18:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6054e64e756a42b', N'TK04', CAST(N'2026-10-17 17:17:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'60841d407af9444', N'TK04', CAST(N'2026-10-17 13:52:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'609c39eaa05e44a', N'TK04', CAST(N'2026-10-08 23:17:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'60aff16d9940498', N'TK02', CAST(N'2026-10-09 06:30:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6121dd709d584a6', N'TK01', CAST(N'2026-10-17 18:22:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'613c240cafdf4ea', N'TK01', CAST(N'2026-10-09 17:38:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'618777e8fd6941d', N'TK03', CAST(N'2026-10-20 22:07:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'618c3adbe5b84a3', N'TK01', CAST(N'2026-10-09 16:14:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'61d18677f46143d', N'TK01', CAST(N'2026-10-09 17:38:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'61d3dc81bda5482', N'TK04', CAST(N'2026-10-15 23:38:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'61f8d79588c1449', N'TK01', CAST(N'2026-10-08 13:13:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'61fac98231f9467', N'TK02', CAST(N'2026-10-08 13:07:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6210dcece5b14f8', N'TK03', CAST(N'2026-10-15 23:43:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'622fe7311b4f46a', N'TK01', CAST(N'2026-10-08 17:19:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6258f03a249b424', N'TK01', CAST(N'2026-10-17 17:37:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'626deedc675a4cd', N'TK01', CAST(N'2026-10-08 09:17:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'628662e73d9c487', N'TK01', CAST(N'2026-10-09 16:14:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'629f0c5282d245f', N'TK01', CAST(N'2026-10-16 20:27:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62ad34453c074bf', N'TK01', CAST(N'2026-10-09 16:16:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62b8cae91e49431', N'TK04', CAST(N'2026-10-15 18:54:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62cae5df89ee465', N'TK02', CAST(N'2026-10-17 20:47:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62d52420ab654ef', N'TK04', CAST(N'2026-10-09 17:38:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62dcacbe033540f', N'TK02', CAST(N'2026-10-09 16:54:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62defcc3d220475', N'TK01', CAST(N'2026-10-20 14:05:06' AS DateTime), N'Danh mục dịch vụ', N'Sửa', N'DV01', N'Giá 10000.00 -> 5000; kinh doanh true; lốc false', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'62e0325bf494498', N'TK01', CAST(N'2026-10-09 17:37:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6314b7ae5665489', N'TK69aa3723', CAST(N'2026-10-18 08:50:36' AS DateTime), N'Tài chính', N'Thêm', N'DS5b17fa31', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'635baecec8e4418', N'TK01', CAST(N'2026-10-08 23:16:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'63c0b1c1844c480', N'TK69aa3723', CAST(N'2026-10-21 07:13:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6431ae74ec24472', N'TK03', CAST(N'2026-10-09 16:12:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'64414270de33414', N'TK04', CAST(N'2026-10-15 19:00:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6446e07024ab494', N'TK01', CAST(N'2026-10-08 08:59:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'64507a5b98a349e', N'TK69aa3723', CAST(N'2026-10-21 10:36:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6452c528507a439', N'TK03', CAST(N'2026-10-21 09:35:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'64656e2424c54b7', N'TK01', CAST(N'2026-10-09 17:38:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'64b84ac28c9c431', N'TK01', CAST(N'2026-10-08 12:08:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'64bc6f5657d943a', N'TK01', CAST(N'2026-10-08 09:17:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'650a6fd46528428', N'TK01', CAST(N'2026-10-09 06:10:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6527b61ca58e4e1', N'TK01', CAST(N'2026-10-09 17:40:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'652c238d1b46468', N'TK01', CAST(N'2026-10-08 12:02:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'652c5d843a1241b', N'TK01', CAST(N'2026-10-18 09:01:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6575b311e8534ae', N'TK01', CAST(N'2026-10-09 06:48:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'657e5e4303ee4a3', N'TK01', CAST(N'2026-10-08 08:20:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'65e27665741645e', N'TK02', CAST(N'2026-10-15 23:41:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'664368d19e994ab', N'TK01', CAST(N'2026-10-15 20:10:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'664b1c529d5b47a', N'TK04', CAST(N'2026-10-15 20:13:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'665b95f8d53e44c', N'TK02', CAST(N'2026-10-21 08:54:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'665c9402f7d44bb', N'TK03', CAST(N'2026-10-17 17:37:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'66640a82e70247c', N'TK01', CAST(N'2026-10-08 08:24:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'666795be5ad04ec', N'TK69aa3723', CAST(N'2026-10-16 19:09:34' AS DateTime), N'Đặt sân', N'Thêm', N'DSb8e725ef', N'Tạo booking giờ tự do; giá/giờ 180000.00; tổng 180000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'668d7de715d5488', N'TK01', CAST(N'2026-10-08 17:18:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'66c21ed3249246b', N'TK02', CAST(N'2026-10-14 18:35:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'66cfb892f0b7467', N'TK03', CAST(N'2026-10-09 16:12:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'66e2286a441c439', N'TK69aa3723', CAST(N'2026-10-14 15:37:42' AS DateTime), N'Authentication / Phân quyền', N'Thêm', N'TK69aa3723', N'Đăng ký tài khoản khách hàng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6710b258e6094cc', N'TK01', CAST(N'2026-10-09 06:48:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'675ff3ce7eb04a4', N'TK01', CAST(N'2026-10-08 17:19:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'676a7361c95d4cc', N'TK02', CAST(N'2026-10-22 11:40:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'677489112fec4e4', N'TK01', CAST(N'2026-10-08 23:17:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6787a817118d45a', N'TK01', CAST(N'2026-10-09 06:48:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'67974428f053426', N'TK01', CAST(N'2026-10-08 13:04:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6799a4a605c847e', N'TK04', CAST(N'2026-10-08 12:03:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'67c7e7111767406', N'TK01', CAST(N'2026-10-09 06:48:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'67d80ccc351c47b', N'TK01', CAST(N'2026-10-09 06:06:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'682988e358f7419', N'TK04', CAST(N'2026-10-08 13:34:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6863a2cc63ad464', N'TK69aa3723', CAST(N'2026-10-18 18:46:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'687579598b7146c', N'TK01', CAST(N'2026-10-08 12:03:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'688940e73828468', N'TK01', CAST(N'2026-10-08 13:04:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'68afff0b3a7d450', N'TK04', CAST(N'2026-10-08 09:17:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'68b79b8912ea428', N'TK01', CAST(N'2026-10-08 13:23:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'68e5618ea5fa4de', N'TK02', CAST(N'2026-10-17 20:35:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6904dee6c98842a', N'TK02', CAST(N'2026-10-15 23:43:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6954dd55545a497', N'TK04', CAST(N'2026-10-17 00:01:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'696f32bc5a98497', N'TK01', CAST(N'2026-10-08 13:04:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'69812a7f9e324df', N'TK04', CAST(N'2026-10-08 06:26:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6981fc8f569e485', N'TK01', CAST(N'2026-10-08 13:07:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'69851b8238f147f', N'TK01', CAST(N'2026-10-08 13:04:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6985b55548da4c3', N'TK01', CAST(N'2026-10-09 17:39:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'69b7a64d74c04be', N'TK04', CAST(N'2026-10-15 18:41:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'69b8452691c1445', N'TK02', CAST(N'2026-10-21 09:48:35' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DS7c177524', N'Dịch vụ phát sinh DV01; số lượng 1; quy cách DON_VI', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'69e91a68b372487', N'TK04', CAST(N'2026-10-08 09:10:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6a52bfd6317f456', N'TK02', CAST(N'2026-10-09 16:10:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6a5f2050a8dd4c6', N'TK02', CAST(N'2026-10-09 06:46:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6a6755634a7a438', N'TK02', CAST(N'2026-10-09 17:40:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6a9cbadf789e4da', N'TK01', CAST(N'2026-10-02 22:38:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6adbea651fba4da', N'TK01', CAST(N'2026-10-08 13:08:17' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6ae2518bc4264c6', N'TK01', CAST(N'2026-10-08 12:05:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6ae429a1d966476', N'TK01', CAST(N'2026-10-08 08:21:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6ae567830b08481', N'TK01', CAST(N'2026-10-08 09:10:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6aee51a3cac9406', N'TK69aa3723', CAST(N'2026-10-21 03:22:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6aff0e89af4a41f', N'TK01', CAST(N'2026-10-08 23:18:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6b00ff2b5ea24da', N'TK02', CAST(N'2026-10-16 09:29:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6b02bdb76482498', N'TK01', CAST(N'2026-10-09 17:38:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6b0c371ed070422', N'TK02', CAST(N'2026-10-15 19:09:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6b1e0e7c67a14e5', N'TK01', CAST(N'2026-10-08 12:06:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6beca880e8e3439', N'TK01', CAST(N'2026-10-08 13:05:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6bf17718e5fb4ee', N'TK04', CAST(N'2026-10-17 14:22:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6bfe9a93fbd34c7', N'TK03', CAST(N'2026-10-21 09:37:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6c0042ed714145c', N'TK69aa3723', CAST(N'2026-10-20 13:30:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6c0ccd29f2fd44f', N'TK01', CAST(N'2026-10-17 18:43:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6c2bb5d2eff44c9', N'TK01', CAST(N'2026-10-09 06:50:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6ca733a474524e1', N'TK01', CAST(N'2026-10-08 12:05:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6cd68f0b018e43e', N'TK03', CAST(N'2026-10-21 09:49:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6cf4701aedad4d4', N'TK01', CAST(N'2026-10-08 09:03:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6d16baaf0f3b4c1', N'TK69aa3723', CAST(N'2026-10-19 00:26:58' AS DateTime), N'Đặt sân', N'Thêm', N'DS99d5359e', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6d319c451cf2431', N'TK01', CAST(N'2026-10-08 12:05:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6d3c3c1f616d45c', N'TK01', CAST(N'2026-10-08 12:06:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6d5f2c1830dd4f4', N'TK69aa3723', CAST(N'2026-10-20 14:29:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6e255752c3e5443', N'TK02', CAST(N'2026-10-15 23:43:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6e53caf8582941f', N'TK01', CAST(N'2026-10-08 23:17:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6e6f96dcf36a4fc', N'TK02', CAST(N'2026-10-15 20:13:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6e7f0f7b38d8492', N'TK01', CAST(N'2026-10-09 16:12:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6e8aa684276d4a0', N'TK69aa3723', CAST(N'2026-10-19 00:21:06' AS DateTime), N'Tài chính', N'Thêm', N'DS6dc55d36', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6ec2e2f56dae432', N'TK01', CAST(N'2026-10-02 22:34:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6eed223ce3f3432', N'TK02', CAST(N'2026-10-21 03:53:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6f3d46867c9d45f', N'TK01', CAST(N'2026-10-08 09:05:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6f6911b52a974d0', N'TK03', CAST(N'2026-10-21 09:34:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6f73894a07ff47e', N'TK01', CAST(N'2026-10-08 06:08:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6f979da2859d482', N'TK01', CAST(N'2026-10-08 06:20:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'6fcbea6e18f4406', N'TK01', CAST(N'2026-10-09 17:37:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7046c9d0a04641d', N'TK01', CAST(N'2026-10-09 17:38:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'704e97ff19a045e', N'TK01', CAST(N'2026-10-18 10:50:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'70671a95f4d6458', N'TK01', CAST(N'2026-10-09 17:39:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'70ae6e8f8572435', N'TK01', CAST(N'2026-10-15 23:39:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'70ed49dfa5e94db', N'TK01', CAST(N'2026-10-09 17:37:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'70f9d00f7a8a4b7', N'TK01', CAST(N'2026-10-08 12:06:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7108719d8f814e6', N'TK01', CAST(N'2026-10-08 09:03:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7111753ab9504dc', N'TK01', CAST(N'2026-10-08 23:17:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7111a7e525f441c', N'TK01', CAST(N'2026-10-09 17:38:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'71142658e011401', N'TK01', CAST(N'2026-10-08 13:21:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7173d6c9b9bc4b2', N'TK02', CAST(N'2026-10-09 16:10:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7188cbfc390b4d0', N'TK69aa3723', CAST(N'2026-10-21 03:24:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'719378ea99a0436', N'TK01', CAST(N'2026-10-08 23:18:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'71a06e3f8dad4fc', N'TK02', CAST(N'2026-10-15 18:55:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'71a0e70f5870436', N'TK03', CAST(N'2026-10-15 19:01:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'71baecaa0ba3499', N'TK01', CAST(N'2026-10-09 17:38:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'723f02f0506a43b', N'TKe09ddb74', CAST(N'2026-10-20 21:20:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TKe09ddb74', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'72599891c53b404', N'TK01', CAST(N'2026-10-21 04:24:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'725f6fbc040343d', N'TK01', CAST(N'2026-10-09 16:14:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'72bf1bafb2a24fa', N'TK03', CAST(N'2026-10-19 13:02:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'72c84b3bf2ad4bb', N'TK01', CAST(N'2026-10-08 06:19:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73219be4187a4e4', N'TK01', CAST(N'2026-10-17 15:45:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7344ddb4edda479', N'TK03', CAST(N'2026-10-09 06:50:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7345c2a5143441f', N'TK02', CAST(N'2026-10-09 16:15:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'734b53ffb64048b', N'TK04', CAST(N'2026-10-08 09:17:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7360314002aa415', N'TK03', CAST(N'2026-10-09 16:12:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73746c985c7a400', N'TK01', CAST(N'2026-10-08 13:07:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73831930afbe422', N'TK03', CAST(N'2026-10-21 03:35:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'738a1f849f4d481', N'TK01', CAST(N'2026-10-09 16:14:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73ac95c0be2c4de', N'TK01', CAST(N'2026-10-08 17:26:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73ad9629ab83476', N'TK02', CAST(N'2026-10-16 19:46:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'73cb6339e2e3427', N'TK04', CAST(N'2026-10-16 19:46:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'740a525499ff44a', N'TK01', CAST(N'2026-10-08 23:16:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7448b5fcb9204a7', N'TK01', CAST(N'2026-10-02 22:40:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7464b87ed6da44f', N'TK01', CAST(N'2026-10-09 16:12:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'74674ab92620428', N'TK01', CAST(N'2026-10-08 12:03:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'746d31f64da4497', N'TK01', CAST(N'2026-10-08 17:19:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7479a513c217464', N'TK01', CAST(N'2026-10-17 14:22:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7480f155eb7f4b7', N'TK02', CAST(N'2026-10-08 09:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'74ba7ce3f4804a3', N'TK01', CAST(N'2026-10-08 23:18:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'74c4ccb968254ed', N'TK01', CAST(N'2026-10-08 12:06:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'74ef07adb13e45e', N'TK01', CAST(N'2026-10-08 17:18:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'751e2c5ec91a49b', N'TK02', CAST(N'2026-10-16 22:13:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'751fc547696841b', N'TK04', CAST(N'2026-10-08 13:04:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7570a3ac443c4c4', N'TK01', CAST(N'2026-10-08 13:11:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'75a49e2ad70942c', N'TK01', CAST(N'2026-10-08 23:17:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7603190c684b44f', N'TK01', CAST(N'2026-10-08 08:21:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7616802535f2408', N'TK02', CAST(N'2026-10-26 14:12:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'764f4c5afec145b', N'TK01', CAST(N'2026-10-09 16:12:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'767f795b57d4446', N'TK69aa3723', CAST(N'2026-10-18 18:58:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'76c10591a3b9463', N'TK01', CAST(N'2026-10-16 19:46:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'76efb2b3cd124ca', N'TK04', CAST(N'2026-10-15 19:09:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'77140ef4ad82456', N'TK69aa3723', CAST(N'2026-10-21 08:32:11' AS DateTime), N'Đặt sân', N'Thêm', N'DS805518a4', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'771a87b3134e495', N'TK01', CAST(N'2026-10-02 23:22:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'778db0dcd092435', N'TK01', CAST(N'2026-10-08 09:06:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'779b21d3ca844d2', N'TK04', CAST(N'2026-10-08 13:08:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7815f56765c5443', N'TK69aa3723', CAST(N'2026-10-21 08:28:50' AS DateTime), N'Tài chính', N'Thêm', N'DSfd1965b2', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7840c5398f104d3', N'TK01', CAST(N'2026-10-08 08:24:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'78557f53a784438', N'TK01', CAST(N'2026-10-08 13:08:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7877fc1a5c9246c', N'TK04', CAST(N'2026-10-17 20:32:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'788562e150ef473', N'TK69aa3723', CAST(N'2026-10-21 03:22:28' AS DateTime), N'Tài chính', N'Thêm', N'DS622125ef', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'78a34d911bbb41b', N'TK01', CAST(N'2026-10-09 06:50:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'78a8e26ac2f949f', N'TK01', CAST(N'2026-10-08 08:26:14' AS DateTime), N'Danh mục dịch vụ', N'Sửa', N'SV03', N'Giá 10000.00 -> 11000; kinh doanh true; lốc true', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'78f9703b2158404', N'TK01', CAST(N'2026-10-02 23:27:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79113c1fc51746e', N'TK01', CAST(N'2026-10-08 08:17:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'791e4cc1c33a448', N'TK01', CAST(N'2026-10-09 17:39:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7922c19609e14f5', N'TK02', CAST(N'2026-10-08 08:26:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'792fcba07e21473', N'TK03', CAST(N'2026-10-09 06:48:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79318cbfd329438', N'TK01', CAST(N'2026-10-08 13:07:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79324a728de1400', N'TK03', CAST(N'2026-10-21 03:16:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'793c26df94784a9', N'TK04', CAST(N'2026-10-15 20:14:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7940a00f522d4d6', N'TK01', CAST(N'2026-10-08 13:07:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79b8a3757a37413', N'TK01', CAST(N'2026-10-08 09:10:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79c5349e403d4a3', N'TK02', CAST(N'2026-10-21 02:42:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'79d1895c39dc4b4', N'TK01', CAST(N'2026-10-09 06:48:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a1590add0a04e4', N'TK01', CAST(N'2026-10-09 06:09:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a3124d39d1f493', N'TK01', CAST(N'2026-10-08 13:04:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a3cf3638013444', N'TK69aa3723', CAST(N'2026-10-19 01:13:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a647bcc38aa4b4', N'TK01', CAST(N'2026-10-02 22:40:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a813d1e7905475', N'TK01', CAST(N'2026-10-08 08:24:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7a857b93595e49e', N'TK01', CAST(N'2026-10-08 13:22:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7abe0b4c2522449', N'TK01', CAST(N'2026-10-08 13:05:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ac808d424fd46a', N'TK01', CAST(N'2026-10-17 16:49:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b01d9579dde4ae', N'TK04', CAST(N'2026-10-17 16:43:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b16b60a8a874b8', N'TK69aa3723', CAST(N'2026-10-21 08:43:33' AS DateTime), N'Tài chính', N'Thêm', N'DSaf089e4f', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b1e6a6cde6d441', N'TK03', CAST(N'2026-10-08 09:06:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b3118ba1d3d41e', N'TK01', CAST(N'2026-10-09 06:08:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b5b59cd774e45a', N'TK02', CAST(N'2026-10-08 09:13:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7b928d6d8c6f427', N'TK01', CAST(N'2026-10-09 17:38:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7bb84dabb6f1485', N'TK01', CAST(N'2026-10-02 20:23:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7bfcd59d355c46a', N'TK02', CAST(N'2026-10-21 10:37:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c00988bb416460', N'TK01', CAST(N'2026-10-08 06:26:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c0a7d76a11d422', N'TK01', CAST(N'2026-10-08 13:07:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c2ccdf2a617492', N'TK02', CAST(N'2026-10-09 17:38:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c4476d905c24cf', N'TK69aa3723', CAST(N'2026-10-22 11:45:32' AS DateTime), N'Đặt sân', N'Thêm', N'DSe4899600', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c53829ef0de4a9', N'TK01', CAST(N'2026-10-08 17:19:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c57326eb6b241a', N'TK01', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Danh mục dịch vụ', N'Sửa', N'SV03', N'Giá 11000.00 -> 10000; kinh doanh true; lốc true', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c5a3bd2a9c24a2', N'TK02', CAST(N'2026-10-17 15:22:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c5b906a3c1f45b', N'TK04', CAST(N'2026-10-15 23:39:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c6e2345a5b146b', N'TK01', CAST(N'2026-10-08 08:20:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c7025c3a1714c4', N'TK02', CAST(N'2026-10-09 16:15:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7c7731129a46423', N'TK02', CAST(N'2026-10-17 00:51:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7cdaea5cd2c2436', N'TK04', CAST(N'2026-10-15 19:36:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ce91184263d4c0', N'TK01', CAST(N'2026-10-09 17:38:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7cf29b043d174c1', N'TK01', CAST(N'2026-10-08 23:18:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7d02e0b95b894e0', N'TK02', CAST(N'2026-10-21 09:02:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7d13cb45f6a54d3', N'TK01', CAST(N'2026-10-09 16:13:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7d3358b04f06455', N'TK01', CAST(N'2026-10-09 06:48:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7d4b0e36068c480', N'TK01', CAST(N'2026-10-09 06:49:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7d7bee6be41d4ba', N'TK01', CAST(N'2026-10-08 08:26:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7db479ed354a405', N'TK01', CAST(N'2026-10-08 13:07:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ddd28c752cc44b', N'TK01', CAST(N'2026-10-08 12:06:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7de341b18b1d4f8', N'TK02', CAST(N'2026-10-09 17:38:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7df33f48d5fd4f3', N'TK02', CAST(N'2026-10-09 17:38:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7e6dd2b57af8438', N'TK01', CAST(N'2026-10-09 16:11:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7e75083e2fd44af', N'TK03', CAST(N'2026-10-09 16:12:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7e9e5754c1944a3', N'TK01', CAST(N'2026-10-17 16:43:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ea60795e2c5422', N'TK04', CAST(N'2026-10-08 09:30:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ebc8c52a20b4b2', N'TK03', CAST(N'2026-10-16 23:59:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7ebff8a23076491', N'TK01', CAST(N'2026-10-08 13:07:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7f05bcad7fd34ec', N'TK01', CAST(N'2026-10-08 13:08:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7f475756b90e4c3', N'TK01', CAST(N'2026-10-08 12:06:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7f7d0d2f3a0f4d8', N'TK01', CAST(N'2026-10-18 00:04:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'7f9f4a8ed6b744e', N'TK01', CAST(N'2026-10-09 17:37:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8023d901b8bd416', N'TK02', CAST(N'2026-10-18 10:50:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'80faaeef7060462', N'TK01', CAST(N'2026-10-09 17:39:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'813255d7f823422', N'TK02', CAST(N'2026-10-09 06:49:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'813d9d9d32e3404', N'TK01', CAST(N'2026-10-09 06:48:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8174028dd3eb452', N'TK01', CAST(N'2026-10-09 16:49:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'818e1bcfd6e8432', N'TK01', CAST(N'2026-10-09 17:38:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'81bc153a7361410', N'TK01', CAST(N'2026-10-02 23:22:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'81d0ae03560140d', N'TK02', CAST(N'2026-10-15 23:39:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'823c082c3ecb41e', N'TK69aa3723', CAST(N'2026-10-21 03:28:57' AS DateTime), N'Tài chính', N'Thêm', N'DSebc7066e', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'825c2a208e22444', N'TK69aa3723', CAST(N'2026-10-21 09:09:13' AS DateTime), N'Tài chính', N'Thêm', N'DS776a68a8', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'825fe4b0aba149d', N'TK69aa3723', CAST(N'2026-10-19 00:20:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'828697aeb2b24ce', N'TK01', CAST(N'2026-10-15 20:12:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'82af65df1aca4ca', N'TK01', CAST(N'2026-10-09 06:50:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'82e78793be904d1', N'TK02', CAST(N'2026-10-21 08:32:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'82f936bf2ce640c', N'TK01', CAST(N'2026-10-08 09:10:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'830c9e22365f448', N'TK01', CAST(N'2026-10-08 13:07:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8312ecb7db6946b', N'TK01', CAST(N'2026-10-08 06:24:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'839546ad419e428', N'TK01', CAST(N'2026-10-09 16:11:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'83b74ce0bf7e499', N'TK03', CAST(N'2026-10-15 19:36:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'83be3d7f30514f0', N'TK01', CAST(N'2026-10-09 06:09:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'83cd486a83bf495', N'TK03', CAST(N'2026-10-18 00:04:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'841c2e61554a4a0', N'TK01', CAST(N'2026-10-08 13:22:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8423a1e1a19c46e', N'TK01', CAST(N'2026-10-09 17:39:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8442d8dd0c95484', N'TK01', CAST(N'2026-10-02 23:29:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8450835e065e44f', N'TK01', CAST(N'2026-10-08 13:07:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'845bf18ac2784c3', N'TK01', CAST(N'2026-10-09 06:09:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8461ec6636cc412', N'TK03', CAST(N'2026-10-15 18:42:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8472d9936222496', N'TK01', CAST(N'2026-10-08 08:24:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'847488c97aa7407', N'TK01', CAST(N'2026-10-08 23:17:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'84c65327109d445', N'TK01', CAST(N'2026-10-21 17:22:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'84d9bf43799a4ea', N'TK01', CAST(N'2026-10-08 12:03:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'84dc2509b44442b', N'TK01', CAST(N'2026-10-08 13:23:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'84fe91871cd845a', N'TK02', CAST(N'2026-10-17 00:01:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'851e9ab0676a4b9', N'TK01', CAST(N'2026-10-08 12:01:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'853b81c9e56e44a', N'TK01', CAST(N'2026-10-02 23:27:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'853e3558e43c423', N'TK01', CAST(N'2026-10-09 06:50:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'85d94a9e069243e', N'TK01', CAST(N'2026-10-09 16:12:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'85f20b17ab4f462', N'TK01', CAST(N'2026-10-08 08:24:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'860a8fa1cfd44e3', N'TK01', CAST(N'2026-10-08 08:26:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8627a927745f406', N'TK01', CAST(N'2026-10-08 09:03:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'862ef1eea675456', N'TK01', CAST(N'2026-10-15 23:42:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'863ac63185df4e5', N'TK01', CAST(N'2026-10-08 09:10:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'86a27d002a5b4e6', N'TK01', CAST(N'2026-10-21 03:35:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'86b407dcb6a44c6', N'TK04', CAST(N'2026-10-08 09:05:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'86ce37afe8a34b2', N'TK01', CAST(N'2026-10-08 13:05:14' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'86f5ff0409df404', N'TK04', CAST(N'2026-10-15 23:41:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'872917e7c38848d', N'TK01', CAST(N'2026-10-08 08:17:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8745a70b42de4d4', N'TK01', CAST(N'2026-10-08 13:21:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8746de41f8fc4eb', N'TK01', CAST(N'2026-10-08 09:10:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'87a00fca03ee419', N'TK69aa3723', CAST(N'2026-10-15 19:46:29' AS DateTime), N'Tài chính', N'Thêm', N'DS419d883b', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'87ce8770e4fe439', N'TK02', CAST(N'2026-10-15 23:42:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'87fa8c9a27e846c', N'TK02', CAST(N'2026-10-09 17:38:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'882e0a212871429', N'TK01', CAST(N'2026-10-08 09:10:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8837ca6146e2458', N'TK02', CAST(N'2026-10-09 06:47:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8846cb4a7063407', N'TK01', CAST(N'2026-10-08 13:04:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'88bd99c4a9cb484', N'TK01', CAST(N'2026-10-08 23:18:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'88e050d9ea3a464', N'TK69aa3723', CAST(N'2026-10-21 02:40:48' AS DateTime), N'Tài chính', N'Thêm', N'DSa5f0cc04', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8926686d8e934d4', N'TK01', CAST(N'2026-10-17 14:22:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8926732fec984d5', N'TK69aa3723', CAST(N'2026-10-21 09:18:00' AS DateTime), N'Tài chính', N'Thêm', N'DS3c7fd553', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'892865109b9644e', N'TK01', CAST(N'2026-10-08 17:19:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8928cd9382dc424', N'TK02', CAST(N'2026-10-17 15:24:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'894905b5743b4da', N'TK01', CAST(N'2026-10-08 12:06:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'89c0e51c5bb3444', N'TK02', CAST(N'2026-10-21 10:46:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'89cdb106864643d', N'TK02', CAST(N'2026-10-17 00:52:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a08edfe393548d', N'TK01', CAST(N'2026-10-08 17:19:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a0f04dfc7754ed', N'TK01', CAST(N'2026-10-08 06:08:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a2504e6fa224bb', N'TK03', CAST(N'2026-10-16 17:09:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a5f681901d2491', N'TK69aa3723', CAST(N'2026-10-21 03:27:20' AS DateTime), N'Tài chính', N'Thêm', N'DSd5f58794', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a644a926d8a459', N'TK01', CAST(N'2026-10-09 06:48:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a8630174a9742b', N'TK01', CAST(N'2026-10-02 23:22:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8a9b0b6898fd4a4', N'TK01', CAST(N'2026-10-08 13:08:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8ab510144bc44d3', N'TK01', CAST(N'2026-10-09 16:15:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8b405120701e4c4', N'TK04', CAST(N'2026-10-16 19:43:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8b535dc5a55c4d0', N'TK01', CAST(N'2026-10-09 06:48:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8b7dcad3ef1244d', N'TK01', CAST(N'2026-10-17 00:01:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8b96ab227783401', N'TK02', CAST(N'2026-10-15 19:36:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8baf91b51bbd41e', N'TK02', CAST(N'2026-10-21 09:48:02' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DS7c177524', N'Nhận sân', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8be52762a2fc4d8', N'TK02', CAST(N'2026-10-16 22:17:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8bfdf922dcd249f', N'TK01', CAST(N'2026-10-08 13:07:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8c236e057e7d40c', N'TK03', CAST(N'2026-10-09 06:48:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8c3d0ce5d520450', N'TK02', CAST(N'2026-10-09 06:49:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8c8bdd0e463a4af', N'TK01', CAST(N'2026-10-08 17:19:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8ca01fd32b6e46e', N'TK01', CAST(N'2026-10-08 13:22:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8cc22e5b022d448', N'TK01', CAST(N'2026-10-09 17:38:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8cc9e730ed3f426', N'TK01', CAST(N'2026-10-09 16:12:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8ccca0969d26474', N'TK02', CAST(N'2026-10-09 16:10:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8cd03b23ba234b6', N'TK01', CAST(N'2026-10-09 16:14:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8ce2ad1c9ba94ad', N'TK01', CAST(N'2026-10-08 17:19:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8cf8f26584ca4a3', N'TK02', CAST(N'2026-10-16 22:15:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8cffcb5bba82423', N'TK02', CAST(N'2026-10-09 17:40:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d008f87f57f42b', N'TK01', CAST(N'2026-10-15 23:39:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d172145d1d44e0', N'TK02', CAST(N'2026-10-09 16:15:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d302a6758f241f', N'TK01', CAST(N'2026-10-08 08:24:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d31d2b9d6f941d', N'TK69aa3723', CAST(N'2026-10-19 00:33:56' AS DateTime), N'Đặt sân', N'Thêm', N'DS81dd06cc', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d57f061355b447', N'TK01', CAST(N'2026-10-08 06:21:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d7c0412e9d0479', N'TK02', CAST(N'2026-10-17 18:20:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8d8d5f845b8e405', N'TK01', CAST(N'2026-10-08 13:07:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8dd71011320045e', N'TK01', CAST(N'2026-10-08 12:06:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8dd889fa4bee4a8', N'TK01', CAST(N'2026-10-09 06:09:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e0eb05aaa21480', N'TK03', CAST(N'2026-10-20 14:00:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e2f4e740af84a7', N'TK03', CAST(N'2026-10-09 06:09:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e474652be29464', N'TK01', CAST(N'2026-10-08 13:22:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e5cd1fc70104e1', N'TK01', CAST(N'2026-10-09 06:10:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e814f8b81cc439', N'TK69aa3723', CAST(N'2026-10-21 10:35:26' AS DateTime), N'Đặt sân', N'Thêm', N'DS15a5d94d', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8e8c986e571c475', N'TK01', CAST(N'2026-10-08 12:02:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8ea1d07fdfac4ec', N'TK04', CAST(N'2026-10-15 19:36:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8eb9e78d57d3417', N'TK01', CAST(N'2026-10-09 06:10:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f047ce4a948407', N'TK01', CAST(N'2026-10-08 13:07:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f183edc5e7c40b', N'TK03', CAST(N'2026-10-09 06:48:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f482309cd7b484', N'TK01', CAST(N'2026-10-08 08:26:15' AS DateTime), N'Danh mục dịch vụ', N'Sửa', N'SV03', N'Giá 11000.00 -> 10000; kinh doanh true; lốc true', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f822eabc1e0498', N'TK04', CAST(N'2026-10-17 18:42:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f8aac078aaf4c6', N'TK01', CAST(N'2026-10-02 23:26:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f9194c2181845b', N'TK01', CAST(N'2026-10-08 09:00:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8f93bec95fce4e9', N'TK01', CAST(N'2026-10-08 08:21:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8fb3439729ac49d', N'TK01', CAST(N'2026-10-15 20:15:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8fb7ae309def492', N'TK01', CAST(N'2026-10-09 16:11:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'8fdb85ddd1e24cf', N'TK02', CAST(N'2026-10-09 16:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'900311b8a89c43f', N'TK01', CAST(N'2026-10-09 06:50:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90259725af00483', N'TK01', CAST(N'2026-10-08 09:06:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'902e49733ac8456', N'TK69aa3723', CAST(N'2026-10-26 14:03:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9046380be5f2482', N'TK02', CAST(N'2026-10-26 14:04:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'904e01bb87e8483', N'TK01', CAST(N'2026-10-08 06:08:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9051d898656c4f8', N'TK01', CAST(N'2026-10-09 06:30:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9072f64a007e480', N'TK01', CAST(N'2026-10-08 12:02:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9073a07bd253406', N'TK01', CAST(N'2026-10-08 09:03:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90c56163ab84410', N'TK03', CAST(N'2026-10-15 23:41:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90ce6ce5f149420', N'TK01', CAST(N'2026-10-08 08:24:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90d1acd22e454de', N'TK01', CAST(N'2026-10-08 17:19:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90ea7a9a202d4fd', N'TK01', CAST(N'2026-10-08 09:06:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'90f1cc21ad6d450', N'TK01', CAST(N'2026-10-20 14:02:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'911d70c76bac4fd', N'TK01', CAST(N'2026-10-08 12:02:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91608a1c46b04dc', N'TK02', CAST(N'2026-10-09 17:40:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91abcd466d5d416', N'TK01', CAST(N'2026-10-08 09:10:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91af1b3911934df', N'TK01', CAST(N'2026-10-08 13:22:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91b586bda82049e', N'TK02', CAST(N'2026-10-17 15:23:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91c33c380ee1426', N'TK01', CAST(N'2026-10-08 13:07:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'91dff77a4caf4e6', N'TK01', CAST(N'2026-10-09 06:48:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'920a3c77a75b4d2', N'TK03', CAST(N'2026-10-21 03:13:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9229f7fa95da4c9', N'TK01', CAST(N'2026-10-08 08:59:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9230099e70ce475', N'TK69aa3723', CAST(N'2026-10-20 14:29:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9234579438354aa', N'TK03', CAST(N'2026-10-16 22:16:57' AS DateTime), N'Tài chính', N'Thêm', N'DS5c92b544', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'924561971b95422', N'TK02', CAST(N'2026-10-15 18:42:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9261d5d9b24843c', N'TK01', CAST(N'2026-10-08 09:10:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'926f95788fef415', N'TK01', CAST(N'2026-10-08 08:59:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'92846a45eb894d3', N'TK04', CAST(N'2026-10-16 19:43:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'928be3b6ccb94a7', N'TK02', CAST(N'2026-10-21 02:39:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9295b53047fb4ef', N'TK01', CAST(N'2026-10-09 06:09:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'929a844256684c9', N'TK01', CAST(N'2026-10-08 12:03:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'92bb52620e424d4', N'TK69aa3723', CAST(N'2026-10-19 00:40:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'92f1ce1cced14f3', N'TK69aa3723', CAST(N'2026-10-21 03:27:09' AS DateTime), N'Đặt sân', N'Thêm', N'DSd5f58794', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9304a428802a4db', N'TK01', CAST(N'2026-10-08 06:23:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'930d601f062743b', N'TK04', CAST(N'2026-10-15 19:07:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'931bb5a331764fb', N'TK03', CAST(N'2026-10-16 16:52:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'931c9a6e19b34e8', N'TK03', CAST(N'2026-10-15 23:41:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'93309bb949d5473', N'TK01', CAST(N'2026-10-09 06:09:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'933324dd25e2459', N'TK01', CAST(N'2026-10-17 15:25:21' AS DateTime), N'Quản trị', N'Sửa', N'TK02', N'Cập nhật trạng thái/role tài khoản: VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'935bd75ac61046e', N'TK01', CAST(N'2026-10-09 06:48:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'936c6614fa9d4c4', N'TK69aa3723', CAST(N'2026-10-22 11:29:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'93b93e22af05495', N'TK01', CAST(N'2026-10-02 21:08:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'93e6eb05f01f430', N'TK01', CAST(N'2026-10-08 13:07:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9430a63f8f3a46f', N'TK04', CAST(N'2026-10-17 17:18:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9479a4ee21aa46e', N'TK02', CAST(N'2026-10-17 17:18:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'94860b94d0ec4a2', N'TK01', CAST(N'2026-10-09 16:13:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'949bd104ec6f42b', N'TK01', CAST(N'2026-10-08 13:08:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'94a3d8e488964f9', N'TK01', CAST(N'2026-10-09 06:09:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'94c735f6eead475', N'TK01', CAST(N'2026-10-08 12:03:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'94f3f3a9aa2e439', N'TK02', CAST(N'2026-10-09 16:13:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'94fc82adb432470', N'TK01', CAST(N'2026-10-19 13:12:03' AS DateTime), N'Quản lý sân', N'Sửa', N'S03', N'Trạng thái: Bảo trì → Đang sử dụng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'952d9d7e2f1d47e', N'TK03', CAST(N'2026-10-08 09:13:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'959f374033a349b', N'TK01', CAST(N'2026-10-08 17:19:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'963a31f1cea4442', N'TK02', CAST(N'2026-10-15 19:09:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9646909e4ecc4ed', N'TK01', CAST(N'2026-10-08 23:17:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'964baa16b186477', N'TK02', CAST(N'2026-10-09 17:40:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'966b59b8c5064e0', N'TK02', CAST(N'2026-10-09 06:49:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'96700708192d4cc', N'TK03', CAST(N'2026-10-09 06:09:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9672e98aaa78447', N'TK69aa3723', CAST(N'2026-10-15 19:41:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'971294a9d35c4b8', N'TK69aa3723', CAST(N'2026-10-20 21:07:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'973e476441c9402', N'TK01', CAST(N'2026-10-08 13:21:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'974bbd79ad9a496', N'TK01', CAST(N'2026-10-09 06:09:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9751d8a8206c480', N'TK01', CAST(N'2026-10-08 13:23:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'975efeda51014d5', N'TK69aa3723', CAST(N'2026-10-21 09:45:09' AS DateTime), N'Tài chính', N'Thêm', N'DS7c177524', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9763be92060941e', N'TK01', CAST(N'2026-10-08 12:05:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9764cc7e8264435', N'TK01', CAST(N'2026-10-08 17:31:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'976aef06df224d1', N'TK03', CAST(N'2026-10-15 19:07:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'978364bbfe8a4aa', N'TK01', CAST(N'2026-10-08 17:18:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'97ce1c9285c74b2', N'TK02', CAST(N'2026-10-09 17:40:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'97eeb2ff2328476', N'TK03', CAST(N'2026-10-09 06:11:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98100230d7964c6', N'TK01', CAST(N'2026-10-08 13:23:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9816ef8e6aa1432', N'TK01', CAST(N'2026-10-08 09:17:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'982250cdf61a45a', N'TK01', CAST(N'2026-10-09 06:09:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9846e0843aa44a7', N'TK02', CAST(N'2026-10-09 06:46:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'987f73950c3b4d5', N'TK01', CAST(N'2026-10-17 17:18:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98839fc182734ef', N'TK01', CAST(N'2026-10-08 13:22:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98b4c24d98e541a', N'TK01', CAST(N'2026-10-15 19:07:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98d432cac300447', N'TK01', CAST(N'2026-10-08 13:22:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98d7a57df50645c', N'TK01', CAST(N'2026-10-08 12:02:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'98f68d9680084db', N'TK01', CAST(N'2026-10-08 12:05:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9900bb76cb524b5', N'TK69aa3723', CAST(N'2026-10-21 07:03:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'990784ca8d59497', N'TK04', CAST(N'2026-10-15 23:43:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99137dae2524425', N'TK02', CAST(N'2026-10-09 17:40:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'997f421e51ac48d', N'TK01', CAST(N'2026-10-08 23:17:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'998abefe324a4e8', N'TK01', CAST(N'2026-10-09 16:12:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99a5c63df85a4e4', N'TK01', CAST(N'2026-10-08 13:08:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99b0f96bd5bb4d3', N'TK01', CAST(N'2026-10-15 19:01:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99c85d2a96e941b', N'TK01', CAST(N'2026-10-08 06:19:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99cbc17026cf428', N'TK02', CAST(N'2026-10-02 22:49:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'99d6ae343d77491', N'TK01', CAST(N'2026-10-09 16:12:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a0509ccbfb949c', N'TK02', CAST(N'2026-10-09 16:15:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a117951e3b1400', N'TK02', CAST(N'2026-10-15 13:44:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a30bbbdfe8b40d', N'TK01', CAST(N'2026-10-08 09:10:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a7659b0ae5a457', N'TK01', CAST(N'2026-10-08 09:10:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a88ce41acae4cc', N'TK01', CAST(N'2026-10-21 04:18:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9a95d25536b6435', N'TK01', CAST(N'2026-10-08 12:01:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ad7dd421b2747e', N'TK69aa3723', CAST(N'2026-10-21 09:45:09' AS DateTime), N'Tài chính', N'Sửa', N'DS7c177524', N'Khuyến mãi chỉ giảm tiền sân; KM02; giảm 7500.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ae60e3625184a4', N'TK01', CAST(N'2026-10-08 09:10:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9afaca78841340a', N'TK01', CAST(N'2026-10-08 09:05:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9b6b29804e0948a', N'TK01', CAST(N'2026-10-17 00:51:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9b779c1f696e47a', N'TK01', CAST(N'2026-10-21 09:53:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9b82ace55b094b6', N'TK01', CAST(N'2026-10-08 13:07:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9b9421e4871940d', N'TK69aa3723', CAST(N'2026-10-21 08:28:40' AS DateTime), N'Đặt sân', N'Thêm', N'DSfd1965b2', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9b96f24cd4914e7', N'TK03', CAST(N'2026-10-08 09:22:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ba14d94088140d', N'TK01', CAST(N'2026-10-08 08:21:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9bbb3a0d353d4e5', N'TK01', CAST(N'2026-10-08 12:05:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9bdb744415e4417', N'TK01', CAST(N'2026-10-08 09:00:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9c0dc00ba7c647f', N'TK01', CAST(N'2026-10-09 06:50:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9c3f9d5b971048e', N'TK01', CAST(N'2026-10-08 06:08:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9c8aa58b6c334e6', N'TK02', CAST(N'2026-10-15 23:39:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9c97d70960d4471', N'TK01', CAST(N'2026-10-15 23:41:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9c9b220a96d24ba', N'TK69aa3723', CAST(N'2026-10-21 09:09:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ccd078e8d56463', N'TK01', CAST(N'2026-10-08 09:00:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9cd5c86131d9478', N'TK01', CAST(N'2026-10-08 13:11:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9cf3bdaeda814f8', N'TK02', CAST(N'2026-10-09 06:47:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9cf6c9aaba1541f', N'TK01', CAST(N'2026-10-08 08:24:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9cf93273adb64dc', N'TK01', CAST(N'2026-10-08 12:06:28' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d120f352831489', N'TK69aa3723', CAST(N'2026-10-19 00:26:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d3c9c07fb004ca', N'TK02', CAST(N'2026-10-21 03:46:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d50f2c2363043b', N'TK04', CAST(N'2026-10-16 09:29:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d5cc6ab5e514b1', N'TK02', CAST(N'2026-10-09 06:49:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d6c1ec9a0ea454', N'TK01', CAST(N'2026-10-15 19:09:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d6e1c0eaef24ef', N'TK02', CAST(N'2026-10-21 10:45:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9d9f07bc24f7401', N'TK04', CAST(N'2026-10-17 15:24:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9dd44428e6ad49b', N'TK01', CAST(N'2026-10-08 08:21:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9de4655a3d5e4fc', N'TK03', CAST(N'2026-10-21 02:42:52' AS DateTime), N'Tài chính', N'Thêm', N'DSa5f0cc04', N'Ghi nhận thực thu 90000', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e2b2726b809495', N'TK01', CAST(N'2026-10-09 17:39:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e2fe158aa034f2', N'TK01', CAST(N'2026-10-08 23:17:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e3e47884d67416', N'TK02', CAST(N'2026-10-09 06:49:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e48422bcc5e465', N'TK01', CAST(N'2026-10-09 16:11:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e493e69c1f747d', N'TK02', CAST(N'2026-10-17 17:37:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e4e50d6469b46b', N'TK02', CAST(N'2026-10-09 16:10:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e6dc0c6e6524ec', N'TK02', CAST(N'2026-10-09 16:15:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e8fef51a40d498', N'TK01', CAST(N'2026-10-08 13:07:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e933a90c018498', N'TK02', CAST(N'2026-10-09 17:38:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e97cf97297045a', N'TK01', CAST(N'2026-10-18 10:50:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9e9db081249a481', N'TK01', CAST(N'2026-10-08 23:18:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ee8386592e7468', N'TK01', CAST(N'2026-10-02 22:38:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9f01646459694c1', N'TK01', CAST(N'2026-10-08 08:59:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9f17f6615dbb46e', N'TK01', CAST(N'2026-10-08 13:04:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9f4fbbd80b434de', N'TK69aa3723', CAST(N'2026-10-18 23:19:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9fbf7c1aaba84e7', N'TK01', CAST(N'2026-10-08 08:24:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9fd227de861c4c5', N'TK01', CAST(N'2026-10-08 09:06:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9fdac11a307c46e', N'TK03', CAST(N'2026-10-20 14:02:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9fe5dbdfa6b540a', N'TK01', CAST(N'2026-10-08 17:19:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9fe70be1d8d1419', N'TK01', CAST(N'2026-10-08 13:23:05' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'9ff00abdba54490', N'TK02', CAST(N'2026-10-09 16:15:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a02188bf2711474', N'TK02', CAST(N'2026-10-17 18:42:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a023000462f04f5', N'TK69aa3723', CAST(N'2026-10-15 19:46:29' AS DateTime), N'Tài chính', N'Thêm', N'DS419d883b', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a045f6e1fe8446b', N'TK02', CAST(N'2026-10-09 17:38:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a04770acd04d442', N'TK01', CAST(N'2026-10-09 06:09:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a0532994793f4f8', N'TK01', CAST(N'2026-10-08 12:06:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a08afe4838e6402', N'TK04', CAST(N'2026-10-15 15:06:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a0f375005ea3485', N'TK01', CAST(N'2026-10-08 23:18:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a0f5b88d2ab54bb', N'TK69aa3723', CAST(N'2026-10-22 11:33:08' AS DateTime), N'Đặt sân', N'Thêm', N'DSb9d7bd29', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 260000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a100439d9b944c1', N'TK01', CAST(N'2026-10-08 12:05:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a114512e382f4c8', N'TK01', CAST(N'2026-10-21 03:54:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a12c53340132462', N'TK01', CAST(N'2026-10-08 13:04:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a133c30f628147f', N'TK01', CAST(N'2026-10-08 09:03:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a13bbe8c182746d', N'TK01', CAST(N'2026-10-17 15:46:07' AS DateTime), N'Quản trị', N'Sửa', N'TK02', N'Cập nhật trạng thái/role tài khoản: VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a13c151b38654aa', N'TK02', CAST(N'2026-10-17 17:18:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1506bde9d5342a', N'TK02', CAST(N'2026-10-09 06:45:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a17112aa09e54ab', N'TK03', CAST(N'2026-10-17 16:43:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a19243213662444', N'TK01', CAST(N'2026-10-09 06:09:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1a5dfadcb6d466', N'TK03', CAST(N'2026-10-08 13:04:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1c6682406ab4f8', N'TK01', CAST(N'2026-10-15 19:40:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1f58532ddc84bc', N'TK69aa3723', CAST(N'2026-10-18 08:50:58' AS DateTime), N'Tài chính', N'Thêm', N'DS5b17fa31', N'Hủy; tỷ lệ hoàn 0.00; thực thu 0.00; yêu cầu hoàn 0.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1fbe319fae94a9', N'TK02', CAST(N'2026-10-18 10:55:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1fbf2b59a9b459', N'TK69aa3723', CAST(N'2026-10-21 03:28:14' AS DateTime), N'Tài chính', N'Thêm', N'DS361bb875', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a1ffe6c524414e7', N'TK69aa3723', CAST(N'2026-10-21 07:13:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2027d5188a64ca', N'TK01', CAST(N'2026-10-15 20:16:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a22394553b28435', N'TK03', CAST(N'2026-10-16 17:09:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a23d910252074d5', N'TK04', CAST(N'2026-10-08 23:17:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a25935e44ec940c', N'TK69aa3723', CAST(N'2026-10-15 13:13:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a25cb8469ced47e', N'TK02', CAST(N'2026-10-09 17:40:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2614528a495462', N'TK04', CAST(N'2026-10-08 17:18:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2c848b0de69421', N'TK01', CAST(N'2026-10-09 06:09:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2d166039a47428', N'TK01', CAST(N'2026-10-08 06:07:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2d22996af81417', N'TK03', CAST(N'2026-10-17 17:37:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2e3d4559e3e4c6', N'TK01', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Danh mục dịch vụ', N'Sửa', N'SV03', N'Giá 10000.00 -> 11000; kinh doanh true; lốc true', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2e454c9d652464', N'TK01', CAST(N'2026-10-09 06:09:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2ecbf33abcf4ab', N'TK69aa3723', CAST(N'2026-10-21 09:08:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a2ef6219eb0f47e', N'TK01', CAST(N'2026-10-08 12:05:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a31f38b0607c48e', N'TK69aa3723', CAST(N'2026-10-22 11:45:39' AS DateTime), N'Tài chính', N'Thêm', N'DSe4899600', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a3494b67baa4476', N'TK01', CAST(N'2026-10-08 13:04:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a35141a15ba843f', N'TK04', CAST(N'2026-10-08 15:06:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a35d625f5d1e41f', N'TK01', CAST(N'2026-10-02 23:26:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a3699cf1ff61421', N'TK01', CAST(N'2026-10-08 09:17:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a38457d5495145c', N'TK01', CAST(N'2026-10-08 12:06:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a38865d2a898481', N'TK04', CAST(N'2026-10-09 17:38:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a38a2f50510e462', N'TK01', CAST(N'2026-10-09 17:38:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a3ea1f7aa9f3476', N'TK01', CAST(N'2026-10-09 16:13:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a3eee94768b342e', N'TK04', CAST(N'2026-10-17 20:33:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a44922bfab334a6', N'TK01', CAST(N'2026-10-09 16:14:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a474f3e4dd20488', N'TK01', CAST(N'2026-10-09 06:08:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a4cc45b7ff7e411', N'TK02', CAST(N'2026-10-09 17:38:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a4d9e7880eb4490', N'TK01', CAST(N'2026-10-09 06:50:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a4e24f71e394440', N'TK01', CAST(N'2026-10-08 17:18:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a5370728de014d3', N'TK01', CAST(N'2026-10-08 12:06:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a53861888f5641e', N'TK01', CAST(N'2026-10-08 08:20:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a56927d67c934a0', N'TK01', CAST(N'2026-10-08 13:23:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a5854591244046f', N'TK03', CAST(N'2026-10-09 17:38:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a5c51af3481141e', N'TK02', CAST(N'2026-10-18 10:55:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a61f551e8f8041f', N'TK01', CAST(N'2026-10-08 13:21:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a675d9ef70ff459', N'TK03', CAST(N'2026-10-19 13:02:41' AS DateTime), N'Tài chính', N'Sửa', N'DS6dc55d36', N'Xác nhận thực thu TTac6761eb', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a678267ae63b4b5', N'TK01', CAST(N'2026-10-08 13:04:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a6892ca408fc450', N'TK04', CAST(N'2026-10-17 00:52:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a691d55769e440e', N'TK01', CAST(N'2026-10-17 18:22:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a6a355a0ceb44e8', N'TK03', CAST(N'2026-10-15 20:14:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a6c312e9303143d', N'TK02', CAST(N'2026-10-20 22:01:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a703147b2396445', N'TK01', CAST(N'2026-10-02 23:22:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a733bfbaa8a3406', N'TK01', CAST(N'2026-10-08 06:24:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a74673968041415', N'TK03', CAST(N'2026-10-08 09:22:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a76bcfb5c2884db', N'TK01', CAST(N'2026-10-08 09:10:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7777faedfef44b', N'TK02', CAST(N'2026-10-09 16:13:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7845ec8190e453', N'TK69aa3723', CAST(N'2026-10-19 00:38:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7a99c6ecdc44e4', N'TK02', CAST(N'2026-10-21 17:22:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7c785c02bdd423', N'TK02', CAST(N'2026-10-17 14:59:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7d28ecca6274b7', N'TK01', CAST(N'2026-10-17 00:51:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7d537c9d6fa4d0', N'TK01', CAST(N'2026-10-15 19:01:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7d5820d199c464', N'TK01', CAST(N'2026-10-09 17:38:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7e9e6ea55cf4ca', N'TK01', CAST(N'2026-10-09 06:09:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a7f1c65680954fb', N'TK01', CAST(N'2026-10-08 12:05:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a80c6da37f7040b', N'TK01', CAST(N'2026-10-09 16:15:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a83571d9e2b441d', N'TK01', CAST(N'2026-10-09 06:09:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a89389bcd0ec4bb', N'TK02', CAST(N'2026-10-21 09:47:56' AS DateTime), N'Đặt sân', N'Sửa', N'DS7c177524', N'Xác nhận booking', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a89fd07f8883422', N'TK01', CAST(N'2026-10-08 17:35:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a8a79bffe4a9443', N'TK01', CAST(N'2026-10-09 06:10:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a8a97cf890ef4cd', N'TK01', CAST(N'2026-10-08 23:17:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a8abfdd686d944a', N'TK01', CAST(N'2026-10-09 17:39:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a8bc5daa17bc4ef', N'TK01', CAST(N'2026-10-08 13:22:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a8e629dc2e2746c', N'TK01', CAST(N'2026-10-09 06:09:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9166820dcb04bb', N'TK01', CAST(N'2026-10-09 06:48:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a92dba5ad2a8470', N'TK01', CAST(N'2026-10-09 17:37:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a92dd304fe9e4ab', N'TK04', CAST(N'2026-10-08 13:05:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a937c01b93fc49d', N'TK01', CAST(N'2026-10-08 13:05:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a944147468204af', N'TK01', CAST(N'2026-10-08 13:22:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9465dd565fd42d', N'TK01', CAST(N'2026-10-08 09:06:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a948f02a5bd3474', N'TK01', CAST(N'2026-10-08 23:18:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9517c233d124ac', N'TK01', CAST(N'2026-10-17 00:53:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a99065b917904fc', N'TK02', CAST(N'2026-10-09 06:51:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9bb8c76dcb7457', N'TK01', CAST(N'2026-10-08 17:18:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9c24752b7a84f6', N'TK02', CAST(N'2026-10-09 17:38:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9d94186b587449', N'TK02', CAST(N'2026-10-21 09:09:29' AS DateTime), N'Đặt sân', N'Sửa', N'DS776a68a8', N'Xác nhận booking', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'a9e83482820c4bc', N'TK01', CAST(N'2026-10-17 15:24:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa3ba091abd345d', N'TK01', CAST(N'2026-10-02 22:38:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa470527e0044da', N'TK02', CAST(N'2026-10-15 19:07:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa4ce0feec3f4b4', N'TK69aa3723', CAST(N'2026-10-21 09:24:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa50651a265a42e', N'TK01', CAST(N'2026-10-08 13:23:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa68878064a848d', N'TK69aa3723', CAST(N'2026-10-18 21:22:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa786dd18c4a464', N'TKe09ddb74', CAST(N'2026-10-20 21:09:22' AS DateTime), N'Authentication / Phân quyền', N'Thêm', N'TKe09ddb74', N'Đăng ký tài khoản khách hàng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aa9fbf549bdc48e', N'TK03', CAST(N'2026-10-08 13:05:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aabcdf7199f1495', N'TK01', CAST(N'2026-10-15 20:13:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aaeedbca3e8a49e', N'TK02', CAST(N'2026-10-09 17:40:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab03a245c292477', N'TK01', CAST(N'2026-10-09 16:13:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab0fb965b9c6439', N'TK69aa3723', CAST(N'2026-10-21 02:40:40' AS DateTime), N'Đặt sân', N'Thêm', N'DSa5f0cc04', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab16f407978145a', N'TK01', CAST(N'2026-10-08 06:23:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab4fa7ad318546a', N'TK69aa3723', CAST(N'2026-10-21 03:53:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab67120e8ba9424', N'TK01', CAST(N'2026-10-08 08:23:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab67597dc90349a', N'TK69aa3723', CAST(N'2026-10-21 09:37:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab6d77b3249048e', N'TK02', CAST(N'2026-10-20 13:56:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ab6e9482feb44e6', N'TK01', CAST(N'2026-10-08 17:28:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aba0d08eec474be', N'TK02', CAST(N'2026-10-09 06:46:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'abc052397df1496', N'TK01', CAST(N'2026-10-15 23:42:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'abcc6d0c2b244da', N'TK01', CAST(N'2026-10-17 00:53:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'abdd97cd036244e', N'TK01', CAST(N'2026-10-17 20:35:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ac03d3d5b915442', N'TK03', CAST(N'2026-10-15 19:09:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ac35779ccc8e474', N'TK03', CAST(N'2026-10-09 06:30:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ac47dda2da60451', N'TK69aa3723', CAST(N'2026-10-21 03:53:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ac6c1bff30a7478', N'TK01', CAST(N'2026-10-08 13:23:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ac8c9b8f01db47f', N'TK04', CAST(N'2026-10-17 14:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'acd4bca83c17447', N'TK03', CAST(N'2026-10-17 16:49:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ace796c2cc9d485', N'TK01', CAST(N'2026-10-08 09:10:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ad105b48234442e', N'TK02', CAST(N'2026-10-09 16:15:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ad442a0744ee4b2', N'TK01', CAST(N'2026-10-08 23:17:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ad6215eec0ea48b', N'TK01', CAST(N'2026-10-09 06:09:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ad6a037c9c57447', N'TK01', CAST(N'2026-10-08 13:04:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'adc55371f6f54fe', N'TK02', CAST(N'2026-10-19 01:30:52' AS DateTime), N'Tài chính', N'Thêm', N'DS1be023c7', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'addf7918a42a4c6', N'TK01', CAST(N'2026-10-08 09:06:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ade11460b0ab490', N'TK01', CAST(N'2026-10-09 06:10:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ade5d8b1e588469', N'TK01', CAST(N'2026-10-08 13:04:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ade8cc1b895b470', N'TK01', CAST(N'2026-10-09 17:39:26' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae15436110354e2', N'TK04', CAST(N'2026-10-15 20:12:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae5815f06d98490', N'TK01', CAST(N'2026-10-08 23:18:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae69df1cb8ee43a', N'TK01', CAST(N'2026-10-08 09:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae6b35dd0f8444a', N'TK01', CAST(N'2026-10-09 06:48:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae6b53b004f24aa', N'TK01', CAST(N'2026-10-09 06:11:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae8b2fa2fd9a445', N'TK01', CAST(N'2026-10-08 08:17:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ae91ff0b22204e5', N'TK01', CAST(N'2026-10-09 17:37:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aeb53d3b3fe6462', N'TK01', CAST(N'2026-10-09 16:12:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'aedbe9d3ab4e4fa', N'TK02', CAST(N'2026-10-09 16:13:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af013b8032e1429', N'TK01', CAST(N'2026-10-17 18:20:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af0cd3ddc5cb44e', N'TK01', CAST(N'2026-10-08 13:07:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af216538617d458', N'TK02', CAST(N'2026-10-09 06:46:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af2a079fa574443', N'TK01', CAST(N'2026-10-08 13:07:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af4ad89a76c94e0', N'TK02', CAST(N'2026-10-21 09:49:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'af7de85bcd9c464', N'TK02', CAST(N'2026-10-17 15:22:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'afcfd9e556324dc', N'TK03', CAST(N'2026-10-17 00:01:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'afdac2e38481464', N'TK01', CAST(N'2026-10-08 09:00:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'afe8fe2dc225424', N'TK02', CAST(N'2026-10-21 09:08:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'afed09d4ada0460', N'TK01', CAST(N'2026-10-09 06:09:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b013ac9abf1d475', N'TK01', CAST(N'2026-10-15 20:16:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b014a7e71d62431', N'TK02', CAST(N'2026-10-21 17:46:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0271d5a421840e', N'TK01', CAST(N'2026-10-09 06:09:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0806ad57b8b4ee', N'TK69aa3723', CAST(N'2026-10-21 08:31:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0842402f46043c', N'TK01', CAST(N'2026-10-09 16:15:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0996311db2c464', N'TK01', CAST(N'2026-10-08 08:24:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b09ab0647072451', N'TK04', CAST(N'2026-10-17 14:22:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0c5011c20a44ed', N'TK04', CAST(N'2026-10-08 13:07:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b0f7e5d290914fa', N'TK01', CAST(N'2026-10-09 17:39:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b1226636e9ec443', N'TK02', CAST(N'2026-10-15 23:39:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b1551a69106a40c', N'TK01', CAST(N'2026-10-02 23:29:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b15e67bf5eb1492', N'TK02', CAST(N'2026-10-09 16:13:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b17055f01e2e455', N'TK01', CAST(N'2026-10-08 12:03:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b181766f3c3f41a', N'TK02', CAST(N'2026-10-09 17:38:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b19c7ada4ebd47c', N'TK01', CAST(N'2026-10-09 17:38:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b1e4660ea4dc4cd', N'TK02', CAST(N'2026-10-09 17:38:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b2179acf9c12479', N'TKe09ddb74', CAST(N'2026-10-20 21:10:19' AS DateTime), N'Đặt sân', N'Thêm', N'DSb3294259', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 763333.33', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b22be5c0296a4cb', N'TK04', CAST(N'2026-10-17 16:41:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b2500d2fcd2043a', N'TK02', CAST(N'2026-10-09 16:13:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b27745472861402', N'TK01', CAST(N'2026-10-09 06:11:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b29e55b7321a4e3', N'TK01', CAST(N'2026-10-09 06:49:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b29eacdf70cc4af', N'TK01', CAST(N'2026-10-08 23:17:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b2d0d43c9d7a4d2', N'TK04', CAST(N'2026-10-17 13:36:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b2ed75e7c04344d', N'TK01', CAST(N'2026-10-08 09:09:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b30ebc2eb35e4a7', N'TK01', CAST(N'2026-10-02 22:37:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b344e103e7304b0', N'TK69aa3723', CAST(N'2026-10-16 19:10:23' AS DateTime), N'Tài chính', N'Thêm', N'DSb8e725ef', N'Hủy; tỷ lệ hoàn 100.00; thực thu 0.00; yêu cầu hoàn 0.00; chưa tự chuyển tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b35da29e6a0d4ea', N'TK03', CAST(N'2026-10-09 17:39:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b3a626572d33414', N'TK01', CAST(N'2026-10-02 23:26:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b3a7c7b3703a4d5', N'TK04', CAST(N'2026-10-09 17:39:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b41256574e10499', N'TK03', CAST(N'2026-10-20 13:56:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b438a2d23ef34b0', N'TK02', CAST(N'2026-10-08 23:17:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b484df48fde146d', N'TK01', CAST(N'2026-10-08 23:20:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b48a72b9de56420', N'TK69aa3723', CAST(N'2026-10-20 21:07:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b4b4764de244447', N'TK69aa3723', CAST(N'2026-10-21 09:13:28' AS DateTime), N'Đặt sân', N'Thêm', N'DS3c7fd553', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b4e21478d642453', N'TK01', CAST(N'2026-10-08 17:18:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b4ec6c08a3c3401', N'TK01', CAST(N'2026-10-09 06:50:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b517a7f488a04a5', N'TK01', CAST(N'2026-10-09 06:48:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b51d1e3779b74c8', N'TK01', CAST(N'2026-10-21 09:51:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b547acaea01844a', N'TK04', CAST(N'2026-10-09 06:09:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b56dc155e23248c', N'TK01', CAST(N'2026-10-08 17:28:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b57a7cc6f800404', N'TK01', CAST(N'2026-10-09 06:09:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5a1f61281ce469', N'TK69aa3723', CAST(N'2026-10-15 19:50:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5afdbcb2a3a4ab', N'TK03', CAST(N'2026-10-08 13:22:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5c288b160d04a7', N'TK01', CAST(N'2026-10-08 17:18:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5c46a85e2d645d', N'TKe09ddb74', CAST(N'2026-10-20 21:09:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TKe09ddb74', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5d679b27e55484', N'TK01', CAST(N'2026-10-08 13:21:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5f07d07a93e439', N'TK01', CAST(N'2026-10-08 06:24:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5f5897a1d55483', N'TK69aa3723', CAST(N'2026-10-20 20:46:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b5f78bed7474433', N'TK01', CAST(N'2026-10-08 23:18:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b61abbd82c7b404', N'TK01', CAST(N'2026-10-08 09:03:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b62c3caddb7041e', N'TK01', CAST(N'2026-10-09 16:12:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b62eefe4d36e465', N'TK69aa3723', CAST(N'2026-10-26 17:22:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b6781918d97d4ec', N'TK01', CAST(N'2026-10-08 13:34:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b682a73b958c462', N'TK01', CAST(N'2026-10-08 23:17:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b683bcaeaa644ad', N'TK01', CAST(N'2026-10-08 17:19:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b6910fd2d3df44f', N'TK01', CAST(N'2026-10-09 16:14:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b69aef5c12b74fd', N'TK04', CAST(N'2026-10-15 18:42:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b69edc3eff034ee', N'TK69aa3723', CAST(N'2026-10-19 00:16:46' AS DateTime), N'Đặt sân', N'Thêm', N'DSa49269f6', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b69ffa8dd31d4a9', N'TK03', CAST(N'2026-10-09 06:48:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b6af66a0b59142d', N'TK69aa3723', CAST(N'2026-10-21 08:28:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b6dc9a8c9b184a1', N'TK02', CAST(N'2026-10-08 13:22:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b72eb052c70447a', N'TK01', CAST(N'2026-10-08 13:04:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b732e6b54c14413', N'TK02', CAST(N'2026-10-08 17:26:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b73e4735efeb49c', N'TK04', CAST(N'2026-10-17 16:45:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b7425f527b514fe', N'TK03', CAST(N'2026-10-08 23:18:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b74a9e6db2404a2', N'TK02', CAST(N'2026-10-21 02:41:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b753f725a5a3478', N'TK01', CAST(N'2026-10-17 18:21:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b78080e2c04c45b', N'TK02', CAST(N'2026-10-09 06:46:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b7ab65e34c894d8', N'TK01', CAST(N'2026-10-08 17:18:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b81daba924b74b3', N'TK02', CAST(N'2026-10-09 06:45:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b8272d3b6bf44eb', N'TK01', CAST(N'2026-10-08 12:05:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b82976a46afe4d4', N'TK01', CAST(N'2026-10-09 06:49:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b831492510ae46e', N'TK02', CAST(N'2026-10-15 18:54:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b8366f78a7164b5', N'TK02', CAST(N'2026-10-15 13:26:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b84f69876f4d4a7', N'TK01', CAST(N'2026-10-09 16:12:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b8529f93d8754fc', N'TK01', CAST(N'2026-10-08 13:13:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b8647a86f36142c', N'TK01', CAST(N'2026-10-08 23:17:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b8f4e123f9e8451', N'TK01', CAST(N'2026-10-08 13:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b911c567c88d47f', N'TK03', CAST(N'2026-10-15 19:37:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9274098e9d2426', N'TK02', CAST(N'2026-10-17 00:53:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b933fd2936f740e', N'TK02', CAST(N'2026-10-09 16:10:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b93c5ca0f5ae4e4', N'TK01', CAST(N'2026-10-08 13:22:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b947137f63b8478', N'TK01', CAST(N'2026-10-08 06:19:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9610304aa0441a', N'TK02', CAST(N'2026-10-21 08:32:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b966c2227956411', N'TK01', CAST(N'2026-10-02 22:34:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b96e9bb9ffe74c0', N'TK01', CAST(N'2026-10-08 12:03:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9831da1b26c474', N'TK01', CAST(N'2026-10-02 23:29:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9bb2a67ff2d4e2', N'TK03', CAST(N'2026-10-21 09:24:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9d3cc18eb5640d', N'TK04', CAST(N'2026-10-08 15:05:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9df54afbdc041e', N'TK01', CAST(N'2026-10-08 17:19:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'b9f5d3a43cee4e7', N'TK01', CAST(N'2026-10-08 13:03:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba15ce465071412', N'TK01', CAST(N'2026-10-09 17:38:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba291ebc7c95480', N'TK01', CAST(N'2026-10-21 18:12:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba3776e69af543e', N'TK03', CAST(N'2026-10-21 03:26:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba524abb49a94a3', N'TK01', CAST(N'2026-10-02 22:38:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba6db907b28b458', N'TK01', CAST(N'2026-10-08 06:21:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba987e23e3c24ad', N'TK01', CAST(N'2026-10-08 13:05:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ba9df00de6ce470', N'TK03', CAST(N'2026-10-16 22:17:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'baa9a95bbd004b3', N'TK03', CAST(N'2026-10-21 03:15:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bab036bceb794a0', N'TK02', CAST(N'2026-10-21 10:45:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'badf26e1f051468', N'TK01', CAST(N'2026-10-09 16:12:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'baefbda7075e41a', N'TK01', CAST(N'2026-10-08 06:23:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb0c5b53c05f435', N'TK03', CAST(N'2026-10-21 09:50:04' AS DateTime), N'Tài chính', N'Thêm', N'DS7c177524', N'Ghi nhận thực thu 72500', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb15fdb5af0b4c8', N'TK01', CAST(N'2026-10-09 17:37:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb2450b737df456', N'TK01', CAST(N'2026-10-16 19:43:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb3819f34cfe405', N'TK02', CAST(N'2026-10-26 14:10:55' AS DateTime), N'Đặt sân', N'Thêm', N'DS30a6aed0', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 262166.67', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb3f5993000244a', N'TK02', CAST(N'2026-10-22 11:36:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb4ebe6e573c467', N'TK69aa3723', CAST(N'2026-10-15 19:41:43' AS DateTime), N'Đặt sân', N'Thêm', N'DSde60d0ed', N'Tạo booking giờ tự do; giá/giờ 180000.00; tổng 180000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb50c4852a0342b', N'TK69aa3723', CAST(N'2026-10-21 03:26:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bb6eb33f562443a', N'TK01', CAST(N'2026-10-15 18:42:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bba93de5cabb439', N'TK01', CAST(N'2026-10-09 06:09:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bbfeccd9c87b4e1', N'TK01', CAST(N'2026-10-08 17:31:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc0389b9c9f0436', N'TK01', CAST(N'2026-10-08 09:22:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc1e90d8f4474aa', N'TK03', CAST(N'2026-10-09 06:09:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc252d53baab46b', N'TK04', CAST(N'2026-10-17 00:01:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc3561eb0da9432', N'TK01', CAST(N'2026-10-08 12:02:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc3c925f25ad44e', N'TK01', CAST(N'2026-10-08 13:05:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc583abd48574e4', N'TK01', CAST(N'2026-10-09 16:11:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc741a7cd10e4d1', N'TK01', CAST(N'2026-10-08 13:23:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bc80f4c27d4e479', N'TK02', CAST(N'2026-10-21 10:45:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bcc9fce2e43b4c8', N'TK01', CAST(N'2026-10-08 09:10:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bccc421251d6460', N'TK03', CAST(N'2026-10-15 18:42:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd065937bfba415', N'TK01', CAST(N'2026-10-08 23:17:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd09beb117074b9', N'TK69aa3723', CAST(N'2026-10-19 00:12:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd1fb8b9286f47d', N'TK01', CAST(N'2026-10-08 17:19:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd23bb4e9343484', N'TK69aa3723', CAST(N'2026-10-21 03:21:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd2d6458ea1e4b3', N'TK03', CAST(N'2026-10-08 17:18:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd801c1bdc2242b', N'TK03', CAST(N'2026-10-08 13:23:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bd891c5b5e2a432', N'TK04', CAST(N'2026-10-15 23:43:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bdb44a7f77e84f6', N'TK01', CAST(N'2026-10-08 08:59:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bde25dfc6f124c1', N'TK02', CAST(N'2026-10-14 18:35:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bdf71767626b4ed', N'TK01', CAST(N'2026-10-17 17:37:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'be1a80ed8878444', N'TK01', CAST(N'2026-10-08 12:06:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'be567798775b4e6', N'TK69aa3723', CAST(N'2026-10-21 08:28:50' AS DateTime), N'Tài chính', N'Thêm', N'DSfd1965b2', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'be5948317a9c48a', N'TK01', CAST(N'2026-10-09 06:49:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'beb0786834dc4ee', N'TK02', CAST(N'2026-10-08 13:13:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'beb6197fd62646c', N'TK02', CAST(N'2026-10-16 19:46:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bebcbe99614247c', N'TK02', CAST(N'2026-10-15 20:13:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'becb2d7a802a4d8', N'TK04', CAST(N'2026-10-08 09:13:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'becbcad11be349f', N'TK02', CAST(N'2026-10-09 16:10:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'becd0dd09feb4fc', N'TK04', CAST(N'2026-10-08 09:17:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf20068262994bd', N'TK01', CAST(N'2026-10-08 13:04:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf3b37213df74f3', N'TK01', CAST(N'2026-10-08 17:19:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf3f6f04c58945d', N'TK01', CAST(N'2026-10-09 16:12:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf484c4072c543a', N'TK03', CAST(N'2026-10-08 13:04:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf77895329df4e0', N'TK69aa3723', CAST(N'2026-10-21 09:09:11' AS DateTime), N'Đặt sân', N'Thêm', N'DS776a68a8', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf9e1d7ac1204ab', N'TK01', CAST(N'2026-10-09 06:48:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bf9e62bc6b63428', N'TK01', CAST(N'2026-10-08 13:07:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfad5444fbe1406', N'TK01', CAST(N'2026-10-08 12:06:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfb037ea08da4f4', N'TK04', CAST(N'2026-10-08 12:07:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfb2a78c56c54aa', N'TK03', CAST(N'2026-10-21 03:21:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfd59d914b48468', N'TK02', CAST(N'2026-10-09 06:49:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bffa786f2e5e4f1', N'TK01', CAST(N'2026-10-08 08:21:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfff6b4b163e4e6', N'TK69aa3723', CAST(N'2026-10-15 13:47:12' AS DateTime), N'Đặt sân', N'Thêm', N'DS419d883b', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'bfff7971305e42c', N'TK01', CAST(N'2026-10-08 13:07:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c011fa69db7e402', N'TK01', CAST(N'2026-10-08 06:07:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c024c5049fc44aa', N'TK02', CAST(N'2026-10-17 18:22:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c05eaf1ffeab4f5', N'TK01', CAST(N'2026-10-08 06:26:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c0f220cd8a684e8', N'TK03', CAST(N'2026-10-17 13:39:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1026e3439244fe', N'TK69aa3723', CAST(N'2026-10-18 08:49:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1538c5e0de44f2', N'TK01', CAST(N'2026-10-08 13:07:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1559499bf004cf', N'TK02', CAST(N'2026-10-21 03:53:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c16c029863b749d', N'TK03', CAST(N'2026-10-18 10:50:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1a748943d31422', N'TK04', CAST(N'2026-10-17 17:37:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1ada13729d1430', N'TK01', CAST(N'2026-10-09 17:37:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1cd204532dc4fd', N'TK01', CAST(N'2026-10-21 17:45:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c1ea45aa93344c5', N'TK01', CAST(N'2026-10-09 16:13:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c21e4591e726467', N'TK01', CAST(N'2026-10-08 12:06:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c230dd3e9e08400', N'TK04', CAST(N'2026-10-17 13:39:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c23c9b13e8ef4f5', N'TK03', CAST(N'2026-10-17 17:18:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c256d43551024db', N'TK01', CAST(N'2026-10-08 13:07:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c25701816756480', N'TK01', CAST(N'2026-10-09 06:49:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c2908beefcb043c', N'TK01', CAST(N'2026-10-08 13:12:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c2d6175ac6d343d', N'TK02', CAST(N'2026-10-15 19:07:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3244e937ef2453', N'TK03', CAST(N'2026-10-21 03:29:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c340a74ea9dd4ff', N'TK01', CAST(N'2026-10-09 16:15:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c346a47c3128411', N'TK02', CAST(N'2026-10-17 15:20:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c363ca6a76dc4df', N'TK01', CAST(N'2026-10-08 23:17:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3677e07a0ea477', N'TK04', CAST(N'2026-10-08 09:03:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c37bd9669917493', N'TK02', CAST(N'2026-10-09 17:38:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3873b52051348a', N'TK01', CAST(N'2026-10-09 17:38:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c38a0355217948e', N'TK01', CAST(N'2026-10-08 12:03:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c38ddde0135c491', N'TK01', CAST(N'2026-10-09 06:49:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c39c9a511250492', N'TK02', CAST(N'2026-10-21 08:54:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3adfb4b3fc8401', N'TK03', CAST(N'2026-10-21 09:29:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3c7fd1f83b6448', N'TK01', CAST(N'2026-10-08 12:05:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c3d2789099b4407', N'TK01', CAST(N'2026-10-08 13:07:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c40ede499249401', N'TK69aa3723', CAST(N'2026-10-21 03:22:28' AS DateTime), N'Tài chính', N'Thêm', N'DS622125ef', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c473ff44387c447', N'TK01', CAST(N'2026-10-02 23:22:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c4dd975901e0413', N'TK69aa3723', CAST(N'2026-10-18 18:58:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c513db9c8f854a4', N'TK69aa3723', CAST(N'2026-10-15 23:28:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c51497f7460e45f', N'TK01', CAST(N'2026-10-08 12:03:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c542c1e610114cd', N'TK01', CAST(N'2026-10-08 12:06:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c544200d91454e9', N'TK01', CAST(N'2026-10-08 23:17:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c547a47d6419422', N'TK02', CAST(N'2026-10-09 17:40:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c5818df002ba434', N'TK02', CAST(N'2026-10-21 03:53:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c584cd8ac634415', N'TK01', CAST(N'2026-10-08 06:22:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c5cc16106e7042b', N'TK01', CAST(N'2026-10-08 06:21:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c5dd78fcdb084a8', N'TK04', CAST(N'2026-10-15 19:36:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c5e0d3053f9547e', N'TK01', CAST(N'2026-10-08 13:22:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c60bdf3a25e24cb', N'TK01', CAST(N'2026-10-08 12:05:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c61366cf36684ce', N'TK04', CAST(N'2026-10-18 10:50:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c616cea2acf5417', N'TK01', CAST(N'2026-10-08 12:06:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c621bdbe3ded48a', N'TK04', CAST(N'2026-10-09 16:15:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c637d458dcb1417', N'TK01', CAST(N'2026-10-09 06:11:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c678db680d1b433', N'TK01', CAST(N'2026-10-08 09:10:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c687dba73d9d486', N'TK01', CAST(N'2026-10-09 16:14:47' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c6d5ec1bd7ac434', N'TK69aa3723', CAST(N'2026-10-19 00:27:51' AS DateTime), N'Đặt sân', N'Sửa', N'DS99d5359e', N'Hủy booking: đe', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7136832616749e', N'TK01', CAST(N'2026-10-17 16:34:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c75358acd7ed43c', N'TK01', CAST(N'2026-10-08 13:04:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7a2aec825b641d', N'TK01', CAST(N'2026-10-09 06:49:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7a8e96680cc4f4', N'TK02', CAST(N'2026-10-21 09:11:01' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DS776a68a8', N'Dịch vụ phát sinh DV02; số lượng 2; quy cách DON_VI', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7a91fbb341c420', N'TK04', CAST(N'2026-10-15 19:39:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7aa64bb088f4a3', N'TK69aa3723', CAST(N'2026-10-18 22:56:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7ce3aeaf19748a', N'TK01', CAST(N'2026-10-09 06:50:16' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c7eb0fcfd4b045f', N'TK01', CAST(N'2026-10-09 06:09:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c8a4ba6109df419', N'TK01', CAST(N'2026-10-08 23:17:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c8a7f5cbea134b0', N'TK01', CAST(N'2026-10-08 17:18:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c8f57491180c479', N'TK03', CAST(N'2026-10-21 03:16:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c8fdd75859b94bd', N'TK69aa3723', CAST(N'2026-10-17 13:56:35' AS DateTime), N'Đặt sân', N'Thêm', N'DS583ac166', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 650000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c9090f6d03bc47d', N'TK01', CAST(N'2026-10-02 23:26:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c9133a419650486', N'TK01', CAST(N'2026-10-08 09:05:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c9372b0e76044c6', N'TK01', CAST(N'2026-10-08 13:05:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c94c1905d518403', N'TK01', CAST(N'2026-10-09 06:48:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c98c868df0e44d5', N'TK01', CAST(N'2026-10-08 09:10:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c99cf6bfb1d245a', N'TK04', CAST(N'2026-10-15 23:32:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c9d184774ff4491', N'TK01', CAST(N'2026-10-08 23:18:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'c9d86c4bbf574f0', N'TK01', CAST(N'2026-10-08 13:22:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ca1612fa78c1461', N'TK01', CAST(N'2026-10-09 06:48:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ca1e201ec68b4f1', N'TK69aa3723', CAST(N'2026-10-20 21:28:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ca1f05f3fc88440', N'TK02', CAST(N'2026-10-15 19:36:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ca3d36f925bf49d', N'TK03', CAST(N'2026-10-15 19:07:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'CAB45DCE3923429', N'TK01', CAST(N'2026-10-22 12:08:01' AS DateTime), N'Đặt sân', N'Sửa', N'DSe4899600', N'Bảo trì Codex theo yêu cầu người dùng: sửa trạng thái Chờ xác nhận thành Đã xác nhận sau đối soát thực thu thành công 90.000đ/90.000đ. Không tạo/sửa khoản thu, hóa đơn hoặc hoàn tiền. Nhật ký gắn TK01, không phải phiên đăng nhập TK01.', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'caf3ef4e0ab74c7', N'TK01', CAST(N'2026-10-17 15:22:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cafca2018b774af', N'TK02', CAST(N'2026-10-09 06:49:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cb671ac9a91b4d2', N'TK01', CAST(N'2026-10-08 08:17:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cb8bccf0312f456', N'TK01', CAST(N'2026-10-09 06:48:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cbea51650a70423', N'TK03', CAST(N'2026-10-17 15:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cbed3a0e28db4c0', N'TK01', CAST(N'2026-10-09 06:48:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cc366ac938ef41b', N'TK01', CAST(N'2026-10-08 09:10:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cc41fd1720b84f9', N'TK01', CAST(N'2026-10-09 06:09:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cc854240425e45d', N'TK69aa3723', CAST(N'2026-10-20 22:32:29' AS DateTime), N'Đặt sân', N'Thêm', N'DSe2413eca', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ccb1fcc1c89a421', N'TK03', CAST(N'2026-10-08 13:34:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ccf3f6f7c86a403', N'TK04', CAST(N'2026-10-17 15:22:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd05ee1e8b074d0', N'TK03', CAST(N'2026-10-17 18:22:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd38288b49f8475', N'TK01', CAST(N'2026-10-08 08:21:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd5a7eb5ae224e3', N'TK01', CAST(N'2026-10-17 18:43:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd836285662b4ac', N'TK02', CAST(N'2026-10-26 14:07:15' AS DateTime), N'Đặt sân', N'Thêm', N'KHe7347f1e', N'Tạo hồ sơ khách tại quầy', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd841dbb5fd9448', N'TK01', CAST(N'2026-10-08 23:17:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd875778c87e423', N'TK04', CAST(N'2026-10-15 23:42:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cd9413c83f9d4f5', N'TK01', CAST(N'2026-10-08 12:05:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cdabf2380d6947c', N'TK69aa3723', CAST(N'2026-10-14 15:40:52' AS DateTime), N'Đặt sân', N'Thêm', N'DSa3a1e2ae', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 805000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cde1e8f8727f454', N'TK01', CAST(N'2026-10-08 08:18:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ce0bcccf6f05489', N'TK04', CAST(N'2026-10-17 18:20:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ce1912768c744e6', N'TK01', CAST(N'2026-10-08 23:17:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ce22e5f56ed0402', N'TK02', CAST(N'2026-10-09 16:13:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ce73ef57ddad42f', N'TK69aa3723', CAST(N'2026-10-18 08:51:05' AS DateTime), N'Đặt sân', N'Thêm', N'DS5f4f261a', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cea2715351c54ee', N'TK01', CAST(N'2026-10-08 17:19:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ceb977f9c09342f', N'TK69aa3723', CAST(N'2026-10-21 08:43:33' AS DateTime), N'Tài chính', N'Thêm', N'DSaf089e4f', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cecafd5fdd70483', N'TK01', CAST(N'2026-10-09 17:38:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ceec7f04c0fe4b9', N'TK01', CAST(N'2026-10-09 16:11:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cf2bd366f72b452', N'TK01', CAST(N'2026-10-09 16:13:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cf3b8f75cd6e456', N'TK02', CAST(N'2026-10-21 07:13:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cf571eefa6c64a6', N'TK01', CAST(N'2026-10-08 13:22:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cf7988bf0d024a5', N'TK04', CAST(N'2026-10-09 06:10:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cfa3c5c972c542c', N'TK01', CAST(N'2026-10-08 17:18:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cfc468bcfdac4ac', N'TK02', CAST(N'2026-10-19 01:59:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'cfec0f07cb2f40f', N'TK01', CAST(N'2026-10-08 06:24:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd01c3611041a4df', N'TK01', CAST(N'2026-10-09 16:12:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd075e37a900049b', N'TK01', CAST(N'2026-10-08 09:09:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd08837daa361463', N'TK69aa3723', CAST(N'2026-10-14 15:37:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd089b44b3070499', N'TK01', CAST(N'2026-10-08 13:04:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd0bfbabae48e424', N'TK01', CAST(N'2026-10-08 06:23:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd0cce429bbc446d', N'TK69aa3723', CAST(N'2026-10-19 00:40:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd0e3df23965f4e8', N'TK02', CAST(N'2026-10-09 16:15:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd103c838bf3c476', N'TK01', CAST(N'2026-10-09 17:38:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd10fc812414d49e', N'TK01', CAST(N'2026-10-08 23:18:37' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd116c7321914459', N'TK01', CAST(N'2026-10-08 13:04:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd130028eaf65481', N'TK01', CAST(N'2026-10-09 16:13:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd132e95ecda34f8', N'TK03', CAST(N'2026-10-08 23:17:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd15b5369da9b4d5', N'TK01', CAST(N'2026-10-21 04:09:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd164f6f0aa53483', N'TK03', CAST(N'2026-10-21 17:47:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1a50adc58eb40a', N'TK03', CAST(N'2026-10-15 20:12:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1ad0b05310342f', N'TK03', CAST(N'2026-10-16 19:46:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1d0c3c69b0a46d', N'TK01', CAST(N'2026-10-09 17:39:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1dc52d3309f488', N'TK04', CAST(N'2026-10-09 17:40:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1e88d2955f5463', N'TK01', CAST(N'2026-10-08 09:03:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1f1519173f94ea', N'TK69aa3723', CAST(N'2026-10-18 21:20:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd1fad960c3cd42c', N'TK04', CAST(N'2026-10-15 23:38:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd282438cf2e54ef', N'TK01', CAST(N'2026-10-09 17:39:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd293b5e30a5a4dc', N'TK04', CAST(N'2026-10-08 15:06:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd29f958713ae487', N'TK01', CAST(N'2026-10-15 23:28:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd2b3d99521c4479', N'TK02', CAST(N'2026-10-09 06:09:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd2cf493497c84f1', N'TK01', CAST(N'2026-10-08 13:08:17' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd2eb1666d85b4f5', N'TK01', CAST(N'2026-10-08 13:07:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd31610a67aac4cf', N'TK01', CAST(N'2026-10-09 06:48:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd31d6835dbdd4d8', N'TK01', CAST(N'2026-10-16 20:27:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3215415b8424b2', N'TK04', CAST(N'2026-10-16 19:42:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd34e82a339f3475', N'TK03', CAST(N'2026-10-08 12:07:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd35ba3c681384be', N'TK69aa3723', CAST(N'2026-10-21 08:32:20' AS DateTime), N'Tài chính', N'Thêm', N'DS805518a4', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd390639e276348f', N'TK01', CAST(N'2026-10-09 06:08:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd392a531786d40f', N'TK01', CAST(N'2026-10-09 06:09:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3acdb33e3c24ed', N'TK01', CAST(N'2026-10-08 17:19:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3be4d88b7cf434', N'TK01', CAST(N'2026-10-08 08:21:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3c34050c67140a', N'TK02', CAST(N'2026-10-21 09:08:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3d82563a9b7465', N'TK01', CAST(N'2026-10-08 06:21:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd3fafbf10f4c466', N'TK01', CAST(N'2026-10-09 16:12:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd41a4371bd034ae', N'TK01', CAST(N'2026-10-09 16:15:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd41ddf67e09145a', N'TK02', CAST(N'2026-10-19 01:47:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4326a2b15824a2', N'TK01', CAST(N'2026-10-08 13:23:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd47f3ae028fb4de', N'TK01', CAST(N'2026-10-08 06:24:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd492ab6af18f464', N'TK01', CAST(N'2026-10-08 12:05:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4a010af1c3f470', N'TK02', CAST(N'2026-10-21 09:48:59' AS DateTime), N'Nhận sân / Dịch vụ', N'Sửa', N'DS7c177524', N'Trả sân; chốt snapshot hóa đơn, chưa tự thu tiền', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4a102514ef04eb', N'TK01', CAST(N'2026-10-09 06:48:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4a5189c0fc94f2', N'TK04', CAST(N'2026-10-18 10:50:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4ab0be59a0c4e4', N'TK01', CAST(N'2026-10-17 20:32:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4affdc976c041f', N'TK02', CAST(N'2026-10-21 09:09:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4b0350225bd486', N'TK04', CAST(N'2026-10-15 18:42:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4c21ebc130a4a9', N'TK01', CAST(N'2026-10-09 06:49:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd4f158c60a1c4fc', N'TK69aa3723', CAST(N'2026-10-22 11:45:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd501e0f6eebc4b9', N'TK01', CAST(N'2026-10-08 09:00:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd51c83ee87f84db', N'TK04', CAST(N'2026-10-16 19:46:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd5247dd226d34ad', N'TK01', CAST(N'2026-10-09 16:12:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd529512965b948e', N'TK01', CAST(N'2026-10-08 09:10:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd535ded8ff724d1', N'TK01', CAST(N'2026-10-09 16:13:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd5581bd6b2b14c3', N'TK02', CAST(N'2026-10-09 16:13:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd56b51cf91654e0', N'TK01', CAST(N'2026-10-09 16:13:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd58bca5306ca477', N'TK01', CAST(N'2026-10-02 23:26:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd5ae3cea11e744a', N'TK02', CAST(N'2026-10-09 06:46:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd62d7e84b6514f9', N'TK01', CAST(N'2026-10-19 15:31:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd64a047244bb4e0', N'TK03', CAST(N'2026-10-17 00:51:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd67de0d67128459', N'TK01', CAST(N'2026-10-09 16:14:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd6874455403744b', N'TK01', CAST(N'2026-10-08 08:24:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd6c6f4de95ec4a7', N'TK01', CAST(N'2026-10-08 17:19:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd6cac4b2d21e4ee', N'TK01', CAST(N'2026-10-08 09:10:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7136fe91cff4c8', N'TK02', CAST(N'2026-10-17 13:39:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd730e54992d6460', N'TK01', CAST(N'2026-10-08 13:08:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd73f049a5c8a457', N'TK01', CAST(N'2026-10-08 13:22:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7971ed31128470', N'TK01', CAST(N'2026-10-02 23:22:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7a05e64f48346f', N'TK01', CAST(N'2026-10-15 18:42:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7b59ea25f8f486', N'TKe09ddb74', CAST(N'2026-10-20 21:10:19' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DSb3294259', N'Dịch vụ đặt trước; 1 dòng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7c4f55c0c8f427', N'TK03', CAST(N'2026-10-08 13:13:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7dd554174034f3', N'TK01', CAST(N'2026-10-08 13:03:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7e422373777497', N'TK01', CAST(N'2026-10-08 09:03:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7e6b5b220de451', N'TK02', CAST(N'2026-10-20 13:55:21' AS DateTime), N'Đặt sân', N'Thêm', N'KH8ae19d2f', N'Tạo hồ sơ khách tại quầy', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd7f7866fd7fd43a', N'TK01', CAST(N'2026-10-09 06:09:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd80a670b344a46b', N'TK01', CAST(N'2026-10-08 13:22:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd81639f5f4d74fe', N'TK01', CAST(N'2026-10-08 09:03:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd849d7be022349b', N'TK69aa3723', CAST(N'2026-10-16 08:17:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd855e6d5f5d94ef', N'TK01', CAST(N'2026-10-02 23:22:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd8616ca214654cf', N'TK01', CAST(N'2026-10-17 16:41:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd89270c46d36412', N'TK01', CAST(N'2026-10-09 16:13:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd8d00d7e74d54ec', N'TK03', CAST(N'2026-10-21 03:21:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd8dc06112ed3406', N'TK01', CAST(N'2026-10-08 13:23:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd8e70f2ab52444b', N'TK01', CAST(N'2026-10-08 12:02:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd902188f9b49452', N'TK04', CAST(N'2026-10-08 13:13:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd952d367a245429', N'TK01', CAST(N'2026-10-08 12:05:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd96a06aef38044b', N'TK02', CAST(N'2026-10-17 14:22:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9847e82919e409', N'TK01', CAST(N'2026-10-16 08:59:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd998b0d6f5214a1', N'TK03', CAST(N'2026-10-15 20:12:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9aec14c0580499', N'TK04', CAST(N'2026-10-08 12:08:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9b06a9ca50c416', N'TK01', CAST(N'2026-10-09 06:09:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9b6dfe333294c6', N'TK69aa3723', CAST(N'2026-10-21 08:41:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9c14f14048e475', N'TK02', CAST(N'2026-10-09 17:40:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9cef26ef8564c3', N'TK03', CAST(N'2026-10-21 03:24:25' AS DateTime), N'Tài chính', N'Thêm', N'DS622125ef', N'Ghi nhận thực thu 180000', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9d03df7dc3b47f', N'TK02', CAST(N'2026-10-09 16:10:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'd9fee78b0c6449a', N'TK01', CAST(N'2026-10-08 17:18:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'da30bc6c30f24cc', N'TK03', CAST(N'2026-10-17 14:22:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'daa861b37b7b4a9', N'TK04', CAST(N'2026-10-16 09:31:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dafd4550fdbc49e', N'TK69aa3723', CAST(N'2026-10-14 15:40:52' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DSa3a1e2ae', N'Dịch vụ đặt trước; 2 dòng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'db38acdf072646c', N'TK01', CAST(N'2026-10-02 22:34:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dbaa79e2e0794e1', N'TK01', CAST(N'2026-10-09 17:39:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dbb4252744ea4da', N'TK01', CAST(N'2026-10-09 16:14:47' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dbdf934098e0490', N'TK01', CAST(N'2026-10-09 06:50:16' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dc170f3833454ea', N'TK02', CAST(N'2026-10-09 16:15:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dc62aaa631664ca', N'TK01', CAST(N'2026-10-08 12:02:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dc79a853086a4c1', N'TK04', CAST(N'2026-10-15 20:13:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dc9b15f8bfaf4b1', N'TK01', CAST(N'2026-10-08 09:10:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dcd17866bd11408', N'TK02', CAST(N'2026-10-09 16:10:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dcf7b7e153c04eb', N'TK01', CAST(N'2026-10-08 12:06:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dd1c70385c9f476', N'TK01', CAST(N'2026-10-08 17:19:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dd633f9141a6494', N'TK01', CAST(N'2026-10-09 06:50:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dda5cf94c70a453', N'TK02', CAST(N'2026-10-21 08:31:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dddac785d045401', N'TK04', CAST(N'2026-10-08 13:23:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dde6d3800da24f2', N'TK01', CAST(N'2026-10-08 13:05:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dde9ab0c3b97496', N'TK01', CAST(N'2026-10-08 13:22:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ddf50516da8648b', N'TK02', CAST(N'2026-10-18 00:04:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ddf53319f7ee467', N'TK01', CAST(N'2026-10-08 13:22:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ddf76ad0385042b', N'TK01', CAST(N'2026-10-08 13:22:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'de95b28b799c4e3', N'TK01', CAST(N'2026-10-08 09:09:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'debeebf869bb48b', N'TK69aa3723', CAST(N'2026-10-19 15:31:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dee1010112844c4', N'TK04', CAST(N'2026-10-08 13:11:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dee4ba573c5f446', N'TK03', CAST(N'2026-10-15 20:10:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'deefbeba862d465', N'TK69aa3723', CAST(N'2026-10-21 03:28:10' AS DateTime), N'Đặt sân', N'Thêm', N'DS361bb875', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'df0f3407dd1e439', N'TK03', CAST(N'2026-10-21 04:01:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'df16ba4ba236413', N'TK04', CAST(N'2026-10-09 17:38:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'df50d1a3ed0542b', N'TK02', CAST(N'2026-10-15 18:42:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'df9b22fddec84e1', N'TK01', CAST(N'2026-10-08 12:05:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dfd58b005a5646d', N'TK02', CAST(N'2026-10-09 17:38:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dfe8030014464f1', N'TK02', CAST(N'2026-10-09 06:49:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'dfff533f828c4a0', N'TK01', CAST(N'2026-10-08 06:22:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e03c02a3fec3478', N'TK01', CAST(N'2026-10-08 13:05:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e03fda0448c94ac', N'TK03', CAST(N'2026-10-16 23:59:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e055b6c0b9a34d6', N'TK01', CAST(N'2026-10-17 16:45:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e07b6a45f5d4455', N'TK03', CAST(N'2026-10-17 18:43:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e08f3fcf687f4ea', N'TK01', CAST(N'2026-10-08 09:06:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0945662fe6c4bc', N'TK04', CAST(N'2026-10-17 00:52:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0a67612c0a04c0', N'TK01', CAST(N'2026-10-08 13:12:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0d7807296684aa', N'TK01', CAST(N'2026-10-08 06:23:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0d9c509d715401', N'TK01', CAST(N'2026-10-16 08:59:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0f0437f56e640c', N'TK04', CAST(N'2026-10-15 20:12:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e0f3c307a1f4443', N'TK04', CAST(N'2026-10-17 18:20:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e11966a3a7d3402', N'TK01', CAST(N'2026-10-08 12:05:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e1650c3d560e43a', N'TK04', CAST(N'2026-10-17 00:52:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e1a76f069e89499', N'TK04', CAST(N'2026-10-17 16:43:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e1ca311b48f540f', N'TK69aa3723', CAST(N'2026-10-15 13:26:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e1dc47efe1704f7', N'TK01', CAST(N'2026-10-09 16:13:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e1e6fa80c375434', N'TK04', CAST(N'2026-10-09 06:09:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e201484b120f4d5', N'TK69aa3723', CAST(N'2026-10-21 02:39:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e222d8ffb7d7406', N'TK02', CAST(N'2026-10-15 18:41:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e225d9a14770483', N'TK03', CAST(N'2026-10-14 18:35:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e25f24e80c274d2', N'TK01', CAST(N'2026-10-08 13:03:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e261a41a1af9480', N'TK04', CAST(N'2026-10-08 17:18:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e271afe60108438', N'TK01', CAST(N'2026-10-08 09:09:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e27acda9bdda443', N'TK01', CAST(N'2026-10-09 06:08:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e27f02590047458', N'TK01', CAST(N'2026-10-08 13:07:58' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2acb34cef35457', N'TK01', CAST(N'2026-10-02 23:22:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2aeadc5a19a490', N'TK69aa3723', CAST(N'2026-10-16 09:00:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2ca4e11ecc144f', N'TK01', CAST(N'2026-10-08 23:17:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2dd1d2d8ff14c2', N'TK01', CAST(N'2026-10-09 16:13:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2eed0643d9a4c2', N'TK69aa3723', CAST(N'2026-10-20 14:16:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e2fe182e44b64ec', N'TK02', CAST(N'2026-10-21 04:24:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e311c739e5db410', N'TK01', CAST(N'2026-10-08 06:08:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e3204acb1175499', N'TK01', CAST(N'2026-10-09 06:48:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e321c3acba71455', N'TK01', CAST(N'2026-10-08 23:16:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e323866866df4b2', N'TK01', CAST(N'2026-10-08 08:21:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e3506570e78c483', N'TK01', CAST(N'2026-10-08 13:08:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e3a72721bd7740b', N'TK02', CAST(N'2026-10-09 16:15:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e3ab39f4619d480', N'TK69aa3723', CAST(N'2026-10-18 19:04:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e40625aa5141474', N'TK02', CAST(N'2026-10-09 16:13:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e446116266b44df', N'TK01', CAST(N'2026-10-09 17:39:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e469d911824d48d', N'TK01', CAST(N'2026-10-08 09:10:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e491e56326284ba', N'TK01', CAST(N'2026-10-09 17:39:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e492c55e0fe04ee', N'TK01', CAST(N'2026-10-08 12:06:28' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e4b5e21719c24b3', N'TK69aa3723', CAST(N'2026-10-21 09:46:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e4fcbb79a9c94c2', N'TK04', CAST(N'2026-10-16 19:43:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e5998c3e614b452', N'TK01', CAST(N'2026-10-08 09:10:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e5c0af1b1134473', N'TK03', CAST(N'2026-10-09 17:38:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e5c10c9f7cdf478', N'TK03', CAST(N'2026-10-21 03:24:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e5c3efaf29c6435', N'TK02', CAST(N'2026-10-08 08:26:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e5dc51056d0443d', N'TK01', CAST(N'2026-10-09 17:37:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e614881a53384e0', N'TK04', CAST(N'2026-10-08 09:06:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e64d6c820e0248d', N'TK01', CAST(N'2026-10-02 23:22:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e680f17b7c8b423', N'TK01', CAST(N'2026-10-08 13:04:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e69553ec2c9341e', N'TK02', CAST(N'2026-10-17 18:22:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e6b0150f167f424', N'TK01', CAST(N'2026-10-09 16:13:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e6b2fa96f8604f4', N'TK01', CAST(N'2026-10-08 09:09:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e6c89e35d35e48f', N'TK02', CAST(N'2026-10-09 06:46:53' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e6ec0f041a4f446', N'TK01', CAST(N'2026-10-17 20:33:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e70b87073c18415', N'TK01', CAST(N'2026-10-08 13:08:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e70b9162aac1436', N'TK02', CAST(N'2026-10-15 19:00:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e73a4dc87f3b4d7', N'TK02', CAST(N'2026-10-21 02:39:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e759b1de3aa4497', N'TK01', CAST(N'2026-10-08 08:24:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e78ce3c8fe64422', N'TK04', CAST(N'2026-10-15 18:41:47' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7a01a42f1624df', N'TK69aa3723', CAST(N'2026-10-22 11:37:49' AS DateTime), N'Đặt sân', N'Thêm', N'DSa9914634', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 63000.00', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7bf420fa5c74a7', N'TK01', CAST(N'2026-10-08 13:21:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7cab70db1ce496', N'TK01', CAST(N'2026-10-08 06:22:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7cb6b00fedf447', N'TK02', CAST(N'2026-10-09 16:10:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7e46ab0736241c', N'TK01', CAST(N'2026-10-08 23:18:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e7fcc81e016b4b6', N'TK01', CAST(N'2026-10-08 08:18:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e81bce940c494d8', N'TK02', CAST(N'2026-10-09 17:40:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e844fbb41a07416', N'TK69aa3723', CAST(N'2026-10-22 11:33:21' AS DateTime), N'Tài chính', N'Thêm', N'DSb9d7bd29', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e855afdbdc6b4dc', N'TK04', CAST(N'2026-10-08 23:18:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e8a3c6dfa8ad4d9', N'TK01', CAST(N'2026-10-08 06:20:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e8c75752f57e4da', N'TK02', CAST(N'2026-10-22 11:45:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e8d54d5721b14f5', N'TK02', CAST(N'2026-10-21 08:44:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e8ed61e7ed7a4bd', N'TK01', CAST(N'2026-10-08 08:26:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e90c1f718a09478', N'TK01', CAST(N'2026-10-08 12:05:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e90ddc89fdb541f', N'TK01', CAST(N'2026-10-17 15:24:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e96cd3dd4e4446c', N'TK69aa3723', CAST(N'2026-10-21 08:43:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e98cbcb80c10449', N'TK01', CAST(N'2026-10-02 23:27:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9aba66208594b6', N'TK01', CAST(N'2026-10-08 13:04:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9c3faa8b4cc440', N'TK01', CAST(N'2026-10-20 14:01:26' AS DateTime), N'Quản trị', N'Sửa', N'TK02', N'Cập nhật trạng thái/role tài khoản: VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9ca71dfcef0452', N'TK01', CAST(N'2026-10-08 23:17:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9d43300fa5c415', N'TK02', CAST(N'2026-10-19 01:13:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9d842fa3369469', N'TK01', CAST(N'2026-10-09 06:48:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9da443ea513466', N'TK01', CAST(N'2026-10-08 13:22:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'e9e12ea4b872472', N'TK69aa3723', CAST(N'2026-10-14 18:38:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ea20158495724cd', N'TK03', CAST(N'2026-10-15 20:13:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ea5cfd20b9064fe', N'TK02', CAST(N'2026-10-17 20:32:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ea94b4cef9b3459', N'TK01', CAST(N'2026-10-08 13:12:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eab4d142fc5a418', N'TK04', CAST(N'2026-10-16 23:59:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eae07ae3bb6f435', N'TK02', CAST(N'2026-10-17 18:43:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eaf07953316d477', N'TK69aa3723', CAST(N'2026-10-19 15:32:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eafbd0a800254e5', N'TK03', CAST(N'2026-10-08 13:07:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eafd6f36e6c4486', N'TK03', CAST(N'2026-10-08 13:22:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb10582508e441b', N'TK01', CAST(N'2026-10-17 00:01:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb1c5b3b8ac44c8', N'TK02', CAST(N'2026-10-21 09:08:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb241c74d51e435', N'TK01', CAST(N'2026-10-08 09:13:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb50e63c8752466', N'TK69aa3723', CAST(N'2026-10-21 02:40:48' AS DateTime), N'Tài chính', N'Thêm', N'DSa5f0cc04', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb6195983f2f423', N'TK01', CAST(N'2026-10-09 06:09:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb647ca86ab54f0', N'TK69aa3723', CAST(N'2026-10-19 00:20:28' AS DateTime), N'Đặt sân', N'Thêm', N'DS6dc55d36', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eb9c9ca0165d441', N'TK01', CAST(N'2026-10-08 13:08:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ebaf768df3c4476', N'TK02', CAST(N'2026-10-22 11:46:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ebb3a1c608dc45e', N'TK02', CAST(N'2026-10-08 09:10:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ebcf46840c0e4c4', N'TK02', CAST(N'2026-10-09 16:10:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ebf276ba8c5c42f', N'TK01', CAST(N'2026-10-02 23:27:02' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ec2898c37be440a', N'TK01', CAST(N'2026-10-09 06:09:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ec417d2dc6b2480', N'TK01', CAST(N'2026-10-08 13:05:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ec5ced0a757e4c8', N'TK01', CAST(N'2026-10-08 13:07:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ec8894adda3d4ca', N'TK04', CAST(N'2026-10-17 13:37:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ecce43a50e2d4cb', N'TK01', CAST(N'2026-10-08 23:17:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed0bcd2e5dff418', N'TK01', CAST(N'2026-10-09 17:38:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed17010f805344f', N'TK01', CAST(N'2026-10-08 12:06:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed3a28173ad6480', N'TK02', CAST(N'2026-10-09 16:15:34' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed3b3b4287594ed', N'TK04', CAST(N'2026-10-17 00:50:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed550688974e48e', N'TK01', CAST(N'2026-10-09 17:38:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ed6ca595f03544f', N'TK01', CAST(N'2026-10-08 09:10:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'edaa811c5542471', N'TK01', CAST(N'2026-10-08 12:07:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'edc373f6764f408', N'TK01', CAST(N'2026-10-08 17:35:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'edda42fda5114da', N'TK03', CAST(N'2026-10-20 22:14:50' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ee0275a329f9427', N'TK69aa3723', CAST(N'2026-10-21 09:18:00' AS DateTime), N'Tài chính', N'Thêm', N'DS3c7fd553', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ee417897595c46e', N'TK69aa3723', CAST(N'2026-10-21 09:13:20' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ee48f736094f44a', N'TK04', CAST(N'2026-10-08 09:10:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ee55827ddb254a8', N'TK01', CAST(N'2026-10-08 08:24:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ee67ddd4bef5476', N'TK01', CAST(N'2026-10-08 17:19:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eeb748c089fb4e1', N'TK01', CAST(N'2026-10-08 09:05:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eed74241513e47b', N'TK03', CAST(N'2026-10-15 23:42:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'eedc590bb35e48b', N'TK03', CAST(N'2026-10-16 22:15:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ef2ea0732a404ef', N'TK02', CAST(N'2026-10-09 16:13:28' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efb77fd25a6d441', N'TK01', CAST(N'2026-10-08 12:05:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efc58341a9784a7', N'TK01', CAST(N'2026-10-08 13:04:27' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efc64a9b1bba4a6', N'TK01', CAST(N'2026-10-09 06:09:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efd0c3364688485', N'TK01', CAST(N'2026-10-08 13:22:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efd305e86ab646b', N'TK01', CAST(N'2026-10-08 13:04:24' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'efed671de48f4a7', N'TK01', CAST(N'2026-10-09 16:12:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f02e3dadbd944ea', N'TK02', CAST(N'2026-10-15 12:55:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0350651cd8848d', N'TK01', CAST(N'2026-10-08 13:22:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f03920f8fd89409', N'TK03', CAST(N'2026-10-08 09:06:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f04e8565e885495', N'TK02', CAST(N'2026-10-09 06:47:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f05b468ad1f04f1', N'TK03', CAST(N'2026-10-17 17:18:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f09436210136460', N'TK02', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0bcd4fdc0454e9', N'TK01', CAST(N'2026-10-17 16:56:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0bf7d2fc6ff4ef', N'TK03', CAST(N'2026-10-22 11:46:51' AS DateTime), N'Tài chính', N'Thêm', N'DSe4899600', N'Ghi nhận thực thu 90000', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0d3b7c1014c473', N'TK01', CAST(N'2026-10-09 06:50:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0ea6eb166e24fe', N'TK01', CAST(N'2026-10-09 06:09:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0edb561652f414', N'TK01', CAST(N'2026-10-09 06:50:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0ee7de5427e44f', N'TK69aa3723', CAST(N'2026-10-16 08:57:47' AS DateTime), N'Nhận sân / Dịch vụ', N'Thêm', N'DS6ae185a3', N'Dịch vụ đặt trước; 1 dòng', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f0f03335dc64431', N'TK03', CAST(N'2026-10-16 19:46:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f10d44b4bb0a4fe', N'TK02', CAST(N'2026-10-08 09:06:05' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f13e465d2e334a0', N'TK01', CAST(N'2026-10-15 23:38:37' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f16b9697d5754ee', N'TK01', CAST(N'2026-10-08 13:23:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f172a58c36064c7', N'TK02', CAST(N'2026-10-15 19:36:22' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f1b94e9c20f94ad', N'TK03', CAST(N'2026-10-17 13:37:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f1ce24a4c2374e9', N'TK03', CAST(N'2026-10-17 16:49:45' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f1e6bcd1cbfd43d', N'TK01', CAST(N'2026-10-08 13:08:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f21117e19241423', N'TK04', CAST(N'2026-10-08 09:17:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2136d6c1d7b474', N'TK01', CAST(N'2026-10-08 06:23:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f21adf318ddb422', N'TK01', CAST(N'2026-10-08 23:17:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2305c8279e3478', N'TK01', CAST(N'2026-10-08 17:18:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f238bc1577834cd', N'TK01', CAST(N'2026-10-09 16:16:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f24cb11f6677422', N'TK03', CAST(N'2026-10-09 16:12:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f25cd1af33bc40a', N'TK01', CAST(N'2026-10-09 06:10:55' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f28c166e6aca476', N'TK01', CAST(N'2026-10-15 23:38:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f28f4380f4b948b', N'TK01', CAST(N'2026-10-08 13:21:32' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f28fb7bdee6546c', N'TK04', CAST(N'2026-10-17 00:51:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2973d12d251478', N'TK02', CAST(N'2026-10-09 16:10:09' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2cfba8e961c4ca', N'TK01', CAST(N'2026-10-08 13:04:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2d6977a759b4bc', N'TK01', CAST(N'2026-10-09 06:10:48' AS DateTime), N'Authentication / Phân quyền', N'Sửa', N'TK01', N'Cập nhật phân quyền vai trò VT02', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f2da5ddaaf9942f', N'TK01', CAST(N'2026-10-15 18:55:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f30f63b3de92416', N'TK03', CAST(N'2026-10-09 17:38:03' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f33afa13f667442', N'TK02', CAST(N'2026-10-09 06:49:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f35f4d0104874fb', N'TK01', CAST(N'2026-10-09 06:09:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f37d74f45e674d2', N'TK03', CAST(N'2026-10-08 09:03:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f38f90ed6126420', N'TK02', CAST(N'2026-10-09 06:49:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f3918c830b7a459', N'TK01', CAST(N'2026-10-08 13:23:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f3c6687d2e8d48c', N'TK01', CAST(N'2026-10-08 13:04:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f3ccd3ab4dbf43e', N'TK01', CAST(N'2026-10-09 06:48:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f3e234abdec4417', N'TK01', CAST(N'2026-10-09 06:48:31' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f40117c8b27244f', N'TK02', CAST(N'2026-10-09 17:40:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f4279892211849c', N'TK01', CAST(N'2026-10-09 06:49:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f42dd47f7c34451', N'TK02', CAST(N'2026-10-09 06:46:56' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f458f0420ba1497', N'TK02', CAST(N'2026-10-16 23:59:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f45ab76180bb401', N'TK69aa3723', CAST(N'2026-10-21 03:29:00' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f482405e988e41b', N'TK01', CAST(N'2026-10-09 06:09:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f4c6ec423934454', N'TK01', CAST(N'2026-10-08 06:26:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f515df880d1f48e', N'TK02', CAST(N'2026-10-21 09:46:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f57cefd7ea8b40a', N'TK69aa3723', CAST(N'2026-10-22 11:45:39' AS DateTime), N'Tài chính', N'Thêm', N'DSe4899600', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f59ba3f7325b4e3', N'TK01', CAST(N'2026-10-08 08:24:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f5c316c478064cc', N'TK69aa3723', CAST(N'2026-10-19 00:13:20' AS DateTime), N'Đặt sân', N'Thêm', N'DSac2992e9', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f6103b7fb5e84ce', N'TK01', CAST(N'2026-10-08 06:24:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f6240b424174458', N'TK01', CAST(N'2026-10-17 16:48:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f644a2ddb718454', N'TK01', CAST(N'2026-10-08 13:08:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f66361732acd4a1', N'TK01', CAST(N'2026-10-08 17:19:36' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f6942a8949ec479', N'TK02', CAST(N'2026-10-09 06:49:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f6ec472c173e4b7', N'TK69aa3723', CAST(N'2026-10-21 10:26:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f700f0bb1922430', N'TK02', CAST(N'2026-10-21 03:46:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f738c61d47ea471', N'TK69aa3723', CAST(N'2026-10-22 11:47:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f794642cceec461', N'TK69aa3723', CAST(N'2026-10-21 03:22:23' AS DateTime), N'Đặt sân', N'Thêm', N'DS622125ef', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 180000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f7ac083ffa0948f', N'TK69aa3723', CAST(N'2026-10-21 08:43:29' AS DateTime), N'Đặt sân', N'Thêm', N'DSaf089e4f', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f7b456dfa0a54b5', N'TK04', CAST(N'2026-10-17 20:35:30' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f7e3d3e2a3c64ee', N'TK01', CAST(N'2026-10-08 13:22:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f7efa2712d8c4d2', N'TK04', CAST(N'2026-10-02 22:49:29' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK04', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f7fc2724ab68406', N'TK69aa3723', CAST(N'2026-10-21 09:38:07' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8248933090b4b2', N'TK01', CAST(N'2026-10-09 17:38:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f82f1a4401e5410', N'TK04', CAST(N'2026-10-09 06:49:04' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f83cd36f5f0c4ed', N'TK02', CAST(N'2026-10-16 22:14:15' AS DateTime), N'Đặt sân', N'Sửa', N'DS5c92b544', N'Xác nhận booking', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f85a1d6d109f451', N'TK01', CAST(N'2026-10-08 08:26:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8638ab89dcd499', N'TK04', CAST(N'2026-10-09 16:10:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f88e04ca032040e', N'TK02', CAST(N'2026-10-09 16:15:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8bf62295c26432', N'TK01', CAST(N'2026-10-09 17:38:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8da2d785a12406', N'TK01', CAST(N'2026-10-09 06:50:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8e0443084d44ac', N'TK01', CAST(N'2026-10-09 17:38:35' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f8e3334bbf1e469', N'TK01', CAST(N'2026-10-02 23:26:42' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f92e686fdc80434', N'TK02', CAST(N'2026-10-09 16:13:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
GO
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f937ced85d164d9', N'TK02', CAST(N'2026-10-15 23:41:57' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK02', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f95312075ff8472', N'TK03', CAST(N'2026-10-16 16:52:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK03', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f989debba427432', N'TK01', CAST(N'2026-10-15 19:40:21' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f98a1e90a11a44d', N'TK02', CAST(N'2026-10-09 06:49:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f99192c4a9e8425', N'TK69aa3723', CAST(N'2026-10-19 00:39:45' AS DateTime), N'Đặt sân', N'Thêm', N'DS1be023c7', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 90000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f992a8b9fa214af', N'TK01', CAST(N'2026-10-09 17:39:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9b067908dd8445', N'TK01', CAST(N'2026-10-21 04:00:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9d8f0fa9600485', N'TK69aa3723', CAST(N'2026-10-16 08:57:47' AS DateTime), N'Đặt sân', N'Thêm', N'DS6ae185a3', N'Tạo booking giờ tự do; giá/giờ 90000.00; tổng 100000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9e5386e61364b0', N'TK01', CAST(N'2026-10-09 17:38:19' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9f2a4d00a34458', N'TK01', CAST(N'2026-10-08 12:05:12' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9f52dd831ba411', N'TK01', CAST(N'2026-10-08 13:34:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'f9fd10bdbb45459', N'TK03', CAST(N'2026-10-09 16:15:41' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa0aa49fcd58472', N'TK01', CAST(N'2026-10-08 17:19:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa2d732cded7425', N'TK03', CAST(N'2026-10-08 12:05:40' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa3f6ca4ae254a1', N'TK01', CAST(N'2026-10-08 13:22:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa41b2335dbc449', N'TK01', CAST(N'2026-10-09 16:12:38' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa4c32c8adad4af', N'TK02', CAST(N'2026-10-21 08:41:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fa8898a5f21947d', N'TK69aa3723', CAST(N'2026-10-18 23:09:43' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fac89a4592ff434', N'TK03', CAST(N'2026-10-09 06:09:25' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'faec60f661964d6', N'TK01', CAST(N'2026-10-08 08:18:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'faee8c5724384b9', N'TK03', CAST(N'2026-10-09 16:10:11' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'faf55563cd294b2', N'TK01', CAST(N'2026-10-08 13:08:15' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fafddb8eccf24e3', N'TK02', CAST(N'2026-10-17 15:22:33' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fb3f1b61e82a484', N'TK69aa3723', CAST(N'2026-10-21 03:47:52' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK69aa3723', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fbf0e455cacb4c5', N'TK69aa3723', CAST(N'2026-10-20 13:27:33' AS DateTime), N'Tài chính', N'Thêm', N'DSb5fc0559', N'Yêu cầu thanh toán; chưa xác nhận thực thu', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc2539f36be94ec', N'TK01', CAST(N'2026-10-08 17:19:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc2f4bb276ad4cb', N'TK01', CAST(N'2026-10-09 17:38:10' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc3dd8892a02427', N'TK69aa3723', CAST(N'2026-10-22 11:33:21' AS DateTime), N'Tài chính', N'Thêm', N'DSb9d7bd29', N'Lập hóa đơn duy nhất từ snapshot booking/dịch vụ', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc5a953e908940f', N'TK01', CAST(N'2026-10-09 17:38:16' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc5f3523d046432', N'TK02', CAST(N'2026-10-20 13:55:21' AS DateTime), N'Đặt sân', N'Thêm', N'DS367339f9', N'Tạo booking giờ tự do; giá/giờ 130000.00; tổng 130000.00', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc63f9338c074fd', N'TK01', CAST(N'2026-10-09 16:10:13' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc72cd39565f477', N'TK01', CAST(N'2026-10-09 06:09:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fc8c344577fd471', N'TK04', CAST(N'2026-10-15 19:35:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fd57bd6e849e4ce', N'TK01', CAST(N'2026-10-08 08:18:14' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fd7fcb3bc1f340b', N'TK01', CAST(N'2026-10-08 12:06:08' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fdd5132d558449a', N'TK02', CAST(N'2026-10-21 17:37:18' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fdd6aa2328f1420', N'TK03', CAST(N'2026-10-08 13:07:44' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK03', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fdd89cef726d427', N'TK01', CAST(N'2026-10-15 19:37:01' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fe008bfc2f1e423', N'TK69aa3723', CAST(N'2026-10-20 20:45:49' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fe34a6c5e94c4ed', N'TK01', CAST(N'2026-10-08 08:24:46' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fe6000dd0e914f0', N'TK01', CAST(N'2026-10-09 16:12:51' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fe7ffd687e824e3', N'TK69aa3723', CAST(N'2026-10-16 09:13:26' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK69aa3723', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fe81630aa91d491', N'TK04', CAST(N'2026-10-17 18:42:48' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ff1991201528444', N'TK01', CAST(N'2026-10-21 03:46:06' AS DateTime), N'Authentication / Phân quyền', N'Đăng xuất', N'TK01', N'Đăng xuất khỏi hệ thống', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ff22a91dd1ea4b7', N'TK01', CAST(N'2026-10-09 16:12:59' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ff2c3b1386e2418', N'TK01', CAST(N'2026-10-09 16:12:39' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ff504ea461b54a7', N'TK02', CAST(N'2026-10-15 19:39:23' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK02', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'ffb65911151b4ff', N'TK04', CAST(N'2026-10-16 19:46:17' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK04', N'Đăng nhập thành công', 1, NULL);
INSERT INTO dbo.[NhatKyHeThong] ([MaNhatKy], [MaTK], [ThoiGian], [ChucNang], [ThaoTac], [DoiTuong], [NoiDungThayDoi], [KetQua], [GhiChu]) VALUES (N'fffb8af3282a43b', N'TK01', CAST(N'2026-10-17 17:18:54' AS DateTime), N'Authentication / Phân quyền', N'Đăng nhập', N'TK01', N'Đăng nhập thành công', 1, NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: XacNhanSan (2 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[XacNhanSan] ([MaXacNhan], [MaDatSan], [MaNV], [ThoiGianNhan], [ThoiGianKetThuc], [TinhTrangSan], [GhiChu]) VALUES (N'XNa053537c', N'DS7c177524', N'NV02', CAST(N'2026-10-21 09:48:02' AS DateTime), CAST(N'2026-10-21 09:48:59' AS DateTime), NULL, NULL);
INSERT INTO dbo.[XacNhanSan] ([MaXacNhan], [MaDatSan], [MaNV], [ThoiGianNhan], [ThoiGianKetThuc], [TinhTrangSan], [GhiChu]) VALUES (N'XNb95e0819', N'DS776a68a8', N'NV02', CAST(N'2026-10-21 09:10:27' AS DateTime), CAST(N'2026-10-21 09:11:10' AS DateTime), NULL, NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: ChiTietDichVu (7 dòng)
-- ------------------------------------------------------------
SET IDENTITY_INSERT dbo.[ChiTietDichVu] ON;
GO
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DSa3a1e2ae', N'DV01', 1, CAST(N'2026-10-14 15:40:52' AS DateTime), NULL, 547, N'DAT_TRUOC', N'DON_VI', 10000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DSa3a1e2ae', N'DV02', 1, CAST(N'2026-10-14 15:40:52' AS DateTime), NULL, 548, N'DAT_TRUOC', N'DON_VI', 15000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DS6ae185a3', N'DV01', 1, CAST(N'2026-10-16 08:57:47' AS DateTime), NULL, 585, N'DAT_TRUOC', N'DON_VI', 10000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DSb5fc0559', N'DV01', 12, CAST(N'2026-10-20 13:26:35' AS DateTime), NULL, 769, N'DAT_TRUOC', N'DON_VI', 10000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DSb3294259', N'DV01', 1, CAST(N'2026-10-20 21:10:19' AS DateTime), NULL, 770, N'DAT_TRUOC', N'DON_VI', 5000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DS776a68a8', N'DV02', 2, CAST(N'2026-10-21 09:11:01' AS DateTime), N'NV02', 771, N'PHAT_SINH', N'DON_VI', 15000.00, NULL);
INSERT INTO dbo.[ChiTietDichVu] ([MaDatSan], [MaDV], [SoLuong], [NgayGhiNhan], [MaNV], [MaChiTiet], [Nguon], [QuyCach], [DonGiaDonViSnapshot], [DonGiaLegacySnapshot]) VALUES (N'DS7c177524', N'DV01', 1, CAST(N'2026-10-21 09:48:35' AS DateTime), N'NV02', 772, N'PHAT_SINH', N'DON_VI', 5000.00, NULL);
GO
SET IDENTITY_INSERT dbo.[ChiTietDichVu] OFF;
GO

-- ------------------------------------------------------------
-- BẢNG: HoaDon (25 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD05b29c87', N'DSa5f0cc04', N'TK69aa3723', 90000.00, 0.00, 0.00, 90000.00, N'DA_HUY', 1, CAST(N'2026-10-21 02:40:48.5269680' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD0e9eec43', N'DSaf089e4f', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 08:43:33.7132720' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD0f1fe39a', N'DS622125ef', N'TK69aa3723', 180000.00, 0.00, 0.00, 180000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-21 03:22:28.3533190' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD2378327a', N'DSb5fc0559', N'TK69aa3723', 130000.00, 120000.00, 0.00, 250000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-20 13:27:32.9518740' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD26378d59', N'DS583ac166', N'TK69aa3723', 650000.00, 0.00, 0.00, 0.00, N'DA_HUY', 1, CAST(N'2026-10-17 13:58:00.1530510' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD2af9de08', N'DSd5f58794', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 03:27:20.5135940' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD2d35946b', N'DS5c92b544', N'TK03', 90000.00, 0.00, 0.00, 90000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-16 22:16:57.7838120' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD34a5f3fc', N'DSebc7066e', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 03:28:57.0291010' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD41757506', N'DS6dc55d36', N'TK69aa3723', 90000.00, 0.00, 0.00, 90000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-19 00:21:06.4069650' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD476dd58b', N'DS5b17fa31', N'TK69aa3723', 94500.00, 0.00, 0.00, 0.00, N'DA_HUY', 1, CAST(N'2026-10-18 08:50:36.5968360' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD7a23a8d9', N'DS805518a4', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 08:32:20.9662140' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD81958389', N'DS1be023c7', N'TK02', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-19 01:30:52.2054490' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD90928d5d', N'DS99d5359e', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'DA_HUY', 1, CAST(N'2026-10-19 00:27:51.4923500' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD9744b1fe', N'DScbe204c4', N'TK69aa3723', 87000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 08:41:36.1676930' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD990cdb61', N'DS419d883b', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-15 19:46:29.3054900' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HD9d8eff08', N'DSb9d7bd29', N'TK69aa3723', 260000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-22 11:33:21.2039600' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDa00d0392', N'DS7c177524', N'TK69aa3723', 75000.00, 5000.00, 7500.00, 72500.00, N'DA_THANH_TOAN', 1, CAST(N'2026-10-21 09:45:09.0710150' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDa01a862e', N'DSa9914634', N'TK69aa3723', 63000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-22 11:38:39.6960100' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDaef9fa76', N'DS3c7fd553', N'TK69aa3723', 90000.00, 0.00, 0.00, 90000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-21 09:18:00.5852550' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDc2629fcd', N'DSe4899600', N'TK69aa3723', 90000.00, 0.00, 0.00, 90000.00, N'DA_THANH_TOAN', 0, CAST(N'2026-10-22 11:45:39.8487120' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDc318cd77', N'DSfd1965b2', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 08:28:50.7623170' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDc3647493', N'DS361bb875', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'DA_HUY', 1, CAST(N'2026-10-21 03:28:14.7315080' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDeb8f8ee3', N'DS15a5d94d', N'TK69aa3723', 90000.00, 0.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 0, CAST(N'2026-10-21 10:36:03.0289820' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDf5a90baa', N'DS776a68a8', N'TK69aa3723', 90000.00, 30000.00, 0.00, 0.00, N'CHUA_THANH_TOAN', 1, CAST(N'2026-10-21 09:09:13.7073150' AS DateTime2));
INSERT INTO dbo.[HoaDon] ([MaHoaDon], [MaDatSan], [MaTKLap], [TienSan], [TienDichVu], [TienGiam], [DaThanhToan], [TrangThai], [DaChot], [NgayLap]) VALUES (N'HDffc175a1', N'DSb8e725ef', N'TK69aa3723', 180000.00, 0.00, 0.00, 0.00, N'DA_HUY', 1, CAST(N'2026-10-16 19:10:04.2957220' AS DateTime2));
GO

-- ------------------------------------------------------------
-- BẢNG: ThanhToan (29 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT05a5f5e8', N'DS3c7fd553', CAST(N'2026-10-21 09:25:08' AS DateTime), 90000.00, N'Chuyển khoản', N'9909fb5a-e558-4731-bfaf-be2c02c6b5ea', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT08c2752a', N'DS583ac166', CAST(N'2026-10-17 13:58:00' AS DateTime), 650000.00, N'Chuyển khoản', N'7f3b54f5-8cc6-41ec-b905-72060a9ba0c4', N'Thất bại', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT0f046669', N'DSa9914634', CAST(N'2026-10-22 11:38:39' AS DateTime), 25200.00, N'Chuyển khoản', N'16a0d016-6fd2-4afc-a8b8-39c655f5281b', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT0f778c1f', N'DS5c92b544', CAST(N'2026-10-16 22:16:57' AS DateTime), 90000.00, N'Tiền mặt', N'005e0a3e-594c-48f8-88a8-27cb1d4c4ec8', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT27b9338c', N'DS5b17fa31', CAST(N'2026-10-18 08:50:36' AS DateTime), 94500.00, N'Tiền mặt', N'73386837-201f-4b01-b7e1-839678bc18b6', N'Thất bại', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT29daaa7e', N'DS7c177524', CAST(N'2026-10-21 09:45:28' AS DateTime), 27000.00, N'Chuyển khoản', N'8e46143e-dd35-4576-95b0-242ec2e59ee3', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT2b046d48', N'DS622125ef', CAST(N'2026-10-21 03:24:25' AS DateTime), 180000.00, N'Chuyển khoản', N'41fa1698-e2ba-4b5a-96a7-5a46ff36cfe8', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT2d3fba03', N'DS361bb875', CAST(N'2026-10-21 03:28:14' AS DateTime), 36000.00, N'Tiền mặt', N'942fd9e9-a03f-489f-9812-23a16cfe4f2e', N'Thất bại', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT2ef0a1e3', N'DSe4899600', CAST(N'2026-10-22 11:46:51' AS DateTime), 90000.00, N'Tiền mặt', N'4e43bf7c-27a5-4fce-ad94-60530ebc495a', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT37c56dff', N'DS776a68a8', CAST(N'2026-10-21 09:09:13' AS DateTime), 36000.00, N'Chuyển khoản', N'3f906a02-1850-481c-bc2d-e0e3473ec6e5', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT3a6eadfa', N'DS15a5d94d', CAST(N'2026-10-21 10:36:03' AS DateTime), 36000.00, N'Chuyển khoản', N'6ecd9579-2049-4830-802f-fe4d45fb3634', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT3b8ff5ff', N'DS3c7fd553', CAST(N'2026-10-21 09:18:00' AS DateTime), 36000.00, N'Chuyển khoản', N'd25e09c2-28ca-422e-9912-c2d752f90b15', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT419ee70c', N'DSfd1965b2', CAST(N'2026-10-21 08:28:50' AS DateTime), 36000.00, N'Chuyển khoản', N'32bcf196-f290-477e-9fdf-83ee0135b2d9', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT476b2c77', N'DScbe204c4', CAST(N'2026-10-21 08:41:36' AS DateTime), 34800.00, N'Chuyển khoản', N'82f5c2b8-fafc-4132-b534-56050bcfd000', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT4ae4ba5a', N'DS805518a4', CAST(N'2026-10-21 08:32:21' AS DateTime), 36000.00, N'Chuyển khoản', N'ae426034-6b80-4d5e-ab02-a0c7f1a342da', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT50dfaa50', N'DSebc7066e', CAST(N'2026-10-21 03:28:57' AS DateTime), 90000.00, N'Tiền mặt', N'8222da7a-f42e-4269-8e05-687338dc2fb8', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT5f2f12de', N'DS7c177524', CAST(N'2026-10-21 09:50:04' AS DateTime), 72500.00, N'Chuyển khoản', N'349904d0-35d9-4480-aefc-974b1de9195d', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT5f67ca9f', N'DSaf089e4f', CAST(N'2026-10-21 08:43:33' AS DateTime), 36000.00, N'Chuyển khoản', N'099a3ab1-ed1c-44fc-98ad-8ecae71f3b86', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT8fc5aefb', N'DSb5fc0559', CAST(N'2026-10-20 13:52:40' AS DateTime), 250000.00, N'Tiền mặt', N'aa2672b2-0482-4a3d-88de-825bf6d40153', N'Thành công', N'NV02');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TT92545dd3', N'DS419d883b', CAST(N'2026-10-15 19:46:29' AS DateTime), 90000.00, N'Chuyển khoản', N'0ab0a5eb-9190-4fab-8f9c-dcccdd837944', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTac6761eb', N'DS6dc55d36', CAST(N'2026-10-19 13:02:41' AS DateTime), 90000.00, N'Chuyển khoản', N'aa74d8a8-dc0d-4af4-9d6e-2e42c96d3ed3', N'Thành công', N'NV03');
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTb6dfce3b', N'DSa5f0cc04', CAST(N'2026-10-21 02:40:48' AS DateTime), 36000.00, N'Chuyển khoản', N'334689e3-c0a8-47b4-a944-b55f29168785', N'Thất bại', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTc9d38076', N'DSb5fc0559', CAST(N'2026-10-20 13:27:33' AS DateTime), 250000.00, N'Chuyển khoản', N'dbfffdb0-a857-4f1f-95ef-76469b1ce410', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTcbf815b5', N'DSb8e725ef', CAST(N'2026-10-16 19:10:04' AS DateTime), 180000.00, N'Chuyển khoản', N'7b6e07d1-4d2b-4969-a332-acc10232cba8', N'Thất bại', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTdaf90c2f', N'DSb9d7bd29', CAST(N'2026-10-22 11:33:21' AS DateTime), 104000.00, N'Chuyển khoản', N'263709a9-7d66-4425-a3fe-796596f82373', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTecca48fa', N'DSd5f58794', CAST(N'2026-10-21 03:27:20' AS DateTime), 36000.00, N'Tiền mặt', N'792d59ba-8b34-4a3e-801d-331bc954e653', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTf047b8af', N'DS622125ef', CAST(N'2026-10-21 03:22:28' AS DateTime), 180000.00, N'Chuyển khoản', N'04bd3ef6-d146-4268-87b5-1bf1b82be033', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTfcc5c828', N'DSe4899600', CAST(N'2026-10-22 11:45:39' AS DateTime), 36000.00, N'Tiền mặt', N'5dbd4fa9-33c6-4170-92e0-2d93ceca1eed', N'Chờ xử lý', NULL);
INSERT INTO dbo.[ThanhToan] ([MaTT], [MaDatSan], [NgayThanhToan], [SoTien], [PhuongThuc], [MaGiaoDich], [TrangThai], [MaNV]) VALUES (N'TTff86a05a', N'DSa5f0cc04', CAST(N'2026-10-21 02:42:52' AS DateTime), 90000.00, N'Chuyển khoản', N'47d8a8b5-0a0a-4e91-9acf-1fa74baaab18', N'Thành công', N'NV03');
GO

-- ------------------------------------------------------------
-- BẢNG: HuyDatSan (6 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HY0076358b', N'DSa5f0cc04', CAST(N'2026-10-21 03:27:57.5017770' AS DateTime2), N'eaaarth', N'Khách hàng', 50.00, 45000.00, 90000.00);
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HY078dd7d5', N'DS99d5359e', CAST(N'2026-10-19 00:27:51.5264780' AS DateTime2), N'đe', N'Khách hàng', 50.00, 0.00, 0.00);
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HY531ca06e', N'DS583ac166', CAST(N'2026-10-17 14:02:27.5380660' AS DateTime2), N'gzx', N'Khách hàng', 0.00, 0.00, 0.00);
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HY6063a27c', N'DS361bb875', CAST(N'2026-10-21 03:28:32.7608910' AS DateTime2), N'dằ', N'Khách hàng', 50.00, 0.00, 0.00);
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HY6a794703', N'DS5b17fa31', CAST(N'2026-10-18 08:50:58.9026590' AS DateTime2), N'edfgh', N'Khách hàng', 0.00, 0.00, 0.00);
INSERT INTO dbo.[HuyDatSan] ([MaHuy], [MaDatSan], [NgayHuy], [LyDo], [NguoiHuy], [TiLeHoan], [SoTienHoan], [SoTienThucThuSnapshot]) VALUES (N'HYfe775243', N'DSb8e725ef', CAST(N'2026-10-16 19:10:23.0458620' AS DateTime2), N'sdfghbmn,', N'Khách hàng', 100.00, 0.00, 0.00);
GO

-- ------------------------------------------------------------
-- BẢNG: DanhGia (0 dòng)
-- ------------------------------------------------------------
-- (Bảng không có dữ liệu)

-- ------------------------------------------------------------
-- BẢNG: PhanHoi (1 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[PhanHoi] ([MaPhanHoi], [MaKH], [MaDatSan], [NgayGui], [LoaiPhanHoi], [NoiDung], [TrangThaiXuLy], [MaNV], [NgayXuLy], [KetQuaXuLy]) VALUES (N'PHbe04d5be', N'KHc64de18c', N'DS622125ef', CAST(N'2026-10-21 03:53:36' AS DateTime), N'Khiếu nại', N'sân hư', N'Chờ xử lý', NULL, NULL, NULL);
GO

-- ------------------------------------------------------------
-- BẢNG: HoanTien (1 dòng)
-- ------------------------------------------------------------
INSERT INTO dbo.[HoanTien] ([MaHT], [MaTT], [MaHuy], [NgayHoan], [SoTienHoan], [PhuongThuc], [TrangThai], [MaNV], [NgayXacNhan], [LyDo]) VALUES (N'HT80fe36cd', N'TTff86a05a', N'HY0076358b', CAST(N'2026-10-21 03:27:57' AS DateTime), 45000.00, N'Chuyển khoản', N'Đã hoàn', N'NV03', CAST(N'2026-10-21 03:35:08.6171260' AS DateTime2), N'ok đã hoàn');
GO

-- ------------------------------------------------------------
-- BẢNG: YeuCauHuyDatSan (0 dòng)
-- ------------------------------------------------------------
-- (Bảng không có dữ liệu)

-- ------------------------------------------------------------
-- BẢNG: ChiTietDanhGia (0 dòng)
-- ------------------------------------------------------------
-- (Bảng không có dữ liệu)

-- Tái kích hoạt kiểm tra khóa ngoại và trigger sau khi hoàn tất nạp dữ liệu
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
GO
EXEC sp_msforeachtable "ENABLE TRIGGER ALL ON ?";
GO

PRINT N'Hoàn tất nạp dữ liệu vào cơ sở dữ liệu QuanLySanBong.';
GO

