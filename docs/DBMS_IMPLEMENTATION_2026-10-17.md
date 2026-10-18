> Bản chụp kiểm tra trước đợt sửa mới. Ba mục chuẩn hóa/snapshot, view legacy và backup tự động đã được xử lý tiếp; xem [nghiệm thu 18/10/2026](DBMS_NORMALIZATION_VIEWS_BACKUP_2026-10-18.md) để biết trạng thái hiện hành và giới hạn.

# Kết quả hoàn thiện kỹ thuật đồ án CNPM và DBMS

Ngày thực hiện: 17/10/2026. Phạm vi là hoàn thiện code, SQL và minh chứng kỹ thuật theo phần còn thiếu đã đối chiếu rubric. **Không viết báo cáo cuối kỳ hoặc slide**, theo yêu cầu bổ sung của người dùng. Đây là nhật ký bàn giao kỹ thuật.

## Kết quả hiện hành

Đã áp dụng ba migration lên **QuanLySanBong** sau khi người dùng xác nhận rõ cả ba. Bản web mới đang chạy ở **8082**, PID **28340**, health ứng dụng/database UP. Không đổi mật khẩu người dùng, schema bảng, stack, UI hoặc các snapshot cũ. Bốn trigger mới bảo vệ cập nhật tương lai, không backfill dữ liệu.

| Thành phần | Trước | Sau kiểm chứng trên database chính |
|---|---:|---:|
| Stored procedure nghiệp vụ |0|**5**|
| Function nghiệp vụ |1|**5**|
| Trigger nghiệp vụ đang bật |1|**5**|
| Bốn SQL role nghiệp vụ tương ứng nhóm người dùng |Chưa có đủ bộ|**4 role mới**, quyền khác nhau|
| View dự án |6|6; đã ghi rõ hợp đồng và view legacy|
| Bảng dự án, không tính sysdiagrams |27|27|
| Non-PK index trên bảng dự án |12|12; không xóa/đổi index nguồn để đo|

SSMS diagram procedures/function không nằm trong số lượng nghiệp vụ trên. Bốn SQL role mới không có nghĩa web đã đổi thành bốn connection pool hoặc bốn SQL login dùng mật khẩu; xem phần phân quyền.

## 1. Công nghệ phần mềm

### Tích hợp thật các thành phần SQL

`ReportRepository.java` đã thay năm truy vấn inline bằng lệnh EXEC có bind parameter:

- usage → usp_ReportUsage;
- finance → usp_ReportFinance;
- methods → usp_ReportPaymentMethods;
- reconciliation → usp_ReportReconciliation;
- topServices → usp_ReportTopServices.

Giữ Controller → Service → Repository, role/permission ở backend, kiểm tra ngày/bộ lọc và response alias hiện có. Không đưa input người dùng vào tên procedure hoặc SQL nối chuỗi. Không sửa HTML, menu, thao tác khách hay thiết kế UI trong đợt này.

### Tính tương thích

Các báo cáo vẫn phân biệt doanh thu tại trả sân, tiền thực thu và hoàn đã xác nhận. Test đối chiếu số liệu hóa đơn/dịch vụ/thu/hoàn, trường hợp chưa trả sân, khoảng ngày, hủy, hoàn chờ và quyền truy cập đều đạt.

Test Phase6 trước đây sửa trực tiếp ngày của giao dịch đã thu để tạo fixture. Đã đổi sang Clock điều khiển thời điểm **lúc tạo thu tiền**, giữ giao dịch thành công bất biến. Lượt kiểm thử đầu phát hiện mock Clock chưa xử lý withZone; đã sửa cấu hình test, không làm yếu trigger để test qua.

### Kiểm thử và triển khai

| Kiểm chứng | Kết quả | Bằng chứng |
|---|---|---|
| Runtime/unit/MVC/rollback bằng SanBongApp |**130/130**, 0 failure/error/skipped, JDK24 |exports/rubric-runtime-final-tests.log|
| Commit/concurrency và kiểm thử SQL trên fixture riêng |**119/119**, 0 failure/error/skipped |exports/rubric-fixture-release-tests.log|
| Trong tập119: RubricSqlIntegrationTest |**19 ca**, gồm 5 CHECK, 4 SP ngày sai, UDF, 4 trigger, no-op và quyền web |backend/src/test/java/com/sanbong/RubricSqlIntegrationTest.java|
| Candidate browser |PASS |exports/rubric-browser-8084.log|
| Browser bản chính |PASS, bốn vai trò, 1440/390px, 0 pageerror/0 lỗi API tải báo cáo |exports/rubric-browser-8082.log|
| Chính sách tách suite |PASS; test cleanup vẫn bị chặn ở runtime/internal |backend/scripts/verification-suite-check.ps1|
| Package stage |BUILD SUCCESS, JDK24 |exports/rubric-stage/rubric-package.log|
| Server chính |UP, PID28340, cổng8082 |exports/rubric-deployment.json|

Không cộng số test thành tỷ lệ hoàn thiện hoặc điểm rubric. Browser chỉ đọc báo cáo và đăng nhập, không thu tiền, chuyển khoản hoặc tạo booking thật. Tập119 chạy trên database fixture có dữ liệu copy và marker riêng, không chạy cleanup trên nguồn. Các lần thử thất bại vẫn giữ log; kết quả cuối dùng file có chữ final/release.

Quyền trên UI đã kiểm tra: khách bị403 khi gọi báo cáo tài chính; nhân viên sân chỉ có usage; kế toán có finance/reconciliation/refunds; quản trị có cả bốn. Kiểm tra cả menu báo cáo, tải dữ liệu/trạng thái rỗng và không tràn ngang trang ở390px. Không dùng kết quả này để tuyên bố đã kiểm lại mọi tương tác trên20 trang.

JAR hiện hành SHA256: `B44DEC3DFAB52A45DB60AF1A962A4BBF59FD17CC6F11759D00E3BA9BF22B6357`. JAR cũ giữ tại exports/backend-before-rubric-20261017.jar. So hash source frontend/src-main với stage trước khi triển khai; có rollback JAR nếu khởi động thất bại. Preview8084 và phiên Playwright do đợt này tạo đã đóng.

## 2. Hệ quản trị cơ sở dữ liệu

### Ba migration đã áp dụng

| File | Nội dung và giới hạn |
|---|---|
| database/migrations/RubricReporting_20261017.sql |5 SP chỉ đọc, TRY/CATCH/THROW, 4 TVF; cấp EXECUTE đúng5SP cho SanBongRuntimeRole; không cấp quyền quản trị|
| database/migrations/RubricSnapshotGuards_20261017_PROPOSAL.sql |4 trigger bảo vệ snapshot dịch vụ/thu tiền/hóa đơn chốt và nội dung audit; **đã được duyệt và áp dụng**, hậu tố PROPOSAL giữ theo tên file đã review|
| database/migrations/RubricDatabaseRoles_20261017.sql |SB_Customer, SB_PitchStaff, SB_Accountant, SB_Manager và bốn SB_Demo* WITHOUT LOGIN; không mật khẩu hoặc thêm membership cho service account|

Ban đầu kiểm duyệt tự động chặn lệnh gộp vì phê duyệt chỉ nêu bốn trigger. Sau khi giải thích phương án, người dùng đã xác nhận **“Đồng ý áp dụng cả ba”**; mới thực hiện lại. Preflight hash ban đầu có alias SQL trùng từ khóa, đã sửa và chạy thành công trước bất kỳ migration nào. Không coi lệnh bị chặn hoặc preflight lỗi là đã áp dụng.

Bốn function mới: fn_ReportDays, fn_BookingReceipts, fn_BookingRefunds, fn_BookingNetCash; kết hợp fn_TyLeHoan hiện có thành5. Bốn TVF mới được gọi trong SP thật, hàm tỷ lệ hoàn tiếp tục được gọi từ nghiệp vụ tài chính.

Bốn trigger mới không tính lại tổng dịch vụ hoặc tự thực hiện hoàn/chuyển tiền. TRG_CapNhatTienDatSan vẫn là nguồn tính tổng duy nhất. Cập nhật lượng dịch vụ, xác nhận thu đang chờ và đồng bộ tiền đã trả trên hóa đơn chốt vẫn chạy đúng khi các trường snapshot không thay đổi.

### Phân quyền hai tầng

Các SB_Demo* không thể đăng nhập bằng SQL Authentication vì WITHOUT LOGIN. DBA dùng EXECUTE AS USER để demo quyền SQL. Web vẫn dùng SanBongApp với whitelist cũ cộng quyền EXECUTE5SP; backend xử lý4vai trò web và ownership. Không hứa rằng mỗi phiên web tự đổi SQL principal.

Probe trên fixture đã xác nhận bốn ma trận khác nhau, lỗi229 khi customer đọc ThanhToan, và GRANT → REVOKE → DENY rồi rollback. Không cấp quyền đọc toàn bộ booking/khách/tài khoản cho SQL role khách. Manager không db_owner, không sửa/xóa nhật ký hoặc xóa thu tiền. File: database/rubric-permission-probes.sql; log: exports/rubric-permission-probes.log.

### Transaction, constraint và concurrency

Năm demo SQL: (1) đặt sân + nhật ký, (2) dịch vụ + trigger tổng, (3) trả sân + hóa đơn chốt, (4) thu tiền + đồng bộ hóa đơn, (5) hủy + hoàn theo thực thu. **5 COMMIT_PASS và5 ROLLBACK_PASS**. Khi cố ý lỗi sau các bước ghi, không còn dòng liên quan trong các bảng kiểm tra. Các bộ dữ liệu thành công chỉ được giữ trên fixture để người dùng xem; SQL demo không thay API vận hành đầy đủ.

Hai kết nối SQL thực tế: A giữ UPDLOCK/HOLDLOCK trên sân; B nhận lỗi1222; sau A rollback, B lấy khóa được. Không ghi dữ liệu ở phép thử này. Các test nghiệp vụ cạnh tranh đã chạy trong119ca. Bằng chứng: exports/rubric-transactions.log, exports/rubric-concurrency.json.

Năm CHECK probe bị chặn với SQL547: giá dịch vụ0, số lượng dịch vụ0, khuyến mãi kết thúc trước bắt đầu, số tiền thu0, khung giờ kết thúc không sau bắt đầu. Kiểm tra metadata nguồn không có CHECK/FK disabled hoặc untrusted tại thời điểm nghiệm thu.

### Index có đo và actual plan

| Mẫu truy vấn | Dòng mỗi bảng thử | Logical reads trước → sau |
|---|---:|---:|
| Sân/ngày |50.000|403 → 2|
| Thu tiền theo booking/trạng thái |50.000|407 → 3|
| Dịch vụ theo booking |50.000|261 → 3|
| Username |50.000|259 → 3|
| SĐT khách |50.000|217 → 3|

Đã kiểm tra **5 kết quả trước/sau giống nhau**, actual plan từ Table Scan sang Index Seek; XML plan, STATISTICS IO/TIME và JSON được giữ. Bảng thử là heap tổng hợp trong rubric_bench trên fixture; không thay index nguồn. Dịch vụ dùng covering variant có INCLUDE, khác index nguồn hiện tại. Không diễn giải số đo này thành cam kết tốc độ trên dữ liệu/thời điểm khác hoặc tải người dùng thật. Log ANSI đầu được đọc đúng mã hóa để phục hồi plan, runner đã bổ sung UTF-8 cho lần chạy sau.

File: database/rubric-index-benchmark.sql, scripts/measure-rubric-indexes.ps1, scripts/verify-rubric-index-results.py; kết quả exports/rubric-indexes/results.json và verification.json, cùng10file.sqlplan.

### ERD, từ điển dữ liệu và tạo lại schema

- docs/DBMS_SCHEMA_DICTIONARY.md: **27 bảng**, cột/kiểu/NULL/default/computed, khóa/FK/CHECK, ERD Mermaid theo cardinality từ schema.
- docs/DBMS_TECHNICAL_GUIDE.md: hợp đồng6view, phụ thuộc hàm/khóa, giải thích giá và snapshot lịch sử, CRUD nghiệp vụ, quyền và cách kiểm chứng.
- exports/rubric-schema.json: metadata schema-only lấy từ nguồn sau triển khai, không xuất dữ liệu ứng dụng/hash/password.
- database/rubric-schema-new-only.sql: tạo mới schema đầy đủ; đã chạy thành công lên **SanBong_SchemaDemo_20261017_Rubric**, CHECKDB đạt,27bảng/21module. So cột/kiểu/nullability/identity hai chiều với nguồn:0khác biệt. Chạy lần nữa cùng tên bị chặn; không DROP/ghi đè database đã có.

Snapshot mới là **schema-only**, không có danh mục seed, tài khoản, SQL grants, login hoặc dữ liệu người dùng; không phải bộ cài tự đăng nhập được. Tạo user runtime/danh mục demo trên database mới là công việc provision riêng. Không dùng bootstrap DROP/reset trên nguồn. Backup có dữ liệu là phương án riêng, cần giữ kín.

### Backup và bảo toàn dữ liệu

Đã có COPY_ONLY/CHECKSUM/VERIFYONLY mới trước thay đổi và sau triển khai. Backup sau có đủ đối tượng SQL mới; receipt tại exports/rubric-post-deployment-backup.json. **Đã restore chính backup sau triển khai** sang database hoàn toàn mới QuanLySanBong_Fixtures_20261017_RubricRestore: CHECKDB đạt,5SP/5trigger/4SQLrole có đủ, hash9bảng trùng nguồn. JAR mới khởi động với JDBC/JPA ddl-auto=validate trên bản restore, healthUP; preview8085 đã dừng. Không restore đè database hiện có. Bằng chứng: exports/rubric-release-restore-check.log, rubric-release-restore-fingerprints.txt, rubric-restore-smoke.json và rubric-restore-startup.log.

SHA-256 JSON đầy đủ, sắp theo khóa của9bảng DatSan/HoaDon/ChiTietDichVu/ThanhToan/HoanTien/HuyDatSan/XacNhanSan/DichVu/GiaTheoCa: **giữ nguyên trước migration, sau migration và sau hồi quy/UI**. Chỉ nhật ký đăng nhập thật được bổ sung. Không dùng checksum đơn giản hoặc chỉ một chiều EXCEPT để nhận là toàn bộ lịch sử không đổi. Các bảng ngoài9bảng này không nằm trong chứng minh hash đó.

Bằng chứng: exports/rubric-source-before.txt, rubric-source-after.txt, rubric-source-final.txt. Helper: database/rubric-financial-fingerprints.sql.

## Còn lại và giới hạn thực tế

1. **3NF nghiêm ngặt cho toàn schema vật lý chưa được chứng nhận.** Đã viết khóa/phụ thuộc và mô hình quan hệ; một số giá trị tiền/quy cách là snapshot hoặc dẫn xuất lưu có chủ đích. Không tự xóa/tái thiết kế cột tài chính để đạt khẩu hiệu chuẩn hóa. Nếu yêu cầu loại toàn bộ dư thừa vật lý, cần một thiết kế/migration tài chính riêng được review; xem giải thích trong DBMS_TECHNICAL_GUIDE.md.
2. **View legacy:** V_KhungGioTrong chỉ là danh mục ứng viên, không phải lịch trống theo ngày; V_DoanhThuTheoNgay là thu gộp; V_TyLeLapDay không dùng cho GIA_GIO. Đã ghi rõ và các API hiện hành dùng phép tính đúng. Chưa đổi/xóa view legacy để tránh phá hợp đồng ngoài web.
3. **Backup định kỳ/archive/hash OS/retention:** chưa bật. SQL verify đạt nhưng Windows identity hiện không đọc được BAK để hash. Chưa có lịch/nơi lưu được chốt và identity có quyền OS phù hợp; không tự mở ACL hoặc đặt lịch.
4. **Vận hành ở xa/trusted proxy:** chưa chứng nhận client thật hoặc tách IP tin cậy qua tunnel. Bản chạy này được nghiệm thu local, không phải chứng nhận Internet production.
5. **Git/lịch sử nhóm:** workspace hiện không có.git; không tự tạo lịch sử đóng góp hoặc remote thay người dùng. Báo cáo cuối kỳ/slide/phân công thành viên đã được người dùng loại khỏi yêu cầu thực hiện đợt này.

## File chính và chạy lại

- Code: backend/src/main/java/com/sanbong/repository/ReportRepository.java.
- Test: RubricSqlIntegrationTest.java, Phase6IntegrationTest.java; backend/run-rubric-verification.ps1; backend/scripts/rubric-reports-browser.js.
- SQL: ba migration ở trên; rubric-transactions.sql, rubric-permission-probes.sql, rubric-index-benchmark.sql, rubric-financial-fingerprints.sql, rubric-schema-new-only.sql.
- Tooling: scripts/export-rubric-schema.ps1, build-schema-artifacts.py, measure-rubric-indexes.ps1, verify-rubric-index-results.py, verify-rubric-concurrency.ps1, check-rubric-browser.ps1.
- Hướng dẫn đầy đủ: docs/DBMS_TECHNICAL_GUIDE.md. Bảng đối chiếu rubric ban đầu đã có chú thích trạng thái hiện tại ở đầu file.

```powershell
# Ở thư mục gốc dự án, Maven trên PATH hoặc cấu hình MAVEN_HOME đúng:
.\backend\run-verification.ps1 -Suite runtime -EnvFile .\.env.test.local -Offline
.\backend\run-rubric-verification.ps1 -EnvFile .\.env.rubric.local -Offline

# Chạy web từ nguồn đã build; giữ terminal mở:
.\backend\manage-backend.ps1 -Action run -EnvFile .\.env.test.local
```

Web hiện đã chạy; không mở thêm server8082 khi cổng đang có listener. Không chia sẻ profile private, cookie, BAK thật hoặc run file lên Git/public. Bộ thử tạo bản copy và dữ liệu tổng hợp; không tự xóa database copy/BAK sau đợt này.
