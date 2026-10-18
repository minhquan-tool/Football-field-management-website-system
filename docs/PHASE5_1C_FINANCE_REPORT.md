# Phase 5.1C — Hóa đơn, thanh toán và hủy/hoàn tiền

Ngày kiểm chứng: 08/10/2026. **CODE COMPLETE / AWAITING MANUAL UI VERIFICATION**.

Backend, migration, HTTP trên JAR thật và SQL verify đã PASS. Chưa kiểm chứng thao tác/hiển thị bằng trình duyệt; không coi HTTP trả HTML là kiểm thử UI. Dừng tại 5.1C, không triển khai Phase 6 hoặc LAN. Giữ HTML/CSS/JS → REST → Spring Boot → JPA/JDBC → SQL Server; không dùng SqlProxy, không thay dependency/version, không reset database.

## 1. Audit và dependency trước migration

Database thực tế là `QuanLySanBong`. Trước thay đổi chưa có HoaDon; ThanhToan đã cho phép nhiều giao dịch/booking. HoanTien liên kết MaTT và MaHuy, qua ThanhToan xác định booking. HuyDatSan đã unique MaDatSan. Tiền dùng decimal(18,2), phương thức tiền mặt/chuyển khoản và các trạng thái giao dịch/hoàn đã có constraint.

Kiểm tra FK, index, default constraint, trigger và view tài chính trước sửa. Không có trigger tài chính cập nhật ThanhToan/HoanTien; giữ nguyên trigger dịch vụ `TRG_CapNhatTienDatSan`. View cũ `V_DoanhThuTheoNgay` là doanh thu thu vào chưa trừ hoàn, giữ nguyên để không phá dependency. CN04 là thanh toán; CN05 là phản hồi, không dùng CN05 cho hoàn tiền. Không sửa các dòng permission hiện có.

Baseline có 7 sân, 3 booking, 0 giao dịch thu/hoàn/hủy, 0 chi tiết dịch vụ/nhận sân. Do không có lịch sử tài chính nên không cần tự chuyển đổi hoặc backfill hóa đơn cũ.

## 2. Schema thêm/sửa và migration

Đã chạy `database/migrations/Phase5_1C_Finance.sql` bằng sqlcmd UTF-8, `-f 65001 -b`. Script kiểm tra đúng database, trạng thái chưa migrate, trùng khóa legacy; toàn bộ DDL trong transaction với XACT_ABORT và rollback khi lỗi. **Không chạy lại migration trên database đã áp dụng.**

| Đối tượng | Thay đổi đã áp dụng |
|---|---|
| HoaDon | Bảng mới, MaHoaDon PK, MaDatSan unique/FK, MaTKLap FK tài khoản; snapshot TienSan/TienDichVu/TienGiam/TongTien/DaThanhToan; trạng thái, NgayLap, DaChot |
| HoaDon.ConLai | Computed persisted: tổng trừ đã trả; hóa đơn hủy có số cần thu thêm bằng 0 |
| HoaDon.HoanTatTaiChinh | Computed persisted, chỉ true khi đã chốt, đủ tiền và trạng thái DA_THANH_TOAN |
| HoaDon constraints | Các tiền không âm, giảm không vượt tiền sân, công thức tổng đúng, đã trả không vượt tổng; enum trạng thái |
| ThanhToan | Index (MaDatSan,TrangThai) INCLUDE SoTien; unique filtered MaGiaoDich khác NULL làm idempotency key |
| HoanTien | Unique (MaHuy,MaTT); thêm NgayXacNhan datetime2(7) và LyDo nvarchar(255), nullable để giữ legacy |
| HuyDatSan | NgayHuy datetime → datetime2(7), giữ default cũ; thêm SoTienThucThuSnapshot nullable và CHECK khoản hoàn không vượt chính sách trên snapshot mới |
| fn_TyLeHoan | Function chính sách 10h/2h bằng so sánh datetime2 chính xác |
| V_ThuChiThucNhan | View thu thành công dương, hoàn đã xác nhận âm; thời điểm hoàn là NgayXacNhan |

Không thay cột tiền legacy, MaKhungGio, giá theo ca, bảng catalog hay unique chống booking trùng của 5.1A/B. Không thêm SP/trigger tài chính. Các trạng thái/method constraint ThanhToan/HoanTien cũ vẫn là nguồn chuẩn.

## 3. Backup và rollback

Đã tạo SQL Server backup **COPY_ONLY, CHECKSUM** trước migration và `RESTORE VERIFYONLY WITH CHECKSUM` thành công:

`C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\QuanLySanBong_Phase5_1C_PreMigration_20261008.bak`

Đây là vị trí backup của môi trường kiểm thử, không phải đường dẫn phụ thuộc trong ứng dụng. Không restore/reset dữ liệu.

`database/migrations/Phase5_1C_Rollback.sql` là rollback có guard mặc định khóa, từ chối khi có dữ liệu tài chính mới. Chưa chạy rollback. Nếu đã có giao dịch thật, phải đối soát/export lịch sử và lập kế hoạch riêng, không bật guard để xóa lịch sử.

Trong lần thực thi ban đầu, default constraint của NgayHuy ngăn đổi kiểu; một lần kiểm tra tiếp theo phát hiện cú pháp EXEC động chưa hợp lệ. Các transaction lỗi đã rollback, không để schema dở dang. Script cuối đã sửa cách gỡ/khôi phục default và dựng câu DDL động, thực thi thành công.

## 4. API

Base mặc định `http://127.0.0.1:8080/api`; session, CSRF và permission Phase 2 được giữ nguyên.

| Method | Path dưới /api | Mục đích |
|---|---|---|
| GET | /finance/bookings/{id} | Booking, hóa đơn, giao dịch, hoàn/hủy và thực thu; customer phải đúng owner |
| GET | /finance/bookings/{id}/cancel-preview | Chính sách tại thời điểm đọc; tính lại khi hủy thật |
| GET | /finance/promotions | Khuyến mãi phần trăm đang hoạt động |
| GET | /finance/transactions | Sổ thu/hoàn và thực nhận từ SQL |
| POST | /finance/bookings/{id}/invoice | Lập/cập nhật một hóa đơn từ snapshot; optional maKM |
| POST | /finance/bookings/{id}/payments | Nhân viên ghi nhận thực thu, bắt buộc daNhanTien=true |
| POST | /finance/bookings/{id}/payment-requests | Khách gửi yêu cầu xác minh, luôn Chờ xử lý |
| POST | /finance/payments/{id}/confirm | Nhân viên được cấp quyền xác nhận thực thu, bắt buộc daNhanTien=true |
| POST | /finance/payments/{id}/reject | Từ chối yêu cầu đang chờ |
| POST | /finance/refunds/{id}/confirm | Kế toán/admin xác nhận đã trả tiền thực tế, phương thức và lý do bắt buộc |
| POST | /bookings/{id}/cancel | Route cũ, nay hủy + snapshot chính sách + yêu cầu hoàn cùng transaction |

PaymentRequest bắt buộc tiền >0, precision đúng decimal(18,2), method hợp lệ, idempotencyKey 8–50 ký tự. Backend không nhận total hoặc trạng thái Thành công do khách tự đặt. Exception vẫn trả API response rõ ràng; lỗi database không lộ SQL/credentials ra frontend, chi tiết SQL error code/state có trong server log.

## 5. Hóa đơn và công thức

Một booking chỉ một MaHoaDon; gọi lại route invoice không tạo bản thứ hai. Giá sân lấy DatSan snapshot; dịch vụ lấy SUM ChiTietDichVu.ThanhTien snapshot. Xem hóa đơn không định giá lại bằng catalog.

`TienGiam = round(TienSan × % / 100, 2)` chỉ giảm sân.

`TongTien = TienSan + TienDichVu − TienGiam`.

Hóa đơn đang sử dụng chưa chốt được đồng bộ khi thay đổi dịch vụ; hóa đơn đã chốt giữ snapshot. DaThanhToan là SUM giao dịch Thành công, không phải các yêu cầu đang chờ. Trigger cũ cập nhật tiền dịch vụ/tổng DatSan; Java refresh DatSan và đồng bộ sang HoaDon, không cộng dịch vụ lần hai.

Chỉ áp dụng khuyến mãi phần trăm còn hiệu lực theo ngày chơi. KM02 yêu cầu ngày trong tuần, cuối tuần bị từ chối. Điều kiện khuyến mãi dạng văn bản tùy ý chưa có bộ phân tích tổng quát. Booking legacy GIA_KHUNG không cho áp dụng khuyến mãi mới; khi không chọn maKM giữ nguyên giảm tiền legacy, kể cả giảm cố định cũ.

Ví dụ đã kiểm thử: 13:00–15:00 → sân 260.000; Coca lốc 6 → 58.200; giảm 10% sân → 26.000; tổng **292.200**. Frontend gửi tongTien=1 không đổi kết quả.

## 6. Trả trước, từng phần, trả sau và hoàn tất

Cho phép trả đủ trước khi đá, chưa trả khi đặt rồi trả sau, hoặc trả một phần. Đã xác nhận booking không đồng nghĩa đã trả tiền. Thanh toán đủ trước khi nhận sân không đồng nghĩa hoàn tất tài chính.

Sau trả trước vẫn được bổ sung dịch vụ khi đang dùng và chưa chốt. Tổng mới tăng thì trạng thái hóa đơn trở lại chưa đủ/đã trả một phần và ConLai cập nhật. Trả sân chốt dịch vụ, không tự ghi nhận thêm tiền; hóa đơn chỉ HoanTatTaiChinh=true khi chốt và đủ tiền. Không cho sửa dịch vụ bình thường sau trả sân.

Ví dụ kiểm thử trả trước 260.000 rồi thêm nước 5.000: còn 5.000; trả sân vẫn chưa hoàn tất; thu thêm 5.000 mới hoàn tất. HTTP còn kiểm thử sân 45.000 + Coca lốc 58.200 =103.200 trả trước; thêm Coca đơn 10.000 → tổng113.200/còn10.000; thu sau trả sân → hoàn tất.

Hóa đơn hủy có ConLai=0 (không thu thêm), không phải đã hoàn tiền. Khoản được hoàn và tình trạng đã hoàn nằm trong HuyDatSan/HoanTien. DaThanhToan giữ số thu thành công; thực thu sau hoàn được đọc riêng, không biến khoản hoàn thành thanh toán âm.

## 7. Chống double payment

Mọi ghi tài chính khóa **San → DatSan**, refresh dữ liệu sau khóa, kiểm tra số còn thiếu trong transaction READ_COMMITTED. Tái sử dụng thứ tự khóa của booking/dịch vụ; không chỉ dựa vào index.

Khóa bảo vệ hai request trên cùng booking; unique MaGiaoDich bảo vệ idempotency. Retry cùng key/body trả trạng thái đã có, không tạo giao dịch mới; đổi body với key cũ trả conflict. Hai giao dịch chỉ còn100.000 đã kiểm thử → một200, một409, SUM không vượt tổng. Khi xác nhận yêu cầu đang chờ, số dư được tính lại, không dựa số dư lúc khách gửi yêu cầu.

## 8. Chính sách hủy

Thời gian bắt đầu là NgayChoi + GioBatDau snapshot. Clock backend dùng Asia/Ho_Chi_Minh, không so sánh chỉ ngày và không lấy giờ browser làm chuẩn. NgayHuy dùng datetime2 tránh làm tròn qua biên.

| Khoảng đến giờ bắt đầu tại lúc hủy | Tỷ lệ |
|---|---:|
| ≥10h, gồm đúng10h | 100% |
| ≥2h và <10h, gồm đúng2h | 50% |
| <2h | 0% |

Giữ kiểm tra owner, chưa nhận sân/chưa đến giờ, trạng thái booking cho phép hủy. Booking đã sử dụng/hoàn thành bị từ chối. Preview chỉ là dự kiến; hủy thật tính lại dưới lock bằng thời điểm server.

## 9. Tính và xác nhận hoàn

`ThucThuTaiHuy = SUM(ThanhToan Thành công) − SUM(HoanTien Đã hoàn)`.

`SoTienHoan = round(ThucThuTaiHuy × TiLeHoan /100, 2)`.

Khách trả200.000 trên tổng292.200: hoàn100% là200.000, 50% là100.000, 0% là0. Chưa trả thì hoàn0, không tạo row hoàn tiền0 vì constraint tiền hoàn phải >0.

Hủy tạo yêu cầu hoàn Chờ duyệt phân bổ trên các giao dịch thực thu, không ghi Đã hoàn ngay. Phân bổ theo ngân sách tổng đã làm tròn, không cộng các phần làm tròn gây vượt chính sách. Yêu cầu thanh toán còn chờ được đánh dấu thất bại khi booking hủy.

Xác nhận hoàn là nhân viên đã thực sự trả tiền mặt/chuyển khoản: lưu MaNV, phương thức thực tế, NgayXacNhan, số tiền, lý do và trạng thái. Ứng dụng **không tự chuyển tiền ngân hàng**. NgayHoan cũ dùng làm thời điểm yêu cầu, NgayXacNhan là thời điểm hoàn thực tế mới.

## 10. Chống double refund

Unique (MaHuy,MaTT) ngăn tạo hai yêu cầu cho cùng lần hủy/giao dịch. Xác nhận khóa cùng San/DatSan, đọc lại trạng thái, kiểm tra khoản hoàn thuộc booking đã hủy, payment thành công, tổng hoàn không vượt kế hoạch HuyDatSan và không vượt từng khoản thu.

Hai request xác nhận cùng MaHT trả200/200 theo idempotency nhưng chỉ một cập nhật/nhật ký/thực chi. Retry lần nữa không hoàn lại. Đây là idempotency có chủ đích, không phải hai giao dịch chi.

## 11. Authorization

Backend kiểm tra CN04_XEM/THEM/SUA và role; không dựa nút ẩn frontend. Khách chỉ xem/gửi yêu cầu/hủy booking của mình, không ghi Thành công hoặc xác nhận hoàn. Nhân viên sân có thể ghi thu nếu CN04_THEM; xác nhận yêu cầu cần CN04_SUA. Permission dữ liệu hiện tại của nhân viên sân không có CN04_SUA nên không được confirm/reject yêu cầu.

Hoàn tiền chỉ ACCOUNTANT/ADMIN + CN04_SUA, cần nhân viên hoạt động tương ứng để lưu người thực hiện. Không thêm quyền giả và không đổi phân quyền Phase2.

## 12. Transaction, log và legacy

Thanh toán; hủy + yêu cầu hoàn + đổi booking; xác nhận thu/hoàn; dịch vụ + đồng bộ hóa đơn đều transaction. Failure ghi nhật ký làm rollback nghiệp vụ, đã có test fault injection. Nhật ký cơ sở dữ liệu ghi actor, booking, thao tác, số tiền/tỷ lệ/thực thu; server log phục vụ chẩn đoán.

Booking legacy có payment nhưng chưa invoice bị chặn tự hủy/chuyển đổi để cần đối soát thay vì tự diễn giải lại lịch sử. Đây là guard bảo toàn tiền, không có tình huống này trong3 booking baseline. Không backfill hóa đơn hoặc đổi tiền legacy.

| Booking | Đơn giá trước/sau | Tiền sân trước/sau | Dịch vụ trước/sau | Giảm trước/sau | Tổng trước/sau | Giờ/slot giữ nguyên |
|---|---:|---:|---:|---:|---:|---|
| DS01 | 250.000 | 250.000 | 0 | 20.000 | 230.000 | 17:30–19:00 /KG03 |
| DS02 | 300.000 | 300.000 | 0 | 0 | 300.000 | 19:00–20:30 /KG04 |
| DS3b97491a | 200.000 | 200.000 | 0 | 0 | 200.000 | 16:00–17:30 /KG02 |

## 13. Build, run, Hibernate và JDBC

- `clean verify`: **121 tests, 0 failure, 0 error, 0 skipped**, BUILD SUCCESS;22 test tài chính mới +99 regression. Log `backend/phase5_1C-build.log`, XML tại target/surefire-reports.
- JavaScript syntax check finance.js/operations.js PASS. Sau chỉnh nhãn/ẩn form ban đầu, package lại JAR: BUILD SUCCESS (`backend/phase5_1C-package.log`); không thay logic Java sau full suite.
- JAR cuối đang chạy localhost:8080/api, PID15800 ở thời điểm báo cáo. Startup thành công11,639 giây; Hikari mở kết nối SQL Server, EntityManagerFactory initialized, `ddl-auto=validate` giữ nguyên. Log `backend/phase5_1C-startup.log`.
- JPA validate áp dụng các Entity đang ánh xạ. Bảng tài chính mới dùng JdbcTemplate, được kiểm chứng bằng migration/constraint/query/HTTP, không tuyên bố Hibernate validate các bảng không có Entity.
- Final JAR read-only HTTP: admin đọc ledger rỗng/thực nhận0 và DS01 tổng230.000 qua JDBC thật; static tài chính mới trả đúng nội dung. `FINAL_JAR_JDBC_READ_AND_STATIC_HTTP_PASS`.
- Không đổi Maven/pom/dependency/JDBC driver; sử dụng portable Maven có sẵn và JDK hiện có, credentials vẫn lấy môi trường/.env local ignored.

## 14. Ma trận kiểm thử

| Nhóm | Kết quả |
|---|---|
| Hóa đơn đúng sân/dịch vụ/giảm chỉ sân; fake total; unique invoice | PASS |
| Cash/bank, trả trước/từng phần/trả sau, phát sinh và thu phần thiếu | PASS |
| Không vượt tổng, đủ tiền từ chối thu thêm, checkbox thực nhận bắt buộc | PASS |
| Payment race còn100.000: một200, một409; retry idempotency | PASS |
| Khách không đặt Thành công, kiểm tra owner, nhân viên không tự hoàn | PASS |
| Booking xác nhận không thanh toán vẫn hợp lệ | PASS qua regression + luồng HTTP |
| Hủy10h01/đúng10h/dưới10h/đúng2h/dưới2h; chưa trả/partial | PASS |
| Không hoàn hai lần, refund race và retry, giới hạn thực thu/chính sách | PASS |
| Không hủy sau sử dụng; audit; rollback thu/hủy/hoàn khi audit lỗi | PASS |
| Tiền3 booking legacy, snapshot dịch vụ, overlap/race5.1A/B | PASS |
| Regression toàn bộ Phase1–5.1B | 99 tests PASS; HTTP5.1A/B PASS |
| Browser/manual UI | CHƯA KIỂM CHỨNG; checklist bên dưới |

Các lỗi phát hiện khi kiểm thử đã sửa: SQL datetime không nhận chuỗi thiếu giây tại phút00 (formatter giờ đầy đủ), precision thời điểm hủy/default dependency, fixture nhận sân có giờ tương lai khiến checkout vi phạm constraint, cleanup cũ thiếu HoaDon. Không sửa kiến trúc để lách lỗi.

## 15. HTTP integration và SQL verify

`backend/scripts/phase5-1c-http-check.mjs` chạy trên JAR thật với session/CSRF bốn role, actual SQL Server; kết quả **PHASE5_1C_HTTP_PASS**,14 điểm SQL verify PASS.

Đã chạy: partial200.000 trên292.200; payment race phần92200; khách giả Thành công bị chặn; full refund và refund race/retry; yêu cầu khách50.000 chỉ kế toán xác nhận; hủy partial50.000; các case ngày hiện tại gần10h/2h; trả trước103.200, nhận sân, phát sinh10.000, trả sân còn nợ rồi thu thêm → hoàn tất; booking sử dụng hủy409.

Exact10h/2h kiểm chứng thêm bằng SQL fn và Clock cố định trong integration test; HTTP thời gian thật dùng khoảng601/598/121/118 phút để tránh chênh vài giây khi gửi request. Script toàn bộ HTTP cần chạy trong cửa sổ07:00–11:29 để tạo đủ booking hôm nay+10h trong giờ hoạt động; đây là giới hạn fixture, không giới hạn thêm của ứng dụng.

Fixture tài chính FCHCBAA5D: trước cleanup7 hóa đơn,9 payments,6 hủy,6 refunds,3 dòng dịch vụ,1 lượt nhận/trả đã đóng. Hai khoản hoàn được xác nhận; SQL đếm đúng2 nhật ký xác nhận hoàn dù race/retry. View thực nhận243.200 cho fixture. Các tổng thu/hoàn đều không vượt invoice/chính sách/thực thu.

`cleanup-phase5-1c-test.sql` kiểm tra ID FCH+6hex, marker sân/booking, idempotency prefix, không có lượt chơi mở/đánh giá; xóa đúng dữ liệu fixture theo FK. Đã dọn6 hoàn,9 thu,6 hủy,3 dịch vụ,7 hóa đơn,1 lượt nhận/trả,46 nhật ký fixture,7 bookings và1 sân.

HTTP5.1A (FAH4809D9) và5.1B (SBHA5B99A) cũng PASS, đã SQL verify/cleanup riêng. Cleanup A/B được bổ sung HoaDon để tương thích tài chính mới. Catalog Coca đơn giá10.000 được hồi phục sau test catalogB.

SQL cuối:7 San,3 DatSan; **0 HoaDon/ThanhToan/HoanTien/HuyDatSan/ChiTietDichVu/XacNhanSan**,0 sân fixture;3 legacy như bảng trên. View thực nhận0, fn đúng10h100%/đúng2h50%. Không xóa DS01/DS02/DS3b97491a.

Chạy lại test chỉ ở database dev/test đã bố trí thời gian, dùng AUTH_TEST_PASSWORD từ môi trường, PHASE5_1C_TEST_STATE trỏ file tạm. Ghi lại fixture ID từ state, SQL verify rồi cleanup bằng `sqlcmd -f 65001 -b -i backend/scripts/cleanup-phase5-1c-test.sql -v PitchId=FCHxxxxxx`. Không dùng cleanup cho booking thật/manual. Nếu script lỗi giữa chừng, đọc state/SQL và kiểm tra guard trước dọn, không tự xóa rộng.

## 16. File đã thêm/sửa

Thêm:

- `database/migrations/Phase5_1C_Finance.sql`, `Phase5_1C_Rollback.sql`.
- `backend/src/main/java/com/sanbong/config/FinanceClockConfig.java`.
- `backend/src/main/java/com/sanbong/controller/FinanceController.java`.
- `backend/src/main/java/com/sanbong/service/FinanceService.java`.
- `backend/src/main/java/com/sanbong/repository/FinanceRepository.java`.
- `backend/src/main/java/com/sanbong/dto/InvoiceRequest.java`, `PaymentRequest.java`, `ReceiptConfirmation.java`, `RefundConfirmation.java`.
- `backend/src/test/java/com/sanbong/FinanceIntegrationTest.java`.
- `backend/scripts/phase5-1c-http-check.mjs`, `cleanup-phase5-1c-test.sql`.
- `frontend/js/finance.js`, báo cáo này.

Sửa:

- `backend/src/main/java/com/sanbong/service/BookingService.java`: tích hợp hủy/hoàn trong transaction cũ.
- `backend/src/main/java/com/sanbong/service/OperationsService.java`: cho phát sinh sau trả trước, sync/chốt hóa đơn.
- `backend/src/main/java/com/sanbong/controller/OperationsController.java`: thông báo trả sân đúng luồng tài chính.
- `backend/src/main/java/com/sanbong/config/SecurityConfig.java`: route tài chính và role, giữ method permission.
- `backend/src/main/java/com/sanbong/controller/ApiExceptionHandler.java`: log lỗi JDBC trên server.
- `backend/src/test/java/com/sanbong/BookingConcurrencyTest.java`: dọn HoaDon/nhật ký tài chính fixture.
- `backend/scripts/cleanup-phase5-1a-test.sql`, `cleanup-phase5-1b-test.sql`: dọn HoaDon của fixture exact ID.
- `frontend/Quan_ly_lich_dat_san.html`, `frontend/Man_hinh_chinh_NVKT.html`: gắn panel/sổ tài chính thật, bỏ số liệu giả và cập nhật nhãn theo luồng mới; chưa bật xuất báo cáo Phase6.
- `frontend/js/bookings.js`, `frontend/js/operations.js`: thông báo hủy/trả sân; không báo đã thu/hoàn tự động.
- `AGENTS.md`, `backend/README.md`: ghi phạm vi5.1C và hướng dẫn hiện tại.

## 17. Manual UI checklist

Đăng nhập tại `http://127.0.0.1:8080/api/Dang_nhap.html` (dùng tài khoản/mật khẩu hiện tại). Calendar: `/api/Quan_ly_lich_dat_san.html` cho admin/nhân viên/khách theo quyền hiện có. Kế toán: `/api/Man_hinh_chinh_NVKT.html`. Không thao tác test trên3 booking legacy. Fixture tự động đã dọn; checklist cần tạo booking kiểm tra riêng với ghi chú nhận diện.

1. Admin tạo booking LS01 vào một ngày trong tuần còn hiệu lực KM02,13:00–15:00; Coca SV03 lốc6 số lượng1. Xem detail: sân260.000, dịch vụ58.200. Chọn giảm10% →26.000, tổng292.200. Lập lại hóa đơn giữ cùng MaHoaDon. Nếu KM02 đã hết hiệu lực ở thời điểm kiểm thử sau này, không bật lại catalog thật để lách; dùng promotion dev phù hợp.
2. Ghi tiền mặt200.000, tích xác nhận thực nhận. Đã trả200.000, còn92.200, trạng thái THANH_TOAN_MOT_PHAN. F5/mở lại giữ đúng số. Gửi thêm tiền vượt92.200 bị từ chối, không toast thành công.
3. Booking khác: khách gửi yêu cầu Chuyển khoản, vẫn Chờ xử lý/đã thu0; nhân viên không có CN04_SUA không có nút xác nhận. Kế toán xác nhận đã nhận thật → mới cộng tiền. F5 giữ đúng trạng thái. Khách không xem booking của người khác hoặc xác nhận hoàn.
4. Booking ngày hiện tại, start trong khoảng có thể nhận sân (từ30 phút trước start), end hợp lệ: thử trả đủ trước, nhận sân và thêm dịch vụ. ConLai tăng đúng tiền snapshot; trả sân chốt dịch vụ nhưng còn nợ. Thu phần thiếu → HoanTatTaiChinh true. Trả sân không tự tạo payment; chỉnh dịch vụ sau trả sân bị chặn. Giá sân dùng đúng ca tại start, không ép con số ví dụ nếu giờ thử khác.
5. Booking tương lai chưa nhận sân, đã trả200.000: xem preview trước hủy. ≥10h hoàn200.000;2–<10h hoàn100.000;<2h hoàn0. Hủy thành công không đồng nghĩa Đã hoàn; khoản >0 phải Chờ duyệt. Invoice DA_HUY/conLai0; F5 vẫn giữ khoản hoàn pending và thực thu chưa giảm.
6. Kế toán/admin mở booking pending: chọn phương thức hoàn thực tế, nhập lý do và xác nhận đã trả thật. Đã hoàn có người/thời gian, thực thu giảm đúng. Retry không tăng tổng hoàn; nhân viên/khách không được thực hiện. Khoản0 không có nút trả khoản0.
7. Trang kế toán ban đầu chưa chọn booking phải ẩn form thu/lập invoice/hoàn. Nhập mã booking hoặc bấm giao dịch để xem; số đã trả/còn thiếu, danh sách thu/hoàn, tổng thực nhận đều lấy API. Sau thao tác, nút xem booking trong hàng đợi hoàn dùng được; refresh giữ dữ liệu. Chuyển khoản được mô tả là xác minh thủ công, không có thông báo tự chuyển ngân hàng.
8. Không thu đủ khi thiếu CSRF/permission; thử lỗi validation/API và xác nhận không toast thành công. Kiểm tra modal cuộn được, không vỡ bố cục khi lịch sử dài; console không lỗi. Các nút xuất báo cáo/đối soát ngân hàng chưa làm không được báo success giả.

Chưa đánh dấu các bước trên PASS trước khi thực sự thao tác browser.

## 18. Technical debt và điểm dừng

- Chưa triển khai báo cáo tổng hợp Phase6, export/PDF hóa đơn, đối soát ngân hàng tự động hoặc payment gateway. Sổ thu/hoàn hiện tại là dữ liệu nội bộ thật, toàn thời gian; không giả bộ bộ lọc báo cáo đã hoạt động.
- Điều kiện promotion văn bản tùy ý cần mô hình eligibility rõ hơn khi được giao; hiện hỗ trợ phần trăm, hiệu lực và rule ngày trong tuần KM02, không tự áp giảm cố định cũ sang booking mới.
- Không đối soát tự động payment legacy chưa có hóa đơn; phải kiểm tra nghiệp vụ trước migration lịch sử nếu sau này có dữ liệu loại đó.
- Cần manual UI verification như checklist, review vận hành backup/mật khẩu dev/secrets/TLS theo môi trường trước triển khai nội bộ; chưa triển khai LAN/server.

**Dừng tại Phase5.1C.**
