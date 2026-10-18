# Kết quả xử lý mức trung bình — CNPM và DBMS, 17/10/2026

Đã cập nhật bản chính8082, PID26024. JAR cũ được giữ tại `exports/backend-before-medium-20261017.jar`; metadata/hash tại `exports/medium-deployment.json`. Không đổi schema bảng, mật khẩu người dùng hoặc snapshot tiền lịch sử. Phần chưa đủ điều kiện nghiệm thu được ghi riêng, không tính là đã xong.

## Phần 1 — Công nghệ phần mềm (CNPM)

| Mã | Việc đã xử lý | Kiểm chứng | Trạng thái |
|---|---|---|---|
| C-M01 | VIP10 chỉ áp dụng **ngày chơi thứ Tư**, đúng lựa chọn người dùng. Backend kiểm tra ngày đã lưu của booking; kế toán/nhân viên không dùng cờ xác minh để vượt ngày. Trang khuyến mãi hiển thị điều kiện từ database và hướng dẫn khách tự áp mã trước thanh toán | 7 ca mới phủ thứ Hai–Chủ nhật; thứ Tư đạt, 6 ngày khác bị từ chối cho khách và thao tác lập hóa đơn của kế toán. UI bản chính hiển thị “Chỉ áp dụng thứ Tư” | **Đã sửa, triển khai** |
| C-M02 | 19 trang chuyển khỏi CDN, trang chủ vốn đã dùng CSS local. CSS Tailwind tĩnh, Montserrat có tiếng Việt, Font Awesome và logo phục vụ cùng server; giữ license và manifest hash. Ảnh nền ngoài trả HTML được thay bằng ảnh sân sẵn có trong project | Static check20trang; browser chặn Internet:0request tài nguyên UI ngoài, font/icon/logo tải được; form đạt ở1440/768/390px, điều hướng27mục của4vai trò đạt ở1440/1024/768/390px | **Đã sửa, triển khai** |
| C-M03 | Khai báo forwarding NONE; ForwardedHeaderPolicy chặn khởi động nếu bật framework/native hoặc tự đặt header Tomcat khi chưa có proxy trust được review. Login limiter tiếp tục dùng remoteAddr, bỏ qua header client giả | 7 ca policy startup, 7 ca MVC limiter; bản chính khởi động và đăng nhập4vai trò đạt | **Đã hardening chế độ direct**; tách IP từng khách qua tunnel vẫn chưa nghiệm thu |
| C-M04 | Thêm phép đo GET có giới hạn/opt-in cho health, options và danh mục sân, không tạo booking/thanh toán | Trên JAR cuối:300request/10luồng,300HTTP200,0lỗi; p50=12,93ms, p95=39,81ms, max=89,08ms. Log có timestamp và phạm vi | **Đã có baseline local**; chưa đo tải dài hạn/nghiệp vụ ghi hoặc client ở xa |
| C-M05 | Tách test rollback của runtime và test commit/concurrency. Có runner chọn suite; lệnh manage-backend build mặc định chọn suite runtime, không chạy ngầm test commit; test cleanup cần identity riêng và marker dùng một lần | 100ca của7suite commit/concurrency đạt trên database fixture riêng; kiểm tra PowerShell xác nhận hai suite không giao nhau và profile sai bị chặn | **Đã thực hiện** |
| C-M06 | Báo cáo hiện hành ghi rõ thời điểm, loại kiểm thử, môi trường, giới hạn và log; bảng tiến độ được cập nhật. Kết quả cũ giữ theo đợt | Báo cáo này, bảng CNPM/DBMS và metadata exports | **Đã cập nhật** |

Google Maps/chỉ đường vẫn cần Internet khi mở chức năng đó. Kết quả “offline” ở đây là tài nguyên giao diện và nghiệp vụ nối tới server local còn hoạt động khi không truy cập CDN, không phải bản đồ offline hoặc web chạy khi server đã tắt.

Tailwind vốn có trong dự án, chỉ đổi cách phục vụ sang CSS biên dịch; không thêm framework runtime. Cách build/quét HTML và JavaScript đối chiếu [tài liệu compiler standalone](https://tailwindcss.com/blog/standalone-cli) và [content configuration v3](https://v3.tailwindcss.com/docs/content-configuration). Compiler ghim3.4.17, không đưa fileEXE vào JAR.

### Giới hạn proxy cần giữ đúng

Origin hiện phục vụ trực tiếp/LAN và có thể được tunnel gọi qua loopback. Guard không tạo ranh giới proxy mới và không xác minh IP thật của người ở xa. Nhiều người qua tunnel vẫn có thể chung ngân sách IP; bộ đếm vẫn trong bộ nhớ một server và reset khi restart. Không bật `SERVER_FORWARD_HEADERS_STRATEGY=framework/native` hoặc cấu hình `server.tomcat.remoteip.*` để né giới hạn này. Cần đánh giá một origin chỉ nhận từ proxy tin cậy và kiểm thử client thật trước khi thay chế độ.

## Phần 2 — Hệ quản trị cơ sở dữ liệu (DBMS)

| Mã | Việc đã xử lý | Kiểm chứng | Trạng thái |
|---|---|---|---|
| D-M01 | Bỏ membership db_datareader/db_datawriter của SanBongApp. Dùng SanBongRuntimeRole với whitelist25bảng,3view báo cáo và hàm tính tỷ lệ hoàn | Đã thử trên database copy trước, sau đó áp dụng database chính và chạy hồi quy130ca. GlobalReader0,GlobalWriter0,RuntimeRole1; audit INSERT1,UPDATE0,DELETE0 | **Đã áp dụng** |
| D-M02 | Runner backup Windows Authentication, COPY_ONLY/CHECKSUM/VERIFYONLY, file tên mới, receipt; chuẩn bị tùy chọn archive/hash/retention và script đăng ký task có WhatIf, không ghi đè task cũ | Backup thật và VERIFYONLY đạt. Tiến trình Windows hiện không elevated, không đọc được fileBAK để hash; receipt ghi SHA256null và cảnh báo. Không bật archive/Prune/task | **Hoàn thành runner kiểm chứng SQL; chưa bật lịch/retention/archive** |
| D-M03 | Sửa dữ liệu điều kiện KM02 theo thứ Tư; migration kiểm tra đúng mã, loại giảm10%, chưa được dùng trước khi đổi. Điều kiện khác và tiền đã lưu được giữ | Migration thực tế đạt; tại lúc áp dụng không có booking dùng KM02; snapshot tiền DatSan/HoaDon so với bản restore trước sửa không khác | **Mâu thuẫn VIP10 đã sửa**; schema mã/rule có cấu trúc mới chỉ là đề xuất |
| D-M04 | Database `QuanLySanBong_Fixtures_20261017_Medium`, login riêng chỉ có user trên bản copy. Marker dev/test + SanBongFixtureDatabase=1 trước test commit. Profile private `.env.fixture.local` có ACL hạn chế. Bản copy chặn CONNECT của runtime web | 100test đạt; fixture chỉ truy cập copy, runtime chỉ truy cập nguồn trong cặp này; sysadmin của fixture=0. Không đổi login/password đang dùng | **Đã tách hai chiều** |

### Ma trận quyền runtime

SQL runtime là một service account; bốn vai trò người dùng vẫn được kiểm tra ở backend bằng role/permission/ownership. Không diễn giải thành bốn vai trò web có bốn SQL login riêng.

- SELECT trên25bảng nghiệp vụ đã liệt kê trong migration.
- INSERT/UPDATE chỉ trên các bảng được nghiệp vụ cần tới; BangGia, ChiTietDanhGia, HuyDatSan và audit chỉ INSERT; GiaTheoCa chỉ UPDATE.
- DELETE chỉ ChiTietDichVu, vẫn qua điều kiện/trạng thái/khóa ở backend. Không quyền DELETE booking, hóa đơn, thu/hoàn, tài khoản hoặc audit.
- VaiTro, ChucNang, TieuChiDanhGia chỉ đọc;3view báo cáo chỉ SELECT. Giữ EXECUTE fn_TyLeHoan.
- Không db_owner, ALTER/CONTROL database hoặc BACKUP DATABASE cho tài khoản web. Giữ DENY sửa/xóa audit.

Lượt rehearsal đầu thiếu SELECT trên3view báo cáo nên test phát hiện lỗi229. Đã bổ sung đúng3view rồi chạy lại đạt115ca trên bản copy trước áp dụng nguồn. Không cấp lại role writer toàn database.

### Backup còn cần cấu hình

Chưa có câu trả lời cho lựa chọn lịch backup/nơi lưu ngoài máy. Script task hiện chỉ có **bản WhatIf** đề xuất02:00,giữ14ngày; chưa đăng ký automation hoặc Scheduled Task. Cần chốt lịch, nơi lưu và Windows identity có quyền đọc/xóa backup phù hợp trước khi bật retention hoặc archive. S4U trong script đăng ký không hỗ trợ network share, theo [tài liệu Task Scheduler của Microsoft](https://github.com/MicrosoftDocs/sdk-api/blob/docs/sdk-api-src/content/taskschd/ne-taskschd-task_logon_type.md); nơi lưu ngoài máy cần cấu hình identity riêng phù hợp, không đưa password vào chat hoặc script.

Runner chỉ cân nhắc xóa các backup do chính runner quản lý, có receipt/hash khớp, nằm đúng thư mục và quá hạn, sau khi có backup mới xác minh thành công. Không có SHA256/quyền OS phù hợp thì bỏ qua việc xóa. **Lượt này không chạy Prune, không xóa fileBAK và không kiểm chứng archive ngoài máy.**

`docs/PROMOTION_RULES_PROPOSAL.md` ghi hướng mở rộng mã duy nhất/quy tắc có cấu trúc. Chưa tự áp dụng schema tài chính mới cho mục này.

## Kết quả kiểm thử và triển khai

| Phạm vi | Kết quả cuối | Bằng chứng |
|---|---|---|
| Runtime + unit/MVC, transaction rollback trên DEV |130ca,0failure/error/skipped,BUILD SUCCESS,JDK24 |exports/medium-final-runtime-tests.log |
| Commit/concurrency trên database dùng một lần |100ca,0failure/error/skipped |exports/medium-disposable-fixture-final-tests.log |
| Anonymous CSS/font/ảnh và chặn POST tài nguyên |4ca trong tập130 |LocalAssetsHttpTest |
| UI offline server chính |PASS,0request UI ngoài |exports/medium-offline-main.log |
| Form/icon server chính |PASS |exports/medium-form-main.log |
| VIP10 hiển thị đúng điều kiện |PASS |exports/medium-vip10-ui-main.log |
| Menu4vai trò/27mục/4viewport |PASS,0pageerror/API GET failures |exports/medium-navigation-main.log |
| Quyền runtime và catalog sau áp dụng |PASS |exports/medium-final-sql-state.txt |
| Snapshot tiền lịch sử ở các cột đã đối chiếu |0khác biệt |exports/medium-history-snapshots.txt |
| Read-only load local |300/300HTTP200 |exports/medium-read-load-results.json |
| Backup SQL checksum/verify |PASS; OS hash/retention/archive chưa nghiệm thu |exports/medium-managed-backup-result.json |

Không cộng130và100thành tỷ lệ hoàn thiện sản phẩm. Hai tập dùng mục tiêu và identity khác nhau. Một test Phase6 cũ giả định NV chưa được cấp CN06, trong khi quyền đó đã được duyệt trước đây; đã sửa test tự thiết lập baseline trên fixture và khôi phục matrix sau test. Lượt cuối100ca đạt. Log lần đầu giữ tại exports/medium-disposable-fixture-tests.log.

Migration VIP10 lần đầu dừng ở guard vì sqlcmd chưa được chỉ rõUTF-8. Đã chạy lại với `-f 65001`, điều kiện mới đọc lại đúng tiếng Việt; guard đã ngăn cập nhật sai. JAR mới khỏe trước khi đổi catalog, không sửa snapshot để làm migration đạt.

Preview8084 và phiên Playwright đã đóng; server chính8082 tiếp tục chạy. Không thực hiện chuyển khoản ngân hàng, đổi mật khẩu người dùng hoặc restore đè nguồn.

## File chính và cách chạy lại

- Backend: FinanceService.java, SecurityConfig.java, ForwardedHeaderPolicy.java, application.yml.
- Database: RuntimeLeastPrivilege_20261017.sql, Vip10Wednesday_20261017.sql.
- UI:19HTML, css/tailwind.css + input/config build, vendor font/icon/license/hash, logo local.
- Tests: CustomerPromotionTest, LocalAssetsHttpTest, RuntimePermissionsTest, ForwardedHeaderPolicyTest, TestDatabaseSafetyListener/Test, Phase6IntegrationTest; offline-assets-browser.js, local-assets-check.mjs, read-load-check.mjs.
- Vận hành: backend/manage-backend.ps1, run-verification.ps1, verification-suites.ps1; scripts/build-frontend-css.ps1, localize-frontend-assets.mjs, prepare-disposable-fixtures.ps1, backup-database.ps1, register-backup-task.ps1. Policy checker tại backend/scripts/verification-suite-check.ps1.
- Báo cáo, mẫu env và hướng dẫn liên quan được cập nhật. Không ghi credentials vào các file nguồn/báo cáo này.

Từ thư mục project, với Maven trên PATH hoặc MAVEN_HOME hợp lệ:

```powershell
# Các test runtime dùng rollback; không chạy toàn bộ suite commit bằng profile này.
.\backend\run-verification.ps1 -Suite runtime -EnvFile .\.env.test.local -Offline

# Chỉ database fixture riêng, KHÔNG dùng profile này để vận hành web.
.\backend\run-verification.ps1 -Suite fixtures -EnvFile .\.env.fixture.local -Offline

# Backup mới với quyền Windows/SQL phù hợp; chưa prune hoặc archive.
.\scripts\backup-database.ps1

# Xem kế hoạch task, chưa đăng ký. Chỉ đăng ký thật sau khi chốt cấu hình và chạy elevated.
.\scripts\register-backup-task.ps1 -WhatIf
```

Fixture profile đã tồn tại được bảo vệ khỏi ghi đè. Muốn tạo môi trường mới, chọn tên database/login mới và backup đã review qua prepare-disposable-fixtures.ps1; script từ chối database/login/file đích đã có, không DROP/reset tự động. Bản copy có dữ liệu dự án và phải giữ quyền truy cập hạn chế.
