> Bản chụp kiểm tra trước đợt sửa mới. Ba mục chuẩn hóa/snapshot, view legacy và backup tự động đã được xử lý tiếp; xem [nghiệm thu 18/10/2026](DBMS_NORMALIZATION_VIEWS_BACKUP_2026-10-18.md) để biết trạng thái hiện hành và giới hạn.

# FINAL SYSTEM AUDIT — San_Bong

Ngày kiểm tra: 08/10/2026. Phạm vi: source hiện tại, toàn bộ test hiện có, JAR mới build, HTTP thật và SQL Server thật. Đây là báo cáo audit, chưa triển khai patch hoặc migration.

## 1. Executive summary

**GO cho demo có kiểm soát trên dev; NO-GO cho pilot có giao dịch tiền thật, vận hành nội bộ hằng ngày và production tại thời điểm audit.** Không công bố hệ thống sẵn sàng Internet.

Nền tảng đã hoạt động end-to-end: HTML/JS → REST/session/CSRF → Spring Boot → JDBC/JPA → SQL Server. `mvn clean verify` đạt **147 test, 0 failure, 0 error, 0 skipped**. JAR mới build khởi động, Hibernate validate, health UP; HTTP bốn role và đối chiếu thu/hoàn/báo cáo với SQL đạt PASS. Admin internal đăng nhập và đọc API bảo vệ đạt PASS.

Tuy nhiên, audit bổ sung phát hiện các nhánh ngoài regression hiện tại:

- **F01/P0, tính bất biến tài chính:** booking đã trả sân nhưng chưa có hóa đơn vẫn cho áp khuyến mãi; tổng tiền và doanh thu ngày đã ghi nhận bị thay đổi.
- **F02/P1, chính sách mật khẩu:** đăng ký chấp nhận một mật khẩu nằm trong danh sách bị startup internal cấm. Tài khoản mới như vậy có thể làm lần restart sau thất bại.
- **F03/P1, booking:** trạng thái sân đang sử dụng hiện tại chặn cả booking/availability ngày tương lai, dù không overlap.
- **F04/P1, vận hành quầy:** chưa có luồng nhân viên tạo khách hàng mới; đặt tại quầy chỉ dùng khách đã tồn tại.
- **F21/P1, cấu hình riêng:** `.env.runtime.local` dùng mật khẩu SQL không khớp login hiện tại. Chỉ kết luận cho file này; app internal đang chạy vẫn kết nối tốt.

Không thấy booking trùng, orphan/ràng buộc vi phạm hoặc tổng tiền sai công thức trong dữ liệu internal hiện có. Điều này không thay thế kiểm thử tải lớn hoặc cam kết không còn lỗi.

### Giữ an toàn môi trường

| Đối tượng | Cách kiểm tra | Kết quả bảo toàn |
|---|---|---|
| `QuanLySanBong_Phase7_RestoreTest`, marker internal | SQL đọc; HTTP admin login/GET/logout | Không chạy fixture/cleanup, không reset password/schema/dữ liệu nghiệp vụ |
| `QuanLySanBong`, marker dev | Toàn bộ regression; fixture HTTP có marker và cleanup exact ID | Còn đúng 3 booking legacy; tiền khớp bản internal; fixture sân/khách đã xóa hết |
| Internal server cổng 8080 | Giữ nguyên process; đọc health/API | Không stop/restart/build đè JAR đang chạy |
| Audit server cổng 8082, loopback | JAR build trong thư mục TEMP riêng; startup/restart test | Tách khỏi ứng dụng internal |
| Source HTML/CSS/JS/Java/SQL/script theo manifest | So sánh SHA-256 147 file trước/sau | 0 file thay đổi |

Hash của tài khoản và toàn bộ hàng DatSan internal trước/sau giống nhau; row count các bảng khác không đổi, riêng `NhatKyHeThong` tăng 452 → 455 do các lần đăng nhập audit. Không đăng nhập được bốn role internal vì không có mật khẩu của ba tài khoản còn lại; không tự reset để lấy quyền kiểm thử.

## 2. Architecture review

```text
Browser → HTML/CSS/JavaScript trong JAR, cùng origin /api
        → Spring Security: session + CSRF + role/permission
        → Controller → Service → Repository (JPA/JdbcTemplate)
        → Microsoft JDBC Driver → SQL Server TCP
```

Kiến trúc đúng định hướng, không có C# backend/SqlProxy dependency trong source/runtime được kiểm tra. Frontend dùng helper `SanBong.request`, không chứa JDBC hoặc database password; URL API theo origin, không ghim IP máy phát triển. `localhost`/loopback trong default backend và script health là cấu hình server, không phải frontend gọi nhầm API. Không thấy đường dẫn `C:\Users\...` bắt buộc trong application source; đường dẫn tool cục bộ dùng trong audit không được thêm vào source.

Service chịu trách nhiệm validation, ownership, tính giá, transaction và audit. Repository dùng bind parameter/JPA; SQL động báo cáo không ghép trực tiếp giá trị người dùng thành câu SQL. Hibernate giữ `ddl-auto=validate`, `open-in-view=false`, không tự tạo/sửa schema. Frontend được đóng gói từ thư mục HTML trong Maven; không cần Live Server.

Chức năng đang hoạt động lấy dữ liệu API thật. Một số prototype khuyến mãi/đánh giá/feedback được ghi rõ chưa hoàn thiện và bị chặn các thao tác giả; không coi chúng là module đã triển khai. Những route bị 403 theo role không phải link chết. Một lần probe audit GET `/admin/accounts` trả 405 vì route này dùng POST; đã sửa probe sang `/security/accounts`, không sửa project.

Code dư còn lại: logic giá theo BangGia và overload overlap theo KhungGio trong `BookingService`, một số hàm mẫu inline/prototype không được luồng thật sử dụng. Bảng/slot/giá legacy phải giữ vì còn lịch sử và màn hình đọc; không xóa chỉ vì booking mới dùng interval.

## 3. Customer journey review

| Bước | Kết quả | Bằng chứng/giới hạn |
|---|---|---|
| Khách cũ login/me/logout | PASS HTTP dev | Session thật tài khoản khách hiện có |
| Khách mới đăng ký/login | PASS HTTP dev | Tạo tài khoản/KhachHang fixture, role VT01; không tự chọn staff/admin |
| Xem availability/chọn giờ tự do | PASS API + review UI | Rule giờ/giá PASS regression; F03 chặn sân đang dùng dù ngày tương lai |
| Dịch vụ đặt trước | PASS HTTP/SQL | Nước suối lốc 6 = 29.100; booking 08–09 = 90.000 + 29.100 = 119.100 |
| Áp khuyến mãi tự phục vụ | Chưa có | Customer POST invoice bị 403 đúng policy hiện tại; prototype KM không kết nối nghiệp vụ |
| Tạo/xem booking, đọc lại sau đăng nhập mới | PASS HTTP dev | Session mới vẫn GET đúng booking đã lưu; đây là kiểm chứng persistence, chưa phải thao tác F5 trên browser |
| Thanh toán/yêu cầu xác nhận | PASS luồng hiện có | Khách chỉ tạo pending; accountant xác nhận mới tính thực thu |
| Hủy/xem refund | PASS khách cũ + regression | Refund dựa tiền đã thu; khách mới hủy booking chưa thu đạt PASS |
| Ownership/IDOR | PASS HTTP khách mới | GET booking/finance và POST cancel booking KH khác đều 403 |
| Đánh giá/feedback | Chưa hoàn thiện | Có prototype, không có luồng lưu/đọc API đầy đủ được chứng minh |

UX sơ bộ: **Chấp nhận được**, chưa đạt toàn bộ journey người dùng yêu cầu. Những vướng chính: không tự áp KM, chưa hướng dẫn rõ thông tin nhận chuyển khoản, danh mục nước suối trùng tên khác giá, mặc định hôm nay 08–09 có thể đã quá giờ, chưa có đánh giá thật. Không xác nhận console sạch/mobile tốt khi chưa có browser.

## 4. Staff journey review

Login → lịch → đặt cho khách có sẵn → xác nhận → nhận sân → phát sinh dịch vụ → trả sân → kiểm tra nợ hoạt động qua API. HTTP thật đã nhận sân, thêm Coca đơn bên cạnh lốc đặt trước, trả sân và kế toán thu phần còn lại. Regression kiểm tra sửa/xóa dòng, quantity sai, dịch vụ ngừng bán, rollback lỗi, chặn sửa dịch vụ sau trả sân, nhận sân lặp và chặn hủy khi đang chơi.

Khó vận hành quầy với khách vãng lai: lookup chỉ trả khách đã có; UI còn câu “Phase 4 chỉ đặt cho khách hàng đã có trong hệ thống.” Không có thao tác nhân viên nhập nhanh khách mới. Buộc khách tự đăng ký là workaround chưa được thiết kế cho quầy.

Concurrency booking và thao tác dịch vụ có integration test dùng SQL Server thật và transaction/lock riêng. Hai PUT số lượng tuyệt đối cùng dòng được tuần tự hóa, giữ tiền consistent nhưng lần ghi sau vẫn thắng; chưa có version để báo nhân viên đang sửa từ dữ liệu cũ. Đây là rủi ro lost update về ý định thao tác, **không phải double charge đã chứng minh**.

Staff có thể thu nếu role + CN04 cho phép; xác nhận hoàn bị giới hạn accountant/admin. Xem report cần permission tương ứng; role alone không đủ. UX sơ bộ: **Chấp nhận được với khách có sẵn**, chưa đủ vận hành quầy độc lập.

## 5. Accountant journey review

HTTP thật đạt: xem hóa đơn; xác nhận customer pending; thu từng phần và phần còn thiếu; refund pending → xác nhận hoàn; báo cáo doanh thu/thu/hoàn/thực nhận theo ngày/phương thức; kiểm tra lại SQL.

`FinanceIntegrationTest` đạt các nhánh idempotency, đổi payload cùng key, payment race không vượt nợ, refund race/retry một lần, refund dựa actual paid, boundary 10h/2h, rollback khi ghi audit thất bại. Pending payment/refund không được tính là actual cash. Nhận/trả sân không giả lập chuyển tiền ngân hàng.

Rủi ro lớn là F01: báo cáo doanh thu sau checkout vẫn thay đổi khi hóa đơn chưa tồn tại. Luồng kế toán cũng phụ thuộc danh sách giao dịch tải tất cả và lookup mã booking; với booking chưa có giao dịch phải nhập mã thủ công. `finance.js` có nhánh che mất lỗi reload sau POST thành công và nguy cơ đổi booking đang xem lúc mutation đang chạy.

UX sơ bộ: **Chấp nhận được**, nhưng **NO-GO dùng tiền thật trước F01**. Chưa chứng minh hiệu quả với danh sách dài hoặc thao tác trực tiếp trên browser.

## 6. Admin journey review

Đạt HTTP/regression: dashboard; CRUD/trạng thái sân; giá legacy đọc; catalog giá dịch vụ; tạo/sửa nhân viên; tạo/khóa/mở tài khoản fixture; reset BCrypt; revoke session; role cập nhật có hiệu lực với session hiện tại; logs và reports. API tài khoản không trả MatKhau. Nhân viên nghỉ làm bị khóa khả năng dùng session và không thể mở lại tài khoản trái trạng thái.

Chặn tự khóa tài khoản admin đang dùng và mất admin cuối cùng; PermissionService bảo vệ các quyền tối thiểu để quản trị/phục hồi. Role/permission được kiểm tra backend, không chỉ ẩn nút.

Chưa có quản trị giá theo ca thực tế; màn “Bảng giá & Khung giờ” vẫn đọc BangGia legacy trong khi booking mới đọc GiaTheoCa. Không có quản lý khuyến mãi tổng quát; điều kiện KM02 đang gắn theo mã cụ thể. Cần chốt phạm vi thay vì thêm CRUD/logic suy diễn tùy ý.

Admin internal: login → `/auth/me` → `/security/accounts`, `/reports/dashboard`, `/pitches`, `/finance/transactions` → logout PASS. Không reset bất kỳ tài khoản internal nào trong audit.

## 7. Business-rule review

| Rule | Kết quả |
|---|---|
| 1 cơ sở, nhiều sân, giờ tự do 07–22 | Đúng kiến trúc, PASS regression |
| Giá cả booking theo giờ bắt đầu | PASS M1–M5: 405.000 / 180.000 / 260.000 / 195.000 / 180.000 |
| Trước 07, sau 22, start=22, end≤start | Bị từ chối trong regression |
| Overlap đầu/cuối/trong/bao trùm; sát biên | PASS regression; HTTP overlap trả 409 |
| Concurrency overlap | San pessimistic lock + transaction + kiểm tra khoảng; PASS integration |
| Snapshot legacy | DS01=230.000, DS02=300.000, DS3b97491a=200.000 giữ nguyên |
| Giá SV01–SV07 | SQL internal đúng 50k/thùng; 5k; 10k; 10k; 12k; 10k; 12k |
| Lốc 6 giảm 3% | `unit × 6 × 0,97`, snapshot; SV02=29.100, SV03=58.200 |
| DAT_TRUOC/PHAT_SINH | Được lưu riêng; snapshot nguồn/quy cách/giá; PASS tests |
| TienSan phút/60×DonGia; giảm chỉ tiền sân; tổng | PASS test và SQL dữ liệu hiện tại; không dùng duration đã round để tính tiền |
| Cash/Transfer; trước/sau/từng phần | PASS HTTP và SQL |
| Không vượt tổng/thu; pending không actual | PASS regression, lock/idempotency/constraints |
| Hủy ≥10h:100%, ≥2h:50%, <2h:0% | SQL `fn_TyLeHoan` dùng datetime2/so sánh DATEADD, PASS boundary tests |
| Chốt dịch vụ sau trả sân | PASS |
| Chốt snapshot tài chính khi trả sân | **FAIL ở nhánh chưa có hóa đơn — F01** |

### F01 — tái hiện tài chính quan trọng

Trên fixture DEV, không thanh toán/lập hóa đơn trước: tạo booking → xác nhận → check-in → check-out. Booking thành “Đã sử dụng”, `GET finance` không có invoice. Sau đó accountant/admin `POST .../invoice {maKM:"KM02"}` vẫn trả 200.

Probe xác nhận: tổng 8.666,67 → 7.800; tổng doanh thu ngày/sân 216.616,67 → 215.750; invoice vừa tạo cuối cùng `daChot=true`. Báo cáo sử dụng fallback DatSan khi chưa invoice nên doanh thu sau trả sân bị giảm 866,67. Probe đầu tiên cũng cho tổng 10.833,33 → 9.750.

Nguyên nhân: `OperationsService.checkOut` gọi `finance.sync`; `sync` bỏ qua khi chưa có invoice. `sealed(id)` trả false khi chưa có invoice; `invoice()` kiểm tra sealed/paid/pending trước khi `ensure()`, không chặn theo lịch sử checkout. Báo cáo Phase5.1C mô tả hóa đơn đã chốt giữ snapshot; nhánh này phá tính bất biến đó. Không kết luận phép tính phần trăm sai hoặc tiền ngân hàng bị tự chuyển.

## 8. Database review

Live internal: **28 bảng, 37 FK, 48 CHECK, 41 index**. FK và CHECK đều enabled/trusted; `DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS` không báo vi phạm. Với FK được kiểm tra trên toàn dữ liệu, không tìm thấy orphan thuộc các quan hệ có FK. Không có cascade delete vô tình ở các FK nghiệp vụ được đọc.

PK/FK bảo vệ quan hệ; unique bảo vệ tài khoản/hóa đơn một booking/idempotency giao dịch; index interval DatSan theo San/ngày/bắt đầu INCLUDE kết thúc/trạng thái phù hợp hướng query. Index này **không tự bảo vệ interval overlap**: an toàn đến từ lock San và transaction kiểm tra overlap. Runtime không cấp DDL hay quyền xóa audit. DML trực tiếp bởi SQL administrator nằm ngoài bảo vệ interval của Service; không vận hành booking bằng sửa tay SQL.

Trigger `TRG_CapNhatTienDatSan` dùng tập inserted/deleted, SUM ThanhTien và đặt lại TienDichVu/TongTien; Java refresh entity rồi sync invoice, không cộng hai lần. Các test dịch vụ/concurrency/rollback đạt PASS. Constraint DatSan có mode, giờ, duration, status, số tiền không âm; không nên hiểu CHECK số tiền không âm là đã enforce mọi công thức nghiệp vụ bằng SQL.

Đối chiếu hiện tại internal: money formula mismatch=0; interval overlap=0; service total mismatch=0; invoice mismatch=0. Dataset rất nhỏ: 7 sân, 3 booking legacy, 0 hóa đơn/giao dịch/dịch vụ/visit. Giá/financial snapshots của lịch sử được giữ; không chạy script DROP hoặc migration.

View đang dùng: V_Phase6_Revenue theo ngày checkout và snapshot/fallback; V_ThuChiThucNhan chỉ confirmed payments/refunds; V_Phase6_UsageBooking theo phút, loại booking hủy. Báo cáo capacity dùng 900 phút/sân/ngày và danh sách sân hiện tại, không có lịch sử downtime/cấu hình sân theo từng ngày; UI đã giải thích đây là capacity lý thuyết.

View legacy cần cảnh báo: V_KhungGioTrong chỉ cross join sân/slot, chưa loại booking theo ngày; V_TyLeLapDay đếm slot không còn đúng giờ tự do; V_DoanhThuTheoNgay thực chất tổng receipt trước hoàn, không phải revenue theo nghĩa Phase6. Không thấy repository báo cáo hiện tại gọi các view legacy này; chúng là debt, không phải lỗi report runtime đã chứng minh.

N+1 có khả năng ở list DatSan: quan hệ customer/san/slot EAGER và truy cập loại sân; chưa đo số query trên dữ liệu lớn, nên ghi rủi ro, không khẳng định đã xảy ra nghẽn. Khi sửa cần projection/fetch có phạm vi, không refactor toàn bộ model.

Migration đề xuất riêng, chưa áp dụng: chỉ nếu chọn optimistic version cho các dòng sửa đồng thời thì thêm version + backfill/default/DTO/conditional update sau kiểm tra trigger/dependency. Ngừng bán SKU legacy là cập nhật catalog có phê duyệt, không xóa lịch sử. F01/F02/F03/F05 có thể sửa Java/JS không cần đổi schema. Giữ tất cả legacy snapshots.

## 9. Security review

Điểm đạt: BCrypt cost12; không plaintext internal; CSRF writes; session HttpOnly/SameSite Lax, timeout30m; filter reload quyền/status/credential fingerprint; reset password revoke session; ownership kiểm tra backend; API401/403; deny-default route; safe exception response; SQL parameter binding; dữ liệu động chủ yếu textContent/DOM, innerHTML của finance là template tĩnh. Static source scan không thấy database secret trong frontend. SQL runtime sysadmin=0, db_owner=0, CREATE TABLE=0, DELETE audit=0; UPDATE account/EXEC refund function được cấp cho nghiệp vụ cần dùng.

Health công khai chỉ UP/DOWN, không trả stack trace/credential. Môi trường internal cấm debug, migration plaintext và DDL auto update. Log giao dịch/audit dùng actor/số tiền/rule; test kiểm tra password fixture không xuất hiện trong API audit. Chưa chạy fuzz/XSS browser hay kiểm toán toàn bộ log lịch sử; không tuyên bố có pentest đầy đủ.

Các điểm cần sửa/chốt:

- F02: `RegisterRequest` cho min8 và AuthService không chặn denylist; HTTP dev đăng ký `12345678` trả 200. `InternalReadiness` từ chối tất cả active hash match danh sách có giá trị đó. Không thực hiện restart internal để chứng minh gây outage; nhánh khởi động được xác nhận bằng code/test guard.
- JAR thực tế dùng Spring Security **6.3.3**, Tomcat **10.1.30**, Spring Boot3.3.4. Library BCrypt probe với mật khẩu ngẫu nhiên 72 byte: matches chính xác=true; thêm suffix thành73 byte vẫn=true. Phiên bản nằm trong [Spring advisory CVE-2025-22228](https://spring.io/security/cve-2025-22228/). Không chứng minh bypass mật khẩu admin hiện tại; rủi ro phụ thuộc password đạt72 byte, đường tạo/reset nhân viên cho phép72. Không tự nâng dependency trong audit. Khi chọn version phải bao gồm các bản vá tiếp theo, không chỉ ghim bản đầu tiên sửa CVE.
- [Apache Tomcat security](https://tomcat.apache.org/security-10.html) có advisory cho các version cũ. CVE-2024-50379 yêu cầu write-enabled DefaultServlet trên filesystem không phân biệt hoa/thường; chưa thấy điều kiện write-enabled trong app nên **không gán RCE/P0 cho cấu hình này chỉ từ số version**. Cần dependency review đầy đủ trước release.
- Chưa thấy rate limit/lockout/backoff login/register trong app; có rủi ro brute force/CPU BCrypt. Không bắn tải gây DoS server internal.
- Internal hiện dùng HTTP; cookie không Secure trên HTTP, chưa có CSP. Đưa lên mạng phải chốt HTTPS/cert/cookie và phạm vi network; chưa xác nhận firewall SQL port hoặc LAN client isolation.
- `.env.runtime.local` thử khởi động instance dev trả SQL18456; SQL error log xác nhận password mismatch. Không sửa/revoke runtime login. Chọn đúng file cấu hình và xác nhận credential riêng trước dùng file này restart; không sao chép secret vào report/source.

## 10. Error handling và UI/UX review

| Code | Kết quả audit | Phạm vi |
|---|---|---|
| 400 | PASS | HTTP report ngày đảo; regression validation thời gian/quantity/input |
| 401 | PASS | HTTP anonymous API; session sau logout/reset/lock |
| 403 | PASS | HTTP role/ownership/CSRF; regression permission |
| 404 | PASS | HTTP pitch không tồn tại; regression booking/service missing |
| 409 | PASS | HTTP overlap/F03; regression duplicate/race/state conflict |
| 500 | Review code, chưa fault injection HTTP thật | ApiExceptionHandler trả message chung, log type; không tạo endpoint lỗi hoặc phá app để test |
| 503 | PASS unit health lỗi datasource; review handler/filter | Không chủ động ngắt SQL để thử HTTP503 trên server thật |

Frontend xử lý ApiResponse lỗi bằng exception và feedback. Không thấy nhánh POST thất bại mà code booking/operations vẫn báo đã lưu. **F10:** finance POST thành công nhưng GET reload lỗi bị `load()` catch nuốt; `mutate()` tiếp tục ghi thông báo thành công, che lỗi trạng thái mới. Đây là lỗi hiển thị sau lưu, không phải chứng cứ database không lưu mà báo thành công.

Static check đạt với **14 HTML**, **13 JS**: `node --check`; link tệp đích tồn tại; không `href="#"`; helper API cùng origin; UUID fallback bằng getRandomValues cho môi trường HTTP không có crypto.randomUUID. Các form đang hoạt động có pending/disable hoặc busy guard; bảng có empty state ở các module đã đọc. Timeout toast/debounce là mục đích thật, không gom mọi setTimeout thành fake success. Prototype còn hàm mẫu nhưng bị chặn/ghi rõ chưa triển khai.

Không có browser/app surface khả dụng (`apps=[]`, `browsers=[]`). Do đó **CHƯA KIỂM CHỨNG** render mobile/desktop, overflow, focus/modal, DevTools console/Network, bấm double-click thực tế, accessibility và F5 UI. Review class overflow/responsive hoặc JS busy guard không được coi là browser PASS.

CDN hiện có: cdn.tailwindcss.com, cdnjs.cloudflare.com, fonts.googleapis.com, fonts.gstatic.com, upload.wikimedia.org. API/HTML hoạt động local không chứng minh UI hoạt động offline. Nên giữ UI hiện tại nhưng đóng gói CSS/icon/font cần thiết nếu môi trường không bảo đảm Internet; tránh thêm framework.

Checklist manual sau patch: bốn role desktop/mobile; modal chi tiết/hóa đơn; keyboard/focus; bảng dài; lọc ngày/giờ; mạng mất trước/sau POST; loading/empty/error; reload; double-click; role revoke đang mở trang; API lỗi không success; SKU giá đúng; bank instruction; quầy khách mới; booking tương lai khi sân đang chơi; checkout chưa invoice; console/Network không lỗi. Chưa đánh dấu checklist này PASS.

## 11. Performance / stability review

- Hikari connection timeout5s, validation2s; không sửa pool. Chưa chứng minh SQL statement/lock timeout giới hạn theo SLA mọi query; slow query có thể giữ thread/connection lâu.
- Admin internal GET accounts44ms, pitches42ms, finance transactions55ms, dashboard239ms trong một lần đọc nhỏ. Đây không phải p95/p99 hoặc benchmark tải.
- JAR dev startup đầu19,213s; restart cùng JAR9,157s, healthUP/Hibernate validate. Không restart app internal/Windows/task/service.
- Report giới hạn khoảng ngày≤366, refund/log có pagination; booking/accounts/ledger và một số catalog/list vẫn tải tất cả. Usage ngày×sân và EAGER fetch cần đo khi volume tăng.
- InternalReadiness chạy tối đa5 BCrypt matches/active account lúc startup; tăng theo số tài khoản. `server.ps1` có vòng readiness45×500ms cộng thời gian health request. Chưa đo internal startup số lượng lớn; có nguy cơ vượt thời gian chờ script. Không tự đổi guard bảo mật hoặc làm benchmark hàng nghìn account trên internal.
- Concurrency/rollback hiện có đạt integration test; HTTP E2E hiện chạy workload chức năng nhỏ, không phải soak/load/HTTP concurrency benchmark.
- Log có rotation/retention/size cap. Chưa có bằng chứng heap/GC/leak dài ngày, pool saturation, task recovery, Windows reboot hay backup schedule/offsite/RPO được người vận hành xác nhận. Backup/restore drill Phase7 là bằng chứng cũ, không chạy restore lại hoặc thay lịch backup trong audit này.

## 12. Test results và bằng chứng

Build snapshot chỉ sao chép backend/frontend hiện tại vào TEMP để Maven clean không đụng JAR internal. Test Java và pom giữ nguyên; chỉ copy HTTP script vào TEMP và bổ sung probe audit riêng, không thay các test source hiện có.

| Kiểm tra | Kết quả |
|---|---|
| Maven3.9.9 / Java21, clean verify | **PASS147/147**, build success,2m53s |
| JDBC/entity schema validation | PASS SQLServerConnectionTest và startup JAR |
| JAR HTTP/SQL Phase7 E2E bốn role | PASS employee/account/session; booking/services/payments/cancel/refund/report |
| M1–M5, operating boundary, interval/concurrency | PASS trong147 integration/unit tests hiện có |
| Payment/refund race/idempotency/audit rollback | PASS FinanceIntegrationTest |
| Service snapshot/pack/concurrency/post-return guard | PASS ServiceSalesTest/OperationsConcurrencyTest |
| Fresh customer register/ownership/relogin/pack/cancel/logout | PASS HTTP dev bổ sung |
| CSRF401/403/404/409 + validation400 | PASS HTTP thực tế |
| Admin internal session/readonly API/logout | PASS; safety fixtureTestsAllowed=false |
| Future booking khi sân đang dùng | **FAIL nghiệp vụ**, HTTP409 dù ngày tương lai không overlap |
| Checkout không invoice rồi áp KM | **FAIL snapshot**, HTTP200 và SQL/API revenue thay đổi |
| Registration vs internal denylist | **FAIL policy alignment**, đăng ký200 cho giá trị guard cấm |
| Library BCrypt72/73-byte probe | Xác nhận behavior bị advisory; không dùng password thật |
| Internal consistency/PK-FK-CHECK | PASS theo dataset hiện tại; disabled/untrusted=0 |
| Legacy sau cleanup dev | PASS DS01/DS02/DS3b97491a; difference money so internal=0 |
| Source hashes147 file | PASS không đổi |
| Browser/UI/LAN/Windows reboot/load lớn | **NOT VERIFIED** |

Không xóa/skip test FAIL hoặc sửa code để làm test PASS. Regression PASS không bao phủ các counterexample audit mới.

Bằng chứng cục bộ, không commit/chia sẻ raw log chứa dữ liệu: `run/final-audit/maven-verify.log`, `http-e2e.log`, `extra-http.log`, `seal-probe.log`, `http-state.json`, `internal-http.json`, `database-audit-compact.txt`, `database-stats.txt`, `internal-before.txt`, `internal-after.txt`, `dev-after.txt`, `password-policy-probe.log`, `bcrypt-dependency-probe.txt`, `source-verification.json`, `dev-stdout.log`, `dev-restart-stdout.log`, `restart-result.txt`. Chỉ report này là tài liệu deliverable mới.

## 13. Bug / gap / readiness-gate table

Quy ước: **HTTP** = đã tái hiện; **CODE** = nhánh code xác nhận, chưa browser; **GAP** = chức năng còn thiếu, không giả định đã hoàn thành; **RISK/GATE** = chưa đủ bằng chứng vận hành. Cột “sửa ngay” nghĩa khả năng triển khai **sau khi được duyệt**, không phải đã sửa. File Java dưới `backend/src/main/java/com/sanbong/`.

| ID | Severity | Role | Module | Bug | Cách tái hiện | Nguyên nhân | Rủi ro | File liên quan | Sửa đề xuất | DB migration? | Sửa ngay? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | P0 | KT/Admin | Finance/report | HTTP: đổi tiền/revenue sau checkout chưa invoice | Checkout chưa thu/lập HĐ; POST invoice KM02 →200,8.666,67→7.800 | sync bỏ qua HĐ thiếu; sealed=false; promo chạy trước ensure | HIGH: snapshot tài chính sau trả sân bị thay đổi | service/FinanceService.java; OperationsService.java; repository/FinanceRepository.java; ReportRepository.java | Chốt snapshot khi checkout dù HĐ chưa có; guard returned; test nhánh thiếu HĐ và rollback | Không dự kiến; review dữ liệu đã returned trước patch | Có, patch nhỏ nhưng kiểm tra tài chính MEDIUM |
| F02 | P1 | KH/Admin | Auth/startup | HTTP+CODE: register cho password guard internal cấm | Đăng ký mật khẩu denylist đủ8 ký tự →200; restart guard sẽ từ chối | Policy tạo account và startup không thống nhất | HIGH: lần khởi động sau không phục vụ được | dto/RegisterRequest.java; service/AuthService.java; config/InternalReadiness.java | Policy chung cho register/create/reset; không bỏ guard; kiểm tra account hiện có có kiểm soát | Không | Có, LOW/MEDIUM |
| F03 | P1 | KH/NV | Booking | HTTP: sân hiện đang chơi chặn ngày tương lai | Check-in hôm nay; POST ngày+30 08–09 →409 | activePitch/availability buộc status Trống cho mọi date | HIGH: mất booking hợp lệ | service/BookingService.java | Tách trạng thái vận hành hiện tại khỏi lịch availability; giữ maintenance và interval/lock guards | Không | Có, MEDIUM |
| F04 | P1 | NV | Khách hàng/quầy | GAP: không tạo khách mới tại quầy | Lookup SĐT chưa có; không có bước nhập khách/tạo booking | Chỉ lookup khách hiện hữu | HIGH: quầy không tự nhận khách vãng lai | controller/BookingController.java; service/BookingService.java; frontend/js/bookings.js; Dat_san_tai_quay.html | Endpoint staff create/find customer có validation/unique/transaction; form nhỏ tái dùng UI | Chưa dự kiến; kiểm tra unique SĐT dependency | Cần duyệt phạm vi, MEDIUM |
| F05 | P2 | Admin/NV | Giá | CODE/GAP: bảng giá UI legacy khác nguồn giá booking mới | Mở Bảng giá & Khung giờ; đối chiếu GiaTheoCa | UI đọc BangGia/KhungGio; booking đọc GiaTheoCa | MEDIUM: đọc/giải thích nhầm giá; chưa có quản trị ca | service/PitchService.java; repository/TimePriceRepository.java; frontend/js/pitches.js | Hiển thị nguồn giá hiện hành rõ; nếu cho sửa phải giữ snapshot và quyền | Không cho phần hiển thị | Có, LOW; CRUD cần duyệt |
| F06 | P2 | KH/NV/Admin | Catalog | SQL+HTTP: 2 SKU nước suối active,5k/10k cùng chai | GET booking-services hoặc catalog | DV01 legacy active cùng SV02 mới | MEDIUM: chọn nhầm giá, quy cách thiếu ở legacy | service/OperationsService.java; bảng DichVu; frontend/js/booking-services.js | Chốt SKU legacy ngừng bán hoặc tên phân biệt; giữ toàn bộ snapshot/history | Không schema; cập nhật data cần duyệt | Có sau quyết định catalog, LOW |
| F07 | P2 | KH | Khuyến mãi | GAP: khách không áp KM trong journey | Trang mẫu KM; customer invoice403 | Chỉ employee invoice áp KM | MEDIUM: kỳ vọng journey không đạt | frontend/Man_hinh_Khuyen_mai_KH.html; FinanceController.java; FinanceService.java | Chốt self-service policy; hiển thị điều kiện/khi nào cần nhân viên; không đơn giản mở role | Chưa xác định | Không patch nóng, MEDIUM |
| F08 | P2 | KH | Thanh toán | CODE/GAP: thiếu hướng dẫn nhận chuyển khoản | Chọn transfer; không có bank account/nội dung hướng dẫn trong luồng | Chỉ ghi pending, không cấu hình hướng dẫn | MEDIUM: khách không biết chuyển cho ai | frontend/js/finance.js | Hướng dẫn/config recipient, trạng thái pending; không giả payment gateway | Có thể dùng cấu hình, không schema | Có sau cung cấp thông tin, LOW |
| F09 | P2 | KH/Admin | Đánh giá/feedback | GAP: chưa có review thật | Truy cập trang lịch sử/đánh giá prototype | Chưa có module API lưu/đọc | LOW/MEDIUM: journey chưa đầy đủ | frontend/Man_hinh_LS&ĐG_KH.html; frontend/js/auth.js | Giữ trạng thái chưa triển khai rõ; làm phase riêng nếu duyệt | Chưa xác định | Không cần trước pilot staff |
| F10 | P2 | KT/NV/KH | Finance UI | CODE: lỗi reload sau POST bị success che | POST200 rồi chặn GET reload; load catch, mutate status success | load nuốt error, không trả trạng thái lỗi | MEDIUM: trạng thái/nợ hiển thị không tin cậy | frontend/js/finance.js:64 | Propagate/return load result, báo đã lưu nhưng tải lại thất bại; test Network | Không | Có, LOW |
| F11 | P2 | KT | Finance UI | CODE/RISK: đổi booking từ ledger khi mutation busy | Đang POST rồi click dòng khác; chưa kiểm chứng browser | ledger click gọi load không guard busy | MEDIUM: nhầm chi tiết/thông báo mục đang xem | frontend/js/finance.js | Khóa đổi mục lúc busy hoặc kiểm tra booking/request version khi render | Không | Có, LOW |
| F12 | P2 | NV/KT/Admin | Lists/performance | CODE/RISK: nhiều list không pagination; EAGER có nguy cơ N+1 | Dataset lớn booking/accounts/ledger | findAll/list toàn bộ; nested entity fetch | MEDIUM: UI/query chậm, chưa đo tải | BookingService.java; model/DatSan.java; AdminRepository.java; FinanceRepository.java | Đo query trước; page/filter/projection có phạm vi | Có thể index sau EXPLAIN/plan, chưa cần ngay | Có theo volume, MEDIUM |
| F13 | P2 | NV/Admin | Đồng thời sửa | CODE/RISK: overwrite số lượng/giá từ bản cũ | Hai PUT absolute quantity khác nhau tuần tự | Lock đảm bảo tổng đúng nhưng không có expected version | MEDIUM: lost intent; không double-charge đã thấy | OperationsService.java; OperationsRepository.java; catalog service; operations.js | Chốt semantics; optimistic/expected version nếu cần conflict | Có nếu chọn version column | Cần duyệt, MEDIUM/HIGH |
| F14 | P2 | Tất cả | Auth | CODE/RISK: chưa app rate limit/backoff | Nhiều login/register thất bại; không thử DoS | BCrypt đắt, endpoint public không throttle | HIGH với Internet, MEDIUM nội bộ | config/SecurityConfig.java; AuthController.java | Rate limit/backoff phù hợp mạng nội bộ và error response; không khóa nhầm admin | Không bắt buộc | Sau duyệt, MEDIUM |
| F15 | P2 | Tất cả | Dependency/auth | LIB: BCrypt6.3.3 affected advisory,72byte+suffix vẫn match | Probe library offline72/73byte →true/true | CVE-2025-22228; login không enforce cap | HIGH conditional; chưa bypass account hiện có | backend/pom.xml; SecurityConfig.java; PasswordResetRequest.java | Dependency review bản vá tương thích/BOM; guard input; regression72byte/UTF8 | Không | Cần duyệt version, MEDIUM |
| F16 | P2 | Tất cả | Transport | LIVE/RISK: HTTP, chưa Secure cookie/HTTPS/CSP | Kết nối 8080 HTTP, header CSP absent | Cấu hình vận hành chưa chốt TLS | HIGH nếu mạng không tin cậy | application.yml; SecurityConfig.java; deployment guide | HTTPS/cert/Secure cookie và network scope; CSP phải tương thích UI/CDN | Không | Cần cấu hình/owner, MEDIUM |
| F17 | P2 | Tất cả | Assets | CODE/RISK: UI cần CDN ngoài LAN | Chặn Internet rồi mở trang; chưa render thử | Tailwind/icon/fonts/image remote | MEDIUM: mất style/icon trên mạng offline | 14 HTML; phase7-frontend-results.json | Đóng gói asset giữ UI nếu offline là yêu cầu | Không | Có sau chốt môi trường, LOW/MEDIUM |
| F18 | P2 | KH/NV | Search | CODE: hôm nay08–09 mặc định có thể đã qua | Sau08 mở search với default | Input cố định, ngày mặc định today | LOW/MEDIUM:400 ngay luồng đầu | customer-home.js; bookings.js; HTML booking/home | Chọn giờ tương lai hợp lệ hoặc bắt chọn ngày/giờ trước query | Không | Có, LOW |
| F19 | P3 | KT/Admin | SQL legacy | CODE: view legacy tên/ý nghĩa không đúng giờ tự do/revenue mới | Đọc view definitions; runtime mới không dùng | Giữ view minh họa theo slot/receipt | MEDIUM nếu đối soát thủ công nhầm | V_KhungGioTrong; V_TyLeLapDay; V_DoanhThuTheoNgay; Data SQL | Document deprecated; chỉ migrate view sau dependency review | Có nếu đổi view; không drop ngay | Có tài liệu, LOW |
| F20 | P3 | Dev | Cleanup/text | CODE: helper cũ/inline prototype và text Phase4 | Source scan, lookup báo technical phase | Code chuyển phase còn dư | LOW: bảo trì/khó hiểu | BookingService.java; HTML prototype; bookings.js | Sửa text trước; bỏ code chết chỉ sau usage check | Không | Có, LOW |
| F21 | P1 | Owner | Local deployment | LIVE: một file env riêng có SQL password stale | Start bằng .env.runtime.local →18456; SQL log password mismatch | File riêng không đồng bộ login hiện hành | HIGH nếu dùng file này restart; app đang chạy không lỗi | .env.runtime.local (private); scripts/server.ps1 | Owner xác nhận canonical env/ACL/credential; không đổi SQL login tự động | Không | Cần owner; LOW/MEDIUM |
| F22 | P1 | Owner | Release gate | GATE: chưa chứng minh UI/LAN/reboot/recovery/backup schedule | Thiếu browser/client/admin OS evidence | Phần manual Phase7 còn chờ; không khẳng định task chưa cài | HIGH: chưa đủ bằng chứng daily use | docs/INTERNAL_DEPLOYMENT_GUIDE.md; BACKUP_RESTORE_GUIDE.md; scripts/ | Manual acceptance/restore drill định kỳ/RPO/retention/task/firewall theo quyền | Không schema | Cần máy/client/WindowsAdmin |
| F23 | P2 | Owner | Startup scalability | CODE/RISK: startup BCrypt5N, readiness window hữu hạn | Tăng active users; chưa benchmark internal | Scan hash5 lần/account lúc init | MEDIUM: startup chậm/timeout khi lớn | config/InternalReadiness.java; scripts/server.ps1 | Đo staging; policy write-time + readiness timeout cấu hình; không hạ guard tùy ý | Không bắt buộc | Sau đo, LOW/MEDIUM |

## 14. Fix priorities

### A. Phải xử lý trước khi dùng tiền thật / daily use

F01, F02, F03, F04; xác nhận F21 canonical config; review/vá F15 và chính sách F16 theo môi trường; hoàn tất F22. F04 bắt buộc nếu nhận khách vãng lai, có thể giới hạn demo/pilot chỉ khách đã có nhưng không gọi quầy đầy đủ.

### B. Nên sửa

F05/F06 (giá/catalog rõ); F10/F11 (feedback/race UI); F08 (hướng dẫn transfer); F18; F14 phù hợp rủi ro network. F17 trở thành gate nếu chạy offline.

### C. Có thể để sau khi chốt phạm vi

F07/F09 (self-service KM/review); F12 theo volume; F13 theo semantics chỉnh số lượng; F23 sau benchmark staging. Không đưa các GAP chưa duyệt vào patch hotfix.

### D. Technical debt

F19/F20; các bảng review/backup/report prototype chưa dùng; capacity lịch sử bảo trì chưa lưu. Không xóa bảng/code/legacy/index theo suy đoán.

### Thứ tự triển khai đề xuất

| Fix | Phạm vi | Rủi ro thay đổi | Acceptance cần có |
|---|---|---|---|
| 1 | Security: đồng bộ policy F02; review bản vá F15; xác nhận secret/config F21, kế hoạch TLS F16 | MEDIUM | Không deny startup sau signup; byte boundary; không đổi password hiện có; session/CSRF giữ nguyên |
| 2 | Data integrity/money F01 | MEDIUM | Checkout không invoice vẫn snapshot bất biến; promo sau return409; report không đổi; transaction/audit rollback |
| 3 | Booking F03 | MEDIUM | Sân đang chơi cho đặt tương lai/sát biên hợp lệ; maintenance/overlap/check-in vẫn chặn; concurrency PASS |
| 4 | Role/quầy F04 | MEDIUM | Staff tạo khách tối thiểu có unique/validation, customer không gọi API staff; booking owner đúng |
| 5 | Functional UX F05/F06/F08/F10/F11/F18 | LOW/MEDIUM | Catalog/giá không nhầm; API lỗi không bị che; reload/double-click; giữ CSS/UI |
| 6 | Gate F22 và staging volume F12/F23; asset F17 nếu offline | MEDIUM | Browser4role, LAN client, reboot/task recovery, backup/restore, HTTPS/network theo checklist |
| 7 | Cosmetic/debt F19/F20; GAP F07/F09 chỉ khi duyệt | LOW cho text; MEDIUM cho module | Không phá legacy/routes; không tự mở phase |

Mỗi fix riêng: review dependency/schema → patch tối thiểu → test lỗi mới → full147 + test bổ sung → JAR/HTTP/SQL → báo file/kết quả → dừng theo phạm vi được duyệt. Không dùng migration để né lỗi mapping/Service.

## 15. Role readiness score

Điểm là đánh giá kỹ thuật sơ bộ trên source/API/test, **không phải điểm usability từ thử nghiệm browser**.

| Role | Điểm/10 | UX sơ bộ | Dùng thực tế ngay? | Vướng chính |
|---|---|---|---|---|
| Khách hàng | 6/10 | Chấp nhận được | Chưa trọn journey; demo được | F02/F03; KM/transfer/review/giá trùng; UI chưa browser |
| Nhân viên sân | 6/10 | Chấp nhận được với khách có sẵn | Chưa đủ quầy độc lập | F03/F04; giá legacy; stale quantity edits |
| Kế toán | 6/10 | Chấp nhận được | Không dùng tiền thật trước F01 | Snapshot sau return; reload lỗi/ledger dài; manual reconciliation |
| Admin/chủ sân | 7/10 | Chấp nhận được | Quản trị demo được; daily chưa đạt | Giá ca; env stale; startup policy; deployment acceptance |

## 16. Overall readiness score

**6,5/10 cho ứng dụng nội bộ ở trạng thái chuẩn bị vận hành**, không suy ra readiness bằng tỷ lệ147/147.

| Mức sử dụng | Kết luận | Điều kiện/bằng chứng |
|---|---|---|
| Demo đồ án | **GO có kiểm soát** | DB dev riêng; JAR/API/SQL PASS; trình bày giới hạn, không giao dịch tiền thật |
| Internal pilot có tiền/dữ liệu thật | **NO-GO hiện tại** | F01/F02/F03 và các gate phù hợp phải được xử lý; cần browser/client acceptance |
| Daily internal use | **NO-GO** | Quầy khách mới, tài chính, config, security/network và recovery chưa đạt đầy đủ |
| Public Internet | **NO-GO**, ngoài mục tiêu hiện tại | Không có bằng chứng pentest/TLS/rate limit/dependency hardening/public acceptance |
| Production nội bộ | **NO-GO** | Build PASS chưa đủ thay cho invariants tài chính + vận hành + acceptance |

## 17. Go / No-Go recommendation và điểm dừng

Phê duyệt patch có phạm vi nhỏ theo Fix1–3 trước; chốt quầy khách mới và catalog/giá sau đó; kiểm tra browser/ops trước dùng thật. Giữ Java/SQL Server/UI hiện có, không thêm kiến trúc phân tán hoặc proxy.

**Audit đã hoàn tất. Chưa sửa application source, authentication architecture, database schema, password hoặc dữ liệu nghiệp vụ internal. Chỉ tạo báo cáo này và artifact kiểm tra cục bộ trong run/TEMP. Dừng và chờ người dùng duyệt danh sách lỗi trước khi triển khai bất kỳ fix nào.**
