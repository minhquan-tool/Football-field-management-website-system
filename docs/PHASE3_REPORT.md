# Phase 3 — Quản lý sân bóng

Trạng thái: code, build, integration test và HTTP/SQL test đã đạt; CHƯA đánh dấu
Definition of Done hoàn thành vì chưa xác minh thao tác/refresh bằng trình duyệt.
Công cụ trả danh sách browser rỗng và không mở được Chrome. Dừng trước Phase 4.

## A. File tạo

- backend/src/main/java/com/sanbong/model/BangGia.java.
- dto/PitchRequest.java, PitchStatusRequest.java, PitchView.java, PriceView.java.
- repository/SanRepository.java, LoaiSanRepository.java, BangGiaRepository.java,
  DatSanRepository.java (chỉ dependency đọc booking, không có API booking).
- service/PitchService.java, PitchNotFoundException.java.
- controller/PitchController.java.
- backend/src/test/java/com/sanbong/PitchManagementTest.java.
- backend/scripts/phase3-http-check.mjs, cleanup-phase3-test.sql.
- frontend/js/pitches.js và báo cáo này.

Các đường dẫn Java ngắn ở trên đều nằm dưới backend/src/main/java/com/sanbong.

## B. File sửa

- AGENTS.md: cập nhật phạm vi Phase 3, giữ nguyên nguyên tắc Web App nội bộ.
- backend/README.md: bổ sung API, rule và kiểm tra Phase 3.
- config/SecurityConfig.java: thêm đường dẫn API sân, giữ security Phase 2.
- controller/ApiExceptionHandler.java: 404 sân không tồn tại, 405 thao tác không hỗ trợ.
- repository/SecurityRepository.java: overload writer nhật ký hiện có cho chức năng/đối tượng sân.
- frontend/Quan_ly_san.html: danh sách/options/modal dùng API, bỏ dữ liệu mẫu và xóa vật lý.
- frontend/js/auth.js: miễn chặn thao tác demo cho trang sân đã có API; các trang khác giữ guard cũ.

## C. API (dưới context-path hiện tại /api)

| Method | Endpoint | Chức năng |
|---|---|---|
| GET | /pitches?q=&type=&status= | Danh sách/tìm tên hoặc mã, lọc loại/trạng thái |
| GET | /pitches/{id} | Chi tiết |
| GET | /pitch-types | Loại sân thật |
| GET | /pitch-prices | Bảng giá thật theo loại sân |
| GET | /pitches/{id}/prices | Giá của loại sân gắn với sân |
| POST | /pitches | Thêm |
| PUT | /pitches/{id} | Sửa thông tin/trạng thái |
| PATCH | /pitches/{id}/status | Trống/Đang sử dụng/Bảo trì |

Không tạo DELETE. API trả DTO và format ApiResponse hiện có, không trả entity nhạy cảm.

## D. Rule và dữ liệu

- Validate tên tối đa 50, mô tả 255, mã tối đa 10; mã không trùng, loại phải tồn tại.
- Trạng thái đúng CK_San_TrangThai; không thêm Ngừng hoạt động vì schema chưa hỗ trợ.
- Không đổi mã sân qua update. Tìm kiếm bind tham số và escape wildcard.
- Ghi dữ liệu với transaction SERIALIZABLE, khóa sân khi sửa và kiểm tra booking trước bảo trì.
- Chặn bảo trì sân đang sử dụng hoặc có booking Chờ/Đã xác nhận từ hôm nay trở đi
  (ngày nghiệp vụ Asia/Ho_Chi_Minh). Không tự hủy/hoàn hoặc sửa booking.
- Không xóa sân có/không có lịch sử qua API này. Lịch sử và giá snapshot booking giữ nguyên.
- BangGia chỉ đọc; giá card là mức thấp nhất trong các dòng còn hiệu lực của loại sân,
  kèm loại ngày/thời lượng. Chi tiết hiển thị từng khung giờ, loại ngày, giá và hiệu lực.
- CK_BangGia_DonGia thực tế yêu cầu >0; không tạo CRUD giá hoặc đổi CK thành >=0.
- Nhật ký thêm/sửa/trạng thái dùng NhatKyHeThong trong cùng transaction.

Lỗi đã phát hiện/sửa khi test: literal tiếng Việt không có Unicode trong query booking
cho kết quả sai (0 so với 2 khi dùng Unicode). Đã dùng tham số bind cho trạng thái;
test hồi quy bảo trì từ HTTP 200 sai sang HTTP 409 đúng. Không đổi kiến trúc/schema.

## E. Quyền

Tái sử dụng CN02 hiện có; không tạo role/mã chức năng mới trong DB.
API quản lý sân chỉ cho ROLE_ADMIN hoặc ROLE_PITCH_STAFF, rồi kiểm tra:
- CN02_XEM: danh sách/chi tiết/loại/giá.
- CN02_THEM: thêm.
- CN02_SUA: sửa/đổi trạng thái/bảo trì/mở lại.

Customer và Accountant bị chặn dù Customer có CN02 để đặt sân.
Người vận hành bị thu hồi Them/Sua vẫn xem được nhưng request ghi trả 403.
CSRF vẫn bắt buộc cho thao tác ghi; quyền được reload theo cơ chế Phase 2.

## F. Hard-code loại bỏ

Xóa 6 card sân mẫu, các dòng bảng mẫu, thống kê mẫu, loại sân mẫu trong select,
giá/thiết bị mẫu và handlers chỉ toast thành công. Dữ liệu SQL Server là nguồn chuẩn.
Giữ style, layout grid/table, modal thêm/sửa; thêm detail/giá và nút Chi tiết cần thiết.
Không có credentials hoặc host cố định trong JS quản lý sân; tái sử dụng SanBong.request.

## G. Test

Build clean verify: BUILD SUCCESS, 14 tests (7 authentication + 6 pitch + 1 JDBC),
0 failures/errors. JAR startup và Hibernate validate thành công, JDBC trực tiếp.

| # | Kiểm tra yêu cầu | Kết quả |
|---|---|---|
| 1 | Danh sách | PASS integration + HTTP |
| 2 | Chi tiết và 404 | PASS |
| 3 | Search/filter | PASS, kể cả wildcard literal |
| 4 | Thêm hợp lệ | PASS, đã commit qua HTTP và đọc SQL |
| 5 | Trùng mã | PASS 409 |
| 6 | Sửa | PASS, SQL lưu tên mới |
| 7 | Đổi trạng thái | PASS |
| 8 | Bảo trì/mở lại/xung đột | PASS |
| 9 | Dữ liệu sai | PASS 400 |
| 10 | Chưa đăng nhập | PASS 401 |
| 11 | Role/permission thiếu và CSRF | PASS 403 |
| 12 | Đối chiếu SQL trực tiếp | PASS |
| 13 | Refresh trên trình duyệt | PENDING; fresh HTTP read đã PASS |
| 14 | UI render dữ liệu thật | PENDING browser; source/server markup đã bỏ dữ liệu mẫu |

Không ghi PASS end-to-end browser khi công cụ chưa chạy được browser.

## H. SQL thay đổi

Các integration tests có transaction rollback. HTTP test tạo đúng sân T3TD2918C,
sửa tên và trạng thái, đối chiếu SQL cùng 5 nhật ký sân. Đã xóa riêng sân test và
5 nhật ký test bằng script có kiểm tra ID/marker/không có lịch sử; không dùng API DELETE.
Chạy sqlcmd đọc file UTF-8 với -f 65001 để giữ literal Unicode.
Sau cleanup: 6 sân, 2 booking, 11 bảng giá, 4 tài khoản; test row/journal còn lại 0.
DS01/DS02 vẫn ngày 2026-10-01, giá/TongTien vẫn 250000/230000 và 300000/300000.
Nhật ký login thật của phiên test được giữ. Không thay schema, seed hoặc giá booking.

## I–K. Giới hạn, debt và phần sau

- Thiếu xác nhận thao tác/render/refresh trình duyệt; chưa đánh dấu Phase 3 hoàn thành.
- CN02 hiện gộp quyền sân và đặt sân. Nếu cần tách quyền chi tiết, cần quyết định
  mã chức năng mới và cập nhật module quyền ở một bước riêng; không tự thêm ở đây.
- Quy tắc bảo trì chặn cả ngày hôm nay với booking còn xác nhận, không tự xử lý
  booking quá giờ. Phase lịch/booking cần định nghĩa vòng đời cập nhật trạng thái.
- CRUD bảng giá/loại sân không làm ở Phase 3. Bảng giá thiếu phần cuối tuần/ngày lễ
  theo dữ liệu hiện có; không hard-code giá thay thế. Cần quy tắc giá chồng hiệu lực ở module giá.
- S03 trong SQL thuộc loại 7 người nhưng mô tả ghi 5 người; UI phản ánh nguyên dữ liệu,
  không tự sửa dữ liệu gốc. Có thể chỉnh bằng chức năng sửa sân khi đã xác nhận thông tin.
- Phase booking tương lai phải kiểm tra trạng thái và phối hợp khóa sân/transaction
  để không đặt mới vào sân bảo trì. Chưa làm booking, hóa đơn, thanh toán, hoàn tiền, báo cáo.
- SqlProxy giữ nguyên và không dùng. Không thêm dependency, không mở LAN.

## Bước xác minh giao diện đang chờ

1. Mở http://127.0.0.1:8080/api/Dang_nhap.html, dùng tài khoản admin hoặc nvsan mẫu.
2. Mở Quan_ly_san.html: kiểm tra 6 sân, lọc mã S01, mở chi tiết/bảng giá, đổi grid/table.
3. Thêm mã T3UI01, tên Sân kiểm tra UI, loại bất kỳ, trạng thái Trống, mô tả
   Phase3 manual UI test. Sửa tên, chuyển Bảo trì rồi Mở lại.
4. Refresh F5 và xác nhận tên/trạng thái còn đúng; báo kết quả/lỗi thực tế.

Chỉ dùng mã test mới nếu chưa tồn tại. Bản ghi này chưa được tạo tự động.
Sau xác nhận sẽ dọn chính xác dữ liệu test mới nếu không có lịch sử, rồi kết luận DoD.
