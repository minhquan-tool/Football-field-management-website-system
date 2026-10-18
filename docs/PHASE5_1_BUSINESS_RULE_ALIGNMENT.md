# Phase 5.1 đối chiếu quy tắc nghiệp vụ

Ngày kiểm tra: 08/10/2026. Trạng thái: **ĐÃ ĐỐI CHIẾU — CHỜ DUYỆT MIGRATION, CHƯA HOÀN THÀNH PHASE 5.1**.

## 1. Hiện trạng xác minh

Yêu cầu đính kèm là nguồn quy tắc chính thức mới, thay thế đề xuất giá cả khung và hoàn 100% trước đây cho giao dịch mới. Không dùng các đề xuất cũ làm chính sách của Phase 5.1.

Tuy nhiên, workspace hiện tại chưa có Phase 5 tài chính hoàn chỉnh: không có HoaDon, Finance/Payment/Refund Controller hay Service. OperationsService chỉ nhận/trả sân và dịch vụ; BookingService từ chối hủy booking đã có tiền. SQL xác nhận HoaDon không tồn tại; ThanhToan và HoanTien chưa có dữ liệu. Không thể ghi báo cáo “patch Phase 5 đã hoàn thành” khi bằng chứng không có phần đó.

Đã kiểm tra đúng phạm vi Booking/Operations/SQL/DTO/JS liên quan, không audit lại toàn project. Ban đầu: 7 sân, 3 booking, 0 ChiTietDichVu, 0 XacNhanSan, 0 ThanhToan, 0 HoanTien. Booking DS01/DS02 ngày 01/10 và DS3b97491a ngày 16/10 được giữ nguyên.

AGENTS.md yêu cầu khi schema chưa đủ cho tài chính: “dừng phần đó và đưa migration đề xuất để người dùng xem trước; không tự áp dụng”. Rule B cũng yêu cầu báo schema, đề xuất migration và giữ compatibility. Vì các thay đổi này liên kết với nhau, chưa sửa Entity/API sang schema chưa tồn tại, chưa thay giá danh mục hoặc áp dụng migration.

## 2. Bảng đối chiếu rule A–K

Đúng = giữ; gần đúng = patch cục bộ; sai = khác rule mới; chưa có = chưa triển khai; migration = cần xem trước thay đổi DB.

| RULE | HIỆN TẠI | ĐÚNG/SAI | CẦN SỬA | FILE/TABLE LIÊN QUAN | RỦI RO |
|---|---|---|---|---|---|
| A Một cơ sở, nhiều sân | Có San, không có chi nhánh | Đúng | Giữ nguyên | San, PitchService | Không mở rộng mô hình |
| B Nhập ngày/giờ bắt đầu/kết thúc | BookingRequest bắt buộc maKhungGio; DatSan không có giờ riêng và MaKhungGio NOT NULL | Sai, migration | Thêm giờ snapshot, cho FK slot nullable; adapter dữ liệu cũ | BookingRequest, DatSan, BookingView, bookings.js | Làm code mới trước DB sẽ lỗi validate/null |
| B Overlap theo khoảng | Đã dùng start<end và end>start nhưng đọc giờ từ KhungGio | Gần đúng | So sánh giờ thực của booking mới và legacy, bỏ cách coi slot là đơn vị lịch | BookingService.overlaps, DatSanRepository | Cần so cả booking cũ và mới |
| B Concurrency | Khóa San trước DatSan; unique filtered theo slot | Gần đúng | Giữ khóa chung; index khoảng giờ hỗ trợ truy vấn; không coi unique slot là chống overlap tự do | SanRepository, BookingService, UX_DatSan_KhongTrungLich | MaKhungGio NULL trong unique cũ chỉ cho 1 dòng/sân/ngày; phải thay filter |
| C 07–13 sáng 90k, 13–19 chiều 130k, 19–22 tối 180k | BangGia theo loại sân/slot/ngày, mức giá khác | Sai, migration | Bảng cấu hình 3 ca trong DB, chọn theo giờ bắt đầu cho toàn booking | BangGia, BookingService.price, bảng GiaTheoCa đề xuất | Không đổi BangGia/snapshot cũ, không tự chia nhiều ca |
| C Giờ hoạt động, không quá đóng cửa | Chỉ kiểm tra tương lai, slot hợp lệ | Sai | Backend kiểm tra giờ mở/đóng; cấu hình trong DB | BookingService, GiaTheoCa | Bắt đầu 22:00 không có khoảng dương kết thúc<=22:00 |
| C Snapshot giá | DatSan đã lưu DonGia/TienSan/ThoiLuong | Đúng về snapshot | Giữ tiền lịch sử; đánh dấu đơn vị GIA_KHUNG/GIA_GIO | DatSan | Không diễn giải giá cũ thành giá/giờ |
| D Thời lượng từ giờ thực, tiền sân=giờ×giá | TienSan=DonGia cả slot, thời lượng lấy slot | Sai | Tính theo số phút thực và BigDecimal, chỉ làm tròn tiền ở cuối | BookingService, DatSan | ThoiLuong decimal(4,2) không biểu diễn chính xác 1 phút/60 |
| D Khuyến mãi % chỉ tiền sân | Booking mới MaKM=null/TienGiam=0; DB có cả % và số tiền | Chưa có | Validate hiệu lực và % 0–100; giảm TienSan, không giảm dịch vụ; giữ chương trình/booking cũ | KhuyenMai, BookingRequest/Service | Không suy đoán điều kiện khuyến mãi dạng văn bản; không tự đổi KM01 số tiền |
| D Backend tính tổng, BigDecimal | Không nhận tổng client; Java BigDecimal, trigger SQL tính tổng dịch vụ | Đúng nền tảng | Giữ; tính giá/mã giảm đúng mới trước ghi | BookingRequest, BookingService, OperationsService | Không nhân hoặc cộng dịch vụ thêm ở Java |
| E Danh mục 7 đồ uống/giá mới | DV01 nước 10k, DV02 nước ngọt 15k; có đồ thuê/khăn | Sai, migration dữ liệu | Cập nhật riêng nước suối 5k; thêm SKU đồ uống rõ ràng; giữ DV02 và đồ thuê lịch sử, không đổi tên thành Coca | DichVu | Không xóa SKU cũ hoặc thay giá trong ChiTietDichVu |
| E Chủ sân đổi giá | Có bảng giá DB, chưa có API quản trị dịch vụ | Một phần | API admin cập nhật catalog; giá mới cho dòng mới | OperationsRepository, controller/service dịch vụ | Không sửa các snapshot đã ghi |
| E Snapshot dịch vụ | DonGia lưu tại ChiTietDichVu; sửa qty giữ giá cũ | Đúng | Giữ nguyên tính giá dòng cũ | OperationsService.quantity | Mua mới cùng SKU giá khác không được gộp vào giá cũ |
| F Lốc 6 giảm 3% | Chỉ SoLuong/DonGia, PK(booking,DV), không quy cách | Chưa có, migration | Thêm quy cách/đơn vị snapshot vào dòng; tính 6×giá×0,97 backend/SQL | ChiTietDichVu, DichVu | Cần nhiều dòng cùng DV; không đổi đơn giá chai để giả lốc |
| G Dịch vụ đặt trước | Chỉ thêm khi booking đã check-in; customer bị chặn operations | Sai | Đặt trước trong transaction tạo booking, kiểm tra customer ownership; không mở toàn operations cho customer | BookingRequest, BookingService, OperationsService | Endpoint nhân viên vẫn phải giữ quyền |
| G Phát sinh/phân biệt nguồn | Có dòng dịch vụ nhưng không Nguon; cùng SKU chỉ một dòng | Gần đúng, migration | Nguon DAT_TRUOC/PHAT_SINH; dòng riêng nếu nguồn/giá/quy cách khác | ChiTietDichVu, OperationsRepository | Giữ lịch sử; route theo DV cũ có thể mơ hồ khi nhiều dòng |
| G Khóa sau hoàn tất và trả đủ | Hiện khóa sau trả sân; khóa cả khi mới có tiền trước | Gần đúng | Thanh toán trước không khóa ghi phát sinh; hóa đơn đã chốt/booking kết thúc khóa thao tác thường | OperationsService.requireEditable | Nếu chỉ bỏ hasPayment mà không thêm lifecycle sẽ sửa tiền đã chốt |
| H Tiền mặt/chuyển khoản | SQL CHECK đúng 2 phương thức | Đúng schema, chưa API | Giữ; không giả xác minh ngân hàng | ThanhToan, HoanTien | UI không tuyên bố tự chuyển tiền |
| H Trả 100% khi đặt hoặc trả sau | Chưa API thu tiền/hóa đơn | Chưa có, không phải patch nhỏ | Thu trước đúng tổng tạm tại lúc đặt; khi có phát sinh, thu phần còn lại sau sử dụng | ThanhToan, HoaDon đề xuất | “100% khi đặt” không có nghĩa trả đủ dịch vụ phát sinh sau đó |
| H Xác nhận khác đã thanh toán | Confirm không kiểm tra đã trả tiền; booking độc lập khoản thu | Đúng | Giữ; trạng thái tài chính riêng | BookingService.confirm | Không đổi thành bắt buộc trả trước |
| I Nhân viên tạo, online không bắt buộc MaNV | Đã có; DatSan.MaNV nullable | Đúng | Giữ; thêm HinhThucDat nếu cần biểu diễn rõ | BookingService.create, DatSan | Không suy đoán hình thức các dòng legacy thiếu chứng cứ |
| J 10h/2h/0h theo giờ bắt đầu | Hủy chưa có tiền, TiLeHoan=0; có tiền bị chặn | Chưa có | Tính từ datetime hủy theo Asia/Ho_Chi_Minh tới giờ thực; >=10h 100, >=2h 50, còn lại 0 | BookingService.cancel, HuyDatSan, HoanTien | Đúng biên phút/giây, không chỉ so ngày |
| J Hoàn theo thực thu, chống lặp | Có bảng/FK nhưng chưa API/unique yêu cầu hoàn | Chưa có, migration | SUM khoản Thành công, lưu tỷ lệ/số tiền chốt, request key/unique khoản thu+hủy | ThanhToan, HuyDatSan, HoanTien | Không dùng TongTien nếu chưa thu; khoản 0 không INSERT HoanTien vì CHECK>0 |
| K Constraint/index/trigger/transaction | Đã có; trigger tổng dịch vụ đang hoạt động; Java có khóa/transaction | Đúng nền tảng | Giữ trigger là nơi cập nhật tổng dịch vụ; thêm constraint/index phù hợp dữ liệu mới | TRG_CapNhatTienDatSan, repositories/services | Không để Java/trigger double update |
| K Function/SP nghiệp vụ | Chỉ có function/SP sơ đồ SSMS | Chưa có | Function ca giá, tỷ lệ hoàn, giá lốc; SP atomic tạo booking mới sau precheck, transaction cùng JPA/JDBC | SQL đề xuất | Không tính SP SSMS là code nghiệp vụ; không thêm SP tạo luồng khác phá khóa chung |
| K View | Có 3 view, API chưa dùng trực tiếp | Một phần | View lịch/giao dịch phù hợp; sửa view trống nếu dùng, hiện cross join không loại lịch chiếm chỗ | V_KhungGioTrong, V_DoanhThuTheoNgay, V_TyLeLapDay | Không đưa view trống hiện tại vào API như nguồn đúng |

## 3. Phương án migration tối thiểu theo từng phần

### 3.1 Booking và giá

File DDL xem trước: `database/migrations/Phase5_1_BookingTimes_PROPOSAL.sql`. Mặc định chỉ in trạng thái proposal và RETURN, không thực thi DDL/DML. Chưa chạy file này.

- Thêm DatSan.GioBatDau/GioKetThuc time(0), CheDoGia và HinhThucDat. Dòng cũ được bổ sung giờ từ KhungGio, CheDoGia=GIA_KHUNG, hình thức chưa rõ=KHONG_RO. Không đổi số tiền, ngày chơi, FK slot hay trạng thái cũ.
- Đổi MaKhungGio nullable, giữ FK và bảng KhungGio. UNIQUE slot cũ phải đổi filter chỉ bảo vệ dòng có MaKhungGio. Index(MaSan,NgayChoi,GioBatDau) hỗ trợ khoảng giờ; index này không tự chống overlap.
- Dòng mới GIA_GIO có giờ theo phút, bắt đầu>=07:00, kết thúc<=22:00, end>start. Validation nghiệp vụ vẫn ở backend.
- CheDoGia phân biệt đơn vị DonGia lịch sử, không áp công thức mới để “sửa” tiền cũ. ThoiLuong vẫn là số giờ hiển thị đã làm tròn; tiền mới tính từ phút thực/60, không nhân lại số giờ đã làm tròn. Có thể lấy duration phút từ hai cột giờ mà không thêm cột dư.
- Bảng GiaTheoCa chứa 3 ca với ranh giới và giá chính thức. Các ca không phụ thuộc loại sân/ngày vì rule mới không nêu hệ số khác. BangGia cũ giữ cho legacy. Chưa thêm UI quản lý ca khi chưa có dữ liệu/API.
- DDL đề xuất là phần booking, **không phải migration đầy đủ của tài chính/dịch vụ**. Chưa được duyệt và không cho code dựa vào nó trước khi áp dụng cùng bản backend tương ứng.

### 3.2 Dịch vụ, quy cách và nguồn

ChiTietDichVu hiện khóa kép (MaDatSan,MaDV). Muốn cùng booking có Coca chai, lốc, đặt trước và phát sinh giá khác thì cần nhiều dòng cùng DV. Chỉ thêm cột mà giữ unique cũ sẽ không giải quyết được.

Đề xuất thêm MaChiTiet surrogate key; giữ MaDatSan/MaDV/FK và mọi dòng cũ. Chuyển PK sang MaChiTiet sau kiểm tra FK/dependency. Bổ sung Nguon, QuyCach, SoDonViMoiQuyCach, DonGiaDonViSnapshot; DonGia hiện có tiếp tục là giá mỗi đơn vị bán để computed ThanhTien=SoLuong×DonGia và trigger tổng vẫn đúng. Dòng cũ LEGACY/đơn vị 1, giữ DonGia; dòng lốc có đơn giá 6×giá đơn vị×0,97. Không tạo hệ thống kho.

API sửa/xóa mới theo MaChiTiet. Adapter route cũ theo DV chỉ xử lý khi có đúng một dòng, nếu nhiều dòng trả lỗi chọn dòng rõ ràng, không sửa nhầm nhiều bản ghi. Dòng mua mới cùng SKU giá khác phải là dòng mới, không ghi đè snapshot.

DichVu thêm cờ HoTroLoc; chỉ các SKU được cấu hình mới được bán lốc. Danh sách hỗ trợ chưa được người dùng nêu chính xác; chưa tự áp lốc cho trà đá/thùng hoặc đồ thuê. Khuyến nghị các chai/lon hỗ trợ, cần xác nhận trước seed.

Seed không xóa đồ thuê/khăn/nước ngọt cũ. Nước suối DV01 đổi catalog sang 5.000 cho giao dịch mới; thêm Trà đá 50.000/thùng, Coca 10.000/lon, Pepsi 10.000/lon, Revive chanh muối 12.000/chai, Revive 10.000/chai, Aquarius 12.000/chai bằng mã mới kiểm tra tên/mã trùng. Không đổi DV02 nước ngọt thành thương hiệu khác. Chưa chạy seed.

### 3.3 Tài chính

Phase 5 tài chính thiếu trong workspace, nên phần H/J đòi hỏi xây dựng phần còn thiếu có phạm vi, không thể tuyên bố chỉ sửa vài dòng. Giữ bảng ThanhToan/HuyDatSan/HoanTien. Đề xuất HoaDon snapshot sau trả sân, unique MaDatSan, cùng khóa booking; thu trước là ThanhToan không phải hóa đơn cuối cùng. Bổ sung request key unique filtered cho thu/hoàn và unique khoản thu+hủy khi chọn một lần hoàn cho mỗi khoản.

Tiền trả trước là tổng tiền tại lúc đặt (tiền sân sau khuyến mãi + dịch vụ đặt trước); khoản phát sinh tính vào số còn thiếu khi quyết toán. Customer chỉ chọn phương thức/yêu cầu thanh toán; không tự xác nhận Thành công. Không có gateway thì nhân viên/kế toán xác minh tiền đã nhận. Hoàn tính trên tổng Thành công chưa bị hoàn, chốt trong transaction hủy, mỗi khoản hoàn liên kết khoản thu cụ thể; tổng tiền hoàn không vượt chính sách hoặc tiền thực thu. Hoàn 0 chỉ ghi HuyDatSan, không cố chèn 0 vào HoanTien.

Guard dịch vụ chuyển từ “có thanh toán” sang lifecycle chốt, còn bảo vệ booking đã kết thúc. Không sửa tiền dịch vụ trực tiếp trong Java. Chính sách hoàn cũ 100% trước giờ chơi trong PHASE5_NEXT_DIRECTION.md chỉ là đề xuất cũ, đã bị rule J thay thế, chưa từng áp dụng.

### 3.4 Function, SP, view và transaction

- Function fn_CaGia(@start): xác định ca từ bảng cấu hình; function fn_TyLeHoan(@huy,@batDau): 100/50/0 theo ranh giới chính xác; function fn_GiaLoc(@gia): BigDecimal-equivalent DECIMAL nhân 6×0,97. Không dùng giá hard-code frontend.
- Một SP tạo booking tự do có kiểm tra khoảng giờ/overlap và khóa San, ghi booking/đặt trước/audit trong cùng transaction với Java. Không mở transaction độc lập phá rollback của Spring; trường hợp direct SQL phải theo cùng thứ tự khóa. Chưa tạo SP trên DB.
- View lịch đọc giờ DatSan với fallback slot legacy. View tiền thực nhận cần phân biệt thu Thành công và hoàn Đã hoàn; không SUM hóa đơn đã lập để coi là tiền thu. Không thay report của Phase 6 trong giai đoạn này.
- Constraint không thể thay toàn bộ kiểm tra interval bằng unique đơn giản. Khóa San chung trước đọc lịch và ghi là cơ chế concurrency chính; regression bảo vệ nó.

## 4. Quy tắc kỹ thuật cần chốt

1. Đóng cửa dự kiến 22:00 theo rule C. Giá tối có miền start<=22:00, nhưng start=22:00 không thể đặt khoảng dương nếu end<=22:00. Hướng đề xuất: cho function nhận diện giá 22:00 nhưng từ chối tạo booking bắt đầu đúng giờ đóng cửa.
2. Ví dụ 06:00–08:00 ở rule B chỉ minh họa không overlap; theo giờ mở 07:00 của rule C, không nhận booking thực tế đó. Test overlap thuần có thể dùng 06:00; test đặt thật cần khung trong 07–22. Không tự mở sân lúc 06:00.
3. Đề xuất booking theo phút, không qua nửa đêm, tiền làm tròn 2 chữ số thập phân HALF_UP phù hợp DECIMAL(18,2); quy tắc làm tròn tiền cần ghi rõ trong API/test. ThoiLuong chỉ để hiển thị, không làm nguồn tính tiền sau khi làm tròn.
4. Không tự coi giá sáng/chiều/tối là ngày thường rồi áp thêm cuối tuần/loại sân: rule mới chưa yêu cầu hệ số. Không tự xóa BangGia legacy.
5. Khuyến mãi mới theo %; giữ các mã giảm số tiền và booking lịch sử, không chuyển MucGiam 20.000 thành % hoặc áp mã không rõ điều kiện. Cần danh sách điều kiện có thể kiểm tra trước khi áp dụng tự động.

## 5. Bằng chứng và file thay đổi

Đã đọc BookingRequest/BookingView, DatSan, BookingService, OperationsService/Repository, BookingWorkflowRepository, BookingController, SecurityConfig, SQL schema/seed/index/trigger/dependency và các test liên quan. SQL đọc được 3 booking hiện có và snapshot tiền không thay đổi.

File tạo trong lượt này:

- `docs/PHASE5_1_BUSINESS_RULE_ALIGNMENT.md`: báo cáo này.
- `database/migrations/Phase5_1_BookingTimes_PROPOSAL.sql`: DDL booking/giá để xem trước, chưa thực thi.

Không sửa Java/HTML/CSS/JS, pom, application.yml, seed hiện hành, trigger, data hoặc schema. Chưa loại bỏ SqlProxy; không dùng nó.

## 6. Build và test

Kết quả regression ngày 08/10/2026: Maven `clean verify` **BUILD SUCCESS — 58 tests, 0 failures, 0 errors, 0 skipped**. Authentication 7, BookingConcurrency 4, BookingManagement 19, OperationsConcurrency 4, OperationsManagement 17, PitchManagement 6, SqlServerConnection 1. Không sửa test cũ. Log: `backend/target/phase5_1-baseline-build.log` và XML trong surefire-reports.

Maven portable 3.9.9 trong TEMP đã mất, phục hồi đúng phiên bản bằng gói có SHA512 kiểm tra; không đổi dependency hoặc PATH hệ thống. Lần tải checksum đầu gặp lỗi Invoke-WebRequest của PowerShell, khắc phục bằng UseBasicParsing rồi xác minh SHA512 thành công trước giải nén/chạy. JDK 21 hiện có được dùng trong process.

Sau regression, truy vấn SQL xác minh vẫn 7 sân/3 booking, 0 dòng dịch vụ/lượt nhận/thanh toán/hoàn; snapshot ngày/slot/tiền DS01, DS02, DS3b97491a đúng giá trị trước kiểm tra. HoaDon và hai cột giờ mới vẫn chưa tồn tại; chưa có migration được thực thi.

JAR baseline khởi động thành công trong 14,499 giây; JDBC Hikari kết nối trực tiếp, Hibernate ddl-auto=validate qua và EntityManagerFactory được tạo, không có lỗi schema/startup trong log. Server chỉ nghe 127.0.0.1:8080/api, PID 27288 tại lần kiểm tra, không triển khai LAN. HTTP trang đăng nhập và auth/csrf đều 200. Log startup: `backend/target/phase5_1-startup.log`. SqlServerConnectionTest PASS chứng minh đọc DB từ Java. Đây là backend cũ được build lại, không phải xác nhận rule Phase 5.1 đã chạy.

Các test mới M1–M26 chưa triển khai/chưa chạy vì schema/API mới chưa được duyệt và phần tài chính chưa có. Không đánh dấu PASS bằng cách chỉ test một calculator chưa được API sử dụng.

Giá kỳ vọng cho test API sau triển khai (chưa chạy): 08:00–12:30 = 405.000; 12:20–14:20 = 180.000; 13:00–15:00 = 260.000; 18:30–20:00 = 195.000; 19:00–20:00 = 180.000. Coca lốc = 58.200. Ví dụ tiền sân 260.000, khuyến mãi 10%, dịch vụ 58.200: TienGiam=26.000 và TongTien=292.200, không giảm thêm dịch vụ. Thực thu 200.000 thì hoàn 100%/50%/0% lần lượt 200.000/100.000/0, không dựa vào tổng hóa đơn 292.200.

Sau duyệt phải thêm đủ: M1–M5 biên ca theo start; M6–M10 overlap/bao trùm/sát biên/concurrency; M11–M12 tiền/giảm chỉ TienSan; M13–M16 snapshot/lốc/nguồn dịch vụ; M17–M19 thu trước/thu sau/xác nhận chưa trả; M20–M24 hoàn 10h/2h/0, thực thu và retry; M25 chống double payment; M26 dữ liệu cũ. Thêm ca phút lẻ, 22:00, thiếu giá, % ngoài miền, tiền thu trước rồi phát sinh, rollback audit và nhiều dòng cùng SKU.

Test cũ đổi business rule phải cập nhật expectation chỉ cho booking mới; giữ test legacy tiền cả khung. Không chỉnh test để che lỗi hoặc xóa kiểm tra concurrency/rollback.

## 7. Manual UI và giới hạn

Chưa có UI giờ tự do nên chưa thể nghiệm thu rule mới. Sau triển khai: đăng nhập khách/nhân viên, chọn ngày giờ tự do, xem giá từ API, thử 12:20–14:20 sáng/18:30–20:00 chiều; đặt sát biên, hai máy overlap; đặt trước chai/lốc, thêm phát sinh cùng SKU, đổi catalog rồi kiểm tra snapshot; thu trước và quyết toán phần thiếu; thử hủy đúng ranh giới 10h/2h/ít hơn 2h và hoàn lặp; F5 và kiểm tra SQL. Không đổi đồng hồ hệ thống/dữ liệu thật để kiểm thử.

Technical debt: thiếu tài chính thực; migration dịch vụ/finance/functions/SP chưa có DDL hoàn chỉnh; view trống hiện tại chưa loại booking; catalog quản trị chưa có; giới hạn đang sử dụng hôm nay không cho đặt ngày tương lai cần tách khỏi lịch; chưa manual UI regression. Không bắt đầu Phase 6.

## 8. Điểm dừng

Cần người dùng xem trước và duyệt phương án schema booking/giá/dòng dịch vụ/tài chính trước khi triển khai phụ thuộc. Không chạy đề xuất bảng HoaDon cũ riêng lẻ như thể đủ Phase 5.1. Sau duyệt, chuẩn bị DDL đầy đủ cho từng phần, backup/kiểm tra dependency và áp dụng cùng backend tương ứng; build/startup/validate/test mỗi phần rồi dừng tại Phase 5.1.
