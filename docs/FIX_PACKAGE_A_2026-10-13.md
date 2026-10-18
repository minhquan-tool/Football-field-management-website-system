# Gói A — Guard SQL và toolchain build (13/10/2026)

## Thay đổi

- 9 script `backend/scripts/cleanup-*-test.sql` và `prepare-*-test.sql`: bỏ `USE` ngầm ở bốn script; thêm `:ON ERROR EXIT` và opt-in `SAN_BONG_TEST_MODE=dev/test` trước kiểm marker database hiện được chọn. Caller chọn DB bằng `sqlcmd -d`, giữ marker/history/ID checks cũ. Không chạy SQL trong lượt sửa.
- `backend/pom.xml`: khai báo annotationProcessorPaths cho Lombok hiện có, giữ version BOM và Java21; không thêm framework/dependency runtime.
- `scripts/java-toolchain.ps1` (mới), `backend/manage-backend.ps1`, `scripts/server.ps1`: kiểm Java21 trước build/start; pin JAVA_HOME tới installation được kiểm. Restart kiểm Java/JAR trước dừng server cũ. Stop riêng không cần Java21.
- `backend/scripts/fixture-sql-safety-check.mjs` và `java-toolchain-check.ps1` (mới): policy regression không dùng database.
- `backend/README.md`: cập nhật version, guard, opt-in SQL và phân biệt mô tả phase lịch sử.

## Kiểm tra

- Regression SQL trước fix FAIL tại `cleanup-phase3-test.sql` do USE sau guard; sau fix PASS cả9script. Đây là source-policy regression, chưa phải thực thi SQL trên target test/internal.
- Java version policy PASS; guard gọi JDK24 thật từ chối đúng. Parser launcher PowerShell PASS. Java21 chưa tìm thấy ở vị trí cài tiêu chuẩn đã kiểm; chưa chứng nhận máy đã có môi trường Java21.
- Maven offline trên bản sao source, **không dùng** `maven.compiler.proc=full` workaround: compile83main+20test/support và14unit BCrypt/PasswordPolicy PASS,0failure/error/skipped. Host chạy test vẫnJDK24; đây là kiểm chứng processor fix, không thay build/runtime qualification Java21. Log: `run/fix-package-a-20261013/maven-unit.log`.

## Giới hạn và bước tiếp theo

Chưa chạy full DB regression, chưa xác minh lại quyền SQL/runtime config, chưa tạo release/deploy/restart, chưa áp migration hoặc đổi tài khoản/mật khẩu. Full qualification cần JDK21 và private config DEV/test đúng identity/quyền/marker. Không dùng `.env` bằngsa để ghi PASS dưới identity khác.

Gói sửa source/policy đã có kiểm chứng độc lập; nghiệm thu DB/Java21 runtime còn chờ môi trường. Tiếp tục gói UI tài chính R04/R05 độc lập, giữ kiến trúc và API.
