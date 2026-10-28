# San_Bong backend — Hệ thống quản lý sân bóng

Web App nội bộ: HTML/CSS/JavaScript → REST → Java Spring Boot → SQL Server.
Giữ Java 24, Spring Boot 3.5.16, Microsoft JDBC 12.8.1.jre11; không thêm dependency.
HTML hiện tại được đóng gói vào JAR bằng Maven resources, không nhân bản source.
Host dev mặc định là 127.0.0.1. Các mục Phase 2–6 bên dưới là lịch sử phát triển;
trạng thái hiện hành và giới hạn release xem báo cáo audit/fix trong `../docs/`.
LAN chỉ được nghiệm thu từ client thật.

## Cấu hình và chạy

Trang mở đầu hiện tại là `/api/` → `/api/Trang_chu.html`: khách vãng lai xem/tìm sân
và bản đồ mà không cần đăng nhập. Đặt sân và API nghiệp vụ vẫn giữ xác thực/phân quyền.
Chi tiết: `../docs/PUBLIC_GUEST_HOME_2026-10-14.md`.

Thiết lập JAVA_HOME trỏ tới JDK 24 và dùng Maven trên PATH hoặc MAVEN_HOME.
`manage-backend.ps1` và `scripts/server.ps1` kiểm Java 24 trước build/start; restart kiểm
toolchain và JAR trước khi dừng tiến trình cũ. Maven dùng processor Lombok tường minh,
giữ version đã được Spring Boot quản lý.
Script cũng tìm bản Maven portable đã dùng trong Phase 1 ở thư mục tạm.
Không cần thay PATH hệ thống. Code không phụ thuộc đường dẫn máy phát triển.

Credentials bắt buộc qua APP_DB_USER, APP_DB_PASSWORD. Có thể sao chép
.env.example thành .env ở gốc project để chạy local; .env được gitignore,
không commit hoặc đóng gói vào JAR. Khi dùng `.env` mặc định, biến môi trường có ưu tiên.
Nếu truyền `-EnvFile` explicit, file được chọn có ưu tiên để tránh config process cũ.
Chuẩn bị DEV/test theo `../docs/TEST_ENVIRONMENT_SETUP.md` và `.env.test.example`.
Các biến triển khai: APP_DB_URL, APP_HOST, APP_PORT, APP_CONTEXT_PATH,
APP_SECURE_COOKIE (bật khi dùng HTTPS). Giữ ddl-auto=validate.

```powershell
./backend/manage-backend.ps1 build
./backend/manage-backend.ps1 run
```

Full regression yêu cầu `SAN_BONG_TEST_MODE=dev/test`, datasource đúng identity và
database có marker dev/test; không chạy fixture trên internal. Script SQL
`cleanup-*-test.sql`/`prepare-*-test.sql` không tự đổi database. Chọn target được
review bằng `sqlcmd -d`, dùng `-b -f 65001`; opt-in bằng biến môi trường
`SAN_BONG_TEST_MODE=dev/test` hoặc `-v SAN_BONG_TEST_MODE=dev` cùng fixture ID.
Không chạy bootstrap/reset database để sửa lỗi. Kiểm policy không truy cập DB:

```powershell
node backend/scripts/fixture-sql-safety-check.mjs
./backend/scripts/java-toolchain-check.ps1
```

Mở http://localhost:8080/api/Dang_nhap.html. Đăng nhập bằng username/email/số điện thoại.
Cookie HttpOnly, SameSite=Lax; phiên hết hạn sau 30 phút không hoạt động.
CSRF bảo vệ request thay đổi dữ liệu, gồm login/logout. Checkbox ghi nhớ vô hiệu
hóa vì chưa có persistent login.

## Chuyển dữ liệu cũ

database/migrations/legacy/security-permissions.sql chỉ INSERT quyền còn thiếu trong transaction, không ghi đè
quyền đang có hoặc đổi schema. Quyền mặc định:
- VT04: đầy đủ 8 chức năng.
- VT02: khách hàng, đặt sân, dịch vụ, ghi nhận thanh toán, xử lý phản hồi.
- VT03: thanh toán và báo cáo.
- VT01: đặt sân, thanh toán, phản hồi; các phase nghiệp vụ phải giới hạn theo chủ sở hữu.

Chỉ khi xác nhận password cũ là plaintext, chạy một lần với
APP_MIGRATE_LEGACY_PASSWORDS=true, rồi bỏ biến hoặc đặt false. Migration BCrypt
cost 12 có transaction, bỏ qua BCrypt hợp lệ và dừng khi gặp dạng hash lạ.
Đã chuyển 4 tài khoản mẫu trên máy hiện tại. SeedData dùng BCrypt.
Tài khoản mẫu vẫn dùng password demo yếu; cần thay trước khi triển khai thực tế.
Không chạy script schema có DROP DATABASE.

## Phạm vi Phase 2

- Login/logout, đăng ký khách hàng VT01, /auth/me, /auth/permissions.
- Danh sách tài khoản và ma trận quyền lấy dữ liệu SQL Server thật.
- Lưu ma trận quyền trong transaction; backend kiểm tra quyền Xem/Sửa.
- Khóa account hoặc thay quyền trong DB có hiệu lực trên phiên đang mở.
- Nhật ký login/logout/đăng ký/thay quyền vào NhatKyHeThong; không log password.
- Chưa có thêm/sửa/khóa tài khoản qua UI, quên mật khẩu, persistent login hoặc API sân.
  Các thao tác demo chưa có API bị vô hiệu hóa để tránh báo thành công giả.

API trả JSON {success,message,data}; 400 dữ liệu sai, 401 credentials sai/chưa xác thực,
403 thiếu quyền/CSRF, 409 trùng dữ liệu, 503 database không khả dụng.
Không trả entity/password cho client. Không dùng JWT hoặc SqlProxy.

## Kiểm tra

clean verify chạy test JDBC/JPA Phase 1 và authentication với database thật.
Test authentication có transaction rollback, không để lại tài khoản/đổi quyền mẫu.
Kiểm tra 4 role, password sai, account khóa, CSRF, logout, đăng ký/hash/duplicate,
lưu quyền và hiệu lực trên phiên đang mở. Cần dữ liệu mẫu BCrypt và quyền ban đầu.
Không chạy test trên database đang phục vụ người dùng.

Nghiệp vụ/báo cáo trên dashboard chưa hoàn thiện vẫn là giao diện mẫu.
Phase 3 đã bổ sung quản lý sân; xem docs/PHASE3_REPORT.md ở gốc project.
Chưa chuyển sang booking/thanh toán hoặc triển khai LAN.

## Quản lý sân — Phase 3

Mở /api/Quan_ly_san.html sau đăng nhập vận hành/quản trị. API /pitches hỗ trợ
GET danh sách (q/type/status), GET /{id}, POST thêm, PUT /{id} sửa và PATCH
/{id}/status. GET /pitch-types, /pitch-prices, /pitches/{id}/prices chỉ đọc.
Quyền CN02_XEM/THEM/SUA cộng role ADMIN/PITCH_STAFF được kiểm tra ở backend.
Không có DELETE; bảo trì bị chặn khi sân đang sử dụng hoặc còn booking xác nhận
từ hôm nay trở đi. Không sửa snapshot giá booking hoặc schema.

clean verify hiện chạy 14 tests. HTTP check sử dụng AUTH_TEST_PASSWORD và
PHASE3_TEST_STATE, tạo đúng một sân tạm để đọc SQL/refresh rồi phải cleanup.
cleanup-phase3-test.sql chỉ nhận ID sinh dạng T3T + 6 hex, kiểm tra marker/history.
Khi chạy sqlcmd -i với script UTF-8, thêm -f 65001. Không chạy cleanup trên sân thật.
Xác nhận browser/refresh đang chờ; chưa đánh dấu Phase 3 DoD hoàn thành.
# Phase 4 — tra cứu và đặt sân

API: `GET booking-options`, `GET booking-customers?phone=...`,
`GET availability?date=...&type=...&slot=...&status=...`,
`GET bookings?date=...&pitch=...&slot=...&status=...`, `GET bookings/{id}`,
`POST bookings`, `POST bookings/{id}/confirm`, `POST bookings/{id}/cancel`.
Tái sử dụng session, CSRF và CN02; CUSTOMER chỉ thao tác booking của mình.
Giữ filtered unique index, khóa sân trước booking, transaction bao gồm nhật ký/hủy.
Không thu tiền/giao sân; booking có tiền cần quy trình Phase 5.

Giá cho cả khung giờ lấy từ BangGia theo ngày hiệu lực/loại ngày, lưu snapshot vào DatSan;
không fallback giá cuối tuần/lễ. Có thể đặt `APP_BOOKING_HOLIDAYS` thành các ISO date
phân cách dấu phẩy; mặc định rỗng, người triển khai quản lý lịch lễ thực tế.

Build/test như hướng dẫn hiện có. HTTP check dùng `AUTH_TEST_BASE_URL` (tùy chọn),
`AUTH_TEST_PASSWORD`, `PHASE4_TEST_STATE` rồi chạy `node backend/scripts/phase4-http-check.mjs`
từ root. Script tạo fixture riêng; cần đối chiếu SQL và cleanup exact ID bằng
`backend/scripts/cleanup-phase4-test.sql` với sqlcmd `-b -f 65001 -v PITCH_TEST_ID=<generated-id>`.
Không dùng script cleanup này cho dữ liệu nghiệp vụ hoặc checklist UI thủ công.

Kết quả: 37 tests PASS. Phase 4 **CODE COMPLETE / AWAITING MANUAL UI VERIFICATION**.
File thay đổi, business rules và checklist A–J: [PHASE4_REPORT.md](../docs/PHASE4_REPORT.md).
Dừng trước Phase 5.

# Phase 5 — phần vận hành đã có, tài chính đang dừng

`GET services`, `GET operations/bookings/{id}`, `POST .../check-in`, `POST .../check-out`,
`POST/PUT/DELETE .../services/{serviceId}` dùng role nhân viên sân/quản lý và CN02/CN03 hiện có.
Nhận trong ngày chơi từ30 phút trước bắt đầu đến trước kết thúc; trả sân không có nghĩa đã thu tiền.
Snapshot giá dịch vụ giữ ở ChiTietDichVu, computed column + trigger tính tổng; Java không cộng lần hai.

58 tests PASS (37 regression +21 vận hành). Phase 5 chưa CODE COMPLETE:
HoaDon chưa tồn tại; proposal ở `database/migrations/Phase5_HoaDon_PROPOSAL.sql` chưa được thực thi.
Không có endpoint payment/refund mới hoặc cổng ngân hàng giả.
Schema/điểm dừng, file thay đổi và checklist vận hành: [PHASE5_REPORT.md](../docs/PHASE5_REPORT.md).

HTTP vận hành: chuẩn bị fixture exact ID P5H+6hex bằng
`backend/scripts/prepare-phase5-operations-test.sql`; đặt `OPERATIONS_TEST_ID`, `AUTH_TEST_PASSWORD`,
`AUTH_TEST_BASE_URL` nếu cần rồi chạy `node backend/scripts/phase5-operations-http-check.mjs` từ root.
Đối chiếu SQL và cleanup bằng `cleanup-phase5-operations-test.sql` cùng ID, `sqlcmd -b -f 65001`.
Các script này chỉ dành test isolated, không dùng cho lịch sử nghiệp vụ/booking manual.

# Phase 5.1A booking giờ tự do

Booking mới gửi `ngayChoi`, `gioBatDau`, `gioKetThuc`, `maSan` và khách hàng theo quyền.
Giờ theo phút trong 07:00–22:00. GET `/availability?date=...&start=08:00&end=12:30`
trả sân khả dụng và giá từ GiaTheoCa. Mã slot vẫn đọc được cho legacy; API slot cũ
khi tạo booking mới cũng dùng giá giờ chính thức, không bán lại giá snapshot cũ.
Không gửi cả slot và giờ tự do trong cùng request.

Giờ snapshot trong DatSan là nguồn cho lịch, overlap, check-in và hủy. Tiền legacy
giữ nguyên; thời lượng hiển thị làm tròn 2 chữ số, tiền tính trực tiếp từ phút/60.
Migration chỉ chạy sau backup/dependency review; dùng `sqlcmd -f 65001 -b` cho file UTF-8.
Script proposal và rollback không tự chạy. Xem `docs/PHASE5_1A_BOOKING_TIME_PRICE_REPORT.md`.
HTTP test: `scripts/phase5-1a-http-check.mjs`, env AUTH_TEST_PASSWORD và PHASE5_1A_TEST_STATE;
cleanup dùng script riêng với ID/marker đã kiểm tra. Chưa triển khai 5.1B/tài chính mới.

# Phase 5.1B: dịch vụ và quy cách bán

Catalog chính thức dùng SKU mới SV01–SV07, giữ DV01–DV06 legacy. `DonGia` catalog luôn là giá đơn vị; `giaLoc` do backend trả về (đơn giá × 6 × 0,97). Booking nhận `dichVu: [{maDV,soLuong,quyCach}]` trong cùng transaction; client không gửi giá quyết định.

API: `GET booking-services`, `GET bookings/{id}/services` (kiểm tra owner), `GET/PUT service-catalog[/{id}]` (admin), `POST operations/bookings/{id}/services/{sku}`, `PUT/DELETE operations/bookings/{id}/service-lines/{maChiTiet}`. Route sửa/xóa theo SKU chỉ dùng khi đúng một dòng; nhiều dòng trả 409. Dòng giống nguồn/quy cách/giá đã có: sửa SL thay vì thêm trùng.

UI quản lý catalog nằm trong mục mở rộng ở đầu Lịch đặt sân, chỉ admin. Đặt trước trên hai trang booking; phát sinh tại modal nhận sân/dịch vụ. Trigger `TRG_CapNhatTienDatSan` là nguồn cập nhật tổng duy nhất; Java refresh sau ghi, không cộng tổng lần nữa.

Migration `database/migrations/Phase5_1B_Services.sql` đã áp dụng sau backup/verify; không chạy lại. Rollback template mặc định khóa và từ chối khi có lịch sử mới. SQL scripts UTF-8 phải chạy `sqlcmd -f 65001 -b`. HTTP check: đặt `AUTH_TEST_PASSWORD`, `PHASE5_1B_TEST_STATE` trỏ file tạm rồi chạy `node backend/scripts/phase5-1b-http-check.mjs`; SQL verify trước cleanup fixture bằng `cleanup-phase5-1b-test.sql -v PitchId=SBHxxxxxx`. Không dùng test script trên môi trường thật có người đang thao tác nếu chưa bố trí thời gian kiểm thử.

Chi tiết: [báo cáo 5.1B](../docs/PHASE5_1B_SERVICE_REPORT.md). Phần tài chính được triển khai riêng trong 5.1C bên dưới.

# Phase 5.1C — tài chính nội bộ

Trạng thái hiện tại: **CODE COMPLETE / AWAITING MANUAL UI VERIFICATION**.
Các mô tả điểm dừng tài chính ở Phase4/5/5.1A phía trên là lịch sử từng phase.
Migration `database/migrations/Phase5_1C_Finance.sql` đã áp dụng sau backup/verify;
không chạy lại. Có HoaDon một/booking, giao dịch thu nhiều lần, snapshot hủy
và yêu cầu hoàn chờ kế toán/admin xác nhận thực tế. Không có cổng thanh toán
hoặc tự chuyển tiền ngân hàng. `ddl-auto=validate` giữ nguyên.

API đọc/ghi tài chính dưới `/api/finance`; session + CSRF + CN04/role/owner
được kiểm tra backend. Giữ khóa San → DatSan cho mọi ghi tài chính/dịch vụ.
Thanh toán dùng idempotencyKey; checkbox thực nhận bắt buộc cho nhân viên.
Khách chỉ gửi yêu cầu chờ xác minh, không tự đặt Thành công. Trả sân chốt
dịch vụ nhưng không tự thu tiền; chỉ hoàn tất tài chính khi chốt và đủ tiền.
Hoàn tính trên thực thu với biên10h/2h, không tính trên tổng khi chưa trả đủ.

`clean verify` PASS121 tests; HTTP5.1A/B/C và SQL verify PASS. JAR đã build/run
trực tiếp với SQL Server. Đăng nhập `/api/Dang_nhap.html`; lịch tại
`/api/Quan_ly_lich_dat_san.html`; kế toán tại `/api/Man_hinh_chinh_NVKT.html`.
Host/port/context/database/secrets vẫn cấu hình từ môi trường như trước.

HTTP check: đặt `AUTH_TEST_PASSWORD`, `PHASE5_1C_TEST_STATE` trỏ file tạm,
`AUTH_TEST_BASE_URL` nếu cần rồi chạy `node backend/scripts/phase5-1c-http-check.mjs`
từ root. Chỉ dùng database dev/test khi đã bố trí thời gian; script full case
cần cửa sổ07:00–11:29 giờ Việt Nam để dựng biên10h trong giờ sân07–22.
SQL verify trước cleanup; đọc exact ID FCH+6hex trong state rồi chạy
`sqlcmd -b -f 65001 -i backend/scripts/cleanup-phase5-1c-test.sql -v PitchId=FCHxxxxxx`
với cấu hình kết nối database kiểm thử phù hợp. Không dùng cleanup này cho
booking thật/manual; nếu guard từ chối, kiểm tra dependency, không xóa rộng.

Schema/API/file thay đổi, chứng cứ test/legacy, rollback và checklist UI:
[PHASE5_1C_FINANCE_REPORT.md](../docs/PHASE5_1C_FINANCE_REPORT.md).
Chưa kiểm chứng browser; không tự chuyển Phase6 hoặc triển khai LAN.

# Phase 6 — quản trị và báo cáo

Phase6 đã được giao và triển khai riêng. **CODE COMPLETE / AWAITING MANUAL UI VERIFICATION**.
Các điểm dừng Phase6 ở phần lịch sử trên không còn là phạm vi hiện tại; vẫn dừng
trước triển khai LAN/server. Giữ stack/version/dependencies và ddl-auto=validate.

Admin: trang tài khoản/phân quyền hiện có thêm quản lý nhân viên, tạo/khóa/mở/reset
tài khoản và nhật ký chỉ đọc. API `/admin/*` yêu cầu role ADMIN + CN07/CN08 phù hợp.
Nhân viên ngừng làm khóa tài khoản liên kết; reset mật khẩu BCrypt vô hiệu phiên cũ.
Không xóa vật lý nhân viên/tài khoản nghiệp vụ hoặc lộ password hash.

`/Bao_cao.html` dùng `/reports/usage`, `/reports/finance`, `/reports/refunds`,
`/reports/options`; dashboard admin dùng `/reports/dashboard`. Reports phải có
CN06_XEM và role phù hợp: staff chỉ vận hành, accountant chỉ tài chính/hoàn, admin
toàn bộ; customer không được truy cập. Staff baseline chưa có CN06_XEM, chỉ admin
được cấp nếu cần; không tự seed rộng quyền. Phân quyền Phase2 vẫn dùng route cũ.

Doanh thu snapshot ghi nhận tại ngày trả sân; tiền thu tại ngày nhận tiền; hoàn tại
ngày xác nhận trả tiền thật. Thực nhận dùng V_ThuChiThucNhan. Occupancy theo phút
booking không hủy /900 phút mỗi sân/ngày trong danh mục hiện tại, là công suất lý
thuyết kể cả sân bảo trì, chưa suy ngược lịch sử downtime. Migration additive
`database/migrations/Phase6_ReportViews.sql` đã áp dụng sau backup/verify, không chạy lại;
giữ V_DoanhThuTheoNgay/V_ThuChiThucNhan/V_TyLeLapDay cũ. Không đổi bảng/dữ liệu legacy.

Build141 tests PASS (20 mới +121 regression); HTTP bốn vai trò và API=SQL PASS.
HTTP dev/test: đặt AUTH_TEST_PASSWORD, PHASE6_TEST_STATE trỏ file tạm;
AUTH_TEST_BASE_URL và SQLCMD_TEST_SERVER tùy môi trường (mặc định localhostTCP1433),
chạy `node backend/scripts/phase6-http-check.mjs` từ root. Test nhận/trả cần
07:00–20:50 giờ Việt Nam. SQL verify trước cleanup; state chứa exact pitch/employee/
account ID, không password. Dùng `cleanup-phase6-test.sql` với `-b -f 65001` và
biến PitchId/EmployeeId/AccountId tương ứng; chỉ dành fixture, không dữ liệu thật.
Nếu test lỗi giữa chừng, kiểm tra marker/dependency, không bỏ guard hoặc xóa rộng.

File/API/quyền/SQL/chứng cứ và checklist admin/accountant/staff:
[PHASE6_ADMIN_REPORTS.md](../docs/PHASE6_ADMIN_REPORTS.md).


## Phase 7 — hardening và chuẩn bị nội bộ

APP_ENV=dev/test/internal, APP_HOST/APP_PORT/APP_CONTEXT_PATH và APP_DB_* từ env.
Internal yêu cầu runtime SQL login không sa/db_owner, marker internal, BCrypt
và đã thay mật khẩu demo; ddl-auto=validate. GET /api/health kiểm tra DB.
Scripts start/stop/restart ở ../scripts; Windows Task Scheduler và firewall
phải được administrator xem/xác nhận thủ công. Không dùng SqlProxy.

Mọi fixture test phải opt-in SAN_BONG_TEST_MODE=dev/test, đúng DB marker
dev/test và app environment. Cleanup SQL có guard marker + exact IDs; không
được retag database thật để vượt guard. Đọc hướng dẫn triển khai, backup/restore
và kết quả tại docs/PHASE7_DEPLOYMENT_REPORT.md, INTERNAL_DEPLOYMENT_GUIDE.md,
BACKUP_RESTORE_GUIDE.md. Chưa chứng minh truy cập từ máy client khác trong LAN.
