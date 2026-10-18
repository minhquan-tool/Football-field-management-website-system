# FINAL FIX 01 — F02 Password policy alignment

Ngày: 08/10/2026. Phạm vi duy nhất: F02 trong FINAL_SYSTEM_AUDIT.md. **Đã sửa và kiểm chứng trên DEV; chưa deploy/restart server internal.**

## Root cause và phạm vi audit

Startup internal có denylist riêng, trong khi đăng ký chỉ kiểm tra độ dài/byte; admin create/reset cũng có kiểm tra byte riêng. API có thể chấp nhận password mà guard startup từ chối. Regression trước patch chạy 11 case, 4 FAIL: ba case password bị nhận sai và một case phát hiện DTO hiện password trong log debug.

Đã rà toàn bộ `encoder.encode`, `setMatKhau`, SQL INSERT/UPDATE MatKhau và controller/service liên quan:

| Luồng | Sau sửa |
|---|---|
| POST /auth/register | Policy trước kiểm tra/ghi khách hàng và tài khoản |
| POST /admin/accounts | Policy trước lock/query/write; giữ role/permission |
| POST /admin/accounts/{id}/reset-password | Policy trước lock/query/write; giữ revoke session |
| Quản lý nhân viên, đổi trạng thái/role | Không ghi password; không thêm password write mới |
| Migration legacy opt-in | Chỉ encode plaintext đạt policy; password không đạt làm migration dừng/rollback; hash BCrypt có sẵn được giữ nguyên |
| Password change/self-service reset khác | Không tìm thấy endpoint hiện có |

Không chạy migration legacy hoặc reset bất kỳ password người dùng hiện có. Test reset chỉ dùng tài khoản fixture DEV, transaction rollback.

## Policy chung

`com.sanbong.security.PasswordPolicy` là nguồn chung:

- Không null/blank; ít nhất **10 ký tự**.
- Tối đa **72 byte UTF-8**, không nhầm số ký tự với số byte.
- Không tự trim/normalize password.
- Chặn đúng denylist startup hiện có: `123456`, `12345678`, `admin`, `password`, `demo123`.
- DTO sử dụng constants độ dài từ policy; Service luôn enforce policy, kể cả gọi không qua DTO validation.
- InternalReadiness dùng cùng format BCrypt và cùng denylist; mọi guard environment/validate/debug/privilege vẫn giữ nguyên.
- Hash không thể suy ra độ dài plaintext lịch sử: startup vẫn kiểm tra format/denylist như trước, không tự reset hoặc áp hồi tố min10 lên password hiện có.

BCrypt cost12, session/CSRF/authorization và dependencies giữ nguyên. Password sai trả HTTP400 thông qua validation/ApiExceptionHandler hiện có, thông báo không chứa input/hash/stack trace. DTO password được override toString để không in credentials khi framework log request object. Frontend chỉ cập nhật rule đăng ký và tooltip reset/create, không đổi layout/CSS.

## File đã sửa/tạo

1. `backend/src/main/java/com/sanbong/security/PasswordPolicy.java` — mới, policy write/startup chung.
2. `backend/src/main/java/com/sanbong/service/AuthService.java` — register/migration dùng policy.
3. `backend/src/main/java/com/sanbong/service/AdminService.java` — create/reset dùng policy, bỏ helper byte riêng.
4. `backend/src/main/java/com/sanbong/config/InternalReadiness.java` — dùng shared hash/denylist check; không bỏ guard.
5. `backend/src/main/java/com/sanbong/dto/RegisterRequest.java` — shared constants, redacted toString.
6. `backend/src/main/java/com/sanbong/dto/StaffAccountRequest.java` — shared constants, redacted toString.
7. `backend/src/main/java/com/sanbong/dto/PasswordResetRequest.java` — shared constants, redacted toString.
8. `frontend/Dang_ky.html` — min10/max72, thông tin giới hạn byte.
9. `frontend/Man_hinh_chinh_TK&PQ_HT.html` — tooltip password rule.
10. `backend/src/test/java/com/sanbong/PasswordPolicyIntegrationTest.java` — mới, 11 case.
11. `backend/src/test/java/com/sanbong/PasswordPolicyTest.java` — mới, 8 case.
12. `docs/FINAL_FIX01_F02_REPORT.md` — báo cáo này.

Source booking/finance/database/pom và tất cả test cũ không thay đổi. Artifact kiểm tra ở `run/fix01/` và build TEMP; JAR release ở `releases/`, đều không chứa cấu hình môi trường riêng.

## Build/test/HTTP

**Maven clean verify: PASS 166/166, 0 failure, 0 error, 0 skipped.** Gồm 147 test cũ + 19 test mới. Build thành công trong 3m22s. Một lần compile trung gian lỗi helper byte cũ còn sót đã được sửa; kết quả trên là build đầy đủ cuối cùng, không skip/xóa test.

Tests mới kiểm tra:

- Valid password được lưu BCrypt, matches đúng, qua InternalReadiness với identity/marker internal hợp lệ được mock; không khởi động app vào internal thật.
- Password ngắn/denylist trả400; registration không tạo TaiKhoan/KhachHang.
- Admin create denylist không tạo account; reset denylist không đổi hash fixture.
- API không trả password/hash; password/hash không có trong CapturedOutput application log và audit rows của các thao tác fixture.
- Boundary min10; ASCII72/73 byte; Unicode72/75 byte; 72 byte hợp lệ được hash, >72 từ chối.
- Tất cả denylist bị cả write policy và startup từ chối.
- Migration không encode plaintext bị cấm; không rehash/reset BCrypt hiện có.

HTTP thật trên JAR mới, profile dev, cổng loopback8082, DB `QuanLySanBong` có marker dev. Preflight `/admin/test-safety` xác nhận fixture allowed và đúng DB trước tạo dữ liệu:

| Bước | HTTP |
|---|---|
| Register denylist | 400 |
| Register hợp lệ | 200 |
| Login tài khoản mới | 200 |
| GET /auth/me, role VT01 | 200 |
| Logout | 200 |
| GET /auth/me sau logout | 401 |

Startup JAR14,647s, JDBC/schema validation thành công, healthUP. SQL xác nhận fixture BCrypt cost12; cleanup dùng exact username/phone/name, dependency check, marker dev/test và transaction. Không fixture/cleanup trên internal. Fingerprint toàn bộ TaiKhoan và DatSan internal trước/sau giống nhau; server internal19168/cổng8080 vẫn healthUP. Instance test riêng được dừng sau xác minh.

Bằng chứng: `run/fix01/red.log`, `verify.log`, `http.log`, `http-result.json`, `startup.log`, `cleanup-dev-result.txt`, `internal-before.txt`, `internal-after.txt`. Không chia sẻ raw logs/config riêng.

## JAR và deploy thủ công

JAR đã build sau test PASS: `releases/san-bong-fix01-f02-20261008.jar`.

SHA256: `FD7FBEECC31C92AE62B23DEFFFEC08392F890EA51C142A6F2949A51C0F26FDF5`.

**Không DB migration. Không tự deploy.** Chủ hệ thống chọn cửa sổ bảo trì, xác nhận backup/current release và file env internal đúng, giữ artifact cũ để rollback. F21 còn tồn tại: không dùng lại `.env.runtime.local` stale trước khi xác nhận credentials; không đổi SQL login để né lỗi config.

Trong file env riêng đã xác nhận, đặt `APP_JAR=releases/san-bong-fix01-f02-20261008.jar`; giữ `APP_ENV=internal`, URL/identity SQL đúng, ddl-auto validate, no debug/no legacy migration. Dừng đúng process/service đang phục vụ sau xác nhận quyền sở hữu, rồi chạy start-server theo INTERNAL_DEPLOYMENT_GUIDE với file env đó. Không dùng PID file cũ để dừng process chưa xác minh. Restart sẽ làm session in-memory hiện có hết hiệu lực; thông báo nhân viên đăng nhập lại. Sau start: healthUP, Hibernate validate, login/GET authenticated, password invalid400. Nếu thất bại, xem log riêng và rollback artifact/env đã xác nhận; không reset DB hay bỏ guard.

## Carry-over và regression risk

- **F15 chưa sửa:** không nâng Spring/Spring Security/BCrypt. Library72-byte suffix behavior ở login vẫn cần review bản vá riêng; WRITE giới hạn byte không được coi là đã vá CVE.
- **F16 chưa sửa:** HTTPS/Secure cookie/CSP/network acceptance còn theo audit.
- **F21 chưa sửa:** private runtime env stale cần owner xác nhận; SQL runtime login không bị thay đổi.
- **F01/F03/F04 chưa sửa**, không mở phase hay sửa nghiệp vụ ngoài F02.

Rủi ro thay đổi LOW/MEDIUM: customer signup min8→10 và max64 ký tự→72 byte; người dùng phải theo rule mới. Admin min10 giữ nguyên. Legacy migration opt-in nay từ chối plaintext yếu thay vì hash rồi bị internal startup chặn; mặc định vẫn tắt. Password đã lưu/login cũ không bị thay đổi. Guard không bị làm yếu; toàn bộ regression cũ PASS.

**F02 hoàn thành ở source/JAR đã kiểm thử; server internal đang chạy chưa nhận bản sửa. DỪNG, không tự chuyển F01/F03/F04.**
