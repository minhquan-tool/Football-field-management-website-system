/* SCHEMA ONLY. No user/customer/account records, passwords, bank details, grants or logins.
   Contains reviewed-on-fixture financial guards; review before deployment.
   sqlcmd -b -f 65001 -d master -v NewDatabase=SanBong_SchemaDemo_YYYYMMDD -i <file>
   Will NEVER USE, overwrite, DROP, or restore an existing database. */
SET NOCOUNT ON;
DECLARE @name sysname=N'$(NewDatabase)';
IF @name NOT LIKE N'SanBong_SchemaDemo[_]%' OR @name LIKE N'%[^A-Za-z0-9_]%' OR LEN(@name)>100 THROW 51070,'Use a new SanBong_SchemaDemo_... name',1;
IF DB_ID(@name) IS NOT NULL THROW 51071,'Database exists; no changes performed',1;
DECLARE @create nvarchar(max)=N'CREATE DATABASE '+QUOTENAME(@name)+N' COLLATE SQL_Latin1_General_CP1_CI_AS;';
EXEC(@create);
DECLARE @ddl nvarchar(max)=N'USE '+QUOTENAME(@name)+N'; '+N'SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE dbo.[BangGia](
 [MaBangGia] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaLoaiSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKhungGio] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [LoaiNgay] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [DonGia] decimal(18,2) NOT NULL,
 [NgayHieuLuc] date NOT NULL,
 [NgayHetHieuLuc] date NULL,
 CONSTRAINT [PK_BangGia] PRIMARY KEY CLUSTERED ([MaBangGia] ASC),
 CONSTRAINT [CK_BangGia_LoaiNgay] CHECK ([LoaiNgay]=N''Ngày lễ'' OR [LoaiNgay]=N''Cuối tuần'' OR [LoaiNgay]=N''Ngày thường''),
 CONSTRAINT [CK_BangGia_DonGia] CHECK ([DonGia]>(0)),
 CONSTRAINT [CK_BangGia_HieuLuc] CHECK ([NgayHetHieuLuc] IS NULL OR [NgayHetHieuLuc]>=[NgayHieuLuc])
);
CREATE TABLE dbo.[BaoCao](
 [MaBaoCao] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [LoaiBaoCao] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NgayLap] date NOT NULL CONSTRAINT [DF__BaoCao__NgayLap__4A8310C6] DEFAULT (getdate()),
 [TuNgay] date NOT NULL,
 [DenNgay] date NOT NULL,
 [MaTK] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NoiDung] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_BaoCao] PRIMARY KEY CLUSTERED ([MaBaoCao] ASC),
 CONSTRAINT [CK_BaoCao_ThoiGian] CHECK ([DenNgay]>=[TuNgay])
);
CREATE TABLE dbo.[ChiTietDanhGia](
 [MaDanhGia] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaTieuChi] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [Diem] int NOT NULL,
 CONSTRAINT [PK_ChiTietDanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC,[MaTieuChi] ASC),
 CONSTRAINT [CK_CTDG_Diem] CHECK ([Diem]>=(1) AND [Diem]<=(5))
);
CREATE TABLE dbo.[ChiTietDichVu](
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [SoLuong] int NOT NULL,
 [NgayGhiNhan] datetime NOT NULL CONSTRAINT [DF__ChiTietDi__NgayG__7F2BE32F] DEFAULT (getdate()),
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [MaChiTiet] bigint IDENTITY(1,1) NOT NULL,
 [Nguon] varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CTDV_Nguon] DEFAULT (''LEGACY''),
 [QuyCach] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CTDV_QuyCach] DEFAULT (''DON_VI''),
 [DonGiaDonViSnapshot] decimal(18,2) NULL,
 [DonGiaLegacySnapshot] decimal(18,2) NULL,
 [SoDonViMoiQuyCach] AS (CONVERT([int],case when [QuyCach]=''LOC_6'' then (6) else (1) end)) PERSISTED,
 [DonGia] AS (CONVERT([decimal](18,2),case when [Nguon]=''LEGACY'' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]=''LOC_6'' then (6) else (1) end)*case when [QuyCach]=''LOC_6'' then (0.97) else (1) end,(2)) end)) PERSISTED,
 [ThanhTien] AS ([SoLuong]*CONVERT([decimal](18,2),case when [Nguon]=''LEGACY'' then [DonGiaLegacySnapshot] else round(([DonGiaDonViSnapshot]*case when [QuyCach]=''LOC_6'' then (6) else (1) end)*case when [QuyCach]=''LOC_6'' then (0.97) else (1) end,(2)) end)) PERSISTED,
 CONSTRAINT [PK_ChiTietDichVu] PRIMARY KEY CLUSTERED ([MaChiTiet] ASC),
 CONSTRAINT [CK_CTDV_SoLuong] CHECK ([SoLuong]>(0)),
 CONSTRAINT [CK_CTDV_Nguon] CHECK ([Nguon]=''PHAT_SINH'' OR [Nguon]=''DAT_TRUOC'' OR [Nguon]=''LEGACY''),
 CONSTRAINT [CK_CTDV_QuyCach] CHECK ([QuyCach]=''LOC_6'' OR [QuyCach]=''DON_VI''),
 CONSTRAINT [CK_CTDV_DonGia] CHECK ([DonGia] IS NOT NULL AND [DonGia]>(0)),
 CONSTRAINT [CK_CTDV_Snapshot] CHECK ([Nguon]=''LEGACY'' AND [DonGiaLegacySnapshot] IS NOT NULL AND [DonGiaLegacySnapshot]>(0) AND ([DonGiaDonViSnapshot] IS NULL OR [DonGiaDonViSnapshot]>(0)) OR [Nguon]<>''LEGACY'' AND [DonGiaLegacySnapshot] IS NULL AND [DonGiaDonViSnapshot] IS NOT NULL AND [DonGiaDonViSnapshot]>(0))
);
CREATE TABLE dbo.[ChucNang](
 [MaChucNang] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenChucNang] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MoTa] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ChucNang] PRIMARY KEY CLUSTERED ([MaChucNang] ASC)
);
CREATE TABLE dbo.[DanhGia](
 [MaDanhGia] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKH] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NgayDanhGia] date NOT NULL CONSTRAINT [DF__DanhGia__NgayDan__2B0A656D] DEFAULT (getdate()),
 [NoiDung] nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [DiemTrungBinh] decimal(3,2) NULL,
 CONSTRAINT [PK_DanhGia] PRIMARY KEY CLUSTERED ([MaDanhGia] ASC),
 CONSTRAINT [UQ_DanhGia_DatSan] UNIQUE NONCLUSTERED ([MaDatSan] ASC),
 CONSTRAINT [CK_DanhGia_Diem] CHECK ([DiemTrungBinh] IS NULL OR [DiemTrungBinh]>=(1) AND [DiemTrungBinh]<=(5))
);
CREATE TABLE dbo.[DatSan](
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKH] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKhungGio] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayChoi] date NOT NULL,
 [DonGia] decimal(18,2) NOT NULL,
 [TienDichVu] decimal(18,2) NOT NULL CONSTRAINT [DF__DatSan__TienDich__6D0D32F4] DEFAULT ((0)),
 [MaKM] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [TienGiam] decimal(18,2) NOT NULL CONSTRAINT [DF__DatSan__TienGiam__6E01572D] DEFAULT ((0)),
 [NgayDat] datetime NOT NULL CONSTRAINT [DF__DatSan__NgayDat__6FE99F9F] DEFAULT (getdate()),
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [TrangThai] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__DatSan__TrangTha__70DDC3D8] DEFAULT (N''Chờ xác nhận''),
 [GhiChu] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [GioBatDau] time(0) NOT NULL,
 [GioKetThuc] time(0) NOT NULL,
 [CheDoGia] varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatSan_CheDoGia] DEFAULT (''GIA_KHUNG''),
 [HinhThucDat] varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatSan_HinhThucDat] DEFAULT (''KHONG_RO''),
 [ThoiLuongLegacySnapshot] decimal(4,2) NULL,
 [TienSanLegacySnapshot] decimal(18,2) NULL,
 [ThoiLuong] AS (CONVERT([decimal](4,2),case when [CheDoGia]=''GIA_KHUNG'' then [ThoiLuongLegacySnapshot] else round(datediff(minute,[GioBatDau],[GioKetThuc])/(60.0),(2)) end)) PERSISTED,
 [TienSan] AS (CONVERT([decimal](18,2),case when [CheDoGia]=''GIA_KHUNG'' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)) PERSISTED,
 [TongTien] AS (CONVERT([decimal](18,2),(CONVERT([decimal](18,2),case when [CheDoGia]=''GIA_KHUNG'' then [TienSanLegacySnapshot] else round(([DonGia]*datediff(minute,[GioBatDau],[GioKetThuc]))/(60.0),(2)) end)+[TienDichVu])-[TienGiam])) PERSISTED,
 CONSTRAINT [PK_DatSan] PRIMARY KEY CLUSTERED ([MaDatSan] ASC),
 CONSTRAINT [CK_DatSan_KhoangGio] CHECK ([GioKetThuc]>[GioBatDau]),
 CONSTRAINT [CK_DatSan_CheDoGia] CHECK ([CheDoGia]=''GIA_GIO'' OR [CheDoGia]=''GIA_KHUNG''),
 CONSTRAINT [CK_DatSan_HinhThucDat] CHECK ([HinhThucDat]=''TAI_QUAY'' OR [HinhThucDat]=''TRUC_TUYEN'' OR [HinhThucDat]=''KHONG_RO''),
 CONSTRAINT [CK_DatSan_GioMoi] CHECK ([CheDoGia]=''GIA_KHUNG'' OR [GioBatDau]>=''07:00:00'' AND [GioKetThuc]<=''22:00:00'' AND datepart(second,[GioBatDau])=(0) AND datepart(second,[GioKetThuc])=(0)),
 CONSTRAINT [CK_DatSan_Tien] CHECK ([DonGia]>(0) AND [TienSan] IS NOT NULL AND [TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TongTien]>=(0)),
 CONSTRAINT [CK_DatSan_ThoiLuong] CHECK ([ThoiLuong] IS NOT NULL AND [ThoiLuong]>(0)),
 CONSTRAINT [CK_DatSan_LegacySnapshots] CHECK ([CheDoGia]=''GIA_KHUNG'' AND [ThoiLuongLegacySnapshot] IS NOT NULL AND [ThoiLuongLegacySnapshot]>(0) AND [TienSanLegacySnapshot] IS NOT NULL AND [TienSanLegacySnapshot]>=(0) OR [CheDoGia]=''GIA_GIO'' AND [ThoiLuongLegacySnapshot] IS NULL AND [TienSanLegacySnapshot] IS NULL),
 CONSTRAINT [CK_DatSan_TrangThai] CHECK ([TrangThai]=N''Đã hủy'' OR [TrangThai]=N''Đã sử dụng'' OR [TrangThai]=N''Đã xác nhận'' OR [TrangThai]=N''Chờ xác nhận'')
);
CREATE TABLE dbo.[DichVu](
 [MaDV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenDV] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [DonViTinh] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [DonGia] decimal(18,2) NOT NULL,
 [TrangThai] bit NOT NULL CONSTRAINT [DF__DichVu__TrangTha__7B5B524B] DEFAULT ((1)),
 [HoTroLoc] bit NOT NULL CONSTRAINT [DF_DichVu_HoTroLoc] DEFAULT ((0)),
 CONSTRAINT [PK_DichVu] PRIMARY KEY CLUSTERED ([MaDV] ASC),
 CONSTRAINT [CK_DichVu_DonGia] CHECK ([DonGia]>(0))
);
CREATE TABLE dbo.[GiaTheoCa](
 [MaCa] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [GioBatDau] time(0) NOT NULL,
 [GioKetThuc] time(0) NOT NULL,
 [DonGia] decimal(18,2) NOT NULL,
 CONSTRAINT [PK_GiaTheoCa] PRIMARY KEY CLUSTERED ([MaCa] ASC),
 CONSTRAINT [CK_GiaTheoCa_DonGia] CHECK ([DonGia]>(0)),
 CONSTRAINT [CK_GiaTheoCa_Bien] CHECK ([MaCa]=''SANG'' AND [GioBatDau]=''07:00:00'' AND [GioKetThuc]=''13:00:00'' OR [MaCa]=''CHIEU'' AND [GioBatDau]=''13:00:00'' AND [GioKetThuc]=''19:00:00'' OR [MaCa]=''TOI'' AND [GioBatDau]=''19:00:00'' AND [GioKetThuc]=''22:00:00'')
);
CREATE TABLE dbo.[HoaDon](
 [MaHoaDon] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaTKLap] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TienSan] decimal(18,2) NOT NULL,
 [TienDichVu] decimal(18,2) NOT NULL,
 [TienGiam] decimal(18,2) NOT NULL,
 [DaThanhToan] decimal(18,2) NOT NULL CONSTRAINT [DF__HoaDon__DaThanhT__318258D2] DEFAULT ((0)),
 [TrangThai] varchar(24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__HoaDon__TrangTha__32767D0B] DEFAULT (''CHUA_THANH_TOAN''),
 [DaChot] bit NOT NULL CONSTRAINT [DF__HoaDon__DaChot__336AA144] DEFAULT ((0)),
 [NgayLap] datetime2(7) NOT NULL CONSTRAINT [DF__HoaDon__NgayLap__345EC57D] DEFAULT (sysdatetime()),
 [TongTien] AS (CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])) PERSISTED,
 [ConLai] AS (case when [TrangThai]=''DA_HUY'' then CONVERT([decimal](18,2),(0)) else CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])-[DaThanhToan] end) PERSISTED,
 [HoanTatTaiChinh] AS (CONVERT([bit],case when [DaChot]=(1) AND CONVERT([decimal](18,2),([TienSan]+[TienDichVu])-[TienGiam])=[DaThanhToan] AND [TrangThai]=''DA_THANH_TOAN'' then (1) else (0) end)) PERSISTED,
 CONSTRAINT [PK_HoaDon] PRIMARY KEY CLUSTERED ([MaHoaDon] ASC),
 CONSTRAINT [UQ_HoaDon_DatSan] UNIQUE NONCLUSTERED ([MaDatSan] ASC),
 CONSTRAINT [CK_HD_State] CHECK ([TrangThai]=''DA_HUY'' OR [TrangThai]=''DA_THANH_TOAN'' OR [TrangThai]=''THANH_TOAN_MOT_PHAN'' OR [TrangThai]=''CHUA_THANH_TOAN''),
 CONSTRAINT [CK_HD_Money] CHECK ([TienSan]>=(0) AND [TienDichVu]>=(0) AND [TienGiam]>=(0) AND [TienGiam]<=[TienSan] AND [TongTien]>=(0) AND [DaThanhToan]>=(0) AND [DaThanhToan]<=[TongTien])
);
CREATE TABLE dbo.[HoanTien](
 [MaHT] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaTT] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaHuy] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NgayHoan] datetime NOT NULL CONSTRAINT [DF__HoanTien__NgayHo__1EA48E88] DEFAULT (getdate()),
 [SoTienHoan] decimal(18,2) NOT NULL,
 [PhuongThuc] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TrangThai] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__HoanTien__TrangT__1F98B2C1] DEFAULT (N''Chờ duyệt''),
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayXacNhan] datetime2(7) NULL,
 [LyDo] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_HoanTien] PRIMARY KEY CLUSTERED ([MaHT] ASC),
 CONSTRAINT [CK_HoanTien_SoTien] CHECK ([SoTienHoan]>(0)),
 CONSTRAINT [CK_HoanTien_PhuongThuc] CHECK ([PhuongThuc]=N''Chuyển khoản'' OR [PhuongThuc]=N''Tiền mặt''),
 CONSTRAINT [CK_HoanTien_TrangThai] CHECK ([TrangThai]=N''Từ chối'' OR [TrangThai]=N''Đã hoàn'' OR [TrangThai]=N''Chờ duyệt'')
);
CREATE TABLE dbo.[HuyDatSan](
 [MaHuy] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NgayHuy] datetime2(7) NOT NULL CONSTRAINT [DF__HuyDatSan__NgayH__160F4887] DEFAULT (getdate()),
 [LyDo] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NguoiHuy] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TiLeHoan] decimal(5,2) NOT NULL CONSTRAINT [DF__HuyDatSan__TiLeH__17036CC0] DEFAULT ((0)),
 [SoTienHoan] decimal(18,2) NOT NULL CONSTRAINT [DF__HuyDatSan__SoTie__17F790F9] DEFAULT ((0)),
 [SoTienThucThuSnapshot] decimal(18,2) NULL,
 CONSTRAINT [PK_HuyDatSan] PRIMARY KEY CLUSTERED ([MaHuy] ASC),
 CONSTRAINT [UQ_HuyDatSan_DatSan] UNIQUE NONCLUSTERED ([MaDatSan] ASC),
 CONSTRAINT [CK_HuyDatSan_NguoiHuy] CHECK ([NguoiHuy]=N''Nhân viên'' OR [NguoiHuy]=N''Khách hàng''),
 CONSTRAINT [CK_HuyDatSan_TiLeHoan] CHECK ([TiLeHoan]>=(0) AND [TiLeHoan]<=(100)),
 CONSTRAINT [CK_HuyDatSan_SoTien] CHECK ([SoTienHoan]>=(0)),
 CONSTRAINT [CK_Huy_ThucThu] CHECK ([SoTienThucThuSnapshot] IS NULL OR [SoTienThucThuSnapshot]>=(0) AND [SoTienHoan]<=round(([SoTienThucThuSnapshot]*[TiLeHoan])/(100),(2)))
);
CREATE TABLE dbo.[KhachHang](
 [MaKH] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [HoTen] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [SoDienThoai] varchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [Email] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [DiaChi] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayDangKy] date NOT NULL CONSTRAINT [DF__KhachHang__NgayD__440B1D61] DEFAULT (getdate()),
 [GhiChu] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_KhachHang] PRIMARY KEY CLUSTERED ([MaKH] ASC),
 CONSTRAINT [UQ_KhachHang_SDT] UNIQUE NONCLUSTERED ([SoDienThoai] ASC)
);
CREATE TABLE dbo.[KhungGio](
 [MaKhungGio] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [GioBatDau] time(7) NOT NULL,
 [GioKetThuc] time(7) NOT NULL,
 [ThoiLuong] decimal(4,2) NOT NULL,
 CONSTRAINT [PK_KhungGio] PRIMARY KEY CLUSTERED ([MaKhungGio] ASC),
 CONSTRAINT [CK_KhungGio_Gio] CHECK ([GioKetThuc]>[GioBatDau]),
 CONSTRAINT [CK_KhungGio_ThoiLuong] CHECK ([ThoiLuong]>(0))
);
CREATE TABLE dbo.[KhuyenMai](
 [MaKM] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenKM] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [LoaiGiam] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MucGiam] decimal(18,2) NOT NULL,
 [DieuKien] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayBatDau] date NOT NULL,
 [NgayKetThuc] date NOT NULL,
 [TrangThai] bit NOT NULL CONSTRAINT [DF__KhuyenMai__Trang__66603565] DEFAULT ((1)),
 CONSTRAINT [PK_KhuyenMai] PRIMARY KEY CLUSTERED ([MaKM] ASC),
 CONSTRAINT [CK_KhuyenMai_LoaiGiam] CHECK ([LoaiGiam]=N''Số tiền'' OR [LoaiGiam]=N''Phần trăm''),
 CONSTRAINT [CK_KhuyenMai_MucGiam] CHECK ([MucGiam]>(0)),
 CONSTRAINT [CK_KhuyenMai_ThoiGian] CHECK ([NgayKetThuc]>=[NgayBatDau])
);
CREATE TABLE dbo.[LoaiSan](
 [MaLoaiSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenLoaiSan] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [SoNguoi] int NOT NULL,
 [MoTa] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_LoaiSan] PRIMARY KEY CLUSTERED ([MaLoaiSan] ASC),
 CONSTRAINT [CK_LoaiSan_SoNguoi] CHECK ([SoNguoi]>(0))
);
CREATE TABLE dbo.[NhanVien](
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [HoTen] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [SoDienThoai] varchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [Email] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [ChucVu] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [BoPhan] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayVaoLam] date NULL,
 [TrangThai] bit NOT NULL CONSTRAINT [DF__NhanVien__TrangT__46E78A0C] DEFAULT ((1)),
 CONSTRAINT [PK_NhanVien] PRIMARY KEY CLUSTERED ([MaNV] ASC),
 CONSTRAINT [CK_NhanVien_BoPhan] CHECK ([BoPhan]=N''Quản trị hệ thống'' OR [BoPhan]=N''Kế toán'' OR [BoPhan]=N''Nhân viên sân bóng'')
);
CREATE TABLE dbo.[NhatKyHeThong](
 [MaNhatKy] varchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaTK] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [ThoiGian] datetime NOT NULL CONSTRAINT [DF__NhatKyHeT__ThoiG__3F115E1A] DEFAULT (getdate()),
 [ChucNang] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [ThaoTac] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [DoiTuong] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NoiDungThayDoi] nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [KetQua] bit NOT NULL CONSTRAINT [DF__NhatKyHeT__KetQu__40058253] DEFAULT ((1)),
 [GhiChu] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_NhatKyHeThong] PRIMARY KEY CLUSTERED ([MaNhatKy] ASC),
 CONSTRAINT [CK_NhatKy_ThaoTac] CHECK ([ThaoTac]=N''Đăng xuất'' OR [ThaoTac]=N''Đăng nhập'' OR [ThaoTac]=N''Xóa'' OR [ThaoTac]=N''Sửa'' OR [ThaoTac]=N''Thêm'')
);
CREATE TABLE dbo.[PhanHoi](
 [MaPhanHoi] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKH] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayGui] datetime NOT NULL CONSTRAINT [DF__PhanHoi__NgayGui__367C1819] DEFAULT (getdate()),
 [LoaiPhanHoi] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NoiDung] nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TrangThaiXuLy] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__PhanHoi__TrangTh__37703C52] DEFAULT (N''Chờ xử lý''),
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayXuLy] datetime NULL,
 [KetQuaXuLy] nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_PhanHoi] PRIMARY KEY CLUSTERED ([MaPhanHoi] ASC),
 CONSTRAINT [CK_PhanHoi_TrangThai] CHECK ([TrangThaiXuLy]=N''Đã xử lý'' OR [TrangThaiXuLy]=N''Đang xử lý'' OR [TrangThaiXuLy]=N''Chờ xử lý''),
 CONSTRAINT [CK_PhanHoi_NgayXuLy] CHECK ([NgayXuLy] IS NULL OR [NgayXuLy]>=[NgayGui])
);
CREATE TABLE dbo.[PhanQuyen](
 [MaVaiTro] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaChucNang] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [Xem] bit NOT NULL CONSTRAINT [DF__PhanQuyen__Xem__3B75D760] DEFAULT ((0)),
 [Them] bit NOT NULL CONSTRAINT [DF__PhanQuyen__Them__3C69FB99] DEFAULT ((0)),
 [Sua] bit NOT NULL CONSTRAINT [DF__PhanQuyen__Sua__3D5E1FD2] DEFAULT ((0)),
 [Xoa] bit NOT NULL CONSTRAINT [DF__PhanQuyen__Xoa__3E52440B] DEFAULT ((0)),
 CONSTRAINT [PK_PhanQuyen] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC,[MaChucNang] ASC)
);
CREATE TABLE dbo.[San](
 [MaSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenSan] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaLoaiSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TrangThai] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__San__TrangThai__571DF1D5] DEFAULT (N''Trống''),
 [MoTa] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_San] PRIMARY KEY CLUSTERED ([MaSan] ASC),
 CONSTRAINT [CK_San_TrangThai] CHECK ([TrangThai]=N''Bảo trì'' OR [TrangThai]=N''Đang sử dụng'' OR [TrangThai]=N''Trống'')
);
CREATE TABLE dbo.[SaoLuu](
 [MaSaoLuu] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaTK] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [ThoiGian] datetime NOT NULL CONSTRAINT [DF__SaoLuu__ThoiGian__44CA3770] DEFAULT (getdate()),
 [LoaiThaoTac] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [DuongDan] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [KetQua] bit NOT NULL CONSTRAINT [DF__SaoLuu__KetQua__45BE5BA9] DEFAULT ((1)),
 [GhiChu] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_SaoLuu] PRIMARY KEY CLUSTERED ([MaSaoLuu] ASC),
 CONSTRAINT [CK_SaoLuu_LoaiThaoTac] CHECK ([LoaiThaoTac]=N''Phục hồi'' OR [LoaiThaoTac]=N''Sao lưu'')
);
CREATE TABLE dbo.[TaiKhoan](
 [MaTK] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenDangNhap] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MatKhau] varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaVaiTro] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaKH] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [NgayTao] datetime NOT NULL CONSTRAINT [DF__TaiKhoan__NgayTa__4BAC3F29] DEFAULT (getdate()),
 [TrangThai] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__TaiKhoan__TrangT__4CA06362] DEFAULT (N''Hoạt động''),
 CONSTRAINT [PK_TaiKhoan] PRIMARY KEY CLUSTERED ([MaTK] ASC),
 CONSTRAINT [UQ_TaiKhoan_TenDangNhap] UNIQUE NONCLUSTERED ([TenDangNhap] ASC),
 CONSTRAINT [CK_TaiKhoan_TrangThai] CHECK ([TrangThai]=N''Khóa'' OR [TrangThai]=N''Hoạt động''),
 CONSTRAINT [CK_TaiKhoan_ChuSoHuu] CHECK ([MaKH] IS NULL AND [MaNV] IS NOT NULL OR [MaKH] IS NOT NULL AND [MaNV] IS NULL)
);
CREATE TABLE dbo.[ThanhToan](
 [MaTT] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [NgayThanhToan] datetime NOT NULL CONSTRAINT [DF__ThanhToan__NgayT__0C85DE4D] DEFAULT (getdate()),
 [SoTien] decimal(18,2) NOT NULL,
 [PhuongThuc] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaGiaoDich] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [TrangThai] nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__ThanhToan__Trang__0D7A0286] DEFAULT (N''Chờ xử lý''),
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ThanhToan] PRIMARY KEY CLUSTERED ([MaTT] ASC),
 CONSTRAINT [CK_ThanhToan_SoTien] CHECK ([SoTien]>(0)),
 CONSTRAINT [CK_ThanhToan_PhuongThuc] CHECK ([PhuongThuc]=N''Chuyển khoản'' OR [PhuongThuc]=N''Tiền mặt''),
 CONSTRAINT [CK_ThanhToan_TrangThai] CHECK ([TrangThai]=N''Thất bại'' OR [TrangThai]=N''Thành công'' OR [TrangThai]=N''Chờ xử lý'')
);
CREATE TABLE dbo.[TieuChiDanhGia](
 [MaTieuChi] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenTieuChi] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MoTa] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_TieuChiDanhGia] PRIMARY KEY CLUSTERED ([MaTieuChi] ASC)
);
CREATE TABLE dbo.[VaiTro](
 [MaVaiTro] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [TenVaiTro] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MoTa] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_VaiTro] PRIMARY KEY CLUSTERED ([MaVaiTro] ASC)
);
CREATE TABLE dbo.[XacNhanSan](
 [MaXacNhan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaDatSan] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [MaNV] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 [ThoiGianNhan] datetime NOT NULL,
 [ThoiGianKetThuc] datetime NULL,
 [TinhTrangSan] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 [GhiChu] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_XacNhanSan] PRIMARY KEY CLUSTERED ([MaXacNhan] ASC),
 CONSTRAINT [UQ_XacNhanSan_DatSan] UNIQUE NONCLUSTERED ([MaDatSan] ASC),
 CONSTRAINT [CK_XacNhanSan_ThoiGian] CHECK ([ThoiGianKetThuc] IS NULL OR [ThoiGianKetThuc]>=[ThoiGianNhan])
);
ALTER TABLE dbo.[BangGia] WITH CHECK ADD CONSTRAINT [FK_BangGia_KhungGio] FOREIGN KEY ([MaKhungGio]) REFERENCES dbo.[KhungGio]([MaKhungGio]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[BangGia] WITH CHECK ADD CONSTRAINT [FK_BangGia_LoaiSan] FOREIGN KEY ([MaLoaiSan]) REFERENCES dbo.[LoaiSan]([MaLoaiSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[BaoCao] WITH CHECK ADD CONSTRAINT [FK_BaoCao_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan]([MaTK]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ChiTietDanhGia] WITH CHECK ADD CONSTRAINT [FK_CTDG_DanhGia] FOREIGN KEY ([MaDanhGia]) REFERENCES dbo.[DanhGia]([MaDanhGia]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ChiTietDanhGia] WITH CHECK ADD CONSTRAINT [FK_CTDG_TieuChi] FOREIGN KEY ([MaTieuChi]) REFERENCES dbo.[TieuChiDanhGia]([MaTieuChi]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_DichVu] FOREIGN KEY ([MaDV]) REFERENCES dbo.[DichVu]([MaDV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ChiTietDichVu] WITH CHECK ADD CONSTRAINT [FK_CTDV_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang]([MaKH]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_San] FOREIGN KEY ([MaSan]) REFERENCES dbo.[San]([MaSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang]([MaKH]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhungGio] FOREIGN KEY ([MaKhungGio]) REFERENCES dbo.[KhungGio]([MaKhungGio]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_KhuyenMai] FOREIGN KEY ([MaKM]) REFERENCES dbo.[KhuyenMai]([MaKM]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[DatSan] WITH CHECK ADD CONSTRAINT [FK_DatSan_San] FOREIGN KEY ([MaSan]) REFERENCES dbo.[San]([MaSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HoaDon] WITH CHECK ADD CONSTRAINT [FK_HD_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HoaDon] WITH CHECK ADD CONSTRAINT [FK_HD_TaiKhoan] FOREIGN KEY ([MaTKLap]) REFERENCES dbo.[TaiKhoan]([MaTK]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_HuyDatSan] FOREIGN KEY ([MaHuy]) REFERENCES dbo.[HuyDatSan]([MaHuy]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HoanTien] WITH CHECK ADD CONSTRAINT [FK_HoanTien_ThanhToan] FOREIGN KEY ([MaTT]) REFERENCES dbo.[ThanhToan]([MaTT]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[HuyDatSan] WITH CHECK ADD CONSTRAINT [FK_HuyDatSan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[NhatKyHeThong] WITH CHECK ADD CONSTRAINT [FK_NhatKy_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan]([MaTK]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang]([MaKH]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[PhanHoi] WITH CHECK ADD CONSTRAINT [FK_PhanHoi_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[PhanQuyen] WITH CHECK ADD CONSTRAINT [FK_PhanQuyen_ChucNang] FOREIGN KEY ([MaChucNang]) REFERENCES dbo.[ChucNang]([MaChucNang]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[PhanQuyen] WITH CHECK ADD CONSTRAINT [FK_PhanQuyen_VaiTro] FOREIGN KEY ([MaVaiTro]) REFERENCES dbo.[VaiTro]([MaVaiTro]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[San] WITH CHECK ADD CONSTRAINT [FK_San_LoaiSan] FOREIGN KEY ([MaLoaiSan]) REFERENCES dbo.[LoaiSan]([MaLoaiSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[SaoLuu] WITH CHECK ADD CONSTRAINT [FK_SaoLuu_TaiKhoan] FOREIGN KEY ([MaTK]) REFERENCES dbo.[TaiKhoan]([MaTK]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_KhachHang] FOREIGN KEY ([MaKH]) REFERENCES dbo.[KhachHang]([MaKH]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[TaiKhoan] WITH CHECK ADD CONSTRAINT [FK_TaiKhoan_VaiTro] FOREIGN KEY ([MaVaiTro]) REFERENCES dbo.[VaiTro]([MaVaiTro]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ThanhToan] WITH CHECK ADD CONSTRAINT [FK_ThanhToan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[ThanhToan] WITH CHECK ADD CONSTRAINT [FK_ThanhToan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[XacNhanSan] WITH CHECK ADD CONSTRAINT [FK_XacNhanSan_DatSan] FOREIGN KEY ([MaDatSan]) REFERENCES dbo.[DatSan]([MaDatSan]) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE dbo.[XacNhanSan] WITH CHECK ADD CONSTRAINT [FK_XacNhanSan_NhanVien] FOREIGN KEY ([MaNV]) REFERENCES dbo.[NhanVien]([MaNV]) ON DELETE NO ACTION ON UPDATE NO ACTION;
CREATE NONCLUSTERED INDEX [IX_CTDV_BookingSku] ON dbo.[ChiTietDichVu]([MaDatSan] ASC,[MaDV] ASC);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DatSan_KhongTrungLich] ON dbo.[DatSan]([MaSan] ASC,[NgayChoi] ASC,[MaKhungGio] ASC) WHERE ([TrangThai]<>N''Đã hủy'' AND [MaKhungGio] IS NOT NULL);
CREATE NONCLUSTERED INDEX [IX_DatSan_SanNgayBatDau] ON dbo.[DatSan]([MaSan] ASC,[NgayChoi] ASC,[GioBatDau] ASC) INCLUDE([GioKetThuc],[TrangThai]);
CREATE UNIQUE NONCLUSTERED INDEX [UX_HoanTien_CancellationPayment] ON dbo.[HoanTien]([MaHuy] ASC,[MaTT] ASC);
CREATE NONCLUSTERED INDEX [IX_ThanhToan_BookingState] ON dbo.[ThanhToan]([MaDatSan] ASC,[TrangThai] ASC) INCLUDE([SoTien]);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ThanhToan_Idempotency] ON dbo.[ThanhToan]([MaGiaoDich] ASC) WHERE ([MaGiaoDich] IS NOT NULL);
EXEC(N''
CREATE   FUNCTION dbo.fn_TyLeHoan
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
'');
EXEC(N''CREATE FUNCTION dbo.fn_BookingReceipts(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTien),0) thu FROM dbo.ThanhToan WHERE MaDatSan=@Booking AND TrangThai=N''''Thành công'''');'');
EXEC(N''CREATE FUNCTION dbo.fn_BookingRefunds(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(CASE WHEN h.TrangThai=N''''Đã hoàn'''' THEN h.SoTienHoan ELSE 0 END),0) hoan,ISNULL(SUM(CASE WHEN h.TrangThai=N''''Chờ duyệt'''' THEN h.SoTienHoan ELSE 0 END),0) choHoan FROM dbo.HoanTien h JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=@Booking);'');
EXEC(N''CREATE FUNCTION dbo.fn_KhungGioTrongTheoNgay(@Ngay date) RETURNS TABLE AS RETURN (
 SELECT s.MaSan,s.TenSan,l.TenLoaiSan,k.MaKhungGio,k.GioBatDau,k.GioKetThuc,@Ngay NgayChoi
 FROM dbo.San s JOIN dbo.LoaiSan l ON l.MaLoaiSan=s.MaLoaiSan CROSS JOIN dbo.KhungGio k
 WHERE @Ngay IS NOT NULL AND s.TrangThai<>N''''Bảo trì''''
 AND k.GioBatDau>=''''07:00'''' AND k.GioKetThuc<=''''22:00''''
 AND NOT EXISTS(SELECT 1 FROM dbo.DatSan d WHERE d.MaSan=s.MaSan AND d.NgayChoi=@Ngay
 AND d.TrangThai<>N''''Đã hủy'''' AND d.GioBatDau<k.GioKetThuc AND d.GioKetThuc>k.GioBatDau));'');
EXEC(N''CREATE FUNCTION dbo.fn_ReportDays(@From date,@To date) RETURNS TABLE AS RETURN (WITH digits(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))x(n)) SELECT DATEADD(day,a.n+10*b.n+100*c.n,@From) Ngay FROM digits a CROSS JOIN digits b CROSS JOIN digits c WHERE @From IS NOT NULL AND @To>=@From AND DATEDIFF(day,@From,@To)<=366 AND a.n+10*b.n+100*c.n<=DATEDIFF(day,@From,@To));'');
EXEC(N''CREATE TRIGGER dbo.TRG_AuditContentImmutable ON dbo.NhatKyHeThong AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT * FROM inserted EXCEPT SELECT * FROM deleted)
 THROW 51023,''''Audit records are append-only; content cannot be rewritten'''',1;
 END;'');
EXEC(N''
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
    SET    d.TienDichVu = ISNULL(ct.Tong, 0)
    FROM   DatSan d
           JOIN ds ON ds.MaDatSan = d.MaDatSan
           OUTER APPLY (SELECT SUM(ThanhTien) AS Tong
                        FROM ChiTietDichVu c
                        WHERE c.MaDatSan = d.MaDatSan) ct;
END;
'');
EXEC(N''CREATE TRIGGER dbo.TRG_SealedInvoiceSnapshot ON dbo.HoaDon AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM deleted WHERE DaChot=1
 EXCEPT SELECT MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,TongTien,DaChot,NgayLap FROM inserted)
 THROW 51026,''''Sealed invoice identity and amounts cannot change; received total/status may be synchronized'''',1;
 END;'');
EXEC(N''CREATE TRIGGER dbo.TRG_ServicePriceSnapshot ON dbo.ChiTietDichVu AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM inserted
 EXCEPT SELECT MaChiTiet,MaDatSan,MaDV,DonGia,DonGiaDonViSnapshot,Nguon,QuyCach,SoDonViMoiQuyCach FROM deleted)
 THROW 51024,''''Service SKU/price snapshot is immutable; only quantity may change before financial closing'''',1;
 END;'');
EXEC(N''CREATE TRIGGER dbo.TRG_SuccessfulPaymentSnapshot ON dbo.ThanhToan AFTER UPDATE AS
 BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM deleted WHERE TrangThai=N''''Thành công''''
 EXCEPT SELECT MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,NgayThanhToan,MaNV FROM inserted)
 THROW 51025,''''A received payment is immutable; record a separate authorized refund'''',1;
 END;'');
EXEC(N''CREATE VIEW dbo.V_Phase6_Revenue AS
 SELECT d.MaDatSan,d.MaSan,CAST(x.ThoiGianKetThuc AS date) Ngay,
 COALESCE(h.TienSan,d.TienSan) TienSan,COALESCE(h.TienDichVu,d.TienDichVu) TienDichVu,
 COALESCE(h.TienGiam,d.TienGiam) TienGiam,COALESCE(h.TongTien,d.TongTien) DoanhThu
 FROM dbo.DatSan d JOIN (SELECT MaDatSan,MAX(ThoiGianKetThuc) ThoiGianKetThuc FROM dbo.XacNhanSan
 WHERE ThoiGianKetThuc IS NOT NULL GROUP BY MaDatSan) x ON x.MaDatSan=d.MaDatSan
 LEFT JOIN dbo.HoaDon h ON h.MaDatSan=d.MaDatSan
 WHERE d.TrangThai<>N''''Đã hủy'''';'');
EXEC(N''CREATE VIEW dbo.V_Phase6_UsageBooking AS
 SELECT d.MaDatSan,d.MaSan,d.NgayChoi,d.TrangThai,
 CASE WHEN d.TrangThai=N''''Đã hủy'''' THEN 0 ELSE
 CASE WHEN d.GioKetThuc<=CONVERT(time,''''07:00'''') OR d.GioBatDau>=CONVERT(time,''''22:00'''') THEN 0 ELSE
 DATEDIFF(minute,CASE WHEN d.GioBatDau<CONVERT(time,''''07:00'''') THEN CONVERT(time,''''07:00'''') ELSE d.GioBatDau END,
 CASE WHEN d.GioKetThuc>CONVERT(time,''''22:00'''') THEN CONVERT(time,''''22:00'''') ELSE d.GioKetThuc END) END END PhutDat,
 CONVERT(int,CASE WHEN EXISTS(SELECT 1 FROM dbo.XacNhanSan x WHERE x.MaDatSan=d.MaDatSan AND x.ThoiGianKetThuc IS NOT NULL) THEN 1 ELSE 0 END) DaSuDung
 FROM dbo.DatSan d;'');
EXEC(N''CREATE VIEW dbo.V_ThuChiThucNhan AS
 SELECT MaTT MaGiaoDich,MaDatSan,NgayThanhToan ThoiDiem,PhuongThuc,SoTien SoTienThucNhan,N''''Thu'''' Loai FROM dbo.ThanhToan WHERE TrangThai=N''''Thành công''''
 UNION ALL SELECT h.MaHT,t.MaDatSan,h.NgayXacNhan,h.PhuongThuc,-h.SoTienHoan,N''''Hoàn'''' FROM dbo.HoanTien h
 JOIN dbo.ThanhToan t ON t.MaTT=h.MaTT WHERE h.TrangThai=N''''Đã hoàn'''';'');
EXEC(N''CREATE VIEW dbo.V_ThuTienTheoNgay AS
 SELECT CAST(NgayThanhToan AS date) Ngay,PhuongThuc,COUNT(*) SoGiaoDich,SUM(SoTien) TongTien
 FROM dbo.ThanhToan WHERE TrangThai=N''''Thành công'''' GROUP BY CAST(NgayThanhToan AS date),PhuongThuc;'');
EXEC(N''CREATE FUNCTION dbo.fn_BookingNetCash(@Booking varchar(10)) RETURNS TABLE AS RETURN (SELECT ISNULL(SUM(SoTienThucNhan),0) net FROM dbo.V_ThuChiThucNhan WHERE MaDatSan=@Booking);'');
EXEC(N''CREATE PROCEDURE dbo.usp_ReportFinance @From date,@To date,@Pitch varchar(10)='''''''' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To=''''99991231'''' OR @Pitch IS NULL THROW 51010,''''Invalid report range or pitch'''',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) , rev AS (SELECT Ngay,SUM(TienSan) san,SUM(TienDichVu) dv,SUM(TienGiam) giam,SUM(DoanhThu) doanhThu FROM V_Phase6_Revenue WHERE Ngay>=@From AND Ngay<DATEADD(day,1,@To) AND (@Pitch='''''''' OR MaSan=@Pitch) GROUP BY Ngay), cash AS (SELECT CAST(v.ThoiDiem AS date) Ngay,SUM(CASE WHEN v.Loai=N''''Thu'''' THEN v.SoTienThucNhan ELSE 0 END) thu,SUM(CASE WHEN v.Loai=N''''Hoàn'''' THEN -v.SoTienThucNhan ELSE 0 END) hoan,SUM(v.SoTienThucNhan) net FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='''''''' OR d.MaSan=@Pitch) GROUP BY CAST(v.ThoiDiem AS date)) SELECT z.Ngay ngay,ISNULL(r.san,0) tienSan,ISNULL(r.dv,0) tienDichVu,ISNULL(r.giam,0) tienGiam,ISNULL(r.doanhThu,0) doanhThu,ISNULL(c.thu,0) tienThu,ISNULL(c.hoan,0) tienHoan,ISNULL(c.net,0) thucNhan FROM days z LEFT JOIN rev r ON r.Ngay=z.Ngay LEFT JOIN cash c ON c.Ngay=z.Ngay ORDER BY z.Ngay OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;'');
EXEC(N''CREATE PROCEDURE dbo.usp_ReportPaymentMethods @From date,@To date,@Pitch varchar(10)='''''''' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To=''''99991231'''' OR @Pitch IS NULL THROW 51010,''''Invalid report range or pitch'''',1;
 SELECT v.PhuongThuc phuongThuc,SUM(CASE WHEN v.Loai=N''''Thu'''' THEN 1 ELSE 0 END) soGiaoDich,SUM(CASE WHEN v.Loai=N''''Thu'''' THEN v.SoTienThucNhan ELSE 0 END) tienThu,SUM(CASE WHEN v.Loai=N''''Hoàn'''' THEN 1 ELSE 0 END) soGiaoDichHoan,SUM(CASE WHEN v.Loai=N''''Hoàn'''' THEN -v.SoTienThucNhan ELSE 0 END) tienHoan,SUM(v.SoTienThucNhan) thucNhan FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE v.ThoiDiem>=@From AND v.ThoiDiem<DATEADD(day,1,@To) AND (@Pitch='''''''' OR d.MaSan=@Pitch) GROUP BY v.PhuongThuc ORDER BY v.PhuongThuc;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;'');
EXEC(N''CREATE PROCEDURE dbo.usp_ReportTopServices @Day date AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @Day IS NULL OR @Day=''''99991231'''' THROW 51010,''''Invalid day'''',1;
 SELECT TOP(5) c.MaDV maDV,v.TenDV tenDV,SUM(c.SoLuong*c.SoDonViMoiQuyCach) soDonVi,SUM(c.ThanhTien) tienDichVu FROM ChiTietDichVu c JOIN DichVu v ON v.MaDV=c.MaDV JOIN V_Phase6_Revenue r ON r.MaDatSan=c.MaDatSan WHERE r.Ngay=@Day GROUP BY c.MaDV,v.TenDV ORDER BY SUM(c.SoLuong*c.SoDonViMoiQuyCach) DESC,c.MaDV;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;'');
EXEC(N''CREATE PROCEDURE dbo.usp_ReportUsage @From date,@To date,@Pitch varchar(10)='''''''' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To=''''99991231'''' OR @Pitch IS NULL THROW 51010,''''Invalid report range or pitch'''',1;
 WITH days AS (SELECT Ngay FROM dbo.fn_ReportDays(@From,@To)) SELECT z.Ngay ngay,s.MaSan maSan,s.TenSan tenSan,COUNT(u.MaDatSan) soBooking,ISNULL(SUM(u.DaSuDung),0) soDaSuDung,ISNULL(SUM(CASE WHEN u.TrangThai=N''''Đã hủy'''' THEN 1 ELSE 0 END),0) soDaHuy,ISNULL(SUM(u.PhutDat),0) phutDat,900 phutCongSuat,CAST(ISNULL(SUM(u.PhutDat),0)/60.0 AS decimal(18,2)) gioDat,CAST(ISNULL(SUM(u.PhutDat),0)*100.0/900 AS decimal(18,2)) tyLeLapDay FROM days z CROSS JOIN San s LEFT JOIN V_Phase6_UsageBooking u ON u.NgayChoi=z.Ngay AND u.MaSan=s.MaSan WHERE (@Pitch='''''''' OR s.MaSan=@Pitch) GROUP BY z.Ngay,s.MaSan,s.TenSan ORDER BY z.Ngay,s.MaSan OPTION(MAXRECURSION 366);
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;'');
EXEC(N''CREATE VIEW dbo.V_DoanhThuPhatSinhTheoNgay AS
 SELECT Ngay,COUNT(*) SoHoaDon,SUM(TienSan) TienSan,SUM(TienDichVu) TienDichVu,
 SUM(TienGiam) TienGiam,SUM(DoanhThu) DoanhThu FROM dbo.V_Phase6_Revenue GROUP BY Ngay;'');
EXEC(N''CREATE VIEW dbo.V_DoanhThuTheoNgay AS
 SELECT Ngay,PhuongThuc,SoGiaoDich,TongTien FROM dbo.V_ThuTienTheoNgay;'');
EXEC(N''CREATE VIEW dbo.V_KhungGioTrong AS
 SELECT MaSan,TenSan,TenLoaiSan,MaKhungGio,GioBatDau,GioKetThuc,NgayChoi
 FROM dbo.fn_KhungGioTrongTheoNgay(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE ''''SE Asia Standard Time''''));'');
EXEC(N''CREATE VIEW dbo.V_TyLeSuDungTheoNgay AS
 SELECT u.NgayChoi,COUNT(CASE WHEN u.TrangThai<>N''''Đã hủy'''' THEN 1 END) SoLuotDat,
 SUM(CONVERT(bigint,u.PhutDat)) PhutDat,
 (SELECT COUNT_BIG(*)*900 FROM dbo.San) PhutCongSuat,
 CAST(100.0*SUM(CONVERT(bigint,u.PhutDat))/NULLIF((SELECT COUNT_BIG(*)*900 FROM dbo.San),0) AS decimal(18,2)) TyLeLapDay
 FROM dbo.V_Phase6_UsageBooking u GROUP BY u.NgayChoi;'');
EXEC(N''CREATE PROCEDURE dbo.usp_ReportReconciliation @From date,@To date,@Pitch varchar(10)='''''''' AS
BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
 IF @From IS NULL OR @To IS NULL OR @To<@From OR DATEDIFF(day,@From,@To)>366 OR @To=''''99991231'''' OR @Pitch IS NULL THROW 51010,''''Invalid report range or pitch'''',1;
 SELECT d.MaDatSan maDatSan,s.TenSan tenSan,d.NgayChoi ngayChoi,d.TrangThai trangThai,h.MaHoaDon maHoaDon,h.DaChot daChot,d.TongTien tongBooking,h.TongTien tongHoaDon,h.DaThanhToan thuHoaDon,h.ConLai conLai,ISNULL(p.thu,0) tienThu,ISNULL(r.hoan,0) tienHoan,ISNULL(r.choHoan,0) choHoan,ISNULL(v.net,0) soThucNhan FROM DatSan d JOIN San s ON s.MaSan=d.MaSan LEFT JOIN HoaDon h ON h.MaDatSan=d.MaDatSan CROSS APPLY dbo.fn_BookingReceipts(d.MaDatSan) p CROSS APPLY dbo.fn_BookingRefunds(d.MaDatSan) r CROSS APPLY dbo.fn_BookingNetCash(d.MaDatSan) v WHERE d.NgayChoi>=@From AND d.NgayChoi<=@To AND (@Pitch='''''''' OR d.MaSan=@Pitch) ORDER BY d.NgayChoi,d.MaDatSan;
 END TRY
 BEGIN CATCH
 THROW;
 END CATCH;
END;'');
EXEC(N''CREATE VIEW dbo.V_TyLeLapDay AS
 SELECT NgayChoi,SoLuotDat,(SELECT COUNT(*) FROM dbo.San)*(SELECT COUNT(*) FROM dbo.KhungGio) TongKhungGio,
 TyLeLapDay,PhutDat,PhutCongSuat FROM dbo.V_TyLeSuDungTheoNgay;'');
EXEC sys.sp_addextendedproperty @name=N''SanBongEnvironment'',@value=N''test'';
COMMIT;
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK; THROW;
END CATCH;';
EXEC(@ddl);
PRINT 'New empty schema created; reference/demo data and private runtime user must be provisioned separately.';
