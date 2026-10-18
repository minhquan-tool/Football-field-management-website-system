# Phase 7 — Final hardening / E2E / deployment preparation

Ngày kiểm chứng: 2026-10-08. Tiếp tục project hiện có, không đổi stack/UI tổng thể, không thêm framework/dependency, không nghiệp vụ lớn mới.

**CODE/DEPLOYMENT PREPARATION COMPLETE — AWAITING MANUAL LAN VERIFICATION.**

Không tuyên bố hệ thống đã triển khai production hoặc LAN PASS. Không có browser/client trong công cụ; Windows hiện tại không elevated. Firewall, Task Scheduler, reboot và truy cập thực từ máy khác còn chờ xác nhận thủ công.

## 1. Final regression và runtime
| Kiểm tra | Kết quả / chứng cứ |
|---|---|
| Maven clean verify | 147/147 PASS: giữ nguyên 141 test Phase 1–6, thêm 6 RuntimeHardeningTest; không xóa test để PASS. backend/phase7-build.log, target/surefire-reports |
| Java/JDBC/JPA | Spring Boot 3.3.4, Java21, Microsoft driver12.8.1.jre11 giữ nguyên; TCP SQL1433 trực tiếp, ddl-auto=validate; entity đọc dữ liệu thật |
| Runtime SQL riêng | SanBongAppPhase7; sysadmin=0, db_owner=0, CREATE TABLE=0, DELETE San=0, UPDATE/DELETE audit=0; quyền EXECUTE chỉ fn_TyLeHoan |
| Startup / restart / stop | Script đã chạy thực trên máy hiện tại, health UP; khắc phục readiness localhost/IPv6 bằng loopback IPv4, kiểm tra PID/JAR/starttime và ownership trước stop |
| Profile internal | Startup PASS trên QuanLySanBong_Phase7_RestoreTest sau đổi mật khẩu mạnh CHỈ BẢN COPY, marker internal; Hibernate validate PASS, health UP |
| Listen LAN bằng config | APP_HOST=0.0.0.0, APP_PORT=8081 trên bản copy: listener wildcard dual-stack; HTTP qua loopback và IPv4 Wi-Fi của chính máy PASS |
| Internal fixture policy | Read-only authenticated GET /admin/test-safety reports fixtureTestsAllowed=false on restore copy; no business fixture API called |
| Máy client khác | CHƯA KIỂM CHỨNG; kiểm tra qua IP trên cùng server không thay thế client LAN |
| Health DB down | Unit test: 503, chỉ status/database DOWN, không lộ driver/stack/config |
| Frontend | 14 HTML: link file nội bộ và placeholder navigation PASS; mọi JS node --check PASS; API same-origin, không host localhost cố định/DB config; UUID fallback HTTP LAN 100 mã hợp lệ/khác nhau |

## 2. Connected end-to-end thực tế
`backend/scripts/phase7-e2e-http-check.mjs` + `backend/phase7-http.log`:
- Login admin, nhân viên sân, kế toán, khách; 403 đúng quyền.
- Nhân viên tạo booking giờ tự do hôm nay; khách tạo booking tương lai. Booking cùng sân bị overlap từ chối409; giá theo giờ bắt đầu. M1–M5, biên giờ/overlap/concurrency nằm trong regression FreeTimeBookingTest/BookingConcurrencyTest và các suite cũ.
- Đặt trước SV03 lốc6=58200; nhận sân; thêm SV03 đơn vị=10000; snapshot dịch vụ tổng68200.
- Hóa đơn, thực thu100000 tiền mặt, khách yêu cầu20000 chuyển khoản được kế toán xác nhận; trả sân rồi thu phần thiếu đến ConLai=0.
- Booking tương lai thu50000, khách hủy, kế toán xác nhận hoàn50000; chưa xác nhận không tính thực hoàn.
- Đối chiếu API=SQL: phút sử dụng, tỷ lệ lấp đầy, revenue booking đã trả sân, thu/hoàn/thực nhận, tiền mặt/chuyển khoản, filter ngày/sân/booking/trạng thái và dashboard.
- Tạo tài khoản/nhân viên fixture; đổi vai trò tải lại quyền ngay; khóa/nhân viên ngừng/reset mật khẩu vô hiệu session cũ; audit không chứa mật khẩu; account API không trả hash.
- Cleanup chính xác fixture P7H + 6 ký tự hex, đúng marker, employee/account và payment key; SQL administrator thực hiện. Không dùng runtime login để cleanup. Giữ security audit login của các tài khoản gốc; chỉ xóa audit thuộc fixture xác định.

Lỗi thật đã sửa: runtime least privilege thiếu EXECUTE scalar function dbo.fn_TyLeHoan, làm hủy/hoàn trả503. Đã tái hiện lỗi229, chỉ grant EXECUTE hàm này, rerun E2E PASS; không grant db_owner/sa.

## 3. Security / môi trường
- BCrypt; SQL verify nguồn không có tài khoản plaintext. Mật khẩu demo gốc chưa tự đổi; cần quản lý đổi trước vận hành nội bộ. Internal startup từ chối marker không internal, SQL sysadmin/db_owner, debug, password migration, plaintext và các mật khẩu demo phổ biến.
- Session HttpOnly/SameSite=Lax/30m; CSRF và permission backend giữ nguyên. HTTP LAN không mã hóa credential/session; HTTPS + APP_SECURE_COOKIE=true cần certificate tin cậy trước vận hành trên mạng không đáng tin cậy. HTTPS chưa được kiểm thử thực tế.
- APP_ENV/APP_DB_URL/APP_DB_USER/APP_DB_PASSWORD/APP_HOST/APP_PORT/APP_CONTEXT_PATH, APP_LOG_FILE, APP_JAR cấu hình môi trường. Runtime private file ACL hạn chế, ignored; .bat không secret. Source .env cũ chỉ dev/test, không dùng sa để chạy ứng dụng nội bộ.
- Scan22 logfiles: không thấy credential SQL hoặc mật khẩu private của rehearsal; không in giá trị secret khi scan.
- API lỗi database503 và lỗi500 không SQL stack/text nhạy cảm. Log SQL chỉ type/code/state; internal không debug. Health anonymous chỉ trạng thái; test-safety chỉADMIN.
- Fixture protection: Java global TestExecutionListener yêu cầu SAN_BONG_TEST_MODE explicit; app env và SQL marker đều dev/test. HTTP preflight kiểm tra databaseName và guard; mọi prepare/cleanup SQL thêm marker trước các exact-ID guard. Không retag dữ liệu thật để chạy tests.
- Không SqlProxy.cs/exe trong project hiện tại, không dependency SqlProxy; Phase 7 không tạo hoặc sử dụng C# proxy.

## 4. Migration, backup và dữ liệu legacy
Áp dụng metadata `Phase7_EnvironmentMarker.sql` và permission `Phase7_LeastPrivilege.sql` trên nguồn/copy; nguồn dev, copy test rồi internal cho rehearsal sau review. Tạo dedicated SQL login và database user/role, không bảng/cột/index mới, không sửa tiền. Backup trước thay đổi metadata/quyền. DDL nghiệp vụ Phase 1–6 giữ nguyên.

Backup thực: COPY_ONLY/CHECKSUM/VERIFYONLY PASS; restore sang database riêng QuanLySanBong_Phase7_RestoreTest với file mdf/ldf riêng, DBCC CHECKDB PASS. Recovery SIMPLE; không có point-in-time log recovery. Bản restore giữ lại, không DROP và không ghi đè nguồn. Chi tiết file/path thực và quy trình nằm trong BACKUP_RESTORE_GUIDE.md.

| Legacy | DonGia trước/sau | TienSan trước/sau | TienDichVu | TienGiam | TongTien trước/sau |
|---|---:|---:|---:|---:|---:|
| DS01 |250000 /250000|250000 /250000|0|20000|230000 /230000|
| DS02 |300000 /300000|300000 /300000|0|0|300000 /300000|
| DS3b97491a |200000 /200000|200000 /200000|0|0|200000 /200000|

Nguồn sau khi tests kết thúc/cleanup: 7 sân, 3 bookings, 4 tài khoản, 3 nhân viên, 0 hóa đơn/thanh toán/hoàn tiền. Bản restore: 7 sân, 3 booking, 4 tài khoản; snapshot booking giống nguồn. 4 mật khẩu thử được đổi chỉ trên COPY để kiểm chứng internal; mật khẩu gốc không thay. `backend/phase7-sqlverify.log` chứa SQL verify cuối, không mật khẩu/hash.

## 5. Deployment / log / service
- Scripts start/stop/restart, Task Scheduler AtStartup + recovery3 lần/1 phút; không thêm service wrapper. Có guard PID identity, port đang dùng, env/JAR, health readiness; không tự kill process lạ.
- Đây là Task Scheduler preparation, chưa đăng ký Windows service SCM, chưa chạy elevated để đăng ký task/firewall hoặc reboot.
- Firewall script chỉ appport8080 TCP, Private/Domain, LocalSubnet; không mở Public/SQL1433. IP từ card LAN thực; frontend không hard-code IP. IPv4 quan sát trong rehearsal172.16.0.146, chỉ là chứng cứ máy hiện tại.
- Runtime source được đưa về loopback8080 với dedicated SQL login; không để bản rehearsal LAN8081 chạy sau kiểm chứng.
- Log application/error xoay10MB/ngày, giữ14 ngày, cap200MB/100MB. Startup stdout/error theo mỗi lần launch; operator cần retention riêng. Audit lưu SQL. Rotation cấu hình/khởi tạo appender đã kiểm tra; chưa mô phỏng vượt10MB hoặc 14 ngày.
- Stop script dùng Windows termination: chỉ stop sau khi ngừng ghi và hết request; SQL rollback transaction đang chạy. Foreground Ctrl+C dùng Spring graceful20s. Chưa chứng minh recovery sau reboot/crash; cần checklist manual.

## 6. UI cuối và CDN
Giữ phong cách/class/bố cục hiện có. Nối trang chủ khách với booking-options/bookings/booking-services; bỏ booking/MoMo/hoàn tiền mẫu, quick search ngày/start/end chuyển sang trang đặt sân API thật. Lịch giữ snapshot legacy. Sửa link sai tới module đã có; navigation chưa triển khai chuyển aria-disabled, không href="#". Menu mobile có handler; notification/controls prototype không báo thành công. Feedback mẫu trên trang nhân viên thay trạng thái chưa triển khai. Các trang khuyến mãi/đánh giá còn prototype được gắn cảnh báo và không quảng bá dữ liệu như trạng thái thật; không xây module mới.

Còn cần browser kiểm chứng: console/network, menu mobile, form, loading/empty/forbidden/unauthorized, responsive, thao tác hóa đơn từ calendar và refresh từ máy khác. Static PASS không tương đương render/UI PASS. CDN giữ hiện tại: Tailwind, cdnjs FontAwesome, Google Fonts, Wikimedia. Chưa chốt offline; khi mất Internet asset có thể không đầy đủ. Hướng local asset: lập danh sách version/license, đóng gói CSS/font/icon/ảnh tương ứng rồi render đối chiếu, không tải/thay toàn UI trong lượt này.

## 7. File thay đổi
Backend:
- src/main/resources/application.yml, application-internal.yml, logback-spring.xml.
- src/main/java/com/sanbong/config/InternalReadiness.java, SecurityConfig.java.
- src/main/java/com/sanbong/service/RuntimeSafetyService.java.
- src/main/java/com/sanbong/controller/HealthController.java, ApiExceptionHandler.java, BookingController.java.
- src/test/java/com/sanbong/RuntimeHardeningTest.java, TestDatabaseSafetyListener.java; src/test/resources/META-INF/spring.factories. Test cũ giữ nguyên.
- scripts/test-safety.mjs, phase7-e2e-http-check.mjs, phase7-frontend-check.mjs, phase7-internal-guard-check.mjs, cleanup-phase7-test.sql; tất cả phase2/3/4/5/5.1A/B/C/6 HTTP-check thêm preflight; các cleanup/prepare SQL cũ thêm marker guard.
- backend.ps1, README.md.
Deployment / SQL / tài liệu:
- database/migrations/Phase7_EnvironmentMarker.sql, Phase7_LeastPrivilege.sql.
- scripts/server.ps1, start-server.bat, stop-server.bat, restart-server.bat, register-server-task.ps1, configure-firewall.ps1, backup-database.sql, restore-test-database.sql.
- deploy.env.example, .env.example, .gitignore, AGENTS.md.
- docs/PHASE7_DEPLOYMENT_REPORT.md, INTERNAL_DEPLOYMENT_GUIDE.md, BACKUP_RESTORE_GUIDE.md.
Frontend: frontend/js/auth.js, bookings.js, finance.js, customer-home.js; HTML sửa link/placeholder/menu/prototype và trang chủ khách/nhân viên:
- frontend/Bao_cao.html
- frontend/Dang_ky.html
- frontend/Dang_nhap.html
- frontend/Dat_san_tai_quay.html
- frontend/Man_hinh_chinh.html
- frontend/Man_hinh_chinh_Dat_san_KH.html
- frontend/Man_hinh_chinh_KH.html
- frontend/Man_hinh_chinh_NVKH.html
- frontend/Man_hinh_chinh_NVKT.html
- frontend/Man_hinh_chinh_TK&PQ_HT.html
- frontend/Man_hinh_Khuyen_mai_KH.html
- frontend/Man_hinh_LS&ĐG_KH.html
- frontend/Quan_ly_lich_dat_san.html
- frontend/Quan_ly_san.html

Artifacts verify: backend/phase7-build.log, phase7-http.log, phase7-sqlverify.log, phase7-restore-drill.log, phase7-frontend-results.json; target/surefire-reports. Private env runtime/rehearsal và log/run/releases không commit/chia sẻ. Release đã giữ ở releases/san-bong-phase7-20261008.jar, SHA256 `8DA4EB2385C31EF676AFA544EBC2CFB43BAB0C126B741C091BBDB2509FB85C36`; runtime APP_JAR trỏ relative release để Maven clean sau này không khóa JAR đang chạy.

## 8. Thao tác manual còn bắt buộc — dừng triển khai tại đây
1. Chủ hệ thống chốt server và đổi mật khẩu demo trên nguồn qua quản trị; review backup rồi classification internal, dùng login runtime và certificate SQL phù hợp. Không tự thay password nguồn.
2. Administrator Windows xem/chạy configure-firewall.ps1 và register-server-task.ps1 với identity/ACL phù hợp; kiểm tra quyền và task sau reboot. Hiện session không Administrator nên không thực hiện hai bước này. Truy vấn Get-NetFirewallPortFilter bị Access denied (Windows error5), nên chưa audit được các rule SQL1433 hiện có; không tuyên bố SQL đã bị chặn với client. Dừng phần firewall tại đây, không dùng cách vượt quyền.
3. Máy client khác truy cập `http://SERVER_IP:8080/api/`, login/F5/booking/overlap/nhận-trả/dịch vụ/thanh toán/hoàn/báo cáo/quyền, DevTools và responsive; ghi bằng chứng thực. Chưa có browser/client qua công cụ.

Checklist đầy đủ và hướng dẫn từ máy mới: INTERNAL_DEPLOYMENT_GUIDE.md. Chưa có xác nhận Internet/offline; giữ CDN hiện có và báo dependency.

## 9. Giới hạn / rollback
Không có LAN client/browser PASS, HTTPS certificate, reboot/recovery PASS hay task/firewall thực tế; không gọi những mục này hoàn tất. Không tạo module khuyến mãi/đánh giá/feedback mới. Bảo trì shutdown Windows phải dừng ghi trước; dùng foreground nếu cần graceful. Database recovery SIMPLE; người vận hành phải chốt RPO/retention/offsite.

Rollback deployment: disable task, ngừng ghi, backup, đổi về artifact/env đã xác nhận schema tương thích rồi restart/check health. Giữ immutable JAR release trước mỗi upgrade; không hứa có sẵn artifact Phase6 sau Maven clean. Phase7 không đổi bảng/cột hoặc tiền nên không cần data rollback nghiệp vụ. Nếu phục hồi DB, restore vào database mới/verify trước rồi đổi APP_DB_URL, không tự restore đè nguồn. Không xóa/revoke role/login còn được ứng dụng dùng. Không đưa .env runtime hoặc secret vào git.

DỪNG sau Phase7 preparation; không tự mở phase tiếp theo. LAN chỉ được nâng trạng thái khi có máy client thực và checklist manual PASS.
