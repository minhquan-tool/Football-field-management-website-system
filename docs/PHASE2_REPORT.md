# Phase 2 — Authentication, Login, Role/Permission

Định hướng Web App nội bộ đã ghi tại AGENTS.md. Giữ Phase 1, stack, schema,
JDBC trực tiếp và ddl-auto=validate. Chưa triển khai LAN hoặc Phase 3.

## Kết quả

- BCrypt cost 12 cho 4 tài khoản mẫu, đăng ký mới luôn hash. Migration có
  transaction, opt-in và đã tắt sau khi chạy. Seed mẫu không lưu plaintext.
- Session cookie HttpOnly/SameSite=Lax, timeout 30 phút, CSRF cho login/logout
  và request ghi dữ liệu; session ID đổi sau đăng nhập.
- Đăng nhập username/email/phone, profile thật và logout; bốn role được kiểm tra
  tại backend. Request đang mở được cập nhật quyền/status từ DB.
- REST danh sách tài khoản, đọc/lưu quyền theo role, validation và transaction.
  Chặn thao tác không đủ quyền, giữ quyền quản trị tối thiểu để tránh tự khóa.
- 18 dòng quyền ban đầu được thêm vào bảng đang rỗng; không thay schema/reset DB.
- Nhật ký vào bảng hiện có cho login/logout/đăng ký/thay quyền; không log mật khẩu.
- Credentials chuyển từ YAML sang môi trường. .env local bị gitignore và không
  nằm trong JAR; .env.example chỉ có placeholder. Bỏ JWT secret chưa sử dụng.
- HTML đóng gói vào JAR, URL API tương đối theo context; UI/CSS giữ phong cách cũ.
  Chỉ thêm chọn role/logout cần cho chức năng. Disable nghiệp vụ demo chưa có API.

## Kiểm chứng

Maven 3.9.9/JDK 21: clean verify BUILD SUCCESS, 8 tests, 0 failures/errors.
Giữ test Phase 1 đọc 8 entity; test authentication dùng transaction rollback.
Kiểm tra 4 role, sai password, account khóa và phiên bị thu hồi, CSRF, logout,
đăng ký/hash/duplicate, validation và lưu quyền/hiệu lực trên phiên đang mở.
JAR khởi động với Hibernate validation thành công và JDBC TCP trực tiếp.
HTTP check kiểm tra server thật, cookie/session fixation, CSRF, tài khoản thật,
trang phân quyền và logout. Các request login/logout thật có lưu nhật ký.

## File thay đổi/thêm

- Gốc: AGENTS.md, .gitignore, .env.example; .env local (không commit).
- Data: security-permissions.sql (thêm), seed-data.sql (BCrypt sample).
- Backend: pom.xml (resources HTML), src/main/resources/application.yml,
  backend.ps1, README.md, scripts/phase2-http-check.mjs.
- model/TaiKhoan.java: không serialize/log password.
- config: AccountPrincipal.java, SecurityConfig.java, SessionAccountFilter.java,
  LegacyPasswordMigration.java.
- controller: AuthController.java, PermissionController.java, HomeController.java,
  ApiExceptionHandler.java.
- service: AuthService.java, PermissionService.java.
- repository: TaiKhoanRepository.java, KhachHangRepository.java,
  VaiTroRepository.java, SecurityRepository.java.
- dto: ApiResponse.java, RegisterRequest.java, PermissionRequest.java.
- test: AuthenticationTest.java (thêm), SqlServerConnectionTest.java (port linh hoạt).
- frontend/js: auth.js, permissions.js (thêm).
- 13 trang HTML: Dang_nhap.html, Dang_ky.html, Dat_san_tai_quay.html,
  Man_hinh_chinh.html, Man_hinh_chinh_KH.html, Man_hinh_chinh_Dat_san_KH.html,
  Man_hinh_chinh_NVKH.html, Man_hinh_chinh_NVKT.html,
  Man_hinh_chinh_TK&PQ_HT.html, Man_hinh_Khuyen_mai_KH.html,
  Man_hinh_LS&ĐG_KH.html, Quan_ly_lich_dat_san.html, Quan_ly_san.html.
  Login/register dùng API; còn lại gắn script phiên/logout/profile/navigation.

## Giới hạn và công việc sau

Không có trình duyệt kết nối để kiểm tra ảnh render; đã kiểm tra cú pháp JS,
trang HTTP thực và test backend. Không còn lỗi build/startup/test được phát hiện.
Các dashboard nghiệp vụ vẫn là mẫu, không phải báo cáo dữ liệu thật.
Chưa có UI thêm/sửa/khóa tài khoản, đổi/quên password hoặc persistent login.
Password mẫu yếu phải đổi trước triển khai. Cần đánh giá HTTPS/cookie Secure,
quyền DB và chính sách tài khoản khi đến phase triển khai; chưa mở LAN.
SqlProxy.cs/SqlProxy.exe giữ nguyên và không được dùng.
Dừng tại Phase 2, báo cáo trước khi bắt đầu Phase 3.
