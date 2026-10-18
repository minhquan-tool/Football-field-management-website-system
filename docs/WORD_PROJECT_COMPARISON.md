# Đối chiếu tài liệu Word và project San_Bong

Ngày kiểm tra: 06/10/2026. Nguồn: `E:/Nhom19_QuanLySanBong.docx`, code hiện tại và truy vấn chỉ đọc database `QuanLySanBong`.

Project phù hợp với phần nền tảng, phân quyền, quản lý sân, tra cứu/đặt/lịch và nhận/trả sân/dịch vụ của tài liệu. Chưa đáp ứng toàn bộ 40 chức năng trong Bảng 2-2. Phần tài chính của Phase 5 vẫn dừng chờ quyết định; việc đọc Word không phải là phê duyệt migration hay yêu cầu triển khai các phase tiếp theo.

Đã đọc nội dung đoạn văn/bảng của Word, các hình use case, sơ đồ quan hệ, ảnh giao diện và 10 sơ đồ xử lý Chương 5. Các mục dưới đây dùng tên chương/bảng/hình, không dùng số trang chưa được xác minh bằng render. Không đánh giá bố cục trang Word. Không sửa Word, code nghiệp vụ, schema hoặc dữ liệu; chỉ thêm báo cáo này. Không chạy lại build/test vì đây là đối chiếu chỉ đọc; kết quả test trước đây được phân biệt với kiểm tra hiện tại.

## 1. Khung giờ cố định phù hợp tài liệu

- QTHT_QĐ 3: quản trị thiết lập khung giờ và đơn giá theo loại sân/ngày/khung giờ.
- Bảng 2-2, chức năng 33: “Thiết lập các khung giờ cho thuê”.
- Bảng 4-5: khách hàng “Chọn ca đá trong ngày”. Các biểu mẫu “Từ ... đến ...” không tự chứng minh người dùng được nhập giờ tùy ý.
- Hiện tại `BookingRequest` nhận `maSan`, `ngayChoi`, `maKhungGio`; không nhận giờ bắt đầu/kết thúc tự nhập. `BookingService` đọc `KhungGio`, kiểm tra tương lai, chồng lịch và giá hiệu lực.
- SQL hiện có KG01 06:00–07:30; KG02 16:00–17:30; KG03 17:30–19:00; KG04 19:00–20:30; KG05 20:30–22:00. Mỗi khung 1,5 giờ. Đây là dữ liệu cấu hình hiện tại, không phải tài liệu bắt buộc chỉ được có đúng 5 khung.
- Khung dùng chung, giá theo loại sân/loại ngày/khung. Chưa có API quản trị thêm/sửa/khóa khung giờ.

## 2. Đối chiếu 40 chức năng trong Bảng 2-2

“Có” nghĩa là tìm thấy luồng API/code tương ứng, không chứng nhận UI đã kiểm thử bằng trình duyệt lần này. “Một phần” là còn thiếu thành phần trong mô tả tài liệu. “Chưa” có thể đã có bảng hoặc giao diện mẫu nhưng chưa có nghiệp vụ API hoàn chỉnh.

| STT | Chức năng trong Word | Hiện trạng project |
|---|---|---|
| 1 | Đăng ký tài khoản | Có API đăng ký khách hàng, validation, BCrypt và transaction. |
| 2 | Đăng nhập | Có username/email/phone, session, CSRF, 4 vai trò, logout và kiểm tra quyền backend. |
| 3 | Cập nhật thông tin tài khoản | Chưa có API cập nhật hồ sơ khách hàng. |
| 4 | Tra cứu sân | Có API danh sách/lọc sân và tra cứu theo ngày/loại sân. |
| 5 | Tra cứu khung giờ | Có API availability, chỉ đưa ra khung tương lai không trùng và có giá hiệu lực. |
| 6 | Đặt sân | Một phần: tạo booking thật theo sân/ngày/khung; chưa chọn dịch vụ trước khi đến, mã giảm giá và thanh toán. |
| 7 | Thanh toán | Chưa triển khai nghiệp vụ tài chính/API; Phase 5 đang dừng. |
| 8 | Hủy đặt sân | Một phần: hủy trước giờ chơi, chưa nhận sân, chưa có thanh toán chờ/thành công; chưa xử lý hủy có tiền và chính sách hoàn. |
| 9 | Đăng ký dịch vụ | Một phần: nhân viên/admin ghi nhận khi đã nhận sân; khách hàng chưa tự đăng ký dịch vụ. |
| 10 | Xem lịch sử đặt sân | Một phần: API lịch theo ngày và chi tiết giới hạn đúng chủ sở hữu; trang Lịch sử & Đánh giá riêng vẫn chưa lấy lịch sử thật đầy đủ. |
| 11 | Đánh giá sân | Chưa có API lưu đánh giá; có bảng và UI mẫu. |
| 12 | Gửi phản hồi | Chưa có API gửi phản hồi. |
| 13 | Tra cứu lịch đặt | Có API/UI lịch theo ngày, sân, khung, trạng thái. |
| 14 | Xác nhận khách nhận sân | Có API check-in, nhân viên đang làm việc, đối chiếu booking và trạng thái. |
| 15 | Cập nhật trạng thái sân | Có Trống/Đang sử dụng/Bảo trì; bảo vệ lượt sử dụng đang mở. Trạng thái khác trong Word cần thống nhất. |
| 16 | Tiếp nhận đặt sân tại quầy | Một phần: đặt thật cho khách đã có, tìm bằng điện thoại; chưa tạo khách mới ngay tại quầy. |
| 17 | Ghi nhận dịch vụ phát sinh | Có thêm/sửa số lượng/xóa theo quyền, giá snapshot và trigger SQL cập nhật tổng. |
| 18 | Xử lý hủy/đổi lịch | Một phần hủy; chưa có đổi lịch hoặc hủy/hoàn có tiền. |
| 19 | Kết thúc lượt sử dụng sân | Có check-out, thời điểm kết thúc, booking Đã sử dụng, sân Trống; chưa chuyển sang luồng hóa đơn/thanh toán. |
| 20 | Tiếp nhận phản hồi | Chưa có API xử lý và cập nhật trạng thái phản hồi. |
| 21 | Lập báo cáo sử dụng sân | Chưa có API/báo cáo/xuất dữ liệu hoàn chỉnh; số đếm trên dashboard nhân viên không thay thế báo cáo. |
| 22 | Tra cứu giao dịch | Chưa có API tra cứu tài chính; trang kế toán là mẫu. |
| 23 | Theo dõi tiền hoàn | Chưa có nghiệp vụ/API hoàn tiền. |
| 24 | Tra cứu doanh thu | Chưa có API báo cáo doanh thu thật. |
| 25 | Đối soát doanh thu | Chưa có luồng đối soát thật. |
| 26 | Lập báo cáo doanh thu | Chưa có API và xuất báo cáo. |
| 27 | Lập báo cáo tiền thực nhận | Chưa có API tổng hợp thanh toán trừ hoàn/điều chỉnh. |
| 28 | Quản lý tài khoản | Một phần: danh sách thật; chưa thêm/sửa/khóa/mở khóa tài khoản nội bộ bằng API/UI. Đăng ký khách hàng không thay thế chức năng này. |
| 29 | Phân quyền | Có đọc/lưu ma trận 8 chức năng theo vai trò, backend thực thi và bảo vệ quyền admin tối thiểu. |
| 30 | Quản lý nhân viên | Chưa có API quản trị nhân viên. |
| 31 | Quản lý sân bóng | Có thêm/sửa/lọc/trạng thái; không xóa lịch sử. Giá đọc từ BangGia, không có GiaCoBan trong San. |
| 32 | Quản lý loại sân | Một phần: đọc danh mục; chưa thêm/sửa/xóa. |
| 33 | Quản lý khung giờ | Một phần: đọc và sử dụng khung; chưa thêm/sửa/khóa khung. |
| 34 | Quản lý bảng giá | Một phần: đọc giá hiệu lực; chưa API quản trị giá. |
| 35 | Quản lý dịch vụ | Một phần: đọc danh mục đang kinh doanh và ghi nhận dịch vụ cho booking; chưa quản trị danh mục/đơn giá dịch vụ. |
| 36 | Quản lý khuyến mãi | Chưa có API quản trị/áp dụng mã thật. |
| 37 | Sao lưu dữ liệu | Chưa có workflow sao lưu định kỳ và nhật ký tương ứng. |
| 38 | Phục hồi dữ liệu | Chưa có workflow phục hồi được kiểm soát. |
| 39 | Theo dõi nhật ký hoạt động | Một phần: đã ghi nhật ký auth/phân quyền/sân/booking/vận hành; chưa API/UI tra cứu nhật ký đầy đủ theo mẫu. |
| 40 | Xem báo cáo tổng hợp | Chưa có API tổng hợp dữ liệu thật. |

Ngoài Bảng 2-2: Word có ghi nhớ đăng nhập, quên mật khẩu, thông báo/hồ sơ thành viên, xuất Excel và in chứng từ. Không có luồng hoàn chỉnh tương ứng hiện tại. Không coi nút hay ảnh giao diện là bằng chứng chức năng đã hoàn thành.

## 3. Những khác biệt nghiệp vụ cần chốt

### 3.1 Đơn giá theo giờ hay theo cả khung

Word KH_QĐ 3, Bảng 3-10, Bảng 3-12 và RBTV5 quy định đơn giá mỗi giờ, `TienSan = DonGia × ThoiLuong`. Project Phase 4 hiện lấy giá cho cả khung, `TienSan = DonGia`, phù hợp các snapshot đang có trong database.

Truy vấn thực tế ngày kiểm tra: DS01 thời lượng 1,50, đơn giá 250.000, tiền sân 250.000; DS02 1,50/300.000/300.000; DS3b97491a 1,50/200.000/200.000. Theo công thức Word sẽ lần lượt là 375.000/450.000/300.000.

Đây là khác biệt nghiệp vụ thật, không tự sửa bằng cách nhân thêm 1,5 hoặc đổi dữ liệu cũ. Ảnh giao diện Hình 4-4 còn ghi giá /1.5H, khác với lời văn “mỗi giờ”. Cần chọn đơn vị giá chuẩn rồi đồng bộ Word/UI/API và giữ nguyên giá lịch sử.

### 3.2 Xác nhận đặt sân và thanh toán

Word KH_QĐ 3 nói chỉ xác nhận khi ghi nhận thanh toán. Project hiện cho nhân viên/admin xác nhận booking chờ trước thanh toán. Trong khi đó Word cũng cho chọn tiền mặt tại sân và mô tả quy trình dùng sân rồi thanh toán.

Cần phân biệt xác nhận giữ lịch, thanh toán/cọc và hoàn tất sử dụng. Nếu tiền mặt trả sau được hỗ trợ, quy định “chỉ xác nhận khi đã thanh toán” cần sửa hoặc bổ sung điều kiện. Không âm thầm chặn mọi xác nhận trước thanh toán vì sẽ phá luồng Phase 4 đang hoạt động.

### 3.3 Dịch vụ, khách mới, đổi lịch và chính sách hoàn

- Word cho khách chọn dịch vụ ngay khi đặt; hiện chỉ nhân viên/admin ghi dịch vụ sau check-in.
- Word yêu cầu nhập thông tin khách đặt tại quầy; hiện chỉ chọn khách đã tồn tại. Còn thiếu tiếp nhận khách mới không bắt buộc tự đăng ký tài khoản trước.
- Word yêu cầu đổi lịch; hiện chỉ tạo/xác nhận/hủy, chưa có reschedule.
- Word nói hủy trong thời gian cho phép nhưng không định nghĩa rõ thời hạn/tỷ lệ/phí duyệt. Sơ đồ 5.8 đưa thêm tiền cọc và trạng thái hoàn/mất cọc mà schema hiện không có. Không lấy số cọc/hoàn của UI mẫu làm chính sách thật.
- Check-in hiện có giới hạn 30 phút trước giờ bắt đầu đến trước giờ kết thúc. Word chưa nêu rõ giới hạn này. Cần ghi nhận như quy tắc triển khai để hai bên thống nhất.
- `availability/create/confirm` hiện chỉ cho sân đang Trống, kể cả ngày đặt tương lai. Cần quyết định sân đang có khách hôm nay có được đặt khung trống ngày khác không; tài liệu chưa quy định rõ điều kiện này.

## 4. Đối chiếu thiết kế dữ liệu

Kiểm đếm SQL trực tiếp: **25 bảng nghiệp vụ**, không tính `sysdiagrams`; 3 view `V_KhungGioTrong`, `V_DoanhThuTheoNgay`, `V_TyLeLapDay`. `OBJECT_ID('dbo.HoaDon')` là NULL.

Lời văn và danh mục thuộc tính Chương 3 mô tả 20 quan hệ. Hình 3-1 sơ đồ quan hệ lại thể hiện 25 bảng gần với schema thực tế, bao gồm XacNhanSan, HuyDatSan, TieuChiDanhGia, ChiTietDanhGia và BaoCao. Tài liệu cần đồng bộ lời văn/bảng mô tả với chính sơ đồ của nó.

| Word phần mô tả thuộc tính | SQL/code hiện tại | Đánh giá |
|---|---|---|
| SanBong, GiaCoBan, trạng thái Hoạt động/Ngừng | San, không GiaCoBan; Trống/Đang sử dụng/Bảo trì | Tên, trường và trạng thái chưa thống nhất; giá nằm ở BangGia. |
| KhungGio có MoTa | KhungGio có ThoiLuong, không MoTa | Cần sửa mô tả Word theo schema đã validate. |
| BangGia.MaGia | BangGia.MaBangGia | Khác tên khóa chính. |
| KhachHang/NhanVien có MaTK | TaiKhoan có MaKH hoặc MaNV | Hướng liên kết khác; Word hình ER đã dùng hướng liên kết thực tế. |
| NhanVien.TrangThai là chuỗi | BIT và trường BoPhan riêng | Cần thống nhất kiểu/mã trạng thái. |
| DatSan.HinhThucDat | Chưa có cột này | Hiện MaNV nhận diện người tiếp nhận, chưa thay thế đầy đủ trường hình thức. |
| DatSan có Đang sử dụng/Hoàn thành | CHECK chỉ có Chờ xác nhận/Đã xác nhận/Đã sử dụng/Đã hủy | Đang sử dụng được thể hiện qua San và lượt XacNhanSan chưa kết thúc. Không tự thêm trạng thái vào DB. |
| ChiTietDichVu.ThoiDiemGhiNhan | NgayGhiNhan, có thêm MaNV; ThanhTien computed | Khác tên và chi tiết thiết kế; snapshot giá dịch vụ đã phù hợp. |
| ThanhToan.MaGiaoDich là PK | MaTT là PK, MaGiaoDich là trường riêng | Cần đồng bộ khóa và liên kết tài chính. |
| HoanTien chứa MaDatSan/LyDoHuy/PhiHuy trực tiếp | HoanTien liên kết MaTT và MaHuy; HuyDatSan chứa thông tin hủy | Schema thực tế tách hủy và hoàn, không thiếu chỉ vì các trường nằm ở bảng khác. |
| DanhGia có 6 cột điểm | TieuChiDanhGia + ChiTietDanhGia và DiemTrungBinh | Thiết kế chuẩn hóa khác, có trong hình ER của Word. |
| PhanHoi có DoiTuong/MucDoUuTien/NgayTiepNhan | Cấu trúc thực tế dùng NgayGui/TrangThaiXuLy/KetQuaXuLy, không đủ các trường mô tả | Trước khi làm phản hồi cần chốt phạm vi và mapping. |
| NhatKyHoatDong | NhatKyHeThong | Khác tên, cần sửa tài liệu. Ghi nhật ký đã có, tra cứu chưa có. |
| SaoLuuPhucHoi.DuongDanTapTin | SaoLuu.DuongDan | Khác tên bảng/cột. Workflow chưa triển khai. |

### Hóa đơn trong sơ đồ xử lý

Hình 5.4 dùng `SELECT/UPDATE HoaDon`, Hình 5.6 tổng hợp doanh thu từ `HoaDon`. Tuy nhiên Chương 3 không định nghĩa bảng HoaDon, hình ER không có, SQL hiện cũng không có. Không thể coi các sơ đồ này là chứng cứ migration đã được duyệt.

Đề xuất Phase 5 hiện có: `database/migrations/Phase5_HoaDon_PROPOSAL.sql`, chưa chạy. Cần lựa chọn hóa đơn độc lập hoặc phiếu thanh toán nội bộ dựa trên DatSan với vòng đời chốt rõ ràng; sau đó chỉnh tài liệu và triển khai tài chính theo quyết định.

## 5. Các sơ đồ xử lý cần đồng bộ

- Hình 5.2 tra cứu dùng `V_KhungGioTrong`; code hiện dùng BookingService + repository để lọc ngày, booking chiếm chỗ, khoảng giờ và giá. View hiện chỉ cross join sân/khung và loại Bảo trì, không tự chứng minh slot còn trống của một ngày. Không thay API đúng hiện tại bằng SELECT view đơn thuần.
- Hình 5.3 dùng TienCoc và QR cọc; BookingRequest/DatSan hiện không có TienCoc, chưa có gateway/QR nhận tiền. Đây là yêu cầu chưa thống nhất, không phải chức năng đã chạy.
- Hình 5.4 và 5.6 dựa vào HoaDon chưa được định nghĩa. Báo cáo tiền thực nhận phải dựa trên giao dịch Thành công và khoản Đã hoàn, không chỉ SUM hóa đơn đã lập; cần sửa sơ đồ để nhất quán KT_QĐ 1.
- Hình 5.8 ghi trạng thái “Đã hủy - Hoàn cọc”/“Đã hủy - Mất cọc”; không hợp CHECK hiện tại. Nên mô tả trạng thái booking và tài chính riêng sau khi chốt chính sách.
- Hình 5.10 đưa DonGia trực tiếp vào KhungGio; Chương 3 và schema thực tế đặt giá trong BangGia theo loại sân/ngày/khung. Cần tách đúng hai nghiệp vụ.
- Chương 5 vẽ Controller truy cập bảng trực tiếp; kiến trúc triển khai theo yêu cầu người dùng là Controller → Service → Repository. Cần cập nhật sơ đồ nếu trình bày kiến trúc triển khai thực tế.

## 6. Giao diện và yêu cầu phi chức năng

Phong cách FC-UTE, màu sắc, sidebar và 4 nhóm vai trò trong Word có nền tảng tương ứng ở HTML hiện tại. Các trang login/register, sân, đặt/lịch, nhận/trả sân/dịch vụ và ma trận quyền có JS/API thật. Một số hành động được chuyển sang trang/modal chức năng thật thay vì giữ nguyên vị trí nút trong ảnh mẫu; cần cập nhật ảnh Word khi nghiệm thu.

Dashboard quản trị/kế toán, trang chủ khách, khuyến mãi, lịch sử/đánh giá và phản hồi còn dữ liệu/luồng mẫu ở các phần chưa nối API. Có HTML không đồng nghĩa đã hoàn thành. auth.js chặn một số hành động/form mẫu chưa kết nối, nhưng số liệu mẫu trên màn hình vẫn không được coi là báo cáo thật.

Các yêu cầu bảo mật chính đã có nền tảng: hash BCrypt, session/CSRF, backend permission và ownership, backend validation, transaction/khóa chống trùng, lỗi API, JDBC trực tiếp, secrets môi trường, ddl-auto=validate. Chưa đánh giá hiệu năng bằng đo tải, quy trình backup/restore, triển khai HTTPS/LAN hoặc Internet trong lần đối chiếu này.

Word mục môi trường nêu truy cập Internet; người dùng đã cập nhật mục tiêu Web App nội bộ trên một server. Hướng triển khai nội bộ là chỉ dẫn hiện hành, không tự mở Internet vì lời văn trong Word. Tài liệu nên cập nhật phạm vi triển khai cho thống nhất.

## 7. Thứ tự xử lý đề xuất

1. Chốt đơn vị giá mỗi giờ/cả khung, xác nhận giữ lịch trước/sau thu tiền, vòng đời hóa đơn, cọc và chính sách hủy/hoàn. Không sửa lịch sử giá hay schema trước quyết định.
2. Đồng bộ Chương 3 và sơ đồ xử lý với SQL thực tế; bổ sung thiết kế hóa đơn nếu chọn migration. Không chạy lại script schema có DROP database.
3. Tiếp tục phần tài chính còn dừng của Phase 5 sau khi được duyệt; giữ nhận/trả sân/dịch vụ đã hoạt động. Kiểm thử thanh toán lặp/đồng thời, rollback, hủy/hoàn và phân quyền.
4. Các phần ngoài Phase 5 chỉ lập backlog: hồ sơ/khách mới, đổi lịch, quản trị danh mục/nhân viên/tài khoản, báo cáo, nhật ký tra cứu, khuyến mãi, đánh giá/phản hồi, backup/restore. Không tự triển khai tất cả hoặc chuyển Phase 6.
5. Khi chức năng được nghiệm thu, cập nhật ảnh Word bằng dữ liệu thật và kết quả kiểm thử, không dùng mock làm bằng chứng hoàn thành.

Nguồn code chính: BookingRequest.java, BookingService.java, OperationsService.java, PermissionController.java, PermissionService.java, AuthService.java, SecurityRepository.java và frontend/js/{auth,bookings,operations,permissions,staff-operations}.js. Đối chiếu thêm các báo cáo PHASE2_REPORT.md đến PHASE5_REPORT.md. Phase 5 ghi nhận trước đây build thành công và 58 tests PASS; đây không phải kết quả chạy lại ngày 06/10/2026.
