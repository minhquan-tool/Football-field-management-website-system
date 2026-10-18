# Chuẩn bị môi trường kiểm thử San_Bong

## Hai loại suite sau hardening mức trung bình

- `backend/run-verification.ps1 -Suite runtime -EnvFile .\.env.test.local`: các test rollback dùng SanBongApp đã whitelist, không cấp quyền xóa audit cho test. Lệnh manage-backend build mặc định chọn suite này.
- `backend/run-verification.ps1 -Suite fixtures -EnvFile .\.env.fixture.local`: các test commit/concurrency, chỉ dùng database/login fixture riêng. Cần marker dev/test và SanBongFixtureDatabase=1. Profile private đã tạo có ACL hạn chế; không dùng nó vận hành web chính.
- `scripts/prepare-disposable-fixtures.ps1` tạo bản copy từ backup đã review với database/login tên mới, từ chối ghi đè; runtime bị chặn CONNECT vào bản fixture. Không reset database hoặc mật khẩu có sẵn.
- Không chạy toàn bộ Maven suite trên profile web. Xem [log và cách chạy lại](MEDIUM_FIXES_2026-10-17.md); cần Maven trên PATH/MAVEN_HOME và JDK24. Hai suite kiểm tra tương ứng130và100ca trong đợt này, không phải số cố định cho mọi phiên bản sau.

Nếu chưa có file cấu hình test, không cần gửi mật khẩu qua chat. Cần xác nhận môi trường trước khi tạo file private.

1. Cài/chọn JDK24 trên máy. Kiểm `mvn -version`; launcher chỉ chấp nhận Java24. Không đổi PATH hệ thống nếu không cần, cấu hình JAVA_HOME trong file private.
2. Chủ database xác nhận một DB DEV/test hiện có, đúng schema sau migrations và marker `SanBongEnvironment=dev/test`. Không chọn DB đang phục vụ nội bộ. Nếu chưa có DB riêng, chuẩn bị phương án tạo bản copy/restore vào tên mới để review; không tự restore đè hoặc chạy bootstrap có DROP DATABASE.
3. Xác nhận runtime login riêng, khôngsa/sysadmin/db_owner, quyền nghiệp vụ đúng, EXECUTE fn_TyLeHoan và không DELETE audit. Đọc quyền bằng SSMS dưới đúng runtime identity hoặc `scripts/verify-test-database.sql` với sqlcmd `-b -d <reviewed-db>`. Script chỉ đọc metadata và báo lỗi, không GRANT/ALTER/DELETE. Runtime role không dùng để cleanup; cleanup là thao tác riêng của administrator trên DEV/test.
4. Copy `.env.test.example` thành `.env.test.local` trên máy; điền đường dẫn JDK24, JDBC host/port/database và credentials thật riêng tư. File `.env.test.local` đã nằm trong quy tắc ignore. Certificate/trust phải khớp SQL Server; không tự đổi chính sách TLS trong template để né lỗi.
5. Với file đã được xác nhận, chạy từ root:

```powershell
./backend/manage-backend.ps1 -Action build -EnvFile ./.env.test.local
```

`-EnvFile` explicit có ưu tiên hơn biến môi trường process để tránh dùng nhầm config cũ; cách không truyền file vẫn giữ `.env` với process env ưu tiên như trước. Full test yêu cầu SAN_BONG_TEST_MODE và marker dev/test. Không chạy full test bằngsa để thay identity runtime.

Chỉ sau full test PASS mới chuẩn bị candidate riêng và kiểm startup/API/browser trên loopback port còn trống. Không build đè JAR đang chạy hoặc restart internal. HTTP scripts có administrator SQL verification cần review thêm target `SQLCMD_TEST_SERVER/SQLCMD_TEST_DATABASE` trước chạy; một số helper cũ còn hardcode DB, chưa chứng nhận dùng được với tên DB test mới.

Không chạy script cleanup nếu chưa review exact fixture ID/history. Chọn DB bằng `sqlcmd -d`, dùng `-b -f 65001`; SAN_BONG_TEST_MODE=dev/test phải được cung cấp qua môi trường hoặc `-v`. Các SQL fixture không tự đổi DB.

Nếu chưa biết login/quyền hoặc chưa có database riêng, dừng integration ở bước đó. Unit/policy/browser dùng dữ liệu giả vẫn chạy độc lập. Chưa có cấu hình test không có nghĩa phải reset DB hay đổi password người dùng.
