# FINAL PROJECT CLEANUP + NEXT PHASE AUDIT

Ngày: 09/10/2026. Phạm vi: inventory/secret/config/quyền SQL, cleanup có kiểm soát và guard application F15. **Chưa tạo release hoặc deploy internal.**

## Inventory và cleanup

Quét toàn bộ file/folder project trước thay đổi; manifest file-level: `run/cleanup/inventory.csv`. Phân loại là quyết định giữ/review, không đồng nghĩa đã di chuyển/xóa file. Snapshot ban đầu: KEEP216, ARCHIVE181, SAFE_DELETE96, REVIEW79, SECRET_RISK4; sau review backend/manage-backend.ps1 chuyển KEEP. Số này thuộc thời điểm scan, không phải tổng file sau khi tạo báo cáo/artifacts mới.

| Nhóm | Quyết định |
|---|---|
| KEEP | backend/src gồm tests; pom; html; database/schema/migrations; scripts và backend/manage-backend.ps1; application.yml; AGENTS; .gitignore; skill/CI; docs; example configs; toàn bộ releases để rollback; toàn bộ run/fix05 |
| ARCHIVE | run lịch sử, Playwright screenshots/console/network và probes ngoài F15; giữ nguyên vị trí, chưa archive vật lý |
| SAFE_DELETE | backend/target generated output được đề xuất; chưa xóa vì tool rejection |
| REVIEW_BEFORE_DELETE | IDE metadata .vscode, log lịch sử chưa chứng minh disposable, file hỗ trợ chưa rõ; không xóa |
| SECRET_RISK | .env, .env.runtime.local, .env.lan-rehearsal.local, deploy.env; không xuất giá trị, không xóa hoặc đổi password |
| DANGEROUS_DO_NOT_TOUCH | Bất kỳ database backup/mdf/ldf/trn nếu phát hiện; không thấy file loại này trong inventory project. Không quét/xóa backup ngoài project hoặc TEMP lịch sử |

**Files deleted: 0.** Không xóa source/tests/reports/JAR/config/database scripts. Công cụ từ chối lệnh Remove-Item cho backend/target với thông báo **blocked by policy**; không thử lách bằng shell khác. Target được giữ để owner xử lý thủ công. Không xóa logs đang chạy hoặc bằng chứng F15. Không tìm thấy nhóm docs trùng byte-for-byte (`duplicate-docs.txt`); điều này không chứng minh nội dung tài liệu không trùng về ý nghĩa.

## Secret / database config audit

Quét references password/APP_DB_PASSWORD/DB_PASSWORD/spring.datasource.password/integratedSecurity/authenticationScheme/SanBongApp/JDBC/database names, chỉ lưu file + line + loại, không lưu matching values: `run/cleanup/secret-reference-audit.csv`. Binary JAR không được coi là đã scan text toàn diện.

Private secret assignments (giá trị REDACTED): `.env:2`, `.env.runtime.local:3`, `.env.lan-rehearsal.local:3`, `deploy.env:6`. Đây là cấu hình riêng cần ACL/quản lý secret, không được đưa lên Git/báo cáo chia sẻ. `.env.example` dùng placeholder, được giữ. Log/test artifacts có thể chứa DTO/password fixture do MockMvc failure dumps; giữ riêng và review/redact trước chia sẻ, không tự coi là disposable hoặc không nhạy cảm.

Application.yml giữ đúng:

```yaml
url: ${APP_DB_URL:jdbc:sqlserver://localhost:1433;databaseName=QuanLySanBong;encrypt=false;trustServerCertificate=true}
username: ${APP_DB_USER}
password: ${APP_DB_PASSWORD}
ddl-auto: validate
```

Không đưa secret vào application source/frontend. Không thay config bằng Windows Integrated Authentication. .gitignore bổ sung `.env.*`, `*.local`, `target/`, exceptions `.env.example`/`.env.*.example`/deploy.env.example; .env/deploy.env/logs/backend target/run/releases vẫn ignore. Không có Git repository để khẳng định secret đã được gỡ khỏi history/tracked files; ignore không tự xóa dữ liệu đã từng commit.

## SQL authentication và quyền runtime — BLOCKER

SQL READ admin bằng Windows Authentication (được phép, không phải application datasource):

- `SanBongApp` tồn tại, enabled, type SQL_LOGIN, sysadmin0, db_owner0.
- Trong DEV QuanLySanBong, user SanBongApp có db_datareader/db_datawriter.
- `HAS_PERMS_BY_NAME(fn_TyLeHoan, OBJECT, EXECUTE)` dưới EXECUTE AS USER SanBongApp = **0**: thiếu quyền hàm FinanceRepository thực sự gọi.
- Quyền DELETE NhatKyHeThong = **1** do db_datawriter: rộng hơn runtime role least-privilege hiện có.
- Không GRANT/DENY/drop/alter login/password/role hoặc schema trong lượt này. Không đụng internal DB.

Cấu hình private hiện có không khớp yêu cầu mới: `.env` dùng **sa**; deploy.env và .env.lan-rehearsal.local dùng SanBongAppPhase7/internal; .env.runtime.local dùng SanBongAppPhase7 và đã có ghi nhận stale credential. Không dùng các file này để chạy DEV mới dưới identity sai. Đã yêu cầu owner cung cấp **đường dẫn file cấu hình riêng chứa credentials SanBongApp**, không yêu cầu gửi password qua chat.

Windows auth references còn trong SQL verification/cleanup admin scripts gọi sqlcmd -E: run/fix02, fix03, fix04/http-check.mjs; backend/scripts/phase5-1c, phase6, phase7 HTTP-check scripts. Đây là admin-side SQL verification; datasource Java dùng username/password môi trường. Không xóa admin Windows login hoặc disable Windows auth.

Trước bước F/G, cần xác nhận private credentials SanBongApp và quyền runtime phù hợp; không tự sửa SQL login để lấy quyền. Không đưa password sa sang SanBongApp, không đoán/brute-force credential.

## F15 application guard

Boot3.5.16/Security6.5.11 BOM giữ nguyên, không override modules. Thêm BoundedBcryptPasswordEncoder: matches quá72byte UTF-8 trảfalse; input hợp lệ delegate BCryptcost12. Không trim/normalize/truncate/rehash/reset, không áp min10/denylist vào login legacy. Registration/reset WRITE vẫn PasswordPolicy cũ. Bean SecurityConfig dùng encoder mới; kiến trúc session/CSRF/role không đổi.

Sửa request customer test mới bằng date hợp lệ, giữ assertion200. Unit F15 chuyển sang encoder application được phê duyệt, giữ assertion suffix=false; không sửa/xóa baseline tests. Thêm kiểm tra legacy hash yếu vẫn matches và không trim/normalize.

Probe offline application encoder **PASS**: ASCII72true, wrongfalse, ASCII73suffixfalse, Unicode72true, Unicode75suffixfalse, cost12true (`application-encoder-probe.txt`). Raw BCrypt6.5.11 vẫn có truncation lịch sử theo báo cáo F15; guard không được mô tả là đã sửa thư viện upstream.

## Build/tests/runtime/release

- Maven **compile PASS**, không thêm dependency, build TEMP riêng; `compile.log`. Đây không phải clean verify.
- **Full tests sau guard: chưa chạy** vì chưa có cấu hình SanBongApp hợp lệ và quyền EXECUTE hàm thiếu. Không chạy full bằng sa/identity khác để ghi PASS trái yêu cầu.
- Baseline lịch sử212PASS; run trước guard223tests/218PASS/5FAIL. Các con số cũ không được dùng chứng nhận guard mới.
- Expected suite sau thêm2case:225 (212baseline+13F15); **chưa có tổng PASS/FAIL mới**.
- Chưa startup JAR DEV mới hoặc verify HTTP suffix/bốnrole dưới SanBongApp. Server Fix04 cũ8082 được giữ nguyên; healthUP của bản cũ không chứng minh patch mới.
- Port8080 internal không stop/restart/deploy. Không tạo DB fixture/cleanup trong lượt này.
- Release JAR mới: **không có**; SHA256 mới: **N/A**. F15 **NOT DONE**.

## File thay đổi

`.gitignore`; backend/src/main/java/com/sanbong/security/BoundedBcryptPasswordEncoder.java (mới); config/SecurityConfig.java; tests/BcryptSecurityRegressionTest.java; tests/SecurityUpgradeIntegrationTest.java; hai report FINAL_PROJECT_CLEANUP_REPORT và FINAL_FIX05_F15_REPORT. Artifacts inventory/compile/probe ở run/cleanup, report F15 trước lượt này được giữ tại run/fix05/F15_PRE_CLEANUP_REPORT.md. Không sửa F01–F04, UI, pom, migration hay credentials.

## Next phase gate

1. Owner xác nhận file credentials DEV SanBongApp và quyền fn_TyLeHoan/least privilege; chốt identity/admin fixture cleanup phù hợp, không dùng runtime để sửa internal.
2. Full Maven225tests (không skip), dừng nếu failure.
3. Chỉ sau PASS mới package candidate/test trên8082 bằng SanBongApp, xác minh health/Hikari/validate/HTTP suffix/bốnrole; chỉ thay đúng process DEV đã xác minh, giữ internal8080.
4. Chỉ sau runtime PASS mới release/hash/F15 DONE. Target cleanup bị tool chặn cần owner xử lý riêng.

**NOT READY — chưa có cấu hình DEV SanBongApp được xác nhận; SanBongApp thiếu EXECUTE fn_TyLeHoan; full regression và DEV runtime sau guard chưa chạy.**
