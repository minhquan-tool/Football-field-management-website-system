-- ============================================================================
-- MODULE 07: BẢO MẬT & PHÂN QUYỀN TRÊN SQL SERVER (DATABASE ROLES & PERMISSIONS)
-- Áp dụng cho: QuanLySanBong
-- Mục tiêu Rubric: Tối thiểu 4 Role/Login, cơ chế GRANT / DENY / REVOKE
-- ============================================================================

USE [QuanLySanBong];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- 1. TẠO 4 DATABASE ROLES (Nếu chưa tồn tại)
-- ----------------------------------------------------------------------------
IF DATABASE_PRINCIPAL_ID(N'SB_Customer') IS NULL
    CREATE ROLE [SB_Customer];
GO

IF DATABASE_PRINCIPAL_ID(N'SB_PitchStaff') IS NULL
    CREATE ROLE [SB_PitchStaff];
GO

IF DATABASE_PRINCIPAL_ID(N'SB_Accountant') IS NULL
    CREATE ROLE [SB_Accountant];
GO

IF DATABASE_PRINCIPAL_ID(N'SB_Manager') IS NULL
    CREATE ROLE [SB_Manager];
GO

-- ----------------------------------------------------------------------------
-- 2. TẠO CÁC USER DEMO (WITHOUT LOGIN) ĐỂ PHỤC VỤ KIỂM THỬ IMPERSONATE TRÊN SSMS
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SB_DemoCustomer')
BEGIN
    CREATE USER [SB_DemoCustomer] WITHOUT LOGIN;
    ALTER ROLE [SB_Customer] ADD MEMBER [SB_DemoCustomer];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SB_DemoPitchStaff')
BEGIN
    CREATE USER [SB_DemoPitchStaff] WITHOUT LOGIN;
    ALTER ROLE [SB_PitchStaff] ADD MEMBER [SB_DemoPitchStaff];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SB_DemoAccountant')
BEGIN
    CREATE USER [SB_DemoAccountant] WITHOUT LOGIN;
    ALTER ROLE [SB_Accountant] ADD MEMBER [SB_DemoAccountant];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SB_DemoManager')
BEGIN
    CREATE USER [SB_DemoManager] WITHOUT LOGIN;
    ALTER ROLE [SB_Manager] ADD MEMBER [SB_DemoManager];
END
GO

-- ----------------------------------------------------------------------------
-- 3. PHÂN BỔ QUYỀN HẠN CHI TIẾT (GRANT / DENY) CHO 4 ROLES
-- ----------------------------------------------------------------------------

-- [A] ROLE: SB_Customer (Khách hàng)
-- Quyền: Xem danh mục sân bãi, dịch vụ; cấm xem tài khoản, thanh toán người khác
GRANT SELECT ON dbo.[San] TO [SB_Customer];
GRANT SELECT ON dbo.[LoaiSan] TO [SB_Customer];
GRANT SELECT ON dbo.[DichVu] TO [SB_Customer];
DENY SELECT ON dbo.[TaiKhoan] TO [SB_Customer];
DENY SELECT ON dbo.[ThanhToan] TO [SB_Customer];
GO

-- [B] ROLE: SB_PitchStaff (Nhân viên sân bãi - Phân hệ Võ Minh Quân)
-- Quyền: Xem sân bãi, dịch vụ, chạy báo cáo khai thác sân; cấm xem báo cáo tài chính/doanh thu
GRANT SELECT ON dbo.[San] TO [SB_PitchStaff];
GRANT SELECT ON dbo.[LoaiSan] TO [SB_PitchStaff];
GRANT SELECT ON dbo.[DichVu] TO [SB_PitchStaff];
GRANT EXECUTE ON dbo.[usp_ReportUsage] TO [SB_PitchStaff];
DENY EXECUTE ON dbo.[usp_ReportFinance] TO [SB_PitchStaff];
GO

-- [C] ROLE: SB_Accountant (Kế toán - Phân hệ Võ Văn Gia Hưng)
-- Quyền: Xem view thu chi, thực thi các thủ tục và hàm tài chính, hoàn tiền, đối soát
GRANT SELECT ON dbo.[V_ThuChiThucNhan] TO [SB_Accountant];
GRANT EXECUTE ON dbo.[usp_ReportFinance] TO [SB_Accountant];
GRANT EXECUTE ON dbo.[usp_ReportPaymentMethods] TO [SB_Accountant];
GRANT EXECUTE ON dbo.[usp_ReportReconciliation] TO [SB_Accountant];
GRANT EXECUTE ON dbo.[usp_ReportTopServices] TO [SB_Accountant];
GRANT EXECUTE ON dbo.[fn_TyLeHoan] TO [SB_Accountant];
GO

-- [D] ROLE: SB_Manager (Quản lý - Phân hệ Phan Tiến Đạt & Phạm Phúc Hưng)
-- Quyền: Quản lý sân, chạy toàn bộ báo cáo, kiểm tra audit log; cấm sửa/xóa log và cấm xóa thanh toán
GRANT SELECT, INSERT, UPDATE ON dbo.[San] TO [SB_Manager];
GRANT SELECT ON dbo.[NhatKyHeThong] TO [SB_Manager];
DENY UPDATE, DELETE ON dbo.[NhatKyHeThong] TO [SB_Manager];
DENY DELETE ON dbo.[ThanhToan] TO [SB_Manager];
GRANT EXECUTE ON dbo.[usp_ReportUsage] TO [SB_Manager];
GRANT EXECUTE ON dbo.[usp_ReportFinance] TO [SB_Manager];
GRANT EXECUTE ON dbo.[usp_ReportPaymentMethods] TO [SB_Manager];
GRANT EXECUTE ON dbo.[usp_ReportReconciliation] TO [SB_Manager];
GRANT EXECUTE ON dbo.[usp_ReportTopServices] TO [SB_Manager];
GO
