# Bảo mật và phân quyền

Bộ cài tạo 4 role SB_Customer/SB_PitchStaff/SB_Accountant/SB_Manager và user WITHOUT LOGIN để EXECUTE AS khi báo cáo.
SanBongRuntime là role kết nối backend: SELECT nghiệp vụ, ghi theo từng bảng, EXECUTE báo cáo và fn_TyLeHoan; cấm sửa/xóa nhật ký.
Các user demo SQL không phải tài khoản đăng nhập web; quyền VT01..VT04 của web vẫn kiểm tra tại backend.
DBA tạo SQL login riêng bằng SSMS, không dùng sa/sysadmin. Sửa tên database/login trong provision-runtime-user.sql rồi chạy cả file trong đúng DB.
Giữ mật khẩu trong .env riêng, không ghi vào SQL/Git. Không thay login/mật khẩu đang dùng.
Quyền server khác như CREATE DATABASE, BACKUP/RESTORE chỉ dành cho DBA, không cấp cho runtime.
