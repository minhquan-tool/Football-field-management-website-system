# Phân loại và xử lý vấn đề CNPM / DBMS — 17/10/2026

> **Cập nhật đợt mức trung bình:** Đã triển khai VIP10 thứ Tư, UI local, guard forwarding, whitelist SQL và môi trường fixture riêng. Lượt cuối130test runtime và100test fixture đạt; chi tiết/giới hạn ở [báo cáo mức trung bình](MEDIUM_FIXES_2026-10-17.md). Các số99/92vàPID23920bên dưới là kết quả lịch sử của đợt mức cao; server hiện tạiPID26024,cổng8082.

Đợt này xử lý **mức cao trước**, theo yêu cầu người dùng. Phân biệt lỗi đã xác nhận, rủi ro vận hành và thiếu bằng chứng kiểm thử; test chưa chạy không tự động được coi là lỗi phần mềm. Báo cáo QA trước đó giữ trạng thái trước sửa; tài liệu này theo dõi kết quả mới.

## Phần 1 — Công nghệ phần mềm (CNPM)

### Mức cao

| Mã | Vấn đề / tác động | Xử lý và bằng chứng | Trạng thái |
|---|---|---|---|
| C-H01 | Thiếu kết quả integration mới sau siết quyền SQL: phân quyền, ownership, đặt/nhận/trả sân, hóa đơn, thu/hoàn, khuyến mãi và dịch vụ | Chạy 92 test chọn thuộc 9 lớp với SQL Server thật, SanBongApp, guard DEV/test và transaction rollback. Đạt toàn bộ; gồm kiểm tra chống tự xác nhận chuyển khoản, tiền mặt chờ nhận, idempotency, dịch vụ sau trả trước và không cộng dồn giảm giá | **Đã kiểm chứng trong phạm vi đã chạy**, chưa phải phủ mọi nghiệp vụ |
| C-H02 | Test cũ commit fixture rồi xóa nhật ký; có thể tạo dữ liệu nhưng cleanup thất bại khi runtime đã bị DENY | Đánh dấu 7 lớp AuditCleanupFixture; TestDatabaseSafetyListener chặn runtime trước setup. Không cấp lại DELETE để làm test đạt. Thêm 7 unit tests cho guard: runtime dù có DELETE vẫn bị chặn, thiếu quyền/thông tin bị chặn, rollback suite không cần cleanup | **Đã sửa; 7 test guard đạt**, bộ 92 ca rollback vẫn đạt |
| C-H03 | Chưa nghiệm thu QR/chuyển khoản bằng ứng dụng ngân hàng và thiết bị thật | PaymentQrFlowTest đạt 9 ca backend; QR local, số tiền/ownership/trạng thái kiểm tra ở server, yêu cầu chuyển khoản chưa tự thành thực thu. Không tự chuyển tiền, không gửi dữ liệu tới dịch vụ tạo QR | **Chưa nghiệm thu thực tế**; đây là khoảng trống trước khi thu tiền thật, chưa phải lỗi code đã tái hiện |

Web chính sau siết quyền: **27 mục điều hướng của bốn vai trò** đạt tại 1440/1024/768/390px; không pageerror/API GET failures trong lượt này. Đăng nhập/đăng xuất thật vẫn hoạt động. Server chính vẫn8082, PID23920; không thay JAR vì không sửa mã runtime hoặc UI trong đợt này.

### Mức trung bình — cập nhật sau xử lý

| Mã | Nội dung | Hướng xử lý tiếp | Liên quan |
|---|---|---|---|
| C-M01 | VIP10 tên/điều kiện mâu thuẫn | **Đã sửa theo lựa chọn chỉ thứ Tư**; backend kiểm tra7ngày, UI đọc đúng điều kiện; đã triển khai | CNPM + D-M03 |
| C-M02 | UI phụ thuộc CDN/font/icon/ảnh ngoài | **Đã phục vụ local**, CSS tĩnh; offline UI, form và27mục điều hướng đạt | CNPM |
| C-M03 | Rate limit/proxy trust | **Đã hardening direct origin** bằng guard forwarding; IP riêng từng khách qua tunnel còn chờ mô hình proxy/client thật | CNPM, vận hành |
| C-M04 | Đo tải và client xa | **Đã đo baseline local300GET/10luồng,0lỗi**; chưa nghiệm thu tải dài hạn/nghiệp vụ ghi hoặc client xa | CNPM + hiệu năng DBMS |
| C-M05 | Suite commit/concurrency cần môi trường riêng | **Đã tách database/login/profile fixture,100test đạt**; tài khoản fixture không truy cập database chính | CNPM + D-M04 |
| C-M06 | Báo cáo dễ lỗi thời | **Đã cập nhật** timestamp, môi trường, loại kiểm thử, bằng chứng và phần chưa nghiệm thu | CNPM, tài liệu |

### Mức thấp

| Mã | Nội dung | Hướng xử lý | Trạng thái |
|---|---|---|---|
| C-L01 | /favicon.ico ngoài context trả404 | Bổ sung favicon/link đúng context trong đợt UI tiếp theo | Đã quan sát, chưa sửa; không chặn sử dụng |

## Phần 2 — Hệ quản trị cơ sở dữ liệu (DBMS)

### Mức cao

| Mã | Trước sửa | Xử lý / nghiệm thu | Trạng thái |
|---|---|---|---|
| D-H01 | SanBongApp thuộc db_datawriter; UPDATE=1, DELETE=1 trên dbo.NhatKyHeThong | Lưu quyền/role trước sửa; DENY UPDATE,DELETE riêng audit. Migration xác minh quyền cả bảng/từng cột trước COMMIT và rollback nếu sai. Probe UPDATE/DELETE WHERE1=0 thực tế bị SQL từ chối lỗi229 | **Đã sửa và áp dụng trên QuanLySanBong DEV** |
| D-H02 | Chỉ có bằng chứng restore cũ | Backup COPY_ONLY/CHECKSUM mới, VERIFYONLY, review HEADER/FILELIST; restore database tên mới và MDF/LDF riêng. CHECKDB đạt; đối chiếu đầy đủ dòng hai chiều EXCEPT ở 8 bảng; JAR dùng JDBC/JPA validate khởi động với bản restore, health UP | **Đã kiểm chứng bản backup mới** |

**D-H01:** INSERT/SELECT audit vẫn1; UPDATE/DELETE0; không quyền UPDATE từng cột. Runtime không db_owner, không BACKUP DATABASE. Nghiệp vụ test vẫn ghi audit rồi rollback; đăng nhập/đăng xuất web thật đạt. Không xóa lịch sử, đổi mật khẩu, role ứng dụng, schema hoặc quyền bảng nghiệp vụ. DENY có hiệu lực ngay, không cần restart server.

**D-H02:** Backup mới `QuanLySanBong_QA_20261017_1736.bak` tại thư mục backup mặc định SQL Server. Bản restore **QuanLySanBong_QA_20261017_1736**, ONLINE, markerDEV và quyền chặn audit được giữ. Tại thời điểm đối chiếu: DatSan10, HoaDon4, ThanhToan4, HoanTien0, HuyDatSan2, ChiTietDichVu3, XacNhanSan0, NhatKyHeThong1742 dòng. Đây là dữ liệu thời điểm drill, không phải số cố định cho lần sau.

Backend thử loopback8085 đã dừng; backend chính giữ database nguồn. Giữ database/file drill để đối chiếu, không tự DROP. Bản copy chứa dữ liệu dự án và cần hạn chế truy cập như nguồn. Drill đạt chưa chứng minh đã có lịch backup hay bản sao ngoài máy.

### Mức trung bình — cập nhật sau xử lý

| Mã | Nội dung | Hướng xử lý | Liên quan |
|---|---|---|---|
| D-M01 | Runtime dùng role reader/writer toàn DB | **Đã bỏ hai role rộng**, whitelist25bảng/3view/hàm và hồi quy đạt; audit vẫn append-only | DBMS + CNPM |
| D-M02 | Backup/retention/archive | **Đã có runner và backup SQL verify đạt**; kế hoạch task WhatIf, chưa bật lịch/Prune/archive vì còn chờ cấu hình và quyền Windows | DBMS, vận hành |
| D-M03 | Khuyến mãi văn bản/alias, KM02 mâu thuẫn | **Đã sửa KM02 thứ Tư**, snapshot không đổi; hướng schema mã/rule mới chỉ là đề xuất để xem trước | DBMS + CNPM |
| D-M04 | Test commit cần identity ngoài runtime | **Đã tạo copy dùng một lần và identity riêng**, marker bổ sung,100test đạt; không cấp lại DELETE audit cho web | DBMS + C-M05 |

### Mức thấp

Chưa xác nhận thêm lỗi DBMS mức thấp trong lượt này. Có thể bổ sung sơ đồ role/quyền và hướng dẫn đọc log phục vụ báo cáo; đó là cải thiện tài liệu, không phải lỗi dữ liệu đã phát hiện.

## Kết quả kiểm tra và file thay đổi

Lượt đầu sau siết SQL: **92 test đạt**, không lỗi/bỏ qua. Lượt cuối gồm 92 ca đó và 7 test guard mới: **99 test đạt, 0 failure/error/skipped, BUILD SUCCESS với JDK24**; log `exports/high-priority-final-tests-20261017.log`. Kiểm tra tĩnh guard của 9 script fixture SQL cũng đạt, không thực thi fixture. Không cộng số test của các lượt thành tỷ lệ hoàn thành đồ án.

Đối chiếu cuối lúc17:43: không còn sân/nhân viên mang marker Role audit hoặc tài khoản khách sinh bởi cj_/qrc_ trong các nhóm đã truy vấn; bốn tài khoản mẫu vẫn Hoạt động, web chính healthUP, cổng drill8085 đã đóng. Bằng chứng: `exports/high-priority-final-state-20261017.txt` và `exports/high-priority-verification-20261017.json`. Đây là kiểm tra các nhóm fixture đã nêu, không phải chứng nhận mọi fixture lịch sử trong DB đều bằng0.

File thay đổi:

- `database/migrations/ProtectAuditPermissions_20261017.sql`: xác minh trong transaction; đã áp dụng.
- `scripts/verify-test-database.sql`: kiểm tra UPDATE/DELETE, quyền từng cột và INSERT/SELECT audit.
- `scripts/verify-audit-permissions.sql`: hai probe không khớp dòng nào, xác nhận SQL từ chối.
- `backend/src/test/java/com/sanbong/AuditIntegrityTest.java`: quyền runtime và nghiệp vụ vẫn ghi nhật ký, rollback.
- `AuditCleanupFixture.java`, `TestDatabaseSafetyListener.java`, `TestDatabaseSafetyListenerTest.java` và 7 lớp cũ có cleanup audit được đánh dấu.
- Báo cáo này, `QA_FACT_CHECK_2026-10-17.md`, `SECURITY_HARDENING_2026-10-17.md`, `BACKUP_RESTORE_GUIDE.md`.

Bằng chứng trong exports: `high-priority-permissions-before-20261017.txt`, `high-priority-audit-migration-20261017.txt`, `high-priority-audit-probes-20261017.txt`, `high-priority-runtime-preflight-20261017.txt`, `high-priority-integration-20261017.log`, `high-priority-final-tests-20261017.log`, `high-priority-navigation-live-20261017.log`, `high-priority-backup-20261017.txt`, `high-priority-restore-20261017.txt`, `high-priority-restore-startup.log`, `high-priority-restore-health-20261017.json`.

**Giới hạn của đợt mức cao trước đây:** Chưa chạy concurrency commit cũ, chưa đo tải hoặc sửa VIP10 trong đợt đó. Những phần đã làm ở đợt mức trung bình xem báo cáo mới. Hiện vẫn chưa chuyển tiền ngân hàng, chưa nghiệm thu client xa, lịch backup/retention/archive và proxy trust riêng. Không dùng số test chọn để khẳng định đã phủ hết hệ thống.
