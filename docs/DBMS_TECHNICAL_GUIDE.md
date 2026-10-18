> Trạng thái mới nhất về chuẩn hóa, view và backup: [nghiệm thu 18/10/2026](DBMS_NORMALIZATION_VIEWS_BACKUP_2026-10-18.md). Các mục lịch sử phía dưới phải đọc cùng cập nhật này.

# Hướng dẫn kỹ thuật DBMS của đồ án sân bóng

Tài liệu vận hành và giải thích code, không phải báo cáo cuối kỳ hay slide. ERD và từ điển cột lấy từ metadata thực tế tại [DBMS_SCHEMA_DICTIONARY.md](DBMS_SCHEMA_DICTIONARY.md). Không dùng số test để quy đổi thành điểm rubric.

## Đối tượng SQL và tích hợp web

| Procedure | Luồng sử dụng | Function/view được tái sử dụng |
|---|---|---|
| usp_ReportUsage | `/reports/usage`, dashboard quản trị | fn_ReportDays, V_Phase6_UsageBooking |
| usp_ReportFinance | `/reports/finance`, dashboard | fn_ReportDays, V_Phase6_Revenue, V_ThuChiThucNhan |
| usp_ReportPaymentMethods | Phân bố phương thức trong báo cáo tài chính | V_ThuChiThucNhan |
| usp_ReportReconciliation | `/reports/reconciliation` | fn_BookingReceipts, fn_BookingRefunds, fn_BookingNetCash |
| usp_ReportTopServices | Top dịch vụ trong dashboard | V_Phase6_Revenue |

Repository gọi bằng JdbcTemplate với tham số bind `EXEC dbo.usp_... ?,?,?`; không ghép input vào SQL. Các SP dùng SET NOCOUNT ON, validation và TRY/CATCH/THROW, trả đúng alias và kiểu dữ liệu trước đây. Chúng chỉ đọc nên không mở transaction ghi hoặc COMMIT transaction của Spring. Controller/Service vẫn kiểm tra role, permission, ngày và ownership khi cần. SP báo cáo tổng hợp chỉ dành cho quyền nghiệp vụ tương ứng; khách không có quyền gọi API tài chính.

Bốn TVF mới được dùng thật trong SP. fn_TyLeHoan vẫn phục vụ hủy/hoàn từ FinanceRepository. fn_diagramobjects/sp_*diagram thuộc tiện ích SSMS và không được tính vào kết quả nghiệp vụ.

## Hợp đồng view (cập nhật 18/10/2026)

| View | Ý nghĩa đúng | Phạm vi |
|---|---|---|
| V_Phase6_UsageBooking | Phút đặt trong 07–22h, loại phút của booking hủy; cờ đã sử dụng | Báo cáo công suất hiện hành; không có lịch sử bảo trì/ngừng sân nên mẫu số là danh mục hiện tại |
| V_Phase6_Revenue | Doanh thu tại ngày trả sân, ưu tiên snapshot hóa đơn | Không phải tiền ngân hàng đã nhận |
| V_ThuChiThucNhan | Thu thành công và hoàn đã xác nhận với dấu âm | Nguồn đối soát tiền nội bộ, không phải đối soát sao kê ngân hàng |
| V_DoanhThuTheoNgay | Tổng **thu thành công gộp** theo ngày và phương thức | Tên legacy; chưa trừ hoàn, không dùng thay doanh thu phát sinh hoặc thực nhận ròng |
| V_KhungGioTrong | Khung trống hôm nay theo múi giờ Việt Nam, loại overlap và bảo trì, trong 07–22h | Giữ 6 cột đầu, thêm NgayChoi. Ngày tùy chọn dùng fn_KhungGioTrongTheoNgay(@Ngay); đọc không giữ chỗ |
| V_TyLeLapDay | Tỷ lệ phút đặt / (900 phút × số sân hiện tại) | Giữ cột cũ, thêm PhutDat/PhutCongSuat. TongKhungGio chỉ còn thông tin legacy, không phải mẫu số tỷ lệ |
| V_TyLeSuDungTheoNgay | Số lượt, phút đặt, công suất phút và tỷ lệ | Cùng quy ước công suất lý thuyết với usp_ReportUsage; không có lịch sử bảo trì |
| V_ThuTienTheoNgay | Tiền thu thành công gộp trước hoàn | V_DoanhThuTheoNgay là alias tương thích của view này |
| V_DoanhThuPhatSinhTheoNgay | Tổng doanh thu theo ngày trả sân | Nguồn V_Phase6_Revenue, khác tiền thu và tiền ròng |

Migration LegacyViewContracts_20261018.sql đã được kiểm thử và áp dụng. Ba view legacy có extended property SanBongContract mô tả hợp đồng. API web vẫn dùng khóa San → DatSan khi đặt sân; kết quả view đọc có thể đổi trước khi người dùng xác nhận. Không coi view tiền thu là doanh thu ròng.

## Trigger và bất biến

- TRG_CapNhatTienDatSan: nguồn duy nhất cập nhật TienDichVu từ ChiTietDichVu. TongTien là computed persisted, trigger không ghi trực tiếp nữa.
- TRG_ServicePriceSnapshot: UPDATE không được đổi SKU, booking, đơn giá, quy cách, nguồn hoặc giá snapshot; sửa số lượng hợp lệ vẫn hoạt động trước khi chốt theo service backend.
- TRG_SuccessfulPaymentSnapshot: không sửa nội dung một giao dịch đã thành công. Thu sai cần nghiệp vụ hoàn được cấp quyền, không sửa số thu cũ. Chờ xử lý → Thành công/Thất bại vẫn hợp lệ.
- TRG_SealedInvoiceSnapshot: không đổi danh tính, người lập, ngày lập, tiền và cờ chốt sau khi đã chốt. Cho phép đồng bộ tiền đã thu/trạng thái theo nghiệp vụ, không tính lại giá.
- TRG_AuditContentImmutable: chặn UPDATE thay đổi nội dung nhật ký; INSERT và no-op không bị chặn. Runtime còn có DENY UPDATE/DELETE; trigger không thay quyền và không cấp quyền DELETE.

Bốn trigger bổ sung xử lý theo tập inserted/deleted, dùng EXCEPT để so sánh NULL đúng. Kiểm thử có nhiều dòng và SQL error number; không chỉ kiểm tra một UPDATE không chạm dòng nào. Không có trigger tự chuyển tiền ngân hàng. SQL DBA vẫn có khả năng thay đổi/disable DDL; đây không phải kho nhật ký chống DBA tuyệt đối.

## Ma trận thao tác dữ liệu của web

| Đối tượng | Thêm / đọc / sửa hiện có | Xóa hoặc kết thúc vòng đời |
|---|---|---|
| Sân | POST/GET `/pitches`, PUT `/pitches/{id}`, PATCH status | Chuyển Bảo trì theo nghiệp vụ; không DELETE sân có lịch sử |
| Dịch vụ danh mục | POST/GET `/service-catalog`, PUT `/service-catalog/{id}` | Ngừng kinh doanh bằng trạng thái, giữ SKU cũ |
| Dòng dịch vụ booking | POST `/operations/bookings/{id}/services/{serviceId}`, đọc chi tiết; PUT service-lines | DELETE `/operations/bookings/{id}/service-lines/{line}` có quyền/trạng thái phù hợp; đây là xóa dòng thật trước khi chốt |
| Nhân viên | POST/GET `/admin/employees`, PUT `/admin/employees/{id}` | Ngừng hoạt động, chặn quyền/phiên liên quan; không xóa lịch sử tác nghiệp |
| Tài khoản | Đăng ký khách, POST/PUT admin accounts, GET `/security/accounts` | Khóa/mở; không xóa khoản thu/booking khi khóa tài khoản |
| Đặt sân | POST/GET `/bookings`, chi tiết, xác nhận, nhận/trả sân | Hủy có chính sách, không DELETE booking; đổi lịch không nằm trong bổ sung này |
| Hóa đơn/thu/hoàn | Lập/đọc, thu nhiều lần, xác nhận khoản chờ, hoàn | Không xóa/sửa khoản đã thu hoặc giá hóa đơn đã chốt; dùng nghiệp vụ hủy/hoàn |

Không đồng nhất chuyển trạng thái với SQL DELETE khi trình bày CRUD. Web có xóa dòng dịch vụ hợp lệ; nhiều thực thể chính dùng vòng đời bảo toàn lịch sử thay vì xóa vật lý. Nếu giảng viên bắt buộc nút DELETE cho từng danh mục, đó là yêu cầu cần thống nhất riêng; đợt này không tạo chức năng xóa sân/tài khoản/giao dịch trái nguyên tắc giữ lịch sử.

## Hai tầng phân quyền thực thi

Bảng VaiTro/PhanQuyen là quyền người dùng web; SQL database role là quyền của principal SQL. Web giữ một service account SanBongApp, SanBongRuntimeRole và kiểm tra role/ownership ở backend. Không đưa mật khẩu SQL vào trình duyệt hoặc mở thêm bốn pool.

| SQL role | Quyền minh họa | Giới hạn |
|---|---|---|
| SB_Customer | Đọc danh mục sân/loại/dịch vụ công khai | Không đọc toàn bộ tài khoản/thu tiền; không cấp đọc bảng khách hoặc booking của mọi người |
| SB_PitchStaff | Danh mục, EXEC báo cáo sử dụng | DENY báo cáo tài chính |
| SB_Accountant | EXEC tài chính/phương thức/đối soát/top dịch vụ, đọc view thực nhận, hàm tỷ lệ hoàn | Không UPDATE sân hoặc cấp quyền quản trị |
| SB_Manager | Báo cáo, SELECT/INSERT/UPDATE sân, đọc nhật ký | DENY UPDATE/DELETE nhật ký và DELETE thanh toán; không db_owner |

SB_Demo* là user WITHOUT LOGIN để DBA dùng EXECUTE AS USER khi minh họa. Không có mật khẩu, không thể đăng nhập từ web/SSMS bằng các user này. Chúng là kiểm chứng quyền database, không tuyên bố phiên khách web tự đổi SQL identity. Quyền SQL này có chủ ý hẹp hơn tập chức năng web, không phải đường nghiệp vụ thay thế backend.

`database/rubric-permission-probes.sql` kiểm tra bốn role, thực sự bị lỗi229 khi khách đọc ThanhToan, và GRANT → REVOKE → DENY trong transaction rồi ROLLBACK để giữ ma trận quyền đã review. Chỉ chạy probe trên fixture bằng DBA.

## Thiết kế quan hệ và chuẩn hóa

Chứng minh chuẩn hóa phải bắt đầu từ phụ thuộc hàm theo nghĩa nghiệp vụ, không chỉ nhìn PK hoặc số bảng. Các phụ thuộc dưới đây mô tả thiết kế; dữ liệu hiện có không tự chứng minh không tồn tại phụ thuộc khác.

| Nhóm bảng | Khóa / phụ thuộc chính | Lý do tách |
|---|---|---|
| VaiTro, ChucNang, TieuChiDanhGia, LoaiSan, KhungGio | Mã → tên và thuộc tính của chính danh mục | Không lặp tên vai trò/chức năng/loại sân vào mọi dòng con |
| PhanQuyen | (MaVaiTro, MaChucNang) → Xem, Them, Sua, Xoa | Quan hệ nhiều–nhiều, các quyền phụ thuộc cả cặp khóa |
| San, DichVu, KhuyenMai, GiaTheoCa | Mã → thuộc tính danh mục hiện tại | Giá danh mục hiện tại tách khỏi snapshot giá đã bán |
| KhachHang, NhanVien, TaiKhoan | Mã hồ sơ/tài khoản → thuộc tính; SĐT khách và username có UNIQUE | Hồ sơ và thông tin xác thực tách nhau. TaiKhoan liên kết đúng một KH hoặc NV bằng CHECK |
| DatSan | MaDatSan → khách/sân/ngày/khoảng giờ/trạng thái/snapshot | FK tới danh mục, không chứa danh sách dịch vụ trong một ô |
| ChiTietDichVu | MaChiTiet → booking, SKU, số lượng, snapshot quy cách/giá | Một SKU có thể có nhiều dòng khác nguồn/quy cách; không coi (booking,SKU) là khóa duy nhất |
| XacNhanSan, HuyDatSan, HoaDon | Mã riêng và MaDatSan UNIQUE là khóa ứng viên | Mỗi booking có tối đa một lượt nhận/trả, một phiếu hủy, một hóa đơn theo schema hiện tại |
| ThanhToan | MaTT → giao dịch; MaGiaoDich duy nhất khi khác NULL | Tách nhiều lần thu khỏi hóa đơn, bảo vệ idempotency |
| HoanTien | MaHT → lần hoàn; (MaHuy,MaTT) duy nhất | Liên kết lần thu và phiếu hủy; không ghi đè thu tiền cũ |
| DanhGia | MaDanhGia và MaDatSan UNIQUE là khóa ứng viên | Booking → KH/sân không phải phụ thuộc vào một thuộc tính không khóa vì MaDatSan là khóa ứng viên của bảng này |
| ChiTietDanhGia | (MaDanhGia,MaTieuChi) → Diem | Không tạo cột Diem1…DiemN, tiêu chí thêm được bằng dòng |
| PhanHoi, NhatKyHeThong, BaoCao, SaoLuu | Mã → nội dung sự kiện/hồ sơ | Bảng audit/lịch sử không thay cho các thực thể nghiệp vụ; BaoCao/SaoLuu không mặc nhiên là workflow đã nối UI |

Cập nhật 18/10: migration tài chính đã được duyệt và triển khai, chuyển 9 thuộc tính dẫn xuất sang computed persisted và thêm 3 snapshot kế thừa để giữ nguyên tiền/thời lượng legacy. JPA/JDBC không ghi trực tiếp các cột computed. Snapshot giá bán/hóa đơn là dữ kiện lịch sử độc lập catalog; các tổng liên bảng TienDichVu/DaThanhToan vẫn có kiểm soát. Mô hình FD/closure cho 27 quan hệ và giả định nghiệp vụ ở DBMS_NORMALIZATION_MODEL.md; kết quả 3NF có điều kiện theo mô hình đó, không tuyên bố toàn bộ schema vật lý hết mọi dư thừa. Xem nghiệm thu 18/10 để biết bằng chứng rollback và đối chiếu dữ liệu.

## Transaction và tranh chấp

`database/rubric-transactions.sql` chỉ nhận tên DB fixture có marker dùng một lần. Năm kịch bản: tạo đặt sân kèm nhật ký; thêm/sửa lượng dịch vụ và trigger tổng; nhận/trả và chốt hóa đơn; thu tiền và đồng bộ hóa đơn; hủy/hoàn theo thực thu. Mỗi kịch bản có một COMMIT quan sát được và một lỗi cố ý sau các bước ghi để kiểm tra ROLLBACK không còn dữ liệu từng bảng. Năm bộ dữ liệu thành công được giữ trên fixture để kiểm tra; không copy lên nguồn.

Kịch bản SQL là minh họa ACID bằng dữ liệu tổng hợp, không phải API mới cho người dùng cuối hoặc quy trình xác nhận tiền thật. Các quy tắc thời gian/role/ownership/idempotency đầy đủ vẫn do backend và hồi quy tích hợp bảo vệ.

`scripts/verify-rubric-concurrency.ps1` dùng hai connection: A giữ UPDLOCK/HOLDLOCK trên sân, B gặp1222 khi hết timeout, A ROLLBACK, B lấy khóa được. Không ghi dữ liệu. BookingConcurrencyTest/OperationsConcurrencyTest kiểm tra thêm hai request nghiệp vụ cạnh tranh thực tế trên fixture.

## Index và giới hạn phép đo

`database/rubric-index-benchmark.sql` tạo schema rubric_bench với năm bảng **tổng hợp** 50.000 dòng/bảng trong fixture. `scripts/measure-rubric-indexes.ps1` lưu STATISTICS IO/TIME và actual XML plan trước/sau từng index. Không DROP/DISABLE index nguồn hoặc benchmark bằng dữ liệu khách thật.

| Mẫu truy vấn | Logical reads trước → sau | Ghi chú |
|---|---|---|
| Sân/ngày/giờ | 403 → 2 | Mô phỏng IX_DatSan_SanNgayBatDau |
| Thu tiền theo booking/trạng thái | 407 → 3 | Mô phỏng index INCLUDE SoTien |
| Dịch vụ theo booking | 261 → 3 | Bản thử có INCLUDE lượng/giá; index nguồn hiện không có INCLUDE, không nhận là số đo trực tiếp của index nguồn |
| Username | 259 → 3 | Unique index, bảo vệ định danh và tìm kiếm |
| SĐT khách | 217 → 3 | Unique index; không xóa UNIQUE của bảng nguồn để đo |

Số đo là một lần thử có chọn lọc trên heap tổng hợp và truy vấn chọn lọc; không chứng minh mọi truy vấn, kích thước và độ lệch dữ liệu đều tốt hơn. CPU/elapsed rất ngắn có thể bằng0ms; dùng logical reads/plan làm minh chứng chính. Mỗi cặp cần so kết quả truy vấn giống nhau trước khi diễn giải hiệu năng. Kết quả và kế hoạch nằm trong exports/rubric-indexes.

Chạy scripts/verify-rubric-index-results.py sau phép đo để xác nhận năm kết quả giống nhau, năm actual plan chuyển từ Table Scan sang Index Seek và lưu verification.json. Runner SQLCMD đã ghim UTF-8; công cụ verify cũng đọc được bộ log ANSI của lần thử đầu.

## Tạo lại schema và chạy kiểm tra

`database/rubric-schema-new-only.sql` là snapshot schema-only: 27 bảng, khóa/ràng buộc/index, view/function/procedure/trigger, không chứa dữ liệu người dùng, hash mật khẩu, ngân hàng hoặc login. Chỉ cho phép tên mới SanBong_SchemaDemo_...; từ chối nếu DB tồn tại, không DROP/reset/restore. Dùng SQLCMD -b để dừng khi lỗi. Không dùng file này thay backup có dữ liệu; danh mục, tài khoản quản trị và service identity phải được provision riêng trên DB mới. Bốn role nằm trong migration riêng; không xuất quyền vào snapshot một cách ngầm định.

```powershell
# Trong thư mục gốc dự án, với private profile fixture đã chuẩn bị:
.\backend\run-rubric-verification.ps1 -EnvFile .\.env.rubric.local -Offline

# Chỉ fixture, bằng Windows identity có quyền DBA:
sqlcmd -S tcp:localhost,1433 -E -C -b -f 65001 -d TEN_DB_FIXTURE -v ReviewedDatabase=TEN_DB_FIXTURE -i database/rubric-transactions.sql
sqlcmd -S tcp:localhost,1433 -E -C -b -f 65001 -d TEN_DB_FIXTURE -v ReviewedDatabase=TEN_DB_FIXTURE -i database/rubric-permission-probes.sql
.\scripts\verify-rubric-concurrency.ps1 -Database TEN_DB_FIXTURE

# Chỉ DB mới, không dùng tên của database đang có:
sqlcmd -S tcp:localhost,1433 -E -C -d master -b -f 65001 -v NewDatabase=SanBong_SchemaDemo_TEN_MOI -i database/rubric-schema-new-only.sql
```

Các runner cần JDK24, Maven có trên PATH hoặc MAVEN_HOME. Không chia sẻ .env.rubric.local, .env.test.local, cookie hoặc backup dữ liệu thật lên repository công khai. Không chạy test fixture bằng SanBongApp hoặc DB internal.
