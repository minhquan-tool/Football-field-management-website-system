# Phase 6 — Quản trị và báo cáo nội bộ

Kiểm chứng ngày08/10/2026. **CODE COMPLETE / AWAITING MANUAL UI VERIFICATION**.

Build,141 integration/regression tests, JAR startup, JDBC, Hibernate validate, HTTP bốn vai trò và đối chiếu SQL đã PASS. Computer-use inventory trả `apps: [], browsers: []`, không có trình duyệt kết nối để thao tác UI. Không đánh dấu checklist UI PASS. Giữ stack và các nghiệp vụ Phase1–5.1C; chưa triển khai LAN/server.

## 1. Phạm vi và quyết định nghiệp vụ

Đã hoàn thiện nhân viên, tài khoản nhân viên, khóa/mở/reset, gán role, tái sử dụng ma trận quyền Phase2, nhật ký chỉ đọc, báo cáo sử dụng sân, doanh thu phát sinh, tiền thu/hoàn/thực nhận, phương thức thanh toán, báo cáo hoàn và dashboard admin.

- Nhân viên ngừng làm được giữ lại; khóa các tài khoản liên kết, không xóa vật lý lịch sử. Cho làm lại không tự mở tài khoản: admin phải mở rõ ràng.
- Một nhân viên mới chỉ được tạo tài khoản khi đang làm và chưa có tài khoản; không biến tài khoản khách thành nhân viên hoặc ngược lại.
- Không cho admin tự khóa/hạ quyền tài khoản đang thao tác, ngừng chính nhân viên liên kết hoặc làm mất quản trị viên hoạt động cuối cùng. Các thay đổi quản trị dùng SERIALIZABLE và khóa tập admin đang hoạt động để tránh hai thao tác song song bỏ qua kiểm tra cuối cùng.
- Doanh thu phát sinh tại **ngày trả sân**: tiền sân + dịch vụ − giảm sân, từ snapshot hóa đơn nếu có, fallback snapshot DatSan cho lịch sử đã sử dụng chưa có hóa đơn. Không tính booking hủy hoặc tiền trả trước chưa trả sân là doanh thu đã phát sinh.
- Tiền thu tại NgayThanhToan của giao dịch Thành công; tiền hoàn tại NgayXacNhan của khoản Đã hoàn. Thực nhận = tiền thu − tiền đã hoàn trong khoảng. Không lấy SUM HoaDon để gọi là thực thu; thực nhận một ngày có thể âm.
- Giờ được đặt là phút snapshot nằm trong07:00–22:00, loại booking hủy. Đã sử dụng xác định bằng lượt nhận/trả đã đóng. Booking hủy vẫn được đếm riêng.
- Lấp đầy là **công suất lý thuyết của danh mục hiện tại**:900 phút/ngày/sân, kể cả sân hiện đang bảo trì. Chưa có lịch sử mở/đóng/bảo trì nên không giả lập công suất khả dụng lịch sử. API và UI nêu cơ sở tính; đây không phải tỷ lệ đã trừ thời gian bảo trì. Lấp đầy của khoảng dùng tổng phút/tổng công suất, không lấy trung bình các phần trăm làm tròn.

## 2. Schema/view, backup và rollback

Audit schema thực tế NhanVien, TaiKhoan, NhatKyHeThong, permission, index/constraint và ba view hiện có. Không thêm/sửa bảng hoặc cột, không backfill, không sửa tiền legacy, không đổi dependency hoặc Hibernate `ddl-auto=validate`.

Hai view mới qua migration `database/migrations/Phase6_ReportViews.sql`:

| View | Nguồn/công dụng |
|---|---|
| V_Phase6_UsageBooking | Một dòng/booking, phút đặt cắt vào07–22, trạng thái, đã sử dụng; phục vụ aggregate ngày/sân |
| V_Phase6_Revenue | Snapshot của booking đã trả sân, ngày ghi nhận doanh thu; MAX thời gian trả tránh nhân bản khi join lượt sử dụng |

Giữ nguyên các view cũ:

- V_DoanhThuTheoNgay đang SUM thanh toán thành công: **tiền thu**, không phải doanh thu phát sinh/thu trừ hoàn. Không đổi nghĩa/cột cho dependency cũ; báo cáo mới dùng view doanh thu mới.
- V_ThuChiThucNhan từ5.1C dùng trực tiếp để tổng hợp tiền thu/hoàn/thực nhận và phương thức, không sửa.
- V_TyLeLapDay là view slot legacy; không dùng để đo booking giờ tự do. Giữ các cột/định nghĩa legacy để không phá consumer cũ; báo cáo phút mới thay thế việc sử dụng view này ở Phase6.

Migration kiểm tra đúng database/chưa migrate, có transaction/XACT_ABORT và rollback khi lỗi; đã chạy UTF-8 `sqlcmd -f 65001 -b`. Không chạy lại trên database đã áp dụng. Không thêm SP/trigger chỉ để trình diễn môn DBMS, không thêm index khi chưa có bằng chứng cần thiết.

Trước migration đã backup COPY_ONLY + CHECKSUM, RESTORE VERIFYONLY WITH CHECKSUM PASS:

`C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\QuanLySanBong_Phase6_PreViews_20261008.bak`

Đây là vị trí backup của máy kiểm thử, không phải đường dẫn phụ thuộc trong code. `Phase6_ReportViews_Rollback.sql` mặc định khóa; chỉ bỏ hai view mới sau review/phối hợp phiên bản backend, không xóa dữ liệu. Chưa chạy rollback hoặc restore.

## 3. API

Base mặc định `http://127.0.0.1:8080/api`. POST/PUT tiếp tục dùng session và CSRF.

| Method/path | Chức năng/quyền |
|---|---|
| GET /admin/options | Ngày server và role hiện có; ADMIN + CN07_XEM |
| GET /admin/employees?q=&active=&page=&size= | Danh sách/lọc/phân trang; ADMIN + CN07_XEM |
| GET /admin/employees/{id} | Chi tiết; ADMIN + CN07_XEM |
| POST /admin/employees | Thêm; ADMIN + CN07_THEM |
| PUT /admin/employees/{id} | Sửa/ngừng; ADMIN + CN07_SUA |
| POST /admin/accounts | Tạo tài khoản nhân viên; ADMIN + CN07_THEM |
| PUT /admin/accounts/{id} | Khóa/mở/gán role; ADMIN + CN07_SUA |
| POST /admin/accounts/{id}/reset-password | Reset; ADMIN + CN07_SUA |
| GET /admin/logs?from=&to=&actor=&action=&module=&target=&page=&size= | Nhật ký chỉ đọc; ADMIN + CN08_XEM |
| GET /reports/options | Ngày server/danh mục sân; role nội bộ + CN06_XEM |
| GET /reports/usage?from=&to=&pitch= | Vận hành; ADMIN/PITCH_STAFF + CN06_XEM |
| GET /reports/finance?from=&to=&pitch= | Doanh thu/thu/hoàn/thực nhận và phương thức; ADMIN/ACCOUNTANT + CN06_XEM |
| GET /reports/refunds?from=&to=&status=&booking=&method=&page=&size= | Báo cáo hoàn; ADMIN/ACCOUNTANT + CN06_XEM |
| GET /reports/dashboard | Tổng hợp ngày Việt Nam; ADMIN + CN06_XEM |

Tái sử dụng `/security/accounts`, `/security/permissions?role=...`, `PUT /security/permissions/{role}`. Không tạo module phân quyền trùng. Danh sách tài khoản vẫn giữ khả năng đọc được cấp CN07_XEM của Phase2; **các thao tác quản trị mới, đọc/sửa ma trận quyền chỉ admin có permission tương ứng**, không cho nhân viên tự nâng quyền.

Schema chưa có chức năng riêng cho nhân viên/nhật ký: quản lý danh tính nhân viên dùng CN07, nhật ký quản trị dùng CN08_XEM. Không tự tạo role hoặc chức năng mới để lách thiết kế hiện tại.

## 4. Authentication, validation và nhật ký

- BCrypt cost12 dùng encoder Phase2; không plaintext/hash trả trong API hoặc UI.
- Mật khẩu tài khoản mới/reset tối thiểu10 ký tự và tối đa72 byte UTF-8. Password input được xóa sau lưu/đóng; không lưu ở localStorage.
- SessionAccountFilter nạp lại role/permission/status mỗi request như trước. Bổ sung kiểm tra nhân viên đang làm và fingerprint của BCrypt hash lưu **chỉ trong session server**. Reset mật khẩu làm phiên cũ hết hiệu lực ở request tiếp theo; không thêm cột credential version vào DB.
- Nhân viên ngừng làm không login được; khóa tài khoản vô hiệu phiên cũ. Đổi role/permission có hiệu lực ở request tiếp theo, không phải đợi F5/login lại.
- Tên đăng nhập, liên kết nhân viên, loại owner, role, email/độ dài/điện thoại/ngày vào làm được validate backend; ngày báo cáo tối đa366 ngày, from≤to, giới hạn kiểu datetime SQL cũ. Phân trang1–100 rows/page; filter không nội suy vào SQL.
- Nhật ký Quản trị ghi người thao tác, ID, loại hành động và mô tả; reset không ghi mật khẩu/hash/token. UI không có sửa/xóa nhật ký; API không có route mutation nhật ký.
- Thay đổi nhân viên/tài khoản/quyền và nhật ký cùng transaction. Không có thao tác xóa nhân viên/tài khoản nghiệp vụ.

## 5. Query/report và UI

ReportService → ReportRepository → SQL Server, các query aggregate/set-based, prepared parameters; không lặp fetch từng booking để tính báo cáo.

| Báo cáo | Cơ sở/filter |
|---|---|
| Sử dụng sân | Calendar ngày × danh mục sân, left join view booking; vẫn có dòng0 khi không có booking; lọc sân/khoảng ngày |
| Doanh thu/ngày | Tổng snapshot tại ngày trả sân; tiền sân/dịch vụ/giảm/tổng tách riêng |
| Thu/hoàn/thực nhận | V_ThuChiThucNhan, khoảng `[from, to+1 ngày)` theo event tài chính |
| Phương thức | Cash/Transfer; count và tiền thu Thành công, % trên tiền thu; count/tiền hoàn riêng, thực nhận riêng |
| Hoàn tiền | Ngày xác nhận cho Đã hoàn; ngày yêu cầu cho chưa xác nhận; lọc status/booking/method, paging; có actor/time/tỷ lệ/thực thu lúc hủy |
| Dashboard | Booking hôm nay, sân đang dùng (lượt chưa trả), bảo trì, doanh thu, thực nhận, hoàn, lấp đầy, top5 dịch vụ và10 booking ngày |

Finance dùng2 query aggregate; usage1; refunds/logs2 gồm count/page; dashboard6 query báo cáo cố định, không tăng theo số booking. Không tuyên bố đã benchmark tối ưu lớn; dataset nhỏ hiện tại không chứng minh nhu cầu index bổ sung. Báo cáo bounded366 ngày, logs/refunds/employees có pagination.

Tái sử dụng layout/nav/card/font/CSS có sẵn:

- `Man_hinh_chinh.html`: thay dashboard, lịch/dịch vụ mẫu bằng dữ liệu thật. Không còn DS0192/PH042 hoặc số4.250K giả.
- `Man_hinh_chinh_TK&PQ_HT.html`: mở form tạo tài khoản, thêm bảng/form nhân viên và nhật ký, tái sử dụng ma trận quyền.
- `Bao_cao.html`: tái sử dụng khung giao diện quản trị; date/pitch/type filters, table/totals/methods, refund filters/pagination, loading/empty/error states. Role và CN06 quyết định loại báo cáo cho phép.
- Nav báo cáo/quản trị được nối tới trang thật, không toast báo thành công giả. Mọi dữ liệu đọc lại từ API khi F5.

## 6. Build/test và HTTP/SQL

`clean verify`: **141 tests,0 failure,0 error,0 skipped — BUILD SUCCESS** (2 phút53 giây).20 mới trong Phase6IntegrationTest +121 regression Phase1–5.1C. Log `backend/phase6-build.log`, XML `target/surefire-reports`. Node syntax check admin/reports/dashboard/permissions và HTTP script PASS.

JAR cuối khởi động ở127.0.0.1:8080/api, PID27432 tại thời điểm kiểm chứng, startup15,998 giây. Hikari kết nối thành công, EntityManagerFactory initialized, Hibernate validate PASS. SqlServerConnectionTest đọc trực tiếp TCP1433/QuanLySanBong và các Entity PASS; không dùng SqlProxy. Log `backend/phase6-startup.log`.

| Kiểm thử | Kết quả |
|---|---|
| Admin xem/tìm/lọc/thêm/sửa nhân viên, chi tiết | PASS |
| Ngừng nhân viên khóa tài khoản; không mở khi nhân viên chưa làm lại | PASS |
| Khóa không login, mất hiệu lực phiên; mở lại login | PASS |
| Reset BCrypt/no hash API/no secret audit, phiên cũ401 | PASS |
| Tạo trùng tài khoản nhân viên, password yếu/quá72 byte, owner sai bị chặn | PASS |
| Tự khóa/hạ quyền/ngừng admin đang thao tác bị chặn | PASS |
| Không đủ quyền403; đổi role/grant/revoke có hiệu lực ngay | PASS |
| Nhật ký filter, audit đúng, không mutation | PASS |
| Booking/used/cancel, phút/occupancy đúng SQL | PASS |
| Sân/dịch vụ/doanh thu vs tiền thu/hoàn/net/method đúng SQL | PASS |
| Trả trước chưa sử dụng không là doanh thu; hoàn pending không trừ net | PASS |
| Ngày/khoảng ngày inclusive, invalid range/filter/paging | PASS |
| Dashboard booking/net đúng SQL, snapshot legacy giữ nguyên | PASS |
| Toàn bộ regression booking giờ tự do/overlap/race/dịch vụ/finance |121 PASS |
| Browser/UI | CHỜ KIỂM CHỨNG THỦ CÔNG |

HTTP thật `backend/scripts/phase6-http-check.mjs`: **PHASE6_HTTP_PASS**, admin/kế toán/nhân viên/khách, session+CSRF, API equality với SQL (không chỉ status). Log `backend/phase6-http.log`.

Fixture P6H25ED2B/NVb8aa0dcb/TKdcabbbd9, password test ngẫu nhiên chỉ dùng trong memory:

| Booking/giá trị | SQL/API |
|---|---|
| DS13ddd2e3 ngày08/10, đã trả sân | Sân90.000 + Coca lốc58.200 =148.200; trả120.000; còn28.200; chưa hoàn tất tài chính |
| DSab3545e9 ngày28/10, đã hủy | Tổng130.000; thu50.000; hoàn50.000 đã được NV03 xác nhận |
| Revenue ngày08/10 |148.200 (không tính booking hủy) |
| Tiền thu / đã hoàn / thực nhận ngày08/10 |170.000 /50.000 /120.000 |
| Cash net / Transfer net |100.000 /20.000; phương thức hoàn Transfer50.000 tách riêng |
| Sử dụng sân test ngày08/10 |60 phút/900 phút=6,67%,1 booking đã sử dụng |

`backend/phase6-sql-before-cleanup.log` lưu đối chiếu. Script cleanup kiểm tra exact ID/marker/password giao dịch prefix, dependency/open visit; đã dọn1 hoàn,3 thu,1 hủy,1 dòng dịch vụ,2 hóa đơn,1 lượt nhận/trả,29 nhật ký fixture,2 booking,1 sân,1 tài khoản,1 nhân viên. Không xóa nhật ký nghiệp vụ bình thường qua API; cleanup chỉ dành fixture được kiểm soát.

SQL cuối `backend/phase6-sql-final.log`:3 nhân viên,4 tài khoản,7 sân,3 booking;0 invoice/payment/refund và0 nhân viên/sân fixture còn lại. Permission table giữ nguyên baseline; staff hiện chưa có CN06_XEM, phải admin cấp nếu cần báo cáo vận hành. Ba legacy tiền trước/sau:

| Booking | Đơn giá | Sân | Dịch vụ | Giảm | Tổng |
|---|---:|---:|---:|---:|---:|
| DS01 |250.000|250.000|0|20.000|230.000|
| DS02 |300.000|300.000|0|0|300.000|
| DS3b97491a |200.000|200.000|0|0|200.000|

Các lỗi kiểm thử đã sửa: tên sân fixture dài quá50 ký tự (rút tên test, không đổi schema); lệnh kiểm tra login khóa thiếu session CSRF (sửa harness); đường dẫn named pipe trong Node SQL verify escape sai (dùng SQLCMD_TEST_SERVER, mặc định TCP localhost1433). Fixture khởi tạo dở chỉ có nhân viên được kiểm tra marker/không account trước dọn. Không đổi backend sang proxy để xử lý lỗi.

Chạy lại HTTP chỉ trên môi trường dev/test đã bố trí thời gian: AUTH_TEST_PASSWORD và PHASE6_TEST_STATE trỏ file tạm, AUTH_TEST_BASE_URL/SQLCMD_TEST_SERVER tùy môi trường; `node backend/scripts/phase6-http-check.mjs`. Test nhận/trả cần07:00–20:50 giờ Việt Nam để tạo booking60 phút hợp lệ. Nếu lỗi, đọc state và dependency trước cleanup. Dọn bằng `sqlcmd -b -f 65001 -i backend/scripts/cleanup-phase6-test.sql -v PitchId=P6Hxxxxxx EmployeeId=NVxxxxxxxx AccountId=TKxxxxxxxx`, với kết nối test phù hợp. Không dùng script cho dữ liệu thật hoặc bỏ guard.

## 7. File thêm/sửa

Thêm:

- `database/migrations/Phase6_ReportViews.sql`, `Phase6_ReportViews_Rollback.sql`.
- `backend/src/main/java/com/sanbong/controller/AdminController.java`, `ReportController.java`.
- `backend/src/main/java/com/sanbong/service/AdminService.java`, `ReportService.java`.
- `backend/src/main/java/com/sanbong/repository/AdminRepository.java`, `ReportRepository.java`.
- `backend/src/main/java/com/sanbong/dto/EmployeeRequest.java`, `StaffAccountRequest.java`, `AccountUpdateRequest.java`, `PasswordResetRequest.java`.
- `backend/src/test/java/com/sanbong/Phase6IntegrationTest.java`.
- `backend/scripts/phase6-http-check.mjs`, `cleanup-phase6-test.sql`.
- `frontend/Bao_cao.html`, `frontend/js/admin.js`, `reports.js`, `dashboard.js`.
- Báo cáo này.

Sửa:

- `AccountPrincipal.java`: trạng thái nhân viên vào điều kiện login.
- `AuthService.java`, `SecurityConfig.java`, `SessionAccountFilter.java`: fingerprint server/session, role/route mới, reset revoke; giữ session/CSRF Phase2.
- `PermissionController.java`: role admin cho đọc/sửa ma trận; giữ read capability danh sách tài khoản Phase2.
- `SecurityRepository.java`: thêm MaNV/MaKH vào danh sách an toàn, không hash.
- `frontend/js/permissions.js`: tái sử dụng phân quyền, danh sách account giao admin.js, lỗi không dùng toast success.
- `frontend/Man_hinh_chinh.html`, `Man_hinh_chinh_TK&PQ_HT.html`: dashboard/forms thực.
- Các trang HTML hiện có có link báo cáo/tài khoản/nhân viên/nhật ký dạng `href="#"`: nối nav tới trang thật; giữ nội dung nghiệp vụ Phase1–5.1C.
- `AGENTS.md`, `backend/README.md`: phạm vi Phase6/hướng dẫn và điểm dừng.

Không sửa pom/JDBC driver/booking overlap/giá/service snapshots hoặc finance money workflow để làm Phase6.

## 8. Manual UI checklist

URL gốc `http://127.0.0.1:8080/api`; đăng nhập `/Dang_nhap.html` bằng credentials hiện tại. Test fixture tự động đã dọn; tạo dữ liệu kiểm tra có ghi chú riêng, không sửa ba booking legacy.

**Admin — `/Man_hinh_chinh_TK&PQ_HT.html`:**

1. Danh sách tài khoản/nhân viên đọc thật;3 nhân viên/4 tài khoản baseline. Thử tìm/lọc Đang làm/Ngừng, xem chi tiết, phân trang khi đủ dữ liệu; form tạo mặc định ẩn.
2. Thêm nhân viên test, sửa chức vụ/bộ phận/ngày, F5 giữ thay đổi. Tạo tài khoản từ nhân viên đang làm chưa có account, role lấy từ DB; password10–72 byte, không hiện hash. Tạo trùng/invalid input không báo thành công.
3. Đăng nhập tài khoản test ở trình duyệt/phiên riêng. Khóa ở admin → request tiếp theo phiên test401 và login bị từ chối. Mở → login lại. Ngừng nhân viên → account khóa; mở khi nhân viên chưa làm lại bị409. Không thử ngừng NV01 trên dữ liệu thật.
4. Reset bằng password input ở admin → phiên test cũ401, password cũ không login, password mới login; UI không lưu/reveal hash. Reset chính admin sẽ quay về login.
5. Đổi role test staff ↔ accountant → API/quyền đổi ở request tiếp theo. Gán/bỏ CN06_XEM cho VT02 trong ma trận (chỉ khi đã bố trí kiểm thử), phiên staff xem báo cáo vận hành200/403 đúng; ghi lại và khôi phục quyền sau test. Staff/khách không tự sửa ma trận.
6. Nhật ký từ/đến/user/action/module/target, row mới có actor/ID/nội dung đúng, không password/token. Chỉ đọc; không có nút xóa/sửa. F5 đọc SQL, filter/paging hoạt động.

**Admin — `/Man_hinh_chinh.html`, `/Bao_cao.html`:**

7. Ngày lấy giờ Việt Nam; dashboard baseline ngày08/10 có số liệu0 nếu không thêm booking hôm nay, không hiện số mẫu cũ. Tổng số sân7, bảo trì/đang dùng từ DB. Click lịch dùng chức năng thật; top services rỗng khi chưa có booking đã trả.
8. Tạo booking test60 phút trong giờ07–22, Coca SV03 lốc6: dịch vụ58.200, sân lấy ca start. Thu100.000 cash và20.000 transfer (kế toán xác nhận pending nếu khách gửi), nhận/trả sân. Nếu start07–13, sân90.000, tổng148.200, còn28.200, chưa hoàn tất. Doanh thu148.200 tại ngày trả, tiền thu120.000 tại ngày nhận; service snapshot không bị định giá lại.
9. Lọc Usage đúng ngày/sân →1 used booking,60 phút/900=6,67%. Hủy booking khác → tăng count hủy, không tăng phút. Range nhiều ngày tính tổng capacity900×số ngày×số sân được chọn; đọc chú thích công suất danh mục, không coi là net capacity đã trừ bảo trì.

**Accountant — `/Bao_cao.html` và `/Man_hinh_chinh_NVKT.html`:**

10. Chỉ report tài chính/hoàn được phép; không quản trị nhân viên/permission. Finance chọn date/range/pitch → tiền sân/dịch vụ/giảm/doanh thu/thu/hoàn/net tách biệt.
11. Booking tương lai đã thu50.000 Transfer, hủy≥10h → pending refund50.000, net chưa giảm. Sau xác nhận trả thật → ngày xác nhận có hoàn50.000/net giảm50.000; Cash không giảm nếu hoàn bằng Transfer. Báo cáo phương thức chỉ thu Thành công, tỷ lệ tính trên gross thu.
12. Refund filter status/booking/method/date: row có tiền thu, thực thu lúc hủy, tỷ lệ, hạn mức booking, khoản hoàn, actor/time. Khoản pending chưa có người xác nhận. Không cộng cột hạn mức booking lặp ở nhiều giao dịch. F5 giữ đúng SQL.

**Staff — `/Bao_cao.html`:**

13. Baseline VT02 chưa CN06_XEM → thông báo chưa được cấp, API403; không số liệu giả. Nếu admin cấp CN06_XEM → Usage truy cập được, Finance/Refund/Admin vẫn403. Không được tự nâng quyền.

**Cả ba vai trò:**

14. Loading/empty/error rõ ràng; filter ngày đảo/ngày quá366/page invalid bị từ chối; F5 không mất dữ liệu đã lưu; console không lỗi. Kiểm tra cuộn bảng/modal trên màn hình nhỏ và chữ/label tiếng Việt. Các thay đổi chưa được kiểm chứng browser phải ghi FAIL/issue cụ thể trước deployment, không tự đánh dấu PASS.

## 9. Technical debt và trước deployment nội bộ

- Cần hoàn thành checklist browser, đối chiếu báo cáo với định nghĩa doanh thu tại trả sân đã chọn và công suất lý thuyết danh mục. Nếu cần occupancy net khả dụng lịch sử, phải thiết kế lịch đóng/bảo trì trước, không suy ngược từ trạng thái San hiện tại.
- Chưa PDF/export kế toán, tự đối soát/cổng ngân hàng hoặc hỗ trợ tự động cưỡng chế đổi password lần đầu. Reset hiện tại do admin, audit và hết hiệu lực phiên; cần quy trình bàn giao password riêng, không gửi bằng nhật ký.
- Báo cáo hoàn lịch sử đã hoàn trước5.1C mà không có NgayXacNhan cần đối soát để xác định ngày thực chi. Dataset baseline không có trường hợp đó; không tự backfill bằng ngày yêu cầu và ghi sai thực nhận.
- Tìm tài khoản hiện lọc ở frontend trên danh sách nhỏ; đánh giá pagination server khi số tài khoản tăng. Chỉ thêm index theo query plan/đo thời gian trên dữ liệu thực, không thêm tùy ý lúc dataset nhỏ.
- Trước deployment: credentials/password dev phải thay phù hợp; cấu hình host/port/database/cookie HTTPS theo môi trường, quyền SQL tối thiểu, backup/restore vận hành được kiểm tra, tải CDN font/Tailwind/icons cần đường truy cập hoặc phương án đóng gói nội bộ được phê duyệt. Chưa thay stack/build dependency để xử lý offline trong Phase6.

**Dừng sau Phase6. Không tự triển khai LAN/server.**
