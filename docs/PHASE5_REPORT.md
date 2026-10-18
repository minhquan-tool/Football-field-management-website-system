# Phase 5 — Nhận sân, dịch vụ và phần tài chính đang dừng

**PARTIAL / AWAITING INVOICE SCHEMA DECISION.** Chưa CODE COMPLETE và chưa COMPLETE Phase 5.
Nhận/trả sân + dịch vụ đã build/test HTTP/SQL. UI còn chờ kiểm tra thủ công vì browser tool
trả `[]`. Hóa đơn/thanh toán/hủy đã thanh toán/hoàn tiền chưa được triển khai.
Không tự chuyển Phase 6. Không đổi tech stack, schema, trigger, seed hoặc dùng SqlProxy.

## A. File tạo mới

Java dưới `backend/src/main/java/com/sanbong/`:

- `dto/CheckInRequest.java`, `dto/ServiceQuantityRequest.java`.
- `repository/OperationsRepository.java`.
- `service/OperationsService.java`, `controller/OperationsController.java`.
- `backend/src/test/java/com/sanbong/OperationsManagementTest.java`, `OperationsConcurrencyTest.java`.
- `frontend/js/operations.js`, `frontend/js/staff-operations.js`.
- `backend/scripts/prepare-phase5-operations-test.sql`, `cleanup-phase5-operations-test.sql`,
  `phase5-operations-http-check.mjs`.
- `database/migrations/Phase5_HoaDon_PROPOSAL.sql` — bản đề xuất, **không thực thi**.
- Báo cáo này.

## B. File chỉnh sửa

- `AGENTS.md`: phạm vi Phase 5, yêu cầu dừng khi cần quyết định schema tài chính.
- `config/SecurityConfig.java`: cổng role cho `/services` và `/operations/**`.
- `repository/BookingWorkflowRepository.java`, `service/BookingService.java`:
  chặn hủy theo Phase 4 khi đã có XacNhanSan.
- `service/PitchService.java`: không đổi sang Trống/Bảo trì khi lượt nhận chưa trả.
- `frontend/Quan_ly_lich_dat_san.html`: modal vận hành cùng kiểu card/màu/CSS hiện có.
- `frontend/js/bookings.js`: nút Nhận sân / Dịch vụ mở modal cho nhân viên/quản lý.
- `frontend/Man_hinh_chinh_NVKH.html`: các card vận hành, số sân/lịch đọc API thật;
  bỏ thao tác nhận sân/dịch vụ mô phỏng. Phản hồi/report còn ngoài phạm vi.
- `frontend/Dat_san_tai_quay.html`, `Man_hinh_chinh_Dat_san_KH.html`:
  cập nhật hướng dẫn dịch vụ sau nhận sân, giữ form booking Phase 4.
- `backend/README.md`: hướng dẫn phần vận hành và giới hạn tài chính.

## C. API

Context path hiện `/api`, có thể cấu hình như Phase 1–4; dùng ApiResponse/session/CSRF hiện có.

| Method | Endpoint | Quyền sau cổng role PITCH_STAFF/ADMIN |
|---|---|---|
| GET | `/services` | CN03_XEM |
| GET | `/operations/bookings/{id}` | CN02_XEM |
| POST | `/operations/bookings/{id}/check-in` | CN02_SUA |
| POST | `/operations/bookings/{id}/check-out` | CN02_SUA |
| POST | `/operations/bookings/{id}/services/{serviceId}` | CN03_THEM |
| PUT | `/operations/bookings/{id}/services/{serviceId}` | CN03_SUA |
| DELETE | `/operations/bookings/{id}/services/{serviceId}` | CN03_XOA |

Check-in body tùy chọn `tinhTrangSan`, `ghiChu` (tối đa 255 ký tự); gửi `{}` nếu không có.
Dịch vụ POST/PUT body `soLuong` integer >0. Giá/thành tiền client gửi thêm bị bỏ qua.
GET detail trả `booking`, `visit`, `services`; tổng là **tiền booking**, không phải hóa đơn đã phát hành.
Giữ 400/401/403/404/409/500/503 hiện có; không trả stack trace cho frontend.
Không có API phát hành hóa đơn/ghi nhận thanh toán/hoàn tiền ở thay đổi này.

## D. Database/schema/trigger thực tế

Chỉ đối chiếu các bảng và UI liên quan Phase 5, không audit lại project.

- `XacNhanSan`: MaXacNhan varchar(10) PK; MaDatSan varchar(10) FK DatSan **UNIQUE**;
  MaNV FK NhanVien; ThoiGianNhan datetime; ThoiGianKetThuc nullable datetime;
  TinhTrangSan/GhiChu nvarchar(255). CHECK kết thúc >= nhận. Có đủ nhận/trả sân.
- `DichVu`: PK MaDV varchar(10); TenDV nvarchar(100), DonViTinh nvarchar(20),
  DonGia decimal(18,2)>0, TrangThai bit. 6 dịch vụ hoạt động: DV01 nước suối 10000,
  DV02 nước ngọt 15000, DV03 thuê bóng 30000, DV04 giày 40000, DV05 bib 50000,
  DV06 khăn lạnh 5000. Đây là dữ liệu SQL, không phải danh sách/giá hard-code frontend.
- `ChiTietDichVu`: PK kép (MaDatSan,MaDV), FK DatSan/DichVu/NhanVien;
  SoLuong int>0, DonGia decimal(18,2)>0 snapshot, NgayGhiNhan datetime,
  **ThanhTien computed PERSISTED = SoLuong*DonGia, decimal(29,2)**.
- `TRG_CapNhatTienDatSan` trên ChiTietDichVu AFTER INSERT/UPDATE/DELETE:
  lấy union MaDatSan trong inserted/deleted, tính lại SUM(ThanhTien), gán
  DatSan.TienDichVu và TongTien=TienSan+SUM−TienGiam. Không cộng dồn từ tổng cũ,
  không đọc lại giá catalog; trigger không cần sửa/xóa.
- `DatSan` tiếp tục giữ snapshot tiền sân/dịch vụ/giảm/tổng decimal(18,2) và 4 trạng thái
  Chờ xác nhận / Đã xác nhận / Đã sử dụng / Đã hủy. Giữ unique index chống trùng Phase 4.
- `ThanhToan` FK trực tiếp DatSan; SoTien decimal(18,2)>0; phương thức Tiền mặt/Chuyển khoản;
  trạng thái Chờ xử lý/Thành công/Thất bại. Chỉ PK MaTT, chưa có unique theo booking/thành công.
- `HuyDatSan`: MaDatSan UNIQUE; TiLeHoan decimal(5,2) 0–100; SoTienHoan decimal(18,2)>=0.
- `HoanTien`: FK ThanhToan và HuyDatSan, MaNV; tiền >0; trạng thái Chờ duyệt/Đã hoàn/Từ chối;
  chưa có unique theo thanh toán/hủy. Các bảng đủ lưu lịch sử hoàn nhưng chưa có policy tự động.
- **Không tồn tại HoaDon/ChiTietHoaDon**. ThanhToan không tham chiếu hóa đơn độc lập.
- NhatKyHeThong và quyền CN02/CN03/CN04 giữ nguyên.

## E. Nhận/trả sân

Check-in yêu cầu booking Đã xác nhận, chưa có XacNhanSan; ngày chơi hôm nay,
từ 30 phút trước giờ bắt đầu đến trước giờ kết thúc theo Asia/Ho_Chi_Minh.
Sân Trống và không còn visit chưa trả. Nhân viên phải liên kết account và đang làm việc.
Ghi XacNhanSan + San→Đang sử dụng + nhật ký cùng transaction.
Không thêm trạng thái booking mới: khi đang nhận, DatSan vẫn Đã xác nhận và có visit mở.

Trả sân đóng ThoiGianKetThuc, DatSan→Đã sử dụng, San→Trống; từ chối lần hai.
Đã sử dụng diễn tả kết thúc sử dụng sân, **không đồng nghĩa đã thanh toán**.
Không tạo ThanhToan hoặc hóa đơn khi trả sân. Trả sân khóa chỉnh dịch vụ sau đó.

## F–G. Dịch vụ và tiền

Chỉ thêm/sửa/xóa dòng khi đã nhận, chưa trả, DatSan Đã xác nhận và không có ThanhToan
Chờ xử lý/Thành công. POST lấy giá DichVu hoạt động, lưu DonGia snapshot vào ChiTietDichVu;
trùng dòng trả 409, dùng PUT sửa số lượng. PUT giữ nguyên DonGia cũ dù catalog đổi giá/trạng thái.
DELETE chỉ quyền CN03_XOA (hiện ADMIN có; PITCH_STAFF không có).

Backend dùng BigDecimal nhân số lượng để kiểm tra giới hạn decimal(18,2) của tổng booking.
Computed column là nguồn thành tiền dòng; trigger là nguồn cập nhật tổng. Java **không ghi/cộng**
TienDichVu/TongTien lần nữa; refresh entity sau DML JDBC để response lấy đúng tiền mới.
Giá/tổng/số lượng sai hoặc làm tổng vượt precision bị từ chối trước ghi dữ liệu.

## H–J. Điểm dừng hóa đơn, thanh toán, hủy/hoàn

Yêu cầu người dùng: “Nếu phát hiện schema hiện tại không đủ để triển khai an toàn một nghiệp vụ
tài chính: DỪNG phần đó” và đưa vấn đề/schema/rủi ro/thay đổi/migration trước.

Vấn đề: DatSan giữ tổng booking và ChiTietDichVu có snapshot, nhưng chưa có bản ghi riêng cho
**thời điểm phát hành, người lập, trạng thái và số tiền chốt hóa đơn**. Một view/read response trên
DatSan có thể làm phiếu tạm tính; nó không tự tạo một hóa đơn cuối cùng độc lập. Dùng trạng thái
Đã sử dụng hoặc ThoiGianKetThuc để thay luôn trạng thái hóa đơn sẽ gộp hoàn tất sử dụng sân và
vòng đời tài chính. Dùng nhật ký làm nơi lưu hóa đơn sẽ biến audit thành nguồn tài chính thứ hai.
Các cách đó chưa được chọn/áp dụng. Không thêm hóa đơn trong bộ nhớ hoặc báo phát hành giả.

Đề xuất để xem xét: **một bảng HoaDon** có MaHoaDon PK, MaDatSan UNIQUE, FK khách/nhân viên lập,
NgayLap, snapshot TienSan/TienDichVu/TienGiam/TongTien và trạng thái hóa đơn riêng.
File `database/migrations/Phase5_HoaDon_PROPOSAL.sql` cụ thể hóa DDL; có guard mặc định từ chối
thực thi. Chỉ tạo bảng rỗng, không backfill hóa đơn suy đoán, không DROP, không đổi trigger/tables cũ.
ThanhToan vẫn liên kết MaDatSan; service tương lai dùng cùng khóa booking + invoice.

**Migration chưa chạy.** Không tự coi script này đã được phê duyệt. Nếu chọn tiếp tục dùng DatSan
thay cho hóa đơn độc lập, cần thống nhất rõ rằng đó là phiếu thanh toán nội bộ và quy tắc chốt/
đóng băng/thời điểm phát hành; không âm thầm coi projection hiện tại là hóa đơn cuối cùng.

Sau quyết định hóa đơn còn cần chốt chính sách thanh toán toàn bộ một lần hay trả nhiều lần,
điều kiện/tỷ lệ hoàn và quyền duyệt. Schema cho lưu nhiều ThanhToan không tự chứng minh workflow
partial payment; UI cọc/80% cũ là mô phỏng, không lấy làm policy thật. Không tự chọn 80% hoặc
tuyên bố chuyển tiền ngân hàng. Hoàn tiền sau này là ghi nhận xử lý nội bộ nếu không có gateway.

Hủy booking chưa nhận/chưa thanh toán tiếp tục API Phase 4. Đã nhận hoặc có tiền vẫn bị chặn;
không chỉ đổi Đã hủy rồi bỏ qua tiền. Các workflow tài chính chưa CODE COMPLETE.

## K–N. Quyền, transaction và chống trùng

CN02: check-in/out dùng SUA; CN03: catalog XEM, thêm THEM, sửa SUA, xóa XOA;
backend bắt buộc PITCH_STAFF/ADMIN trước method permission. CUSTOMER/ACCOUNTANT không được
ghi thao tác vận hành ở thay đổi này. Không thêm/sửa role hoặc PhanQuyen.

Đọc booking, khóa **San trước DatSan**, refresh sau khóa; cùng thứ tự Phase 4 để phối hợp
bảo trì/hủy/booking. READ_COMMITTED; XacNhanSan UNIQUE MaDatSan và ChiTietDichVu PK kép
bảo vệ cuối cùng. Transaction bao gồm DML dịch vụ, trigger, visit, trạng thái và NhatKyHeThong.
Audit lỗi sau flush làm rollback cả visit/status hoặc line/tổng do trigger.
SLF4J chỉ ghi action/booking/account ID; không ghi credential/token/secret.

Chống duplicate invoice/double payment **chưa implement, chưa test**, không suy ra từ test nhận sân.
Đề xuất UNIQUE HoaDon.MaDatSan và khóa invoice/booking cho phát hành/ghi tiền; cần triển khai
và chạy concurrency thanh toán thật sau quyết định schema. HoanTien cũng cần kiểm tra/khóa trước ghi
để không hoàn lặp; chưa có endpoint tài chính mới.

## O–P. Concurrency và test

`clean verify`: **58 tests, 0 failures, 0 errors, BUILD SUCCESS**.
37 regression Phase 1–4 + 17 OperationsManagementTest + 4 OperationsConcurrencyTest.
Spring Boot/JDBC/validate startup PASS; JAR đang chạy localhost:8080/api, không mở LAN.

| Nhóm yêu cầu Phase 5 | Kết quả |
|---|---|
| 1–5 nhận hợp lệ/missing/hủy/lặp/thiếu quyền | PASS |
| 6–12 catalog/add/qty/missing/inactive/thành tiền/snapshot | PASS |
| 13–16 hóa đơn và duplicate invoice | BLOCKED, chưa implement/test |
| 17–23 thanh toán/double/concurrency/rollback tài chính | BLOCKED, chưa implement/test |
| 24 hủy chưa thanh toán | Regression Phase 4 PASS; thêm chặn đã nhận |
| 25–28 hủy đã trả tiền/rule hoàn/double refund/quyền hoàn | BLOCKED, chưa implement/test |
| 29 transition | Vận hành PASS; tài chính chưa implement |
| 30 SQL lưu đúng | Vận hành PASS; chưa ghi hóa đơn/thanh toán/hoàn |
| 31 trigger không cộng hai lần | PASS, thêm/sửa/xóa và rollback |
| 32 orphan/test residual | PASS cleanup, FK giữ nguyên |
| 33–34 giữ lịch sử/Phase 1–4 | Regression PASS; không sửa schema/giá booking cũ |
| Browser click/render/F5 | PENDING, không có browser tool |

Test transaction độc lập: hai check-in 200+409, đúng một visit; hai add cùng dịch vụ 200+409,
tổng chỉ ghi một dòng; audit check-in lỗi rollback visit và San; audit add lỗi rollback dòng
và tổng trigger. Test thêm thời gian nhận sai, trả lặp, khóa chỉnh sau trả/đã có tiền,
tràn tiền, thiếu CSRF, thu hồi permission và chặn bypass ở API sân/hủy Phase 4.

Lần test đầu thất bại do fixture dùng giờ sát nửa đêm phần lẻ giây; chuyển fixture sang
23:59:59 giây nguyên rồi chạy lại ca check-in và toàn suite đều PASS. Không sửa khung giờ thật
hoặc nới kiểm tra thời gian để làm test pass.

HTTP thật hai session admin trên fixture riêng `P5HD3D7C5`:
check-in race 200/409; add DV01 SL2 race 200/409 → 170000;
sửa SL3 → 180000; thêm DV03 SL1 → 210000; xóa DV03 → 180000;
trả sân → Đã sử dụng/San Trống; fresh GET thấy đúng snapshot; sửa sau trả 409.
SQL trực tiếp: một visit NV01 có nhận/kết thúc; một dòng DV01 SL3, DonGia10000,
ThanhTien30000; TienSan150000+TienDichVu30000=TongTien180000; 6 audit; 0 ThanhToan.
Không test ghi nhận thanh toán/hoàn tiền qua HTTP vì phần đó chưa được triển khai.

## Q. Fixture/cleanup và dữ liệu hiện tại

Integration dùng rollback hoặc fixture ID/marker riêng và cleanup trong transaction.
HTTP fixture dùng sân + slot + booking riêng cùng ID P5Hxxxxxx, khung giờ cả ngày là
**dữ liệu test**, không phải giá/slot nghiệp vụ mới. Prepare/cleanup có guard ID/marker,
SET options đúng filtered index, không chạm bảng giá hoặc booking hiện có.
Đã dọn chính xác dòng dịch vụ, visit, 6 audit, booking/sân/slot thử; residual ID/audit=0.

Sau test SQL: **7 sân, 3 booking, 11 giá sân, 5 slot, 6 dịch vụ; 0 chi tiết dịch vụ,
0 visit, 0 payment, 0 refund**. DS01/DS02 vẫn ngày 2026-10-01, giá/tổng
250000/230000 và 300000/300000. Booking `DS3b97491a` ngày 2026-10-16, tổng200000,
Chờ xác nhận là dữ liệu hiện có của người dùng, không thuộc fixture và được giữ lại.
Giữ login/logout journal. Bảng HoaDon vẫn không tồn tại, chứng minh proposal chưa áp dụng.
Log: `backend/target/phase5-build.log`, `phase5-startup.log`, `surefire-reports/` (không commit target).

## R. Checklist UI phần vận hành — còn chờ

Chưa có checklist hóa đơn/payment/refund hoạt động vì các endpoint đó chưa được tạo;
không yêu cầu người dùng thử nút mô phỏng ở dashboard kế toán.
Password dùng thông tin mẫu đã cung cấp, không lặp lại ở đây.

1. Đăng nhập `nvsan` tại http://127.0.0.1:8080/api/Dang_nhap.html.
2. Tại http://127.0.0.1:8080/api/Dat_san_tai_quay.html, tra khách `0987654321`,
   chọn **2026-10-05, S04, KG01 06:00–07:30**, giá150000; ghi chú `Phase5 manual operations test`.
   Chỉ tạo nếu slot chưa có booking; không sửa/hủy booking người khác. Ghi mã DS mới.
3. Mở http://127.0.0.1:8080/api/Quan_ly_lich_dat_san.html?date=2026-10-05&pitch=S04,
   xác nhận đúng mã DS test. **Nhận sân phải thử trong 05:30–trước07:30 ngày 2026-10-05**;
   ngoài cửa sổ này mong đợi 409 (không sửa giờ hệ thống hoặc booking cũ để bỏ kiểm tra).
4. Bấm **Nhận sân / Dịch vụ → Nhận sân**. Mong đợi visit mở/San Đang sử dụng;
   F5, mở lại modal: vẫn Đã nhận sân; nút nhận lại bị khóa, API nhận lại trả409.
5. Chọn **DV01 Nước suối**, SL**2**, **Thêm dịch vụ**: giá snapshot10000, thành tiền20000,
   tổng booking170000. Sửa SL**3**, **Lưu SL**: thành tiền30000, tổng180000; F5 giữ đúng.
6. Thêm **DV03 Thuê bóng**, SL**1**, giá30000: tổng210000. Nvsan không có nút Xóa.
   Nếu cần thử xóa, đăng nhập **admin**, mở đúng booking test và bấm **Xóa** dòng DV03:
   tổng trở về180000. Chỉ thao tác trên mã DS thử đã ghi lại.
7. Bấm **Trả sân (chưa thanh toán)**, xác nhận: visit có giờ kết thúc, DatSan Đã sử dụng,
   San Trống, tổng180000; F5 vẫn đúng. Sửa dịch vụ/nhận/trả lần nữa bị từ chối.
   Không coi số tiền này là hóa đơn phát hành hoặc khoản tiền đã thu.
8. Báo mã DS và PASS/FAIL từng bước. Booking manual test giữ lịch sử, không xóa bằng API.

Nếu thử sau 2026-10-05, dùng ngày Thứ Hai tương lai còn giá/slot nhưng cần xác nhận ngày mới
trước khi check-in; chưa được nới cửa sổ nhận sân. Fixture HTTP đã dọn, không dùng ID đó để test UI.

## S. Technical debt / quyết định còn cần

- Quyết định HoaDon độc lập (proposal) hay phiếu nội bộ chốt trên DatSan; chọn rõ trước tài chính.
- Policy thanh toán và hoàn tiền chưa có nguồn chuẩn; không dùng con số mô phỏng làm rule.
- Dòng dịch vụ một giá/booking/DV do PK kép; sửa SL giữ giá đầu, không tạo nhiều giá cho cùng DV.
- Check-in sớm tối đa30 phút là quy tắc vận hành hiện code; nếu chủ sân cần khác phải thống nhất,
  không tự bỏ kiểm tra ngày/giờ để tiện test.
- Hóa đơn phát hành sau này cần thêm guard vào service/discount để đóng băng khoản đã chốt.
- Dashboard kế toán vẫn ngoài phần đã làm, chưa có ledger/invoice thật; các nút demo vẫn bị Phase 2 chặn.
- Chưa xác minh giao diện bằng trình duyệt; một số tên khách legacy SQL còn lỗi encoding,
  không tự sửa dữ liệu cá nhân trong phase này.

## T. Phần tiếp theo

Trước hết hoàn thành **phần tài chính còn thiếu của Phase 5** sau quyết định schema/policy,
chạy đủ invoice/payment/refund và concurrency/rollback tests rồi cung cấp checklist UI đầy đủ.
Không gọi đó là Phase 6. Phase 6 chỉ xét sau khi Phase 5 được kiểm tra và người dùng giao tiếp:
nhân viên/dashboard/báo cáo nâng cao; chưa deployment LAN.
