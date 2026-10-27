# Bộ File SQL Cơ Sở Dữ Liệu QuanLySanBong - Final

Thư mục này chứa toàn bộ các file SQL được xuất hoàn chỉnh, chuẩn hóa và kiểm thử từ cơ sở dữ liệu **QuanLySanBong** chạy trên Microsoft SQL Server (FC UTE Football Management System).

---

## 1. Cấu Trúc Thư Mục

```
database/final/
├── 00_full_database.sql             (Master script: chạy 1 lần là có đầy đủ cấu trúc và dữ liệu)
├── 01_tables_and_constraints.sql    (Tạo CSDL, 28 bảng, khóa chính, khóa ngoại, ràng buộc CHECK, DEFAULT)
├── 02_views.sql                     (9 View báo cáo, thống kê và tra cứu lịch sân)
├── 03_functions.sql                 (6 Hàm người dùng: tính hoàn tiền, doanh thu thực nhận, tra cứu khung giờ trống)
├── 04_stored_procedures.sql         (5 Thủ tục lưu trữ báo cáo tài chính, công suất, phương thức thanh toán)
├── 05_triggers.sql                  (5 Trigger nghiệp vụ tự động hóa và bảo vệ snapshot bất biến)
├── 06_seed_data.sql                 (Dữ liệu chuẩn ban đầu & lịch sử giao dịch vận hành hệ thống)
├── 08_indexes.sql                   (Chỉ mục riêng: unique index, filtered index)
├── 09_transactions_demo.sql         (Demo transaction riêng trên DB fixture dev/test, không thuộc bước cài đặt)
├── README.md                        (Tài liệu hướng dẫn sử dụng và danh mục đối tượng)
└── modules/                         (Các file SQL lẻ từng đối tượng để đọc, đối chiếu hoặc chấm điểm bảo vệ)
    ├── indexes/                     (9 index độc lập, chia theo 5 bảng)
    ├── functions/                   (6 file hàm lẻ)
    ├── procedures/                  (5 file thủ tục báo cáo lẻ)
    ├── tables/                      (28 file bảng lẻ)
    ├── triggers/                    (5 file trigger lẻ)
    └── views/                       (9 file view lẻ)
```

---

## 2. Hướng Dẫn Sử Dụng Trong SSMS (SQL Server Management Studio)

### Cách 1: Chạy toàn bộ trong 1 click (Khuyến nghị khi dựng máy mới)
1. Mở **SQL Server Management Studio (SSMS)** và kết nối tới SQL Server của bạn.
2. Mở file **`00_full_database.sql`**.
3. Nhấn **Execute (F5)**.
4. Toàn bộ cơ sở dữ liệu `QuanLySanBong`, cấu trúc bảng, khóa, chỉ mục, view, hàm, thủ tục, trigger và dữ liệu sẽ được tạo hoàn chỉnh.

### Cách 2: Chạy theo từng phần có thứ tự (Khi cần kiểm soát từng bước)
Thực hiện tuần tự các file theo đúng thứ tự sau:
1. **`01_tables_and_constraints.sql`**: Tạo Database và 28 bảng cùng các ràng buộc.
   Sau đó chạy **08_indexes.sql** trước các bước tiếp theo để tạo chỉ mục.
2. **`03_functions.sql`**: Tạo các hàm tính toán (các View sau này cần gọi hàm).
3. **`02_views.sql`**: Tạo các View thống kê và tra cứu.
4. **`04_stored_procedures.sql`**: Tạo các Stored Procedure báo cáo quản trị.
5. **`05_triggers.sql`**: Tạo các Trigger bảo vệ toàn vẹn và tính tiền.
6. **`06_seed_data.sql`**: Nạp dữ liệu vận hành.

---

Chạy `00_full_database.sql` **hoặc** bộ file thành phần; không chạy cả hai. `modules/indexes/` là bản chia nhỏ để đọc/đối chiếu, không chạy thêm sau `08_indexes.sql`. PRIMARY KEY và 6 UNIQUE CONSTRAINT thuộc phần bảng. File index chỉ tạo mục chưa có, không DROP/rebuild index hiện hữu; không dùng bộ export này làm migration sửa schema.

### Demo transaction chạy riêng trong SSMS

`09_transactions_demo.sql` tái sử dụng script `../report-demo/02_Fixture_and_Five_Transactions.sql`. File không được ghép vào `00_full_database.sql` và không thuộc thứ tự dựng database ở trên. Transaction nghiệp vụ ứng dụng vẫn do `@Transactional` tại tầng Service quản lý.

1. Chuẩn bị bản sao theo `../report-demo/README.md`; chọn DB `QuanLySanBong_Fixtures_*` có marker `SanBongFixtureDatabase=1` và `SanBongEnvironment=dev/test`. Không gắn marker vào DB vận hành để vượt chặn.
2. Chạy `../report-demo/01_Preflight.sql` theo hướng dẫn của file đó.
3. Mở `09_transactions_demo.sql`, đổi `@EnableDemo bit=0` thành `1`, chạy cả file bằng F5; không cần SQLCMD Mode.
4. Mong đợi 5 `COMMIT_PASS` và 5 `ROLLBACK_PASS`: đặt sân; thêm/sửa dịch vụ; trả sân/chốt hóa đơn; thu tiền; hủy/hoàn tiền. COMMIT giữ dữ liệu tổng hợp để xem, mỗi lần chạy lại tạo thêm bản ghi. ROLLBACK kiểm tra không còn dữ liệu dở dang của ca lỗi.
5. Sau khi chạy, `SELECT @@TRANCOUNT AS OpenTransactions, XACT_STATE() AS TransactionState;` phải trả `0, 0`. Nếu gặp lỗi ngoài dự kiến, dừng và kiểm tra, không coi là PASS.

Đây là demo T-SQL, không thay thế đầy đủ validation, phân quyền hoặc idempotency của API. Kiểm thử khóa đồng thời dùng hai file `../report-demo/70A_Concurrency_Window_A.sql` và `../report-demo/70B_Concurrency_Window_B.sql`; demo COMMIT/ROLLBACK này chưa chứng minh đồng thời qua API. File mới được đưa vào bộ final từ script demo hiện có; việc sao chép không đồng nghĩa đã chạy kiểm thử trên SQL Server.

## 3. Danh Mục Chi Tiết Các Đối Tượng CSDL

### 3.1. Danh mục 28 Bảng dữ liệu (Tables)
| STT | Tên bảng | Nhóm chức năng | Mô tả tóm tắt |
|:---:|:---|:---|:---|
| 1 | `VaiTro` | Phân quyền | Danh mục vai trò: Quản trị viên, Nhân viên sân, Kế toán, Khách hàng |
| 2 | `ChucNang` | Phân quyền | Danh mục quyền/chức năng nghiệp vụ trong hệ thống |
| 3 | `PhanQuyen` | Phân quyền | Ma trận phân quyền chi tiết (Xem, Thêm, Sửa, Xóa) cho từng vai trò |
| 4 | `TaiKhoan` | Người dùng | Tài khoản đăng nhập hệ thống, mật khẩu hash BCrypt |
| 5 | `NhanVien` | Nhân sự | Hồ sơ nhân viên, bộ phận, chức vụ |
| 6 | `KhachHang` | Khách hàng | Thông tin khách hàng, số điện thoại định danh |
| 7 | `LoaiSan` | Quản lý sân | Loại sân (Sân 5 người, Sân 7 người) |
| 8 | `San` | Quản lý sân | Danh sách sân bóng cụ thể, trạng thái vận hành |
| 9 | `KhungGio` | Khung giờ | Khung giờ cố định theo ca |
| 10 | `GiaTheoCa` | Giá giờ tự do | Bảng giá theo ca sáng/chiều/tối phục vụ đặt giờ linh hoạt (Phase 5.1A) |
| 11 | `BangGia` | Bảng giá cố định | Bảng giá theo khung giờ cố định và loại ngày |
| 12 | `KhuyenMai` | Khuyến mãi | Danh mục mã giảm giá, voucher theo số tiền hoặc phần trăm |
| 13 | `DatSan` | Đặt sân | Phiếu đặt sân trọng tâm, hỗ trợ cả giờ khung và giờ tự do, cột tính toán PERSISTED |
| 14 | `XacNhanSan` | Vận hành sân | Ghi nhận nhận sân, trả sân và tình trạng sân thực tế |
| 15 | `DichVu` | Dịch vụ | Danh mục dịch vụ nước uống, thuê bóng, giày, áo tập |
| 16 | `ChiTietDichVu` | Dịch vụ | Chi tiết dịch vụ sử dụng theo phiếu đặt sân, quy cách Đơn vị / Lốc 6 giảm 3% |
| 17 | `HoaDon` | Tài chính | Hóa đơn thanh toán, đóng băng snapshot tiền khi chốt trả sân |
| 18 | `ThanhToan` | Tài chính | Lịch sử các lần thanh toán (Tiền mặt / Chuyển khoản), bất biến |
| 19 | `HuyDatSan` | Hủy sân | Phiếu hủy đặt sân, tính tiền phạt và tiền hoàn theo quy định 10h/2h |
| 20 | `HoanTien` | Tài chính | Bản ghi hoàn trả tiền cho khách hàng khi hủy hoặc điều chỉnh |
| 21 | `YeuCauHuyDatSan` | Quy trình hủy | Quy trình khách gửi yêu cầu hủy và nhân viên/quản lý duyệt |
| 22 | `DanhGia` | Phản hồi | Khách hàng đánh giá chất lượng dịch vụ sau khi sử dụng sân |
| 23 | `TieuChiDanhGia` | Phản hồi | Tiêu chí đánh giá chất lượng (Mặt cỏ, Ánh sáng, Phục vụ, Vệ sinh,...) |
| 24 | `ChiTietDanhGia` | Phản hồi | Điểm chi tiết cho từng tiêu chí |
| 25 | `PhanHoi` | Phản hồi | Nhân viên/Quản lý phản hồi ý kiến đánh giá của khách hàng |
| 26 | `BaoCao` | Quản trị | Lưu trữ metadata các kỳ báo cáo định kỳ |
| 27 | `SaoLuu` | Hệ thống | Lịch sử sao lưu và phục hồi cơ sở dữ liệu |
| 28 | `NhatKyHeThong` | Bảo mật | Audit log bất biến, ghi nhận mọi thao tác đăng nhập, sửa đổi dữ liệu |

---

### 3.2. Danh mục 9 Khung nhìn (Views)
1. **`V_DoanhThuPhatSinhTheoNgay`**: Doanh thu ghi nhận tại thời điểm trả sân theo ngày.
2. **`V_DoanhThuTheoNgay`**: Tổng doanh thu từ các hóa đơn đã hoàn tất thanh toán theo ngày.
3. **`V_KhungGioTrong`**: Danh sách các khung giờ trống của từng sân phục vụ tìm kiếm nhanh.
4. **`V_Phase6_Revenue`**: Tổng hợp doanh thu chi tiết tiền sân, tiền dịch vụ, tiền giảm giá.
5. **`V_Phase6_UsageBooking`**: Thống kê số lượt đặt sân và tổng số giờ chơi.
6. **`V_ThuChiThucNhan`**: Báo cáo dòng tiền thực nhận (Tổng tiền thu từ thanh toán trừ tổng tiền hoàn trả).
7. **`V_ThuTienTheoNgay`**: Tổng tiền thực thu tiền mặt và chuyển khoản theo ngày.
8. **`V_TyLeLapDay`**: Tỷ lệ lấp đầy khung giờ của các sân bóng theo ngày.
9. **`V_TyLeSuDungTheoNgay`**: Tỷ lệ sử dụng thời gian sân thực tế theo ngày.

---

### 3.3. Danh mục 6 Hàm (User-Defined Functions)
1. **`fn_TyLeHoan(@BatDau, @Huy)`**: Trả về tỷ lệ hoàn tiền hủy sân (100% nếu hủy trước >= 10h, 50% nếu trước >= 2h, 0% nếu sát giờ).
2. **`fn_BookingNetCash(@MaDatSan)`**: Tính số tiền thực nhận của 1 phiếu đặt sân (Thực thu trừ Tiền đã hoàn).
3. **`fn_BookingReceipts(@MaDatSan)`**: Tính tổng số tiền đã thu thành công của 1 phiếu đặt sân.
4. **`fn_BookingRefunds(@MaDatSan)`**: Tính tổng số tiền đã hoàn trả của 1 phiếu đặt sân.
5. **`fn_KhungGioTrongTheoNgay(@NgayChoi)`**: Trả về bảng các khung giờ còn trống trong ngày cụ thể cho từng sân.
6. **`fn_ReportDays(@TuNgay, @DenNgay)`**: Sinh chuỗi ngày liên tục trong khoảng thời gian báo cáo.

---

### 3.4. Danh mục 5 Thủ tục lưu trữ báo cáo (Stored Procedures)
1. **`usp_ReportFinance`**: Báo cáo tài chính doanh thu phát sinh và đối chiếu thực nhận trong kỳ.
2. **`usp_ReportPaymentMethods`**: Phân tích cơ cấu thanh toán Tiền mặt vs Chuyển khoản ngân hàng.
3. **`usp_ReportReconciliation`**: Báo cáo đối soát công nợ hóa đơn (đã thanh toán đủ, thanh toán 1 phần, chưa thanh toán).
4. **`usp_ReportTopServices`**: Thống kê các dịch vụ có lượt tiêu thụ và doanh thu cao nhất.
5. **`usp_ReportUsage`**: Báo cáo chi tiết công suất hoạt động, số giờ sử dụng và tỷ lệ sử dụng sân.

---

### 3.5. Danh mục 5 Triggers bảo vệ toàn vẹn
1. **`TRG_AuditContentImmutable`**: Bắt buộc nhật ký hệ thống `NhatKyHeThong` là chỉ ghi thêm (append-only), chống sửa đổi nội dung.
2. **`TRG_CapNhatTienDatSan`**: Tự động tính tổng tiền dịch vụ `ChiTietDichVu` cập nhật vào `DatSan.TienDichVu`.
3. **`TRG_SealedInvoiceSnapshot`**: Khóa bất biến số tiền và thông tin hóa đơn khi đã chốt (`DaChot = 1`).
4. **`TRG_ServicePriceSnapshot`**: Bảo vệ snapshot đơn giá dịch vụ sau khi nạp, chỉ cho phép cập nhật số lượng trước khi chốt hóa đơn.
5. **`TRG_SuccessfulPaymentSnapshot`**: Bảo vệ giao dịch thanh toán thành công là bất biến, nghiêm cấm sửa số tiền đã thu.

---

## 4. Ghi Chú Kỹ Thuật
- Bộ script được thiết kế tương thích hoàn toàn với Microsoft SQL Server 2016, 2017, 2019, 2022 và Azure SQL Database.
- Mọi câu lệnh tạo view, hàm, thủ tục và trigger đều dùng cú pháp chuẩn hiện đại `CREATE OR ALTER`.
- Bảng mã UTF-8 có BOM đảm bảo tiếng Việt dấu không bị lỗi font khi mở trên bất kỳ môi trường nào.
