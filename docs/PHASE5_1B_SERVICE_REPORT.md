# Phase 5.1B — Dịch vụ, quy cách bán và snapshot giá

Ngày hoàn thành kiểm thử: 08/10/2026. Đã triển khai backend/API/SQL và bổ sung UI theo phong cách hiện có. **BUILD SUCCESS; 99/99 tests PASS; HTTP integration và SQL verify PASS.** Chưa kiểm tra thao tác click/render trực tiếp trên trình duyệt; checklist nằm ở cuối báo cáo. Dừng tại 5.1B, không triển khai tài chính hoàn chỉnh, 5.1C, Phase 6 hoặc LAN.

## 1. Migration, backup và dependency

Đã audit schema thực tế trước thay đổi:

- `ChiTietDichVu` có PK `(MaDatSan,MaDV)`, `SoLuong int`, `DonGia decimal(18,2)`, `ThanhTien` là cột computed; FK đến DatSan/DichVu/NhanVien.
- Không có FK từ bảng khác tham chiếu PK ChiTietDichVu và không có view schema-bound tham chiếu bảng này. Dependency quan trọng là `TRG_CapNhatTienDatSan` và CHECK số lượng/giá.
- Catalog có 6 SKU DV01–DV06; ChiTietDichVu có **0 dòng trước migration**. Không có dòng lịch sử thật cần chuyển tiền; compatibility legacy vẫn được kiểm thử bằng fixture rollback.
- Java đang dùng JdbcTemplate cho dịch vụ, không có Entity chi tiết dịch vụ cần chuyển khóa JPA.

Đã backup `COPY_ONLY, CHECKSUM` và `RESTORE VERIFYONLY WITH CHECKSUM` thành công, trước khi chạy migration:

```text
C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\QuanLySanBong_Phase5_1B_PreMigration_20261008.bak
```

Đây là vị trí artifact backup trên SQL Server, không phải đường dẫn đưa vào code ứng dụng.

Đã chạy **`database/migrations/Phase5_1B_Services.sql`**, dùng UTF-8 `sqlcmd -f 65001 -b`. Lần chạy đầu bị SQL Server từ chối do thiếu SET QUOTED_IDENTIFIER; transaction rollback, không còn schema dở dang. Đã bổ sung đầy đủ SET options và chạy lại thành công. Không DROP/reset database hoặc xóa SKU/booking legacy; không sửa trigger hoặc cột computed.

Rollback chuẩn bị trong **`Phase5_1B_Rollback.sql`**, mặc định khóa thực thi và **chưa chạy**. Script từ chối nếu có lịch sử dịch vụ mới, nhiều dòng cùng SKU hoặc catalog mới đã được thay đổi; không tự xóa lịch sử thật để phục hồi khóa cũ. Chỉ áp dụng rollback sau review và phối hợp backend cũ. Backup đã xác minh là phương án phục hồi toàn bộ, nhưng restore sẽ cần đánh giá dữ liệu phát sinh sau backup trước khi thực hiện. Migration không tự chạy khi ứng dụng khởi động.

## 2. Schema trước/sau

| Đối tượng | Trước | Sau |
|---|---|---|
| PK ChiTietDichVu | MaDatSan + MaDV | MaChiTiet bigint IDENTITY |
| MaDatSan/MaDV/MaNV | Các FK hiện có | Giữ nguyên FK |
| Nguon | Chưa có | LEGACY / DAT_TRUOC / PHAT_SINH, mặc định LEGACY |
| QuyCach | Chưa có | DON_VI / LOC_6, mặc định DON_VI |
| SoDonViMoiQuyCach | Chưa có | 1 hoặc 6, ràng buộc khớp quy cách |
| DonGiaDonViSnapshot | Chưa có | decimal(18,2), backfill từ DonGia của dòng cũ |
| DonGia / ThanhTien | Giá snapshot và computed số lượng × giá | Giữ semantics giá quy cách và computed hiện có |
| DichVu.HoTroLoc | Chưa có | bit, mặc định 0 cho catalog legacy |
| Index tra cứu | PK kép | IX_CTDV_BookingSku(MaDatSan,MaDV), không unique |

CHECK mới ràng buộc nguồn/quy cách/đơn vị và giá snapshot của dòng mới. Dòng LEGACY cho phép snapshot đơn vị NULL để tương thích các writer/fixture cũ; mọi dòng mới do ứng dụng tạo đều ghi snapshot đơn vị hợp lệ. Dòng legacy được migration backfill bằng giá giao dịch cũ, không lấy lại giá catalog hiện tại.

## 3. Catalog seed

Giữ DV01–DV06, không đổi tên/giá/thương hiệu của SKU cũ. Seed SKU mới có kiểm tra collision trước migration:

| SKU | Tên | Đơn vị | Giá đơn vị | Lốc 6 |
|---|---|---|---:|---:|
| SV01 | Trà đá | Thùng | 50.000 | Không hỗ trợ |
| SV02 | Nước suối | Chai | 5.000 | 29.100 |
| SV03 | Coca | Lon | 10.000 | 58.200 |
| SV04 | Pepsi | Lon | 10.000 | 58.200 |
| SV05 | Revive chanh muối | Chai | 12.000 | 69.840 |
| SV06 | Revive | Chai | 10.000 | 58.200 |
| SV07 | Aquarius | Chai | 12.000 | 69.840 |

Catalog trả 13 dịch vụ đang kinh doanh ở trạng thái hiện tại, gồm cả legacy. DV01 Nước suối 10.000 được giữ nguyên; SV02 là SKU chính thức mới 5.000. Không tự ngừng kinh doanh các SKU legacy.

Admin xem cả dịch vụ ngừng kinh doanh; có thể đổi giá đơn vị, bật/tắt kinh doanh và hỗ trợ lốc. Chỉ đơn vị Chai/Lon được bật hỗ trợ lốc; Trà đá Thùng không được bật. Backend kiểm tra role ADMIN và permission CN03 tương ứng. Không mở quyền operations cho khách hàng.

## 4. Giá snapshot và lốc

`DichVu.DonGia` luôn là giá catalog của một đơn vị; không đổi sang giá lốc.

```text
DON_VI: DonGia dòng = DonGia catalog; SoDonViMoiQuyCach = 1
LOC_6:  DonGia dòng = ROUND(DonGia catalog × 6 × 0,97, 2); SoDonViMoiQuyCach = 6
ThanhTien = SoLuong × DonGia dòng
```

Backend dùng BigDecimal và trả `giaLoc` qua API. Frontend dùng giá từ API để preview, không hard-code đơn giá hoặc tự quyết định giá lốc. Backend lấy catalog đang khóa trong transaction để ghi `DonGiaDonViSnapshot`, `DonGia` theo quy cách và nguồn dịch vụ.

Một booking có thể có cùng SKU với nguồn, quy cách hoặc giá snapshot khác nhau. Nếu đã có đúng cùng SKU/nguồn/quy cách/giá, API thêm trả 409 và hướng dẫn sửa số lượng bằng MaChiTiet; không âm thầm ghi đè hoặc cộng thêm vào dòng không xác định.

Thay giá/ngừng kinh doanh/tắt hỗ trợ lốc của catalog không sửa các dòng đã ghi. Sửa số lượng dòng cũ dùng giá snapshot, không lấy giá catalog mới. Không có API đổi tên/đơn vị SKU nên không đổi nghĩa lịch sử bằng thao tác quản trị trong phase này.

## 5. API và quyền

Các path dưới đây nằm dưới context `/api`:

| API | Mục đích / quyền |
|---|---|
| GET /booking-services | Catalog hoạt động và giá đơn vị/lốc cho người có quyền tạo booking |
| POST /bookings | Nhận thêm `dichVu:[{maDV,soLuong,quyCach}]`; lưu booking + DAT_TRUOC cùng transaction |
| GET /bookings/{id}/services | Đọc snapshot; kiểm tra ownership với khách hàng |
| GET /services | Catalog hoạt động cho nhân viên, giữ compatibility |
| GET /service-catalog | Catalog đầy đủ cho admin có CN03_XEM |
| PUT /service-catalog/{sku} | Đổi donGia/trangThai/hoTroLoc; admin có CN03_SUA |
| POST /operations/bookings/{id}/services/{sku} | Thêm PHAT_SINH; nhân viên đang làm việc có CN03_THEM |
| PUT /operations/bookings/{id}/service-lines/{maChiTiet} | Sửa số lượng đúng dòng, giữ snapshot; CN03_SUA |
| DELETE /operations/bookings/{id}/service-lines/{maChiTiet} | Xóa đúng dòng chưa chốt; CN03_XOA |
| PUT/DELETE /operations/bookings/{id}/services/{sku} | Compatibility: chỉ khi đúng 1 dòng; nhiều dòng trả 409 |

Thêm phát sinh/sửa/xóa yêu cầu booking đã xác nhận, đã nhận sân và chưa trả sân; không bị hủy, không có thanh toán chờ/thành công. Khách hàng không truy cập endpoint operations kể cả booking của chính mình. Không cho sửa/xóa dòng thuộc booking khác bằng mã dòng. Backend validate dịch vụ tồn tại/đang kinh doanh, quy cách, hỗ trợ lốc, số lượng và giới hạn tiền SQL Server.

## 6. Transaction, concurrency và nguồn tính tổng

Booking và dịch vụ đặt trước cùng transaction; dịch vụ lỗi làm rollback cả booking và các dòng đã thêm trước đó. Kiểm tra owner của booking diễn ra ở backend.

Operations tiếp tục khóa San rồi DatSan, refresh trạng thái sau khi chờ khóa, trước khi ghi dòng. Hai nhân viên thêm cùng dòng logic: một 200, một 409; thêm khác quy cách: cả hai được giữ. Hai thao tác sửa số lượng được tuần tự hóa, tổng luôn khớp dòng cuối; không có double charge. Sửa số lượng là ghi giá trị tuyệt đối, hiện chưa có cơ chế version để báo một nhân viên đang ghi đè giá trị vừa sửa của người khác.

Catalog được đọc bằng UPDLOCK/HOLDLOCK khi bán; đổi catalog cũng dùng transaction. Đặt trước nhiều SKU khóa theo thứ tự mã để giảm nguy cơ đảo thứ tự khóa.

**Nguồn duy nhất cập nhật TienDichVu/TongTien vẫn là `TRG_CapNhatTienDatSan`.** Trigger tính SUM(ThanhTien) trên toàn bộ dòng booking khi insert/update/delete, sau đó tính tổng sân + dịch vụ − giảm. Java chỉ validate giới hạn và refresh Entity sau ghi; không cộng TienDichVu lần nữa. CHECK/PK/index/FK được tận dụng; không thêm SP/function SQL vì công thức đã có helper BigDecimal dùng chung và CHECK phù hợp.

Các thao tác đặt trước/phát sinh/sửa/xóa và đổi catalog ghi NhatKyHeThong trong transaction. Không phát hành hóa đơn hoặc báo thanh toán thành công.

## 7. File sửa/thêm

Đường dẫn tương đối từ root project:

- Migration mới: `database/migrations/Phase5_1B_Services.sql`, `Phase5_1B_Rollback.sql`.
- DTO: `backend/src/main/java/com/sanbong/dto/BookingRequest.java`; thêm `PrebookServiceRequest.java`, `ServiceSaleRequest.java`, `ServiceCatalogRequest.java` cùng thư mục.
- Service: `backend/src/main/java/com/sanbong/service/BookingService.java`, `OperationsService.java`; thêm `AmbiguousServiceLineException.java`.
- Repository: `backend/src/main/java/com/sanbong/repository/OperationsRepository.java`.
- Controller: `backend/src/main/java/com/sanbong/controller/BookingController.java`, `OperationsController.java`, `ApiExceptionHandler.java`; thêm `ServiceCatalogController.java`.
- Security: `backend/src/main/java/com/sanbong/config/SecurityConfig.java`.
- UI: `frontend/Dat_san_tai_quay.html`, `frontend/Man_hinh_chinh_Dat_san_KH.html`, `frontend/Quan_ly_lich_dat_san.html`.
- JS: `frontend/js/bookings.js`, `operations.js`; thêm `booking-services.js`, `service-catalog.js`.
- Tests: `backend/src/test/java/com/sanbong/ServiceSalesTest.java` (mới), `OperationsConcurrencyTest.java`, `OperationsManagementTest.java`.
- Scripts mới: `backend/scripts/phase5-1b-http-check.mjs`, `cleanup-phase5-1b-test.sql`.
- Tài liệu: `AGENTS.md`, `backend/README.md`, báo cáo này.

Không thay pom/dependency/version/framework, cấu hình secrets, CSS hoặc schema booking giờ tự do của 5.1A. Không thêm dependency SqlProxy. Giữ ddl-auto=validate. Tái sử dụng cấu trúc Controller → Service → Repository và UI hiện tại; không tạo lại project.

## 8. Build/run và kết quả test

Maven/JDK portable hiện có, `clean verify`: **99 tests, 0 failures, 0 errors, 0 skipped, BUILD SUCCESS** (2 phút 49 giây). Bộ regression cũ giữ nguyên nghiệp vụ; chỉ đổi kỳ vọng số lượng catalog từ 6 thành 13, khi ngừng một SKU từ 5 thành 12.

| Suite | Số test | Kết quả |
|---|---:|---|
| AuthenticationTest | 7 | PASS |
| BookingConcurrencyTest | 5 | PASS |
| BookingManagementTest | 19 | PASS |
| FreeTimeBookingTest | 20 | PASS |
| OperationsConcurrencyTest | 7 | PASS |
| OperationsManagementTest | 17 | PASS |
| PitchManagementTest | 6 | PASS |
| ServiceSalesTest | 17 | PASS |
| SqlServerConnectionTest | 1 | PASS |

Các ca bắt buộc đã được kiểm tra: tải catalog; Nước suối 5.000, Coca 10.000, Coca lốc 58.200, Aquarius lốc 69.840; từ chối Trà đá lốc/quantity<=0/quy cách sai/SKU thiếu/SKU ngừng; đặt trước atomic; phát sinh; cùng SKU khác nguồn/quy cách/giá; đổi catalog giữ giá cũ và dòng mới dùng giá mới; trigger không cộng đôi; kiểm tra role/permission/owner; sửa/xóa đúng mã dòng và từ chối route SKU mơ hồ; chặn sửa sau trả sân; concurrency thêm/sửa; rollback khi dịch vụ/audit lỗi; legacy snapshot và regression booking giờ tự do.

Lỗi phát hiện đã sửa: SET options migration; dùng Entity managed do `saveAndFlush` trả về khi refresh sau trigger; kỳ vọng số lượng catalog cũ trong regression. Cấu hình mật khẩu kiểm thử ban đầu không khớp tài khoản hiện tại được điều chỉnh ở môi trường test, không reset/thay credentials trong database. Lần build cuối tất cả PASS. JavaScript mới/sửa đều qua `node --check`.

JAR đã chạy, PID 10932 tại thời điểm báo cáo, Spring Boot startup thành công trong 22,852 giây. Hikari kết nối trực tiếp Microsoft SQL Server; Hibernate validate và EntityManagerFactory thành công; Tomcat 8080, context `/api`, chỉ localhost. Startup stderr trống. SQL connection test chứng minh JDBC/JPA đọc được DatSan.

Log: `backend/phase5_1B-build.log`, `phase5_1B-startup.log`, `phase5_1B-startup-error.log`; JUnit XML tại `backend/target/surefire-reports/`.

## 9. HTTP integration và SQL verify

HTTP trên JAR thật dùng session/CSRF cho admin, nhân viên và khách hàng. Fixture `SBHAA586E`, hai booking `DSac0c760d`, `DScbf5731e`. Kết quả **PHASE5_1B_HTTP_PASS** và **Staff HTTP PASS**:

- Khách đọc catalog, tạo booking + 3 dòng DAT_TRUOC, tiền dịch vụ 138.040, tổng 228.040; session admin đọc lại đúng dữ liệu database.
- Trà đá lốc/SL 0 bị từ chối; một SKU hợp lệ rồi SKU thiếu làm rollback toàn booking, không có booking nửa hoàn chỉnh.
- Khách không mở operations hoặc sửa catalog.
- Nhân viên nhận sân, thêm PHAT_SINH; admin đổi Coca 10.000→11.000, dòng cũ vẫn 10.000/58.200, dòng mới 11.000/64.020.
- Hai nhân viên thêm cùng dòng lốc mới: 200/409. Sửa/xóa theo MaChiTiet chính xác; route SKU nhiều dòng trả 409. Trả sân xong không sửa dịch vụ được.
- Giá Coca được khôi phục về 10.000 bằng finally; nhật ký đổi/khôi phục catalog được giữ.

SQL trước cleanup xác nhận 7 dòng fixture còn lại sau thử xóa một dòng; unit snapshot 10.000/11.000, giá lốc 58.200/64.020 và Aquarius 69.840 đúng. SUM dòng khớp TienDichVu và TongTien trên mọi booking. Booking phát sinh có tiền sân 45.000, dịch vụ 143.220, tổng 188.220, trạng thái Đã sử dụng. Booking tương lai đã hủy vẫn giữ snapshot dịch vụ để lưu lịch sử; chưa xử lý thu/hoàn tiền.

Cleanup guarded đúng marker/ID, từ chối nếu có thanh toán hoặc lượt nhận sân chưa trả. Đã dọn 14 audit booking/sân fixture, 1 bản ghi hủy, 7 dòng dịch vụ, 1 lượt nhận/trả, 2 booking và 1 sân thử. Không xóa audit login/logout/catalog.

Đã chạy thêm script HTTP Phase 5 cũ: **OPERATIONS_HTTP_OK**, fixture `P5H1A8C61`, PASS check-in/service race/snapshot/trigger/check-out/fresh read; fixture được dọn bằng script guard cũ. Không chạy nghiệp vụ hóa đơn/thanh toán/hoàn tiền.

## 10. Legacy và dữ liệu sau kiểm thử

Sau cleanup: **7 sân, 3 booking, 13 SKU catalog, 0 ChiTietDichVu, 0 XacNhanSan, 0 ThanhToan, 0 HoanTien**. Trigger giữ nguyên và không bị disable; PK và index chi tiết mới tồn tại. Catalog legacy không đổi tiền/tên; catalog Coca chính thức khôi phục đúng seed.

| Booking | Đơn giá trước = sau | Tiền sân trước = sau | Dịch vụ trước = sau | Giảm trước = sau | Tổng trước = sau |
|---|---:|---:|---:|---:|---:|
| DS01 | 250.000 | 250.000 | 0 | 20.000 | 230.000 |
| DS02 | 300.000 | 300.000 | 0 | 0 | 300.000 |
| DS3b97491a | 200.000 | 200.000 | 0 | 0 | 200.000 |

Không chuyển booking cũ sang giá mới hoặc làm lại migration 5.1A.

## 11. UI và checklist thủ công

Hai trang booking có danh sách dịch vụ từ API, SL đơn vị/lốc nếu hỗ trợ và preview tổng. Modal nhận sân/dịch vụ hiển thị nguồn/quy cách/giá snapshot, sửa/xóa theo mã dòng. Admin quản lý catalog ở mục mở rộng **Quản lý danh mục dịch vụ** đầu trang Lịch đặt sân. F5/đọc chi tiết tải dữ liệu từ backend; không lưu dịch vụ giả trong localStorage.

Checklist click/render **chưa thực hiện trực tiếp trên trình duyệt**:

- [ ] Khách hàng/nhân viên mở trang booking: danh mục tải đủ, SV02 Nước suối giá 5.000 và Coca lốc 58.200; phân biệt với SKU legacy giá khác.
- [ ] Chọn SL đơn vị/lốc; preview đúng, Trà đá không có lựa chọn lốc; dữ liệu không hợp lệ được báo lỗi.
- [ ] Tạo booking thử với dịch vụ, xem chi tiết/F5 từ lịch: thấy DAT_TRUOC, quy cách và snapshot đúng tổng API.
- [ ] Admin mở Lịch → Quản lý danh mục dịch vụ; đổi giá/bật tắt, F5 vẫn giữ catalog; dòng đã bán giữ snapshot. Khi test giá phải khôi phục giá phù hợp, không sửa tiền booking legacy.
- [ ] Nhân viên chọn booking thử trong cửa sổ nhận sân hợp lệ, nhận sân và thêm PHAT_SINH với cùng Coca lẻ/lốc; các dòng độc lập, tổng khớp.
- [ ] Sửa/xóa đúng một dòng trong modal, không ảnh hưởng dòng cùng SKU khác; F5 vẫn đúng.
- [ ] Hai trình duyệt thêm/sửa đồng thời: xung đột rõ ràng khi thêm dòng giống hệt; tổng khớp dòng cuối.
- [ ] Trả sân; sửa/xóa không được backend chấp nhận. Khách/kế toán không được mở operations hoặc quản trị catalog.
- [ ] Chỉ dọn booking thử có marker và đã kiểm tra dependency; không thao tác DS01/DS02/DS3b97491a để kiểm thử.

## 12. Technical debt sang 5.1C

- Chưa phát hành/chốt hóa đơn, thanh toán, hủy/hoàn tài chính. Hiện chặn sửa dịch vụ bằng trạng thái nhận/trả và thanh toán hiện có; khi có hóa đơn phải bổ sung kiểm tra trạng thái chốt.
- Booking hủy giữ dòng dịch vụ và snapshot lịch sử; xử lý nghĩa vụ thu/hoàn/cấn trừ dịch vụ phải xác định trong phase tài chính, không tự coi là đã thu tiền.
- Chưa có optimistic version cho UI chỉnh SL; hai lần sửa tuyệt đối dùng giá trị ghi sau, nhưng transaction/trigger bảo đảm tổng nhất quán.
- Catalog legacy còn hoạt động và có thể trùng tên SKU mới; quyết định ngừng SKU cũ là thao tác quản lý catalog, không tự xóa/đổi tên lịch sử.
- Không có kho/tồn kho, đơn vị quy cách tùy ý hoặc SP/function thêm cho mục đích hình thức. Chưa kiểm tra click/render UI trực tiếp.

## 13. Điểm dừng

Không còn lỗi build/JDBC/schema/API/SQL được phát hiện trong phạm vi kiểm chứng. Hoàn thành Phase 5.1B và dừng; không triển khai Phase 5.1C hoặc Phase 6.
