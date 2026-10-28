# Kiểm tra San_Bong và hướng phát triển — 12/10/2026

> Cập nhật 13/10/2026: đã triển khai bản sửa source/policy R01/R02 và browser R04/R05. Xem `FIX_PACKAGE_A_2026-10-13.md` và `FIX_PACKAGE_B_FINANCE_2026-10-13.md`. Danh sách bên dưới là kết quả audit ngày12/10, không phải khẳng định các lỗi này vẫn chưa sửa. Full integration/runtime/release còn chờ môi trường DEV/test và Java21 được xác nhận.

## Kết luận

Project có nền tảng nghiệp vụ và kiến trúc đúng hướng: HTML/JS cùng origin → REST/session/CSRF → Controller → Service → Repository → SQL Server. Nên tiếp tục hoàn thiện project hiện có. Chưa đủ bằng chứng để chứng nhận bản source mới nhất sẵn sàng vận hành có tiền thật.

Không phát hiện P0 mới đã được chứng minh trong lượt này. Các lỗi F01–F04 của audit 08/10 đã có bản sửa trong source; không được tiếp tục trình bày chúng như lỗi chưa xử lý. Vướng chính hiện tại là khả năng tái lập build, an toàn script test, chứng nhận release F15, xử lý trạng thái UI tài chính và nghiệm thu vận hành.

## Phạm vi và bằng chứng mới

Đã inventory cấu trúc project; kiểm tra luồng chính trong controller/service/repository, security/config, HTML/JS, schema/migrations, test guards, scripts triển khai/backup và đối chiếu các báo cáo phase/fix. Có 83 file Java main, 20 file Java test/support, 14 trang HTML, 13 file JS. Đây là audit diện rộng dựa trên mã và kiểm thử có phạm vi; không phải chứng minh mọi nhánh của tất cả file đều đúng.

| Kiểm tra ngày 12/10 | Kết quả | Giới hạn |
|---|---|---|
| Git | `git status` báo không có repository | Không kiểm tra được lịch sử commit, tracked secrets hoặc diff |
| Maven mặc định trên bản sao source | FAIL ở compile: Lombok getter/setter không sinh | Maven 3.10.0 dùng Oracle JDK 24.0.2, project yêu cầu Java 21 |
| Maven offline + `-Dmaven.compiler.proc=full` trên bản sao | Compile 83 main + 20 test/support; 14 test PASS, 0 failure/error/skipped | Chỉ chạy BcryptSecurityRegressionTest và PasswordPolicyTest; không phải full regression/package/release |
| Frontend static check hiện có trên bản sao | PASS: 14 trang, liên kết tương đối, same-origin, không ghim API dev/DB credentials, 100 UUID | Không xác minh tất cả dữ liệu API/runtime |
| `node --check` | PASS cho 13 file JS | Không bắt được tất cả lỗi DOM/asynchronous logic |
| Playwright CLI 0.1.22 | Tái lập lỗi reload finance bằng harness dùng source finance.js hiện tại | Dữ liệu giả, POST/GET giả; không giao dịch/database thật |
| Trang login tĩnh | 390×844: scrollWidth 390; console 0 errors, 1 Tailwind warning khi kiểm tra | Không submit form, không chứng nhận login/session/backend |
| GET health ngoài sandbox | 8080 và 8082 đều ECONNREFUSED | Chỉ kết luận hai địa chỉ loopback/cổng đó ở thời điểm probe; không tự khởi động/restart server |
| Brave | Không tìm thấy exe ở hai đường dẫn cài mặc định Program Files | Không loại trừ Brave portable/cài nơi khác; chưa test Brave |
| Database/SCA/ops | Không chạy fresh SQL audit/full DB tests/dependency vulnerability scan/LAN/reboot/restore | Kết quả SQL và E2E trong tài liệu cũ được ghi rõ là lịch sử |

Bằng chứng mới ở `run/project-audit-20261012/`: `unit-tests-unsandboxed.log` (build FAIL), `unit-tests-proc-full.log` (14 PASS), `work/backend/phase7-frontend-results.json`, `audit-finance.html`, `static-server.cjs`, `finance-reload-error-hidden.png`, `login-mobile.png`. Snapshot/console Playwright ở `.playwright-cli/`. Bản sao source để build không chứa env/secrets, logs hay releases. Browser và server tĩnh audit đã được đóng. Không sửa Java/HTML/JS ứng dụng, pom, schema, credentials hoặc dữ liệu nghiệp vụ.

## Những phần đang đúng và lỗi cũ đã có sửa

- **F01**: OperationsService.checkOut gọi FinanceService.sealAtCheckout trong transaction; `sealed()` xét hóa đơn, lịch sử trả sân và trạng thái đã sử dụng. Khuyến mãi sau chốt bị chặn. CheckoutSnapshotTest và báo cáo FIX02/browser là bằng chứng lịch sử; chưa chạy lại integration hôm nay.
- **F02**: register/reset/startup dùng PasswordPolicy; regression unit mới PASS. Không áp chính sách ghi mật khẩu mới để tự khóa login legacy.
- **F03**: bookablePitch chấp nhận Trống/Đang sử dụng; availability/create kiểm interval overlap theo ngày; check-in vẫn kiểm lượt nhận đang mở. Không còn điều kiện chặn mọi booking tương lai chỉ vì sân đang dùng.
- **F04**: WalkInCustomerService, endpoint staff và UI quầy đã có tạo khách. Unique phone SQL làm trọng tài khi concurrent insert. Không tự tạo tài khoản đăng nhập cho walk-in.
- **F15**: BoundedBcryptPasswordEncoder đã được nối vào SecurityConfig; `matches()` từ chối ứng viên >72 byte UTF-8. 6 case BCrypt và 8 case PasswordPolicy vừa PASS. Đây là bảo vệ ở ứng dụng, không chứng nhận mọi dependency đều không có advisory.
- Method permissions/ownership ở backend, CSRF/session, vô hiệu hóa phiên khi khóa/reset, parameter binding, transaction và khóa San → DatSan, trigger tổng dịch vụ, idempotency thanh toán và hoàn đều có trong mã luồng chính.
- `ddl-auto=validate`, same-origin API và cấu hình môi trường được giữ. Không cần thay stack hoặc thêm proxy database.

## Phát hiện còn cần giải quyết

Mức P1: ưu tiên trước release/test ghi; P2: cần sửa theo tác động vận hành; P3: polish/tài liệu. CODE là suy luận từ nhánh mã cụ thể, không đồng nghĩa đã gây lỗi trên dữ liệu thật.

| ID / mức | Vấn đề và bằng chứng | Tác động / phương án |
|---|---|---|
| R01 / P1 / CODE | `backend/scripts/cleanup-phase3-test.sql:1`, cleanup-phase4-test.sql:1, cleanup-phase5-operations-test.sql:1 và prepare-phase5-operations-test.sql:1 kiểm SanBongEnvironment **trước** `USE QuanLySanBong` ở dòng 3 | Nếu sqlcmd bắt đầu trên DB test khác, guard xác nhận DB A rồi script đổi sang DB B. DB B có thể internal mà không được kiểm lại; fixture predicates khác vẫn còn, không khẳng định đã xóa dữ liệu thật. Bỏ đổi DB ngầm hoặc kiểm DB_NAME + marker trên DB cuối cùng ngay trước mọi ghi, dùng fail-fast `-b`/ON ERROR EXIT. Test trường hợp A=test, B=internal phải từ chối trước INSERT/DELETE. Không chạy các script để chứng minh lỗi trên DB thật. |
| R02 / P1 / REPRO | pom.xml:21 yêu cầu Java21; toolchain hiện tại JDK24; build mặc định thiếu Lombok methods; bật `maven.compiler.proc=full` thì compile và 14 unit PASS | Chuẩn hóa JAVA_HOME/Maven chạy đúng JDK21, xác nhận `mvn -version`, kiểm Java major ở launcher/build và bổ sung setup rõ. Nếu muốn hỗ trợ JDK mới, cấu hình annotation processor explicit riêng sau review. Không sửa model bằng cách viết tay hàng loạt getter/setter. [Lombok Maven](https://projectlombok.org/setup/maven) ghi yêu cầu processor explicit từ JDK23. |
| R03 / P1 / GATE | FINAL_PROJECT_CLEANUP_REPORT và FINAL_FIX05_F15_REPORT ghi guard mới chưa full regression/runtime/release; audit mới chỉ 14 unit | Không dùng số 212 PASS của Fix04 để chứng nhận source mới. Chốt private config DEV và least privilege, chạy toàn suite không skip trên DB dev/test marker + opt-in, rồi startup candidate riêng, HTTP/bốn role và release SHA256. Các báo cáo cũ ghi thiếu EXECUTE fn_TyLeHoan và quyền DELETE audit rộng; **chưa đọc lại quyền SQL hôm nay**, cần xác minh trước khi sửa. |
| R04 / P2 / REPRO | frontend/js/finance.js:50–66: load() catch lỗi rồi trả bình thường; mutate() tiếp tục `status(message)` | Harness POST thành công → GET ném SIMULATED_RELOAD_503 → banner vẫn “Đã lưu hóa đơn từ snapshot backend.”, chi tiết trống. Không phải POST thất bại được báo thành công. Cho load trả trạng thái/throw; nói rõ “Đã ghi nhận, chưa tải lại được”, giữ retry GET và không tự POST lại. |
| R05 / P2 / CODE | finance.js:75 click dòng ledger gọi load() không kiểm busy; mutate/load dùng bookingId/current/status chung | Trong lúc POST booking A đang chạy, người dùng click B; load A/B và status mutation có thể thay màn hình đang xem. Khóa chuyển selection lúc ghi hoặc tách mutation context `{bookingId, requestVersion, key}`; chỉ render nếu còn đúng selection. POST URL được capture trước gửi nên chưa có bằng chứng thu nhầm booking hoặc double charge. Test delayed POST/GET + chọn B + retry key. |
| R06 / P2 / CODE | AdminService create/editEmployee và AdminRepository insert/updateEmployee không kiểm uniqueness identity; schema NhanVien không unique phone/email; TaiKhoanRepository.findByIdentifier tìm cả username/phone/email; AuthService:40 từ chối khi matches.size !=1 | Đổi email/phone nhân viên sang định danh account khác có thể làm login bằng định danh đó thất bại cho hai account. Chốt chính sách định danh dùng đăng nhập, normalize rồi kiểm xung đột trong backend với transaction. Nếu cần constraint mới, đưa migration proposal để duyệt; không áp tự động. Chưa tạo dữ liệu trùng để test live. |
| R07 / P2 / CODE | SecurityConfig/AuthController không có app throttle/backoff cho login/register | BCrypt cost12 làm nhiều lần thử tốn CPU. Bổ sung giới hạn phù hợp mạng nội bộ, 429/Retry-After và audit mức hợp lý; tránh khóa nhầm cả nhóm nhân viên chung IP. Chưa thử tải/DoS và không kết luận có brute-force thành công. |
| R08 / P2 / CODE + browser warning | Cả14 HTML tải Tailwind CDN; fonts/icons/images ngoài máy chủ. Login báo warning Tailwind CDN production. Ảnh hcmute còn trong CSS | Mất Internet/Shields có thể mất style/tài nguyên. Đóng gói CSS đã build/font/icon/ảnh hợp lệ giữ giao diện hiện tại; thử offline. Không suy rằng static link check đã kiểm hết CSS URLs. BA02 ORB là kết quả browser lịch sử, chưa tái lập ORB hôm nay. |
| R09 / P2 / CODE | PitchService.prices/typePrices vẫn dùng BangGia legacy; TimePriceRepository.price dùng GiaTheoCa cho booking mới. pitches.js:125 ghi “Bảng giá theo loại sân” | Nhân viên có thể tưởng giá legacy đang hiển thị là giá booking giờ tự do. Gắn nhãn giá lịch sử rõ, thêm vùng đọc giá giờ hiện hành và preview nhất quán; giữ snapshot/BangGia/MaKhungGio legacy. Quản lý sửa GiaTheoCa là mở rộng cần phạm vi riêng. |
| R10 / P2 / RISK | OperationsService.quantityLine nhận số lượng tuyệt đối, khóa đảm bảo tiền consistent nhưng không kiểm expected version/old quantity | Hai nhân viên cùng sửa có thể ghi đè ý định; chưa chứng minh double charge. Có thể gửi expected quantity/price để trả409 trước, hoặc version column nếu cần migration được duyệt. Tương tự review concurrent catalog edits. |
| R11 / P3 / CODE + history | Trang booking/quầy default08–09; bookings.js tự search khi init; customer-home chọn today | Sau08h query có thể400 ngay khi mở. Chọn giờ tương lai hợp lệ trong07–22 hoặc yêu cầu người dùng chọn trước query; cuối ngày chuyển hôm sau. Backend validation vẫn giữ. BA04 trước đó đã có browser evidence; không gọi400 validation là lỗi backend. |
| R12 / P2 / OPS CONFIG | scripts/backup-database.sql cố định `[QuanLySanBong]`; restore drill cố định `QuanLySanBong_Phase7_RestoreTest`, là tên đã từng dùng cho internal theo audit lịch sử | APP_DB_URL configurable nhưng backup không theo target vận hành. Nếu chạy DB khác, dễ backup sai DB; drill lần sau bị từ chối khi tên đã tồn tại, đây là guard đúng. Đề xuất target được xác nhận/allowlist, đối chiếu DB và backup HEADER/FILELIST, tên drill mới mỗi lần. Không restore đè/drop. Chốt RPO/RTO, retention và bản sao ngoài máy SQL; chưa xác minh lịch backup/reboot hôm nay. |
| R13 / P2 / GATE | HTTP/cookie Secure configurable nhưng chưa có bằng chứng TLS/client LAN/reboot/recovery cho source mới; 8080/8082 không nhận kết nối hiện tại | Không suy ra cấu hình TLS/firewall đã sai trên mọi máy. Trước pilot, xác nhận runtime identity/config canonical, TLS và cookie phù hợp, máy client thật, restart/task, backup/restore sang DB mới. Chưa tự triển khai LAN. |
| R14 / P3 / REPRO + CODE | Không có Git repository; không thấy workflow build/test trong `.github` hiện tại, chỉ modernize hooks. README vẫn giới thiệu Phase2/Boot3.3.4 dù pom3.5.16 | Thiếu lịch sử có thể review/rollback và điểm vào tài liệu hiện hành. Tạo Git sau secret audit, chỉ commit source/config examples; giữ env/run/log/release/bak private. README trỏ trạng thái phase7/fixes và lệnh build thực tế. CI chỉ chạy DB integration khi có SQL test được phân loại; không dùng internal runner DB. |
| R15 / P3 / CODE | AuthService.register dùng LocalDate.now()/LocalDateTime.now() theo timezone JVM, trong khi booking/finance dùng Asia/Ho_Chi_Minh | Máy khác timezone có thể ghi ngày đăng ký/account khác ngày nghiệp vụ. Dùng cùng Clock/Zone cho timestamp ứng dụng và chốt timezone SQL/server; chưa thấy lỗi này trên máy hiện tại Asia/Saigon. |

Script `database/migrations/legacy/schema-bootstrap.sql` còn DROP DATABASE ở đầu: đây là bootstrap lịch sử, **không phải script cập nhật production**. Phải phân biệt rõ trong runbook và không dùng để “sửa schema”. Không chạy file này trong audit.

Các gap chưa phải regression: tự phục vụ khuyến mãi, đánh giá/feedback lưu thật, hướng dẫn chuyển khoản/đối soát đầy đủ, CRUD giá theo giờ. Một số UI prototype đã được chặn để tránh báo thành công giả; chỉ triển khai khi được giao phạm vi. BA03 tên seed lỗi encoding và BA05 header staff mobile là bằng chứng lịch sử; cần xác minh lại trước sửa dữ liệu/layout. Ledger/accounts đọc toàn bộ và EAGER booking là rủi ro scale cần đo query/tải, không kết luận hệ thống hiện đã chậm.

## Hướng tiếp tục theo từng gói

1. **Ổn định release hiện tại**: sửa R01/R02; xác nhận DEV identity/private config/quyền fn_TyLeHoan và audit; full regression + runtime F15; đóng gói candidate immutable/hash. Dừng và báo file/test trước gói tiếp theo. Không reset password/đổi SQL login để lấy test access.
2. **Sửa UX có tác động vận hành**: R04/R05/R11/R09; bổ sung test delayed/failure/retry, giữ UI và snapshot. R06/R10 xử lý theo chính sách định danh/concurrent edit đã chốt; schema change chỉ proposal.
3. **Nghiệm thu Phase7**: E2E bốn role trên DB dev/test, guard internal, offline assets nếu môi trường cần, TLS/cookie, backup đúng target/restore DB mới, máy LAN thật/reboot/task. Kết quả API khác kết quả browser và khác evidence deploy.
4. **Sau khi qua gate**: đo dataset lớn rồi page/filter ledger/accounts và tối ưu projection/index theo query plan; chỉ mở module KM/review/giá mới khi được giao. Không tự gọi đây là Phase8 hoặc mở thêm framework.

Tiêu chí release: lỗi mới có regression; toàn suite PASS không skip trong môi trường đúng; bốn role/CSRF/ownership và tài chính idempotency/rollback/snapshot/legacy PASS; candidate hash + config target được ghi nhận; rollback/backup được kiểm tra theo phạm vi. Test passing đơn lẻ không chứng nhận readiness toàn hệ thống.

## Các phương án công cụ

| Phương án | Cách dùng cho San_Bong | Khi chọn |
|---|---|---|
| A — Tối thiểu, đề xuất làm trước | Git + Java21/Maven + regression hiện có + Playwright CLI + browser Chromium; skill theo nhiệm vụ | Đủ sửa lỗi hiện tại; ít cấu hình và không thêm dependency runtime |
| B — Bổ sung hiểu mã | A + Graphify index source/schema/docs đã chọn + Ponytail làm guideline patch nhỏ | Hữu ích khi số báo cáo/luồng khó theo dõi; thử trên corpus nhỏ và so lại source |
| C — Nhiều AI provider | B + OmniRoute cho công cụ phát triển ở môi trường riêng | Chỉ khi có nhu cầu nhiều provider/fallback/chi phí thực; chưa cần cho chức năng web sân bóng |

**Playwright CLI + Brave.** CLI đã có và đã dùng trong audit. Dùng CLI để thăm dò/reproduce; chuyển các case đã xác định thành E2E tái lập với assertions/trace. Tách storage state cho customer/staff/accountant/admin, coi auth state là secret và không commit. Case ưu tiên: giờ07/22 + boundary overlap, cùng lúc đặt sân, checkout snapshot, retry payment/refund, POST-success/GET-fail, revoke/reset session, offline và390px. Chỉ fixture trên dev/test marker + opt-in. Brave là browser đích bổ sung để test Chromium và ảnh hưởng Shields; không thay Java backend. [Playwright browsers](https://playwright.dev/docs/browsers) mô tả Chromium/Chrome/Edge; CLI help hiện tại không có `--browser=brave`. Khi xác nhận Brave exe/version, review config executablePath hoặc CDP loopback với profile test riêng và kiểm tương thích. Không ghi một lệnh Brave giả như đã được hỗ trợ/test. [Brave chính thức](https://brave.com/vi/) là nguồn sản phẩm; audit hiện chưa kết nối Brave.

**Ponytail.** [Repo tác giả](https://github.com/DietrichGebert/ponytail) mô tả guideline giảm code dư và tái sử dụng. Phù hợp tinh thần patch nhỏ, nhưng không được bỏ validation, transaction, error handling hay regression tài chính. Review skill/hooks trước dùng và giữ AGENTS.md San_Bong; không chép đè bằng AGENTS mẫu. Chưa cài/chưa chạy Ponytail; không coi số tiết kiệm tác giả công bố là kết quả cho project này.

**Graphify.** [Repo Graphify-Labs](https://github.com/Graphify-Labs/graphify) mô tả graph mã/docs, AST local, SQL extraction tùy chọn và edges extracted/inferred. Graphify xây quan hệ, không gom toàn project thành một file hay thay test. Corpus đề xuất: backend/src/main/java, frontend/js + HTML, database/migrations/schema, AGENTS và báo cáo canonical. Loại env, logs, run, target, releases, backup, auth state. Map booking → operations → finance → trigger → report để tìm tác động patch. Xác minh Java/JPA/JDBC SQL Server/trigger mapping bằng vài luồng biết trước; không mặc định inferred edges là dependency thật. Semantic pass docs/media có thể dùng model/backend; chọn rõ backend và corpus. CLI skill và MCP connection là hai cơ chế khác nhau, cài skill không tự có MCP. Chưa cài/chưa index Graphify.

**OmniRoute.** [Repo được tra cứu](https://github.com/diegosouzapw/OmniRoute) mô tả AI gateway/router và tích hợp CLI. Có nhiều fork trùng tên; cần chốt đúng repository/version trước thử. Đề xuất chỉ dùng trên máy dev cho request mô hình nếu cần; schema/prompts đã lọc đi tới provider có thể đổi theo fallback. Giữ secrets phía gateway và kiểm endpoint/protocol/tool-call bằng smoke test. Không đưa OmniRoute vào pom hoặc đường Browser → REST → SQL Server; nó không thay JDBC, authentication hay database connection. Chưa cài/chưa kết nối OmniRoute, và không chứng nhận Codex desktop hiện tại đã dùng gateway này.

**Agent Skills.** Chọn theo công việc: playwright-cli để tái lập browser; diagnosing-bugs khi fix lỗi cụ thể; tdd nếu giao làm test-first; code-review khi có Git và baseline; domain-modeling khi cần chốt nghĩa doanh thu/thực nhận. Skill là workflow/instructions, không tự cung cấp quyền DB hay thay assertion. Không cần bật tất cả skill cùng lúc. Có thể tạo skill riêng cho San_Bong sau này để buộc marker, environment, San→DatSan, legacy snapshot và checklist artifact/test; đây là đề xuất, chưa tạo/cài trong lượt này.

Luồng công cụ đề xuất: **AGENTS.md + skill phù hợp → đọc source/Graphify nếu có → patch nhỏ → Maven/SQL dev-test → Playwright → báo cáo/release**. OmniRoute tùy chọn nằm ở phần kết nối mô hình của công cụ phát triển; Brave nằm ở đầu browser kiểm thử. Runtime application giữ nguyên stack.

## Thay đổi của lượt audit

Chỉ thêm báo cáo này và artifacts audit trong run/. Không triển khai patch application, migration, dịch vụ AI mới hoặc LAN. Những thông tin cần xác nhận cho bước integration kế tiếp là đường dẫn private config DEV đúng identity và quyền SQL hiện hành; không gửi password qua chat. Tạm thời chưa chứng nhận full regression/runtime/release F15 hoặc deployment readiness.
