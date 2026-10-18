# Phase 5.1A — Booking giờ tự do và giá theo ca

Ngày kiểm tra: 08/10/2026. Đã triển khai và kiểm chứng backend/API/SQL. Kiểm tra thao tác trực tiếp trên trình duyệt còn ở checklist bên dưới. Dừng tại 5.1A; không triển khai 5.1B, tài chính/dịch vụ mới, Phase 6 hoặc LAN.

## 1. Kết quả nghiệp vụ

- Booking mới nhập ngày chơi, giờ bắt đầu, giờ kết thúc; không bắt chọn slot cố định.
- Giới hạn 07:00–22:00, kết thúc phải sau bắt đầu, nhập chính xác đến phút, không đặt qua ngày hoặc trong quá khứ.
- Giá lấy từ `GiaTheoCa` theo giờ bắt đầu cho toàn booking: 07:00–trước 13:00 = 90.000đ/giờ; 13:00–trước 19:00 = 130.000đ/giờ; 19:00–trước 22:00 = 180.000đ/giờ.
- `TienSan = số phút thực tế × DonGia / 60`, làm tròn tiền đến hai chữ số thập phân. Không lấy thời lượng đã làm tròn làm đầu vào tính tiền. Ví dụ 07:00–08:01 = 91.500đ.
- Booking mới lưu snapshot giờ, đơn giá, tiền và `CheDoGia=GIA_GIO`; đặt trực tiếp bằng giờ có `MaKhungGio=NULL`. Hình thức đặt phân biệt `TRUC_TUYEN`/`TAI_QUAY` theo người thực hiện.
- Giá mới áp dụng theo ca cho các ngày và loại sân; không tự bổ sung phụ thu cuối tuần/ngày lễ. `BangGia` tiếp tục phục vụ dữ liệu legacy, không quyết định giá booking mới.
- API cũ chỉ gửi `MaKhungGio` vẫn được tiếp nhận nếu giờ hợp lệ: chuyển khoảng giờ của slot thành snapshot và tính giá mới theo ca. Gửi đồng thời slot và giờ tự do bị từ chối. Slot bắt đầu 06:00 không hợp lệ cho booking mới; booking legacy ngoài giờ mới vẫn được giữ nguyên.
- Lịch, tra cứu, xác nhận/hủy và kiểm tra giờ nhận sân đọc snapshot; thay giờ trong bảng `KhungGio` không làm dịch chuyển booking đã có.

## 2. Backup, dependency và migration

Trước migration đã kiểm tra bảng/cột/index/FK/check và dependency trong SQL Server, đồng thời kiểm tra các truy vấn Java. Dependency đáng chú ý: `V_TyLeLapDay`, `V_KhungGioTrong`, `TRG_CapNhatTienDatSan`. Giữ các đối tượng hiện có và khóa ngoại `MaKhungGio`; không DROP/reset database hoặc sửa tiền legacy.

Backup `COPY_ONLY, CHECKSUM` đã tạo và `RESTORE VERIFYONLY WITH CHECKSUM` thành công:

```text
C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\QuanLySanBong_Phase5_1A_PreMigration_20261008.bak
```

Đường dẫn trên là vị trí artifact backup của SQL Server đang kiểm tra, không phải đường dẫn được đưa vào cấu hình ứng dụng.

Danh sách thay đổi schema đã triển khai:

1. Thêm `DatSan.GioBatDau/GioKetThuc time(0) NOT NULL`, backfill từ slot của từng booking cũ.
2. Thêm `CheDoGia varchar(12)` mặc định `GIA_KHUNG` và `HinhThucDat varchar(12)` mặc định `KHONG_RO`.
3. Cho `MaKhungGio` nullable, giữ FK cho giá trị legacy.
4. Điều chỉnh `UX_DatSan_KhongTrungLich`: chỉ booking chưa hủy và có slot. Thêm index `IX_DatSan_SanNgayBatDau` phục vụ tìm khoảng giờ.
5. Thêm CHECK khoảng giờ, chế độ giá, hình thức đặt và giới hạn giờ/phút cho `GIA_GIO`; legacy không bị áp quy tắc giờ mới.
6. Thêm `GiaTheoCa` với ba dòng SANG/CHIEU/TOI, đơn giá decimal(18,2), khóa chính và ràng buộc giá/biên ca.

Đã chạy `database/migrations/Phase5_1A_BookingTimes.sql`. Regression phát hiện literal tiếng Việt trong filter index bị đọc sai encoding ở lần chạy đầu. Đã chạy `Phase5_1A_IndexUtf8Fix.sql` bằng `sqlcmd -f 65001 -b` để sửa riêng index trong transaction, kiểm tra catalog có đúng `Đã hủy` và test hủy/đặt lại PASS. Không thay đổi dữ liệu booking bằng bản sửa index.

`Phase5_1_BookingTimes_PROPOSAL.sql` giữ nguyên chế độ proposal. `Phase5_1A_Rollback.sql` đã chuẩn bị nhưng **chưa chạy**, mặc định khóa thực thi. Rollback từ chối nếu có booking giờ tự do/slot NULL hoặc cấu hình giá mới đã thay đổi; không tự xóa booking thật để đưa schema về cũ. Khi rollback phải phối hợp backend cũ và đánh giá dữ liệu mới trước. Migration không tự chạy khi Spring Boot khởi động.

## 3. Legacy trước/sau

SQL đối chiếu xác nhận các giá trị tiền trước và sau giống nhau:

| Booking | Slot / snapshot giờ | Đơn giá trước = sau | Tiền sân trước = sau | Dịch vụ trước = sau | Giảm trước = sau | Tổng trước = sau |
|---|---|---:|---:|---:|---:|---:|
| DS01 | KG03 / 17:30–19:00 | 250.000 | 250.000 | 0 | 20.000 | 230.000 |
| DS02 | KG04 / 19:00–20:30 | 300.000 | 300.000 | 0 | 0 | 300.000 |
| DS3b97491a | KG02 / 16:00–17:30 | 200.000 | 200.000 | 0 | 0 | 200.000 |

Cả ba giữ `MaKhungGio`, `CheDoGia=GIA_KHUNG`, `HinhThucDat=KHONG_RO`; không chuyển sang phép tính giờ mới. Ngày chơi và trạng thái cũ không bị chuyển đổi. Trigger hiện có vẫn được giữ và hoạt động; không triển khai bảng hóa đơn/tài chính trong lượt này.

Sau khi dọn fixture kiểm thử: SQL có **7 sân, 3 booking**, không còn fixture Phase 5.1A, không có overlap booking đang chiếm sân. Các bảng dịch vụ/nhận sân/thanh toán/hoàn tiền không phát sinh dữ liệu nghiệp vụ từ phase này.

## 4. Chống overlap và concurrency

Điều kiện overlap: `existing.start < requested.end AND requested.start < existing.end`. Hai khoảng sát biên được phép. Booking đã hủy không chiếm lịch.

Tạo booking giữ transaction và pessimistic lock trên bản ghi `San` trước khi đọc lịch và ghi booking. Hai yêu cầu cùng sân được tuần tự hóa tại database; yêu cầu sau đọc được khoảng vừa commit và trả HTTP 409 nếu trùng. Index slot chỉ bảo vệ compatibility legacy, không được coi là cơ chế đủ để chống interval overlap. Các writer tương lai phải tuân thủ cùng cơ chế lock; ghi SQL thủ công ngoài ứng dụng không có bảo đảm chống overlap chỉ từ index này.

## 5. File thay đổi/thêm

Đường dẫn tương đối từ root project:

- Schema: `database/migrations/Phase5_1A_BookingTimes.sql`, `Phase5_1A_IndexUtf8Fix.sql`, `Phase5_1A_Rollback.sql`.
- Entity/DTO: `backend/src/main/java/com/sanbong/model/DatSan.java`, `dto/BookingRequest.java`, `dto/BookingView.java`.
- Repository/service/controller: cùng package `repository/TimePriceRepository.java` (mới), `service/BookingService.java`, `service/OperationsService.java`, `controller/BookingController.java`. OperationsService chỉ sửa việc đọc giờ snapshot; không thêm workflow dịch vụ/tài chính. Tái sử dụng truy vấn lịch và khóa sân hiện có, không tạo repository booking trùng.
- Frontend: `frontend/Dat_san_tai_quay.html`, `frontend/Man_hinh_chinh_Dat_san_KH.html`, `frontend/js/bookings.js`. Dùng style hiện có, thay lựa chọn slot bằng hai input giờ; lịch nhận giờ snapshot qua DTO.
- Tests trong `backend/src/test/java/com/sanbong/`: `FreeTimeBookingTest.java` (mới), `BookingConcurrencyTest.java`, `BookingManagementTest.java`, `OperationsManagementTest.java`, `OperationsConcurrencyTest.java`.
- Scripts: `backend/scripts/phase5-1a-http-check.mjs` (mới), `cleanup-phase5-1a-test.sql` (mới), `prepare-phase5-operations-test.sql`, `phase4-http-check.mjs`.
- Tài liệu: `AGENTS.md`, `backend/README.md`, báo cáo này.

Không đổi dependency/version, CSS, credentials, tech stack hoặc `ddl-auto=validate`. Không thêm phụ thuộc SqlProxy. Maven portable và JDK hiện có được sử dụng, không sửa PATH toàn hệ thống.

## 6. Build/run và kiểm thử

`clean verify`: **BUILD SUCCESS, 79 tests, 0 failures, 0 errors, 0 skipped**. Regression được cập nhật kỳ vọng cho booking mới theo yêu cầu giá mới; các test legacy tiếp tục giữ giá cũ. Phân bố: Authentication 7, BookingManagement 19, BookingConcurrency 5, FreeTimeBooking 20, OperationsManagement 17, OperationsConcurrency 4, PitchManagement 6, SQL connection 1.

| Test giá | Khoảng giờ | Kỳ vọng | Kết quả |
|---|---|---:|---|
| M1 | 08:00–12:30 | 405.000 | PASS |
| M2 | 12:20–14:20 | 180.000 | PASS |
| M3 | 13:00–15:00 | 260.000 | PASS |
| M4 | 18:30–20:00 | 195.000 | PASS |
| M5 | 19:00–20:00 | 180.000 | PASS |

- Overlap đầu/cuối/nằm trong/bao trùm: PASS, trả 409; sát cả hai biên: PASS, được đặt.
- Hai request đồng thời với khoảng khác nhau nhưng overlap: PASS, một 200 và một 409, chỉ một booking được ghi. Cả kiểm thử Spring và HTTP trên server thật đều kiểm tra tình huống này.
- Trước 07:00, sau 22:00, start=22:00, end=start, end<start, có giây khác 0: PASS, từ chối 400.
- Giá theo phút 61 phút; thay giá ca không sửa snapshot cũ; thay giờ slot không dịch chuyển legacy; thiếu giá ca trả lỗi 409: PASS.
- JavaScript `node --check`: PASS. Hai trang có input giờ và ID không trùng: PASS.

Các lỗi phát hiện khi kiểm thử đã sửa: JDBC bind TIME gây so sánh TIME/DATETIME không hợp lệ (đổi truy vấn sang CAST tham số thành TIME), encoding filter index, và chuyển lỗi thiếu cấu hình giá thành business response thay vì lỗi repository chung. Lần build cuối không còn test FAIL.

Đóng gói lại sau thay đổi frontend cuối: **BUILD SUCCESS**. Khởi động JAR thành công trong 8,735 giây; Hikari kết nối trực tiếp SQL Server, Hibernate `validate` thành công, EntityManagerFactory và Tomcat khởi động. Server tại `http://127.0.0.1:8080/api`, PID 29424 tại thời điểm báo cáo, chưa mở LAN.

Log: `backend/target/phase5_1A-build.log`, `phase5_1A-package.log`, `phase5_1A-startup.log`; kết quả JUnit trong `backend/target/surefire-reports/`.

HTTP integration trên JAR thật dùng login/session/CSRF, tạo sân fixture `FAH223877`, ngày 28/10/2026. PASS: năm giá M1–M5, boundary, hai request song song, availability loại sân bị chiếm, lịch, đọc lại bằng session khác, xác nhận/hủy và trả HTML cho nhân viên/khách hàng có input giờ. Script in `PHASE5_1A_HTTP_PASS`.

SQL kiểm tra sáu booking fixture: snapshot giờ/tiền đúng, `MaKhungGio=NULL`, `GIA_GIO`; tất cả được hủy sau test. Cleanup có guard marker và kiểm tra không có dữ liệu tài chính/nhận sân/dịch vụ trước khi xóa đúng fixture: 6 booking, 6 bản ghi hủy, 14 audit liên quan, 1 sân. Nhật ký login/logout được giữ. Ba booking thật không bị xóa/sửa. Các HTTP script phase cũ chỉ được cập nhật compatibility và kiểm tra syntax, không tuyên bố đã chạy lại toàn bộ script cũ; regression Java và HTTP mới đã chạy.

## 7. Manual UI checklist — chưa thao tác trực tiếp trên trình duyệt

- [ ] Đăng nhập nhân viên và khách hàng, mở trang đặt sân tương ứng; thấy ngày chơi, giờ bắt đầu/kết thúc và lựa chọn sân trống, không bắt chọn slot.
- [ ] Chọn ngày tương lai và sân thực sự còn trống; thử M1–M5, kiểm tra giá/tiền trên kết quả API và phần xác nhận trước khi đặt.
- [ ] Đặt một booking thử, F5/mở lịch ở trình duyệt khác; giờ và tiền vẫn đúng snapshot.
- [ ] Thử khoảng overlap trên cùng sân/ngày: UI hiển thị lỗi API, không báo thành công; thử khoảng sát biên phải được chấp nhận.
- [ ] Thử ngoài 07:00–22:00 và end<=start; phải hiện lỗi. Đổi giờ/ngày liên tiếp phải làm mới availability, không dùng kết quả cũ.
- [ ] Hai trình duyệt đặt đồng thời khoảng overlap: chỉ một thành công, một báo xung đột; lịch chỉ có một booking.
- [ ] Mở lịch legacy đúng ngày của DS01/DS02/DS3b97491a, đối chiếu giờ/tiền bảng trên; không chỉnh/hủy các booking này để kiểm thử.
- [ ] Hủy booking thử vừa tạo, kiểm tra lịch/trạng thái và tra cứu lại. Bộ lọc slot cũ chỉ phù hợp các booking có slot; chọn tất cả để xem booking giờ tự do.

## 8. Giới hạn và điểm dừng

Chưa kiểm tra click/render trực tiếp trên trình duyệt. Chưa có UI quản trị `GiaTheoCa`; trang bảng giá cũ vẫn chỉ đọc `BangGia`. Quy tắc trạng thái sân đang sử dụng/bảo trì hiện có được giữ, không thay đổi trong phase này. Quy tắc tài chính, dịch vụ, khuyến mãi/hoàn tiền mở rộng thuộc phần sau, chưa triển khai. Không còn lỗi build/JDBC/schema/test được phát hiện trong phạm vi đã kiểm chứng. Dừng tại Phase 5.1A.
