# FINAL FIX 02 — F01 Financial snapshot after checkout

Ngày: 09/10/2026. Phạm vi duy nhất: F01. F02 được giữ nguyên. **Đã sửa; build, regression, HTTP thật và SQL verification PASS. Chưa deploy/restart internal.**

## Root cause thực tế và tái hiện trước patch

Đã đọc FINAL_SYSTEM_AUDIT.md, FINAL_FIX01_F02_REPORT.md và đối chiếu OperationsService, FinanceService, FinanceRepository, ReportRepository, FinanceController.

Trước sửa, `OperationsService.checkOut` cập nhật visit/trạng thái rồi gọi `FinanceService.sync`. `sync` trả về ngay nếu chưa có HoaDon. `sealed` chỉ đọc DaChot của hóa đơn nên booking đã trả sân nhưng thiếu hóa đơn bị coi là chưa chốt. `invoice` áp khuyến mãi trước `ensure`, sửa DatSan.TienGiam/TongTien rồi mới lập hóa đơn. View doanh thu đọc snapshot DatSan, vì vậy doanh thu đã ghi nhận cũng đổi.

Đã chạy hai regression trên code cũ: **2/2 FAIL** — checkout không tạo snapshot hóa đơn; promotion sau checkout trả 200 thay vì 409. Bằng chứng: `run/fix02/red.log`. Không đổi expected để đạt PASS.

## Patch và invariant

Checkout gọi `sealAtCheckout` ngay trong transaction hiện có, sau flush trạng thái/visit. Phương thức yêu cầu transaction đang tồn tại (`Propagation.MANDATORY`), kiểm tra tổng dịch vụ, tái sử dụng `ensure` để tạo duy nhất hóa đơn khi thiếu và đồng bộ/chốt hóa đơn.

- Sau checkout thành công, HoaDon tồn tại và DaChot=true; DonGia/TienSan/TienDichVu/TienGiam/TongTien của booking giữ nguyên. Snapshot dịch vụ vẫn được bảo vệ bởi guard thao tác dịch vụ hiện có.
- Checkout không tạo payment, không đánh dấu giả đã thu tiền. Hóa đơn chưa thu có DaThanhToan=0 và ConLai=TongTien.
- `sealed` còn nhận diện visit đã trả hoặc DatSan trạng thái Đã sử dụng. Booking đã trả trước patch nhưng chưa có hóa đơn cũng không được áp promotion.
- `sync` chốt theo trạng thái/visit; FinanceRepository hiện có giữ tiền hóa đơn khi DaChot=true. Không đổi định nghĩa báo cáo: doanh thu khác tiền thu, tiền hoàn và thực nhận.
- Invoice request không khuyến mãi được phép gọi lại, không tạo hóa đơn thứ hai hay đổi tiền. Với lịch sử chưa có hóa đơn, request này lập hóa đơn từ snapshot cũ và chốt ngay; không tính giá lại, không backfill hàng loạt.
- Payment, pending confirmation và refund giữ flow/authorization/idempotency hiện có; refund tiếp tục dựa actual paid.

## File thay đổi

| File | Nội dung |
|---|---|
| backend/src/main/java/com/sanbong/service/OperationsService.java | Checkout chốt hóa đơn trong cùng transaction; audit ghi chốt snapshot, chưa tự thu tiền |
| backend/src/main/java/com/sanbong/service/FinanceService.java | sealAtCheckout; nhận diện trạng thái/visit đã trả trong sealed và sync |
| backend/src/test/java/com/sanbong/CheckoutSnapshotTest.java | 15 regression F01 |
| docs/FINAL_FIX02_F01_REPORT.md | Báo cáo này |

Không sửa Controller, Repository, report view, schema, UI, pom/dependency, cấu hình environment hoặc F02. So sánh với snapshot Fix01 xác nhận hai service là các file source hiện có duy nhất thay đổi; mọi test cũ giữ nguyên. Script kiểm chứng riêng nằm trong `run/fix02`, không là thành phần runtime.

## Regression, concurrency và rollback

`mvn clean verify`: **181/181 PASS; failures=0, errors=0, skipped=0**. Giữ đủ 166 test baseline + 15 case F01. BUILD SUCCESS lúc 06:11:28; thời gian 3 phút 35 giây. Log: `run/fix02/verify.log`.

15 case mới bao gồm:

1. Checkout chưa hóa đơn tạo snapshot chốt, chưa thu tiền, giữ tổng dịch vụ.
2. Promotion lặp sau checkout trả 409, tiền và doanh thu không đổi.
3. Invoice lặp, input tổng tiền giả, sync, thu sau checkout và payment idempotency không đổi snapshot.
4. Thu trước một phần rồi checkout và thu phần còn lại.
5. Thêm/sửa/xóa dịch vụ sau trả sân và checkout lần hai bị chặn.
6. Năm case cạnh tranh checkout với invoice, promotion, service, payment và checkout khác.
7. Hai case lỗi tạo invoice hoặc ghi audit checkout làm rollback toàn bộ.
8. Pending transfer được kế toán xác nhận sau checkout, lặp confirm không thu hai lần.
9. Hủy booking fixture khác: đã thu 70.000, tỷ lệ hoàn 50%, hoàn 35.000; xác nhận lặp không hoàn hai lần, không đổi doanh thu booking đã dùng.
10. Booking fixture mô phỏng lịch sử đã trả nhưng chưa hóa đơn: promotion 409, invoice không promotion giữ tiền cũ.

Các case concurrency dùng hai session/request và latch, giữ lock thứ tự San → DatSan. Mutation chạy trước checkout có thể hợp lệ; chạy sau phải chịu guard chốt. Invoice/payment vẫn hợp lệ sau checkout. Double checkout chỉ một request thành công, một 409; chỉ một hóa đơn và một visit đã trả.

Hai case fault injection trả 503 và chứng minh trạng thái DatSan, San, thời điểm trả visit và hóa đơn đều rollback; retry sau bỏ lỗi thành công. Không nuốt lỗi để giả checkout thành công.

Integration tests dùng fixture DEV được đánh dấu; visit fixture được thiết lập có kiểm soát như test Finance hiện có, Clock finance riêng phục vụ rule hoàn tiền. Đây không phải bằng chứng luồng nhận sân HTTP thật; luồng đó kiểm tra riêng trên JAR, không mock thời gian hay bypass rule nhận sân.

## JAR và startup

Build trong thư mục tạm để không ghi đè JAR đang chạy. Artifact: `releases/san-bong-fix02-f01-20261009.jar`.

SHA-256: `89EB4F23902702426662240AD17CD526888737A6105AFB4929DA56A90B1134EF`.

JAR mới khởi động trên DEV, loopback:8082; JDBC trực tiếp SQL Server PASS, Hibernate `ddl-auto=validate` PASS, Spring Boot startup PASS. `/api/health` trả `{"database":"UP","status":"UP"}`. Log: `run/fix02/startup.log`. Server internal port8080 vẫn UP, không restart/deploy.

## HTTP và SQL verification

**PASS trên JAR mới lúc 06:30**, với booking ngày 09/10/2026 lúc 07:00–08:00. Đã chờ đúng cửa sổ nhận sân trước tối đa 30 phút, không đổi clock hoặc rule. Luồng tạo booking → xác nhận → nhận sân → trả sân đều qua HTTP thật; không INSERT visit hay sửa dữ liệu để vượt check-in.

Preflight `/admin/test-safety` xác nhận fixtureTestsAllowed=true và đúng database QuanLySanBong marker dev trước tạo fixture. Thực hiện bằng ba session admin/nvsan/ketoan, CSRF hiện có.

| Kiểm chứng HTTP | Kết quả |
|---|---|
| Finance ngay sau checkout | Có invoice, DaChot=true, DaThanhToan=0, chưa hoàn tất tài chính |
| POST invoice với KM02, lặp hai lần | 409; tiền và doanh thu không đổi |
| POST invoice không promotion | 200; giữ mã hóa đơn và tổng tiền |
| Thêm dịch vụ sau trả sân | 409 |
| Checkout lần hai | 409 |
| Kế toán thu 50.000 tiền mặt, lặp cùng key | Thành công, chỉ ghi một giao dịch |
| Kế toán thu 98.200 chuyển khoản | Thành công; hai payment, ConLai=0, hoàn tất tài chính |
| Reload finance/report và đối chiếu SQL | Snapshot và doanh thu không đổi; một hóa đơn |

| Giá trị SQL | Trước request promotion/payment | Sau request promotion/payment |
|---|---:|---:|
| DonGia | 90.000 | 90.000 |
| TienSan | 90.000 | 90.000 |
| TienDichVu | 58.200 | 58.200 |
| TienGiam | 0 | 0 |
| TongTien | **148.200** | **148.200** |
| SUM(DoanhThu), V_Phase6_Revenue | **148.200** | **148.200** |

Revenue API cũng trả 148.200 trước và sau. Tiền thực thu ban đầu 0, sau thanh toán 148.200; không thay định nghĩa doanh thu. Chứng cứ: `run/fix02/http.log`, `http-result.json` và `http-state.json`. Fixture HTTP đã được cleanup bằng script có guard sẵn trên DEV, đúng ID/marker; không giữ booking thử làm doanh thu giả.

## An toàn dữ liệu, migration và giới hạn

Không migration, không thay schema, không reset database, không sửa trực tiếp lịch sử để kết quả PASS. Fixture chỉ chạy trên QuanLySanBong có marker dev; preflight xác nhận API và database đều cho phép fixture. Không fixture, cleanup, booking/invoice/payment write trên QuanLySanBong_Phase7_RestoreTest internal.

Fingerprint toàn bộ TaiKhoan và DatSan internal trước/sau giống nhau; số dòng HoaDon, ThanhToan, HoanTien, ChiTietDichVu và XacNhanSan đều giữ 0. Chứng cứ: `run/fix02/internal-before.txt`, `internal-after.txt`. Không chứa password/hash người dùng trong báo cáo. Server internal vẫn chạy phiên bản cũ; patch chỉ nằm ở source/JAR mới, chưa có hiệu lực trên server đó.

Regression risk: **MEDIUM**. Checkout nay thêm thao tác lập/chốt hóa đơn và audit trong transaction; sai lệch tổng dịch vụ, lỗi constraint/DB/audit sẽ khiến toàn bộ checkout rollback, cần xử lý nguyên nhân và retry. Đây là thay đổi có chủ đích để tránh trạng thái trả sân thành công nhưng thiếu snapshot tài chính. Không sửa lịch sử hàng loạt; invoice lịch sử được lập từ snapshot đã lưu khi có thao tác hợp lệ.

Carry-over nguyên trạng: **F03** booking tương lai khi sân đang dùng; **F04** khách vãng lai tại quầy; **F15** dependency BCrypt; **F16** HTTPS/transport; **F21** canonical env/credential riêng. Fix này không tuyên bố toàn hệ thống production-ready.

Không tự deploy. Sau khi xác nhận báo cáo, chỉ thay JAR theo quy trình vận hành trong cửa sổ bảo trì với environment đã xác nhận; không dùng lại file env có credential stale được ghi nhận tại F21. Không làm F03/F04 hoặc phase khác.
