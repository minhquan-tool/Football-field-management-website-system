/* ============================================================
   HỆ THỐNG QUẢN LÝ VÀ ĐẶT SÂN BÓNG - NHÓM 19
   Script tạo cơ sở dữ liệu cho Microsoft SQL Server
   Chương 4: Thiết kế dữ liệu
   ============================================================ */

/* ---------- 0. TẠO CƠ SỞ DỮ LIỆU ---------- */
IF DB_ID('QuanLySanBong') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLySanBong SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLySanBong;
END
GO

CREATE DATABASE QuanLySanBong;
GO

USE QuanLySanBong;
GO

/* ============================================================
   1. NHÓM QUẢN TRỊ HỆ THỐNG
   ============================================================ */

-- 1.1 Vai trò
CREATE TABLE VaiTro (
    MaVaiTro    VARCHAR(10)   NOT NULL,
    TenVaiTro   NVARCHAR(50)  NOT NULL,
    MoTa        NVARCHAR(255) NULL,
    CONSTRAINT PK_VaiTro PRIMARY KEY (MaVaiTro)
);
GO

-- 1.2 Chức năng
CREATE TABLE ChucNang (
    MaChucNang   VARCHAR(10)   NOT NULL,
    TenChucNang  NVARCHAR(100) NOT NULL,
    MoTa         NVARCHAR(255) NULL,
    CONSTRAINT PK_ChucNang PRIMARY KEY (MaChucNang)
);
GO

-- 1.3 Phân quyền (bảng trung gian VaiTro - ChucNang)
CREATE TABLE PhanQuyen (
    MaVaiTro    VARCHAR(10) NOT NULL,
    MaChucNang  VARCHAR(10) NOT NULL,
    Xem         BIT NOT NULL DEFAULT 0,
    Them        BIT NOT NULL DEFAULT 0,
    Sua         BIT NOT NULL DEFAULT 0,
    Xoa         BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_PhanQuyen PRIMARY KEY (MaVaiTro, MaChucNang),
    CONSTRAINT FK_PhanQuyen_VaiTro   FOREIGN KEY (MaVaiTro)   REFERENCES VaiTro(MaVaiTro),
    CONSTRAINT FK_PhanQuyen_ChucNang FOREIGN KEY (MaChucNang) REFERENCES ChucNang(MaChucNang)
);
GO

-- 1.4 Khách hàng
CREATE TABLE KhachHang (
    MaKH         VARCHAR(10)   NOT NULL,
    HoTen        NVARCHAR(100) NOT NULL,
    SoDienThoai  VARCHAR(15)   NOT NULL,
    Email        VARCHAR(100)  NULL,
    DiaChi       NVARCHAR(255) NULL,
    NgayDangKy   DATE          NOT NULL DEFAULT GETDATE(),
    GhiChu       NVARCHAR(255) NULL,
    CONSTRAINT PK_KhachHang PRIMARY KEY (MaKH),
    CONSTRAINT UQ_KhachHang_SDT UNIQUE (SoDienThoai)
);
GO

-- 1.5 Nhân viên
CREATE TABLE NhanVien (
    MaNV         VARCHAR(10)   NOT NULL,
    HoTen        NVARCHAR(100) NOT NULL,
    SoDienThoai  VARCHAR(15)   NULL,
    Email        VARCHAR(100)  NULL,
    ChucVu       NVARCHAR(50)  NULL,
    BoPhan       NVARCHAR(50)  NULL,
    NgayVaoLam   DATE          NULL,
    TrangThai    BIT           NOT NULL DEFAULT 1,   -- 1: đang làm việc
    CONSTRAINT PK_NhanVien PRIMARY KEY (MaNV),
    CONSTRAINT CK_NhanVien_BoPhan CHECK (BoPhan IN (N'Nhân viên sân bóng', N'Kế toán', N'Quản trị hệ thống'))
);
GO

-- 1.6 Tài khoản
CREATE TABLE TaiKhoan (
    MaTK         VARCHAR(10)   NOT NULL,
    TenDangNhap  VARCHAR(50)   NOT NULL,
    MatKhau      VARCHAR(255)  NOT NULL,            -- lưu dạng đã mã hóa (hash)
    MaVaiTro     VARCHAR(10)   NOT NULL,
    MaKH         VARCHAR(10)   NULL,
    MaNV         VARCHAR(10)   NULL,
    NgayTao      DATETIME      NOT NULL DEFAULT GETDATE(),
    TrangThai    NVARCHAR(20)  NOT NULL DEFAULT N'Hoạt động',
    CONSTRAINT PK_TaiKhoan PRIMARY KEY (MaTK),
    CONSTRAINT UQ_TaiKhoan_TenDangNhap UNIQUE (TenDangNhap),
    CONSTRAINT FK_TaiKhoan_VaiTro    FOREIGN KEY (MaVaiTro) REFERENCES VaiTro(MaVaiTro),
    CONSTRAINT FK_TaiKhoan_KhachHang FOREIGN KEY (MaKH)     REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_TaiKhoan_NhanVien  FOREIGN KEY (MaNV)     REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_TaiKhoan_TrangThai CHECK (TrangThai IN (N'Hoạt động', N'Khóa')),
    -- Một tài khoản thuộc về khách hàng HOẶC nhân viên, không đồng thời cả hai
    CONSTRAINT CK_TaiKhoan_ChuSoHuu  CHECK ((MaKH IS NULL AND MaNV IS NOT NULL)
                                         OR (MaKH IS NOT NULL AND MaNV IS NULL))
);
GO

/* ============================================================
   2. NHÓM DANH MỤC SÂN BÓNG
   ============================================================ */

-- 2.1 Loại sân
CREATE TABLE LoaiSan (
    MaLoaiSan   VARCHAR(10)   NOT NULL,
    TenLoaiSan  NVARCHAR(50)  NOT NULL,
    SoNguoi     INT           NOT NULL,
    MoTa        NVARCHAR(255) NULL,
    CONSTRAINT PK_LoaiSan PRIMARY KEY (MaLoaiSan),
    CONSTRAINT CK_LoaiSan_SoNguoi CHECK (SoNguoi > 0)
);
GO

-- 2.2 Sân bóng
CREATE TABLE San (
    MaSan      VARCHAR(10)   NOT NULL,
    TenSan     NVARCHAR(50)  NOT NULL,
    MaLoaiSan  VARCHAR(10)   NOT NULL,
    TrangThai  NVARCHAR(20)  NOT NULL DEFAULT N'Trống',
    MoTa       NVARCHAR(255) NULL,
    CONSTRAINT PK_San PRIMARY KEY (MaSan),
    CONSTRAINT FK_San_LoaiSan FOREIGN KEY (MaLoaiSan) REFERENCES LoaiSan(MaLoaiSan),
    CONSTRAINT CK_San_TrangThai CHECK (TrangThai IN (N'Trống', N'Đang sử dụng', N'Bảo trì'))
);
GO

-- 2.3 Khung giờ
CREATE TABLE KhungGio (
    MaKhungGio  VARCHAR(10) NOT NULL,
    GioBatDau   TIME        NOT NULL,
    GioKetThuc  TIME        NOT NULL,
    ThoiLuong   DECIMAL(4,2) NOT NULL,
    CONSTRAINT PK_KhungGio PRIMARY KEY (MaKhungGio),
    CONSTRAINT CK_KhungGio_Gio       CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CK_KhungGio_ThoiLuong CHECK (ThoiLuong > 0)
);
GO

-- 2.4 Bảng giá
CREATE TABLE BangGia (
    MaBangGia       VARCHAR(10)   NOT NULL,
    MaLoaiSan       VARCHAR(10)   NOT NULL,
    MaKhungGio      VARCHAR(10)   NOT NULL,
    LoaiNgay        NVARCHAR(20)  NOT NULL,
    DonGia          DECIMAL(18,2) NOT NULL,
    NgayHieuLuc     DATE          NOT NULL,
    NgayHetHieuLuc  DATE          NULL,
    CONSTRAINT PK_BangGia PRIMARY KEY (MaBangGia),
    CONSTRAINT FK_BangGia_LoaiSan  FOREIGN KEY (MaLoaiSan)  REFERENCES LoaiSan(MaLoaiSan),
    CONSTRAINT FK_BangGia_KhungGio FOREIGN KEY (MaKhungGio) REFERENCES KhungGio(MaKhungGio),
    CONSTRAINT CK_BangGia_LoaiNgay CHECK (LoaiNgay IN (N'Ngày thường', N'Cuối tuần', N'Ngày lễ')),
    CONSTRAINT CK_BangGia_DonGia   CHECK (DonGia > 0),
    CONSTRAINT CK_BangGia_HieuLuc  CHECK (NgayHetHieuLuc IS NULL OR NgayHetHieuLuc >= NgayHieuLuc)
);
GO

-- 2.5 Khuyến mãi
CREATE TABLE KhuyenMai (
    MaKM        VARCHAR(10)   NOT NULL,
    TenKM       NVARCHAR(100) NOT NULL,
    LoaiGiam    NVARCHAR(20)  NOT NULL,
    MucGiam     DECIMAL(18,2) NOT NULL,
    DieuKien    NVARCHAR(255) NULL,
    NgayBatDau  DATE          NOT NULL,
    NgayKetThuc DATE          NOT NULL,
    TrangThai   BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_KhuyenMai PRIMARY KEY (MaKM),
    CONSTRAINT CK_KhuyenMai_LoaiGiam CHECK (LoaiGiam IN (N'Phần trăm', N'Số tiền')),
    CONSTRAINT CK_KhuyenMai_MucGiam  CHECK (MucGiam > 0),
    CONSTRAINT CK_KhuyenMai_ThoiGian CHECK (NgayKetThuc >= NgayBatDau)
);
GO

/* ============================================================
   3. NHÓM NGHIỆP VỤ ĐẶT SÂN
   ============================================================ */

-- 3.1 Đặt sân
CREATE TABLE DatSan (
    MaDatSan     VARCHAR(10)   NOT NULL,
    MaKH         VARCHAR(10)   NOT NULL,
    MaSan        VARCHAR(10)   NOT NULL,
    MaKhungGio   VARCHAR(10)   NOT NULL,
    NgayChoi     DATE          NOT NULL,
    ThoiLuong    DECIMAL(4,2)  NOT NULL,
    DonGia       DECIMAL(18,2) NOT NULL,
    TienSan      DECIMAL(18,2) NOT NULL DEFAULT 0,
    TienDichVu   DECIMAL(18,2) NOT NULL DEFAULT 0,
    MaKM         VARCHAR(10)   NULL,
    TienGiam     DECIMAL(18,2) NOT NULL DEFAULT 0,
    TongTien     DECIMAL(18,2) NOT NULL DEFAULT 0,
    NgayDat      DATETIME      NOT NULL DEFAULT GETDATE(),
    MaNV         VARCHAR(10)   NULL,                 -- NULL nếu khách tự đặt online
    TrangThai    NVARCHAR(20)  NOT NULL DEFAULT N'Chờ xác nhận',
    GhiChu       NVARCHAR(255) NULL,
    CONSTRAINT PK_DatSan PRIMARY KEY (MaDatSan),
    CONSTRAINT FK_DatSan_KhachHang FOREIGN KEY (MaKH)       REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_DatSan_San       FOREIGN KEY (MaSan)      REFERENCES San(MaSan),
    CONSTRAINT FK_DatSan_KhungGio  FOREIGN KEY (MaKhungGio) REFERENCES KhungGio(MaKhungGio),
    CONSTRAINT FK_DatSan_KhuyenMai FOREIGN KEY (MaKM)       REFERENCES KhuyenMai(MaKM),
    CONSTRAINT FK_DatSan_NhanVien  FOREIGN KEY (MaNV)       REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_DatSan_TrangThai CHECK (TrangThai IN (N'Chờ xác nhận', N'Đã xác nhận', N'Đã sử dụng', N'Đã hủy')),
    CONSTRAINT CK_DatSan_ThoiLuong CHECK (ThoiLuong > 0),
    CONSTRAINT CK_DatSan_Tien      CHECK (DonGia > 0 AND TienSan >= 0 AND TienDichVu >= 0
                                          AND TienGiam >= 0 AND TongTien >= 0)
);
GO

-- RB2: một sân chỉ nhận một lượt đặt còn hiệu lực trong cùng ngày và khung giờ
CREATE UNIQUE INDEX UX_DatSan_KhongTrungLich
    ON DatSan (MaSan, NgayChoi, MaKhungGio)
    WHERE TrangThai <> N'Đã hủy';
GO

-- 3.2 Dịch vụ
CREATE TABLE DichVu (
    MaDV       VARCHAR(10)   NOT NULL,
    TenDV      NVARCHAR(100) NOT NULL,
    DonViTinh  NVARCHAR(20)  NULL,
    DonGia     DECIMAL(18,2) NOT NULL,
    TrangThai  BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_DichVu PRIMARY KEY (MaDV),
    CONSTRAINT CK_DichVu_DonGia CHECK (DonGia > 0)
);
GO

-- 3.3 Chi tiết dịch vụ
CREATE TABLE ChiTietDichVu (
    MaDatSan     VARCHAR(10)   NOT NULL,
    MaDV         VARCHAR(10)   NOT NULL,
    SoLuong      INT           NOT NULL,
    DonGia       DECIMAL(18,2) NOT NULL,
    ThanhTien    AS (SoLuong * DonGia) PERSISTED,     -- cột tính toán
    NgayGhiNhan  DATETIME      NOT NULL DEFAULT GETDATE(),
    MaNV         VARCHAR(10)   NULL,
    CONSTRAINT PK_ChiTietDichVu PRIMARY KEY (MaDatSan, MaDV),
    CONSTRAINT FK_CTDV_DatSan   FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT FK_CTDV_DichVu   FOREIGN KEY (MaDV)     REFERENCES DichVu(MaDV),
    CONSTRAINT FK_CTDV_NhanVien FOREIGN KEY (MaNV)     REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_CTDV_SoLuong  CHECK (SoLuong > 0),
    CONSTRAINT CK_CTDV_DonGia   CHECK (DonGia > 0)
);
GO

-- 3.4 Xác nhận nhận sân
CREATE TABLE XacNhanSan (
    MaXacNhan        VARCHAR(10)   NOT NULL,
    MaDatSan         VARCHAR(10)   NOT NULL,
    MaNV             VARCHAR(10)   NOT NULL,
    ThoiGianNhan     DATETIME      NOT NULL,
    ThoiGianKetThuc  DATETIME      NULL,
    TinhTrangSan     NVARCHAR(255) NULL,
    GhiChu           NVARCHAR(255) NULL,
    CONSTRAINT PK_XacNhanSan PRIMARY KEY (MaXacNhan),
    CONSTRAINT UQ_XacNhanSan_DatSan UNIQUE (MaDatSan),
    CONSTRAINT FK_XacNhanSan_DatSan   FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT FK_XacNhanSan_NhanVien FOREIGN KEY (MaNV)     REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_XacNhanSan_ThoiGian CHECK (ThoiGianKetThuc IS NULL OR ThoiGianKetThuc >= ThoiGianNhan)
);
GO

/* ============================================================
   4. NHÓM THANH TOÁN - TÀI CHÍNH
   ============================================================ */

-- 4.1 Thanh toán
CREATE TABLE ThanhToan (
    MaTT           VARCHAR(10)   NOT NULL,
    MaDatSan       VARCHAR(10)   NOT NULL,
    NgayThanhToan  DATETIME      NOT NULL DEFAULT GETDATE(),
    SoTien         DECIMAL(18,2) NOT NULL,
    PhuongThuc     NVARCHAR(20)  NOT NULL,
    MaGiaoDich     VARCHAR(50)   NULL,
    TrangThai      NVARCHAR(20)  NOT NULL DEFAULT N'Chờ xử lý',
    MaNV           VARCHAR(10)   NULL,
    CONSTRAINT PK_ThanhToan PRIMARY KEY (MaTT),
    CONSTRAINT FK_ThanhToan_DatSan   FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT FK_ThanhToan_NhanVien FOREIGN KEY (MaNV)     REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_ThanhToan_SoTien     CHECK (SoTien > 0),
    CONSTRAINT CK_ThanhToan_PhuongThuc CHECK (PhuongThuc IN (N'Tiền mặt', N'Chuyển khoản')),
    CONSTRAINT CK_ThanhToan_TrangThai  CHECK (TrangThai IN (N'Chờ xử lý', N'Thành công', N'Thất bại'))
);
GO

-- 4.2 Hủy đặt sân
CREATE TABLE HuyDatSan (
    MaHuy       VARCHAR(10)   NOT NULL,
    MaDatSan    VARCHAR(10)   NOT NULL,
    NgayHuy     DATETIME      NOT NULL DEFAULT GETDATE(),
    LyDo        NVARCHAR(255) NULL,
    NguoiHuy    NVARCHAR(20)  NOT NULL,
    TiLeHoan    DECIMAL(5,2)  NOT NULL DEFAULT 0,
    SoTienHoan  DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_HuyDatSan PRIMARY KEY (MaHuy),
    CONSTRAINT UQ_HuyDatSan_DatSan UNIQUE (MaDatSan),
    CONSTRAINT FK_HuyDatSan_DatSan FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT CK_HuyDatSan_NguoiHuy CHECK (NguoiHuy IN (N'Khách hàng', N'Nhân viên')),
    CONSTRAINT CK_HuyDatSan_TiLeHoan CHECK (TiLeHoan BETWEEN 0 AND 100),
    CONSTRAINT CK_HuyDatSan_SoTien   CHECK (SoTienHoan >= 0)
);
GO

-- 4.3 Hoàn tiền
CREATE TABLE HoanTien (
    MaHT        VARCHAR(10)   NOT NULL,
    MaTT        VARCHAR(10)   NOT NULL,
    MaHuy       VARCHAR(10)   NOT NULL,
    NgayHoan    DATETIME      NOT NULL DEFAULT GETDATE(),
    SoTienHoan  DECIMAL(18,2) NOT NULL,
    PhuongThuc  NVARCHAR(20)  NOT NULL,
    TrangThai   NVARCHAR(20)  NOT NULL DEFAULT N'Chờ duyệt',
    MaNV        VARCHAR(10)   NULL,
    CONSTRAINT PK_HoanTien PRIMARY KEY (MaHT),
    CONSTRAINT FK_HoanTien_ThanhToan FOREIGN KEY (MaTT)  REFERENCES ThanhToan(MaTT),
    CONSTRAINT FK_HoanTien_HuyDatSan FOREIGN KEY (MaHuy) REFERENCES HuyDatSan(MaHuy),
    CONSTRAINT FK_HoanTien_NhanVien  FOREIGN KEY (MaNV)  REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_HoanTien_SoTien     CHECK (SoTienHoan > 0),
    CONSTRAINT CK_HoanTien_PhuongThuc CHECK (PhuongThuc IN (N'Tiền mặt', N'Chuyển khoản')),
    CONSTRAINT CK_HoanTien_TrangThai  CHECK (TrangThai IN (N'Chờ duyệt', N'Đã hoàn', N'Từ chối'))
);
GO

/* ============================================================
   5. NHÓM ĐÁNH GIÁ - PHẢN HỒI
   ============================================================ */

-- 5.1 Tiêu chí đánh giá
CREATE TABLE TieuChiDanhGia (
    MaTieuChi   VARCHAR(10)   NOT NULL,
    TenTieuChi  NVARCHAR(100) NOT NULL,
    MoTa        NVARCHAR(255) NULL,
    CONSTRAINT PK_TieuChiDanhGia PRIMARY KEY (MaTieuChi)
);
GO

-- 5.2 Đánh giá
CREATE TABLE DanhGia (
    MaDanhGia      VARCHAR(10)   NOT NULL,
    MaDatSan       VARCHAR(10)   NOT NULL,
    MaKH           VARCHAR(10)   NOT NULL,
    MaSan          VARCHAR(10)   NOT NULL,
    NgayDanhGia    DATE          NOT NULL DEFAULT GETDATE(),
    NoiDung        NVARCHAR(500) NULL,
    DiemTrungBinh  DECIMAL(3,2)  NULL,
    CONSTRAINT PK_DanhGia PRIMARY KEY (MaDanhGia),
    CONSTRAINT UQ_DanhGia_DatSan UNIQUE (MaDatSan),     -- mỗi lượt đặt chỉ đánh giá 1 lần
    CONSTRAINT FK_DanhGia_DatSan    FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY (MaKH)     REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_DanhGia_San       FOREIGN KEY (MaSan)    REFERENCES San(MaSan),
    CONSTRAINT CK_DanhGia_Diem CHECK (DiemTrungBinh IS NULL OR DiemTrungBinh BETWEEN 1 AND 5)
);
GO

-- 5.3 Chi tiết đánh giá
CREATE TABLE ChiTietDanhGia (
    MaDanhGia  VARCHAR(10) NOT NULL,
    MaTieuChi  VARCHAR(10) NOT NULL,
    Diem       INT         NOT NULL,
    CONSTRAINT PK_ChiTietDanhGia PRIMARY KEY (MaDanhGia, MaTieuChi),
    CONSTRAINT FK_CTDG_DanhGia  FOREIGN KEY (MaDanhGia) REFERENCES DanhGia(MaDanhGia),
    CONSTRAINT FK_CTDG_TieuChi  FOREIGN KEY (MaTieuChi) REFERENCES TieuChiDanhGia(MaTieuChi),
    CONSTRAINT CK_CTDG_Diem CHECK (Diem BETWEEN 1 AND 5)
);
GO

-- 5.4 Phản hồi
CREATE TABLE PhanHoi (
    MaPhanHoi      VARCHAR(10)   NOT NULL,
    MaKH           VARCHAR(10)   NOT NULL,
    MaDatSan       VARCHAR(10)   NULL,
    NgayGui        DATETIME      NOT NULL DEFAULT GETDATE(),
    LoaiPhanHoi    NVARCHAR(50)  NULL,
    NoiDung        NVARCHAR(500) NOT NULL,
    TrangThaiXuLy  NVARCHAR(20)  NOT NULL DEFAULT N'Chờ xử lý',
    MaNV           VARCHAR(10)   NULL,
    NgayXuLy       DATETIME      NULL,
    KetQuaXuLy     NVARCHAR(500) NULL,
    CONSTRAINT PK_PhanHoi PRIMARY KEY (MaPhanHoi),
    CONSTRAINT FK_PhanHoi_KhachHang FOREIGN KEY (MaKH)     REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_PhanHoi_DatSan    FOREIGN KEY (MaDatSan) REFERENCES DatSan(MaDatSan),
    CONSTRAINT FK_PhanHoi_NhanVien  FOREIGN KEY (MaNV)     REFERENCES NhanVien(MaNV),
    CONSTRAINT CK_PhanHoi_TrangThai CHECK (TrangThaiXuLy IN (N'Chờ xử lý', N'Đang xử lý', N'Đã xử lý')),
    CONSTRAINT CK_PhanHoi_NgayXuLy  CHECK (NgayXuLy IS NULL OR NgayXuLy >= NgayGui)
);
GO

/* ============================================================
   6. NHÓM NHẬT KÝ - SAO LƯU - BÁO CÁO
   ============================================================ */

-- 6.1 Nhật ký hệ thống
CREATE TABLE NhatKyHeThong (
    MaNhatKy        VARCHAR(15)   NOT NULL,
    MaTK            VARCHAR(10)   NOT NULL,
    ThoiGian        DATETIME      NOT NULL DEFAULT GETDATE(),
    ChucNang        NVARCHAR(100) NULL,
    ThaoTac         NVARCHAR(20)  NOT NULL,
    DoiTuong        NVARCHAR(100) NULL,
    NoiDungThayDoi  NVARCHAR(500) NULL,
    KetQua          BIT           NOT NULL DEFAULT 1,
    GhiChu          NVARCHAR(255) NULL,
    CONSTRAINT PK_NhatKyHeThong PRIMARY KEY (MaNhatKy),
    CONSTRAINT FK_NhatKy_TaiKhoan FOREIGN KEY (MaTK) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_NhatKy_ThaoTac CHECK (ThaoTac IN (N'Thêm', N'Sửa', N'Xóa', N'Đăng nhập', N'Đăng xuất'))
);
GO

-- 6.2 Sao lưu dữ liệu
CREATE TABLE SaoLuu (
    MaSaoLuu     VARCHAR(10)   NOT NULL,
    MaTK         VARCHAR(10)   NOT NULL,
    ThoiGian     DATETIME      NOT NULL DEFAULT GETDATE(),
    LoaiThaoTac  NVARCHAR(20)  NOT NULL,
    DuongDan     NVARCHAR(255) NULL,
    KetQua       BIT           NOT NULL DEFAULT 1,
    GhiChu       NVARCHAR(255) NULL,
    CONSTRAINT PK_SaoLuu PRIMARY KEY (MaSaoLuu),
    CONSTRAINT FK_SaoLuu_TaiKhoan FOREIGN KEY (MaTK) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_SaoLuu_LoaiThaoTac CHECK (LoaiThaoTac IN (N'Sao lưu', N'Phục hồi'))
);
GO

-- 6.3 Báo cáo
CREATE TABLE BaoCao (
    MaBaoCao    VARCHAR(10)    NOT NULL,
    LoaiBaoCao  NVARCHAR(50)   NOT NULL,
    NgayLap     DATE           NOT NULL DEFAULT GETDATE(),
    TuNgay      DATE           NOT NULL,
    DenNgay     DATE           NOT NULL,
    MaTK        VARCHAR(10)    NOT NULL,
    NoiDung     NVARCHAR(MAX)  NULL,
    CONSTRAINT PK_BaoCao PRIMARY KEY (MaBaoCao),
    CONSTRAINT FK_BaoCao_TaiKhoan FOREIGN KEY (MaTK) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_BaoCao_ThoiGian CHECK (DenNgay >= TuNgay)
);
GO

/* ============================================================
   7. DỮ LIỆU MẪU (danh mục cơ bản)
   ============================================================ */

INSERT INTO VaiTro (MaVaiTro, TenVaiTro, MoTa) VALUES
 ('VT01', N'Khách hàng',          N'Đặt sân, thanh toán, đánh giá'),
 ('VT02', N'Nhân viên sân bóng',  N'Tiếp nhận và vận hành sân'),
 ('VT03', N'Nhân viên kế toán',   N'Đối soát doanh thu, hoàn tiền'),
 ('VT04', N'Quản trị hệ thống',   N'Toàn quyền quản trị');

INSERT INTO ChucNang (MaChucNang, TenChucNang) VALUES
 ('CN01', N'Quản lý khách hàng'),
 ('CN02', N'Quản lý đặt sân'),
 ('CN03', N'Quản lý dịch vụ'),
 ('CN04', N'Quản lý thanh toán'),
 ('CN05', N'Quản lý phản hồi'),
 ('CN06', N'Tra cứu / lập báo cáo'),
 ('CN07', N'Quản lý tài khoản'),
 ('CN08', N'Phân quyền người dùng');

INSERT INTO LoaiSan (MaLoaiSan, TenLoaiSan, SoNguoi) VALUES
 ('LS01', N'Sân 5 người', 5),
 ('LS02', N'Sân 7 người', 7);

INSERT INTO San (MaSan, TenSan, MaLoaiSan, TrangThai) VALUES
 ('S01', N'Sân số 1', 'LS01', N'Trống'),
 ('S02', N'Sân số 2', 'LS01', N'Trống'),
 ('S03', N'Sân số 3', 'LS02', N'Trống');

INSERT INTO KhungGio (MaKhungGio, GioBatDau, GioKetThuc, ThoiLuong) VALUES
 ('KG01', '06:00', '07:30', 1.5),
 ('KG02', '16:00', '17:30', 1.5),
 ('KG03', '17:30', '19:00', 1.5),
 ('KG04', '19:00', '20:30', 1.5),
 ('KG05', '20:30', '22:00', 1.5);

INSERT INTO BangGia (MaBangGia, MaLoaiSan, MaKhungGio, LoaiNgay, DonGia, NgayHieuLuc) VALUES
 ('BG01', 'LS01', 'KG01', N'Ngày thường', 150000, '2026-01-01'),
 ('BG02', 'LS01', 'KG04', N'Ngày thường', 300000, '2026-01-01'),
 ('BG03', 'LS02', 'KG04', N'Ngày thường', 450000, '2026-01-01'),
 ('BG04', 'LS02', 'KG04', N'Cuối tuần',   500000, '2026-01-01');

INSERT INTO DichVu (MaDV, TenDV, DonViTinh, DonGia) VALUES
 ('DV01', N'Nước suối',   N'Chai', 10000),
 ('DV02', N'Nước ngọt',   N'Lon',  15000),
 ('DV03', N'Thuê bóng',   N'Quả',  30000),
 ('DV04', N'Thuê giày',   N'Đôi',  40000),
 ('DV05', N'Thuê áo bib', N'Bộ',   50000),
 ('DV06', N'Khăn lạnh',   N'Cái',   5000);

INSERT INTO TieuChiDanhGia (MaTieuChi, TenTieuChi) VALUES
 ('TC01', N'Chất lượng mặt sân'),
 ('TC02', N'Cơ sở vật chất'),
 ('TC03', N'Vệ sinh sân'),
 ('TC04', N'Thái độ phục vụ của nhân viên'),
 ('TC05', N'Mức giá dịch vụ'),
 ('TC06', N'Mức độ hài lòng chung');
GO

/* ============================================================
   8. MỘT SỐ TRUY VẤN / VIEW MINH HỌA
   ============================================================ */

-- 8.1 Danh sách khung giờ còn trống của một ngày (KH_QĐ 1)
CREATE VIEW V_KhungGioTrong AS
SELECT  s.MaSan, s.TenSan, ls.TenLoaiSan, kg.MaKhungGio, kg.GioBatDau, kg.GioKetThuc
FROM    San s
        JOIN LoaiSan ls  ON ls.MaLoaiSan = s.MaLoaiSan
        CROSS JOIN KhungGio kg
WHERE   s.TrangThai <> N'Bảo trì';
GO

-- 8.2 Doanh thu theo ngày và phương thức thanh toán (KT_BM 2)
CREATE VIEW V_DoanhThuTheoNgay AS
SELECT  CAST(tt.NgayThanhToan AS DATE) AS Ngay,
        tt.PhuongThuc,
        COUNT(*)          AS SoGiaoDich,
        SUM(tt.SoTien)    AS TongTien
FROM    ThanhToan tt
WHERE   tt.TrangThai = N'Thành công'
GROUP BY CAST(tt.NgayThanhToan AS DATE), tt.PhuongThuc;
GO

-- 8.3 Tỷ lệ lấp đầy sân theo ngày
CREATE VIEW V_TyLeLapDay AS
SELECT  d.NgayChoi,
        COUNT(*) AS SoLuotDat,
        (SELECT COUNT(*) FROM San WHERE TrangThai <> N'Bảo trì')
            * (SELECT COUNT(*) FROM KhungGio) AS TongKhungGio,
        CAST(100.0 * COUNT(*) /
            NULLIF((SELECT COUNT(*) FROM San WHERE TrangThai <> N'Bảo trì')
                 * (SELECT COUNT(*) FROM KhungGio), 0) AS DECIMAL(5,2)) AS TyLeLapDay
FROM    DatSan d
WHERE   d.TrangThai <> N'Đã hủy'
GROUP BY d.NgayChoi;
GO

/* ============================================================
   9. TRIGGER TỰ ĐỘNG TÍNH TIỀN CHO PHIẾU ĐẶT SÂN (RB5)
   ============================================================ */
CREATE TRIGGER TRG_CapNhatTienDatSan
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
    SET    d.TienDichVu = ISNULL(ct.Tong, 0),
           d.TongTien   = d.TienSan + ISNULL(ct.Tong, 0) - d.TienGiam
    FROM   DatSan d
           JOIN ds ON ds.MaDatSan = d.MaDatSan
           OUTER APPLY (SELECT SUM(ThanhTien) AS Tong
                        FROM ChiTietDichVu c
                        WHERE c.MaDatSan = d.MaDatSan) ct;
END;
GO

PRINT N'Tạo cơ sở dữ liệu QuanLySanBong thành công.';
GO
