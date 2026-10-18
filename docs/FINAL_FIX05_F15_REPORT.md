# FINAL FIX05 — F15 application-level BCrypt guard

Ngày09/10/2026. **F15 NOT DONE — application guard đã sửa và compile/probe PASS; full regression và runtime bị chặn bởi cấu hình/quyền SQL SanBongApp.**

## Root cause, dependency và guard

Boot3.5.16/BOM Security6.5.11 giữ nguyên. Không override module, không commercial repository, không Boot4/Security7. Tree sau upgrade tại run/fix05/dependency-after.txt: Security crypto/core/web/config cùng6.5.11; Framework6.2.19, Hibernate6.6.53.Final, Tomcat10.1.55.

Raw BCrypt6.5.11 vẫn nhận prefix72+suffix ở matches; source/checksum và probe trước đã xác minh. [Source upstream](https://github.com/spring-projects/spring-security/blob/6.5.11/crypto/src/main/java/org/springframework/security/crypto/bcrypt/BCrypt.java) giới hạn password mới nhưng cho nhánh kiểm tra legacy đi qua hashpwforcheck. Không coi chỉ nâng version là đáp ứng strict-login requirement.

Theo phê duyệt mới, BoundedBcryptPasswordEncoder implements PasswordEncoder:

- matches raw>72byte UTF-8 trảfalse;
- input hợp lệ delegate BCryptPasswordEncoder(12);
- encode/upgradeEncoding delegate BCrypt;
- không trim/normalize/truncate/rehash/reset;
- không áp min10/denylist hồi tố khi login legacy;
- WRITE tiếp tục PasswordPolicy hiện có ở Service/DTO, InternalReadiness giữ nguyên.

SecurityConfig dùng bean này; không thay provider/filter/session/CSRF/role architecture.

## File sửa

1. backend/src/main/java/com/sanbong/security/BoundedBcryptPasswordEncoder.java — mới.
2. backend/src/main/java/com/sanbong/config/SecurityConfig.java — bean encoder.
3. backend/src/test/java/com/sanbong/BcryptSecurityRegressionTest.java — test encoder application, giữ suffix=false; thêm legacy weak hash và no trim/normalize.
4. backend/src/test/java/com/sanbong/SecurityUpgradeIntegrationTest.java — thêm required date vào request /bookings, giữ expected200.
5. docs/FINAL_FIX05_F15_REPORT.md — báo cáo này.

.gitignore và FINAL_PROJECT_CLEANUP_REPORT thuộc cleanup song song. Không sửa pom thêm, application F01–F04, frontend, schema, credentials hoặc baseline tests. Báo cáo trước guard lưu nguyên ở run/fix05/F15_PRE_CLEANUP_REPORT.md, gồm advisory review/version/status/sourcechecksum và kết quả full run trước.

## Verification thực hiện sau guard

| Probe application encoder | Kết quả |
|---|---|
| ASCII đúng72byte | true |
| Password sai | false |
| PrefixASCII72+suffix73 | false |
| Unicode đúng72byte | true |
| PrefixUnicode72+suffix75 | false |
| BCryptcost12 | true |

Probe **PASS**, dùng input tổng hợp, không truy vấn/reset user thật và không in password/hash. Bằng chứng run/cleanup/application-encoder-probe.txt. **Maven compile PASS** với Java21; run/cleanup/compile.log; build TEMP không ghi đè JAR chạy. Không nhầm compile/probe với full test PASS.

Full run trước guard:223test/218PASS/5FAIL/0error/0skip;212baselinePASS. Sau guard, suite dự kiến225 (212baseline+13F15), **chưa chạy**. Không báo các failure cũ đã được xác nhận hết chỉ nhờ đọc patch. Test legacy/no trim có trong source nhưng chưa chạy JUnit.

## Blocker SQL auth và runtime

Yêu cầu runtime/test cần SanBongApp cho QuanLySanBong DEV. Inventory private files không có cấu hình credentials identity đó: .env dùngsa, file khác SanBongAppPhase7. SQL READ xác nhận server DEV Fix04 PID32112 thực tế đang có SQL sessions login **sa**, databaseQuanLySanBong. Không tự đổi user rồi giữ passwordsa, không đoán credential, không dùngfileinternal hoặc stale.

SanBongApp SQL_LOGIN enabled, sysadmin0/db_owner0; DEV user hiện thuộc db_datareader/db_datawriter. Thiếu EXECUTE fn_TyLeHoan (permission0) và có DELETE audit (permission1). Chưa GRANT/DENY hoặc chỉnh login/password/role. Cần owner xác nhận file cấu hình riêng và quyền runtime đúng; chỉ cung cấp đường dẫn, không password qua chat.

Vì vậy chưa chạy full Maven bằngsa/identity khác, chưa package/release hoặc restart8082 bằng credential không đúng. DEV Fix04 cũ8082 healthUP không chứng minh guard mới; internal19168:8080 không restart/deploy/write, internalDB không đụng. Không migration/reset/cleanup/fixtureDB trong lượt này.

## CVE và carry-over

6.5.11 vượt mốc vá chính thức [headers2026-22732](https://spring.io/security/cve-2026-22732/)6.5.9 và [enumeration2026-22746](https://spring.io/security/cve-2026-22746/)6.5.10. [BCrypt2025-22228](https://spring.io/security/cve-2025-22228/) không liệt kê6.5.11, nhưng behavior strictmatches vẫn cần application guard như probe chứng minh. Không tuyên bố thư viện upstream đổi behavior hoặc mọidependency hếtCVE. Advisory review không áp dụng do khôngOAuth2/SAML/WebFlux/WebAuthn/LDAP/AES/Password4j được giữ trong báo cáo lịch sử; không thêm các tính năng đó.

F16/F21/BA01–BA05 không sửa. Existing hashes chưa reset/rehash; legacy compatibility sau guard cần fullJUnit/HTTP thật. Raw-library probe true và guarded-application probe false được phân biệt rõ.

## Release gate

Release JAR mới/SHA256: **N/A**. Cần credentialsSanBongApp và quyền fn_TyLeHoan trước full225tests; chỉ sau allPASS mới DEV8082 startup/Hikari/JDBC/validate/health/login/logout/session/CSRF/bốnrole/HTTPsuffix. Sau runtimePASS mới release/hash/F15DONE, không deployinternal.

**NOT READY — cấu hình SanBongApp chưa được xác nhận; thiếu EXECUTE fn_TyLeHoan; full regression và DEV runtime sau guard chưa chạy. F15 NOT DONE.**