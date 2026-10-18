# Kiểm tra logic nhóm khách hàng — 16/10/2026

## Kết quả thực tế

- Lần đầu: 95 ca, 91 đạt và 4 thất bại. Bốn ca cùng phát hiện lỗi validation số điện thoại tại đăng ký/hồ sơ: chuỗi toàn dấu + hoặc dấu + giữa số được API chấp nhận HTTP 200.
- Đã sửa `RegisterRequest` và `CustomerProfileRequest`: chỉ chữ số và tối đa một dấu + đứng đầu, giữ nguyên giới hạn độ dài cũ (đăng ký 9–15 ký tự, hồ sơ 7–15 ký tự). Không đổi schema hoặc tự sửa hồ sơ đã tồn tại.
- Lần sau: tập chính 105 ca đạt; dịch vụ đặt trước 17 ca đạt; AuthenticationTest đủ 7 ca đạt thay cho 5 ca đã chạy trong tập chính. **124 ca phân biệt đạt, 0 failure/error/skipped** theo báo cáo XML mới nhất của 10 lớp. Đây là tổng hợp nhiều lần chạy, không phải một lệnh chạy toàn bộ project. Các lớp có ca hỗ trợ vai trò nhân viên/quản lý bên cạnh khách hàng.
- Có 24 ca mới trong `CustomerJourneyIntegrationTest`, dùng khách mới đăng ký để chứng minh quyền/ownership không chỉ dựa vào tài khoản demo.
- Browser trên cổng chính 8082: 6 mục menu khách hàng, 1440/390px, không chuyển thành sidebar trên desktop; số điện thoại sai bị từ chối 400 và dữ liệu hồ sơ không đổi; không page error/GET lỗi.
- Luồng tìm sân → đăng ký/đăng nhập giữ lựa chọn → chọn đúng sân/giờ → lịch sử → in/dọn phiếu: PASS. Browser chỉ đọc và gửi request bị từ chối; không tạo booking/thu/hoàn hoặc hồ sơ mới.

## Đối chiếu theo chức năng khách hàng

| Chức năng | Bằng chứng đã kiểm tra |
|---|---|
| KH01 Đăng ký | Hash mật khẩu, giữ Unicode, ép role VT01 dù payload giả VT04, trùng tên/email/điện thoại không để hồ sơ mồ côi, validation mật khẩu và giới hạn byte BCrypt, số điện thoại sai bị từ chối. |
| KH02 Đăng nhập/đăng xuất | Đăng nhập bằng username/email/điện thoại; sai mật khẩu, thiếu CSRF, tài khoản khóa, phiên bị thu hồi; logout hủy phiên. Không trả mật khẩu/hash trong response profile. |
| KH03 Hồ sơ | Cập nhật Unicode và liên hệ; email/điện thoại mới đăng nhập được; trùng liên hệ bị chặn; số điện thoại sai không thay giá trị đang lưu. |
| KH04 Tìm sân | Trang công khai tải danh mục, tìm sân theo ngày/giờ mà chưa đăng nhập; quyền API nội bộ vẫn được bảo vệ. |
| KH05 Giờ trống | Giờ mở 07:00–22:00, ngày quá khứ, overlap và khoảng liền kề; giá theo giờ bắt đầu và phút thực. Hai khách khác nhau không đặt chồng nhưng được đặt liền giờ. |
| KH06 Đặt sân | Booking gắn với chính khách đăng nhập; giả maKH bị chặn; gửi tổng tiền/đơn giá/trạng thái giả không được dùng làm dữ liệu quyết định. Snapshot và audit được kiểm tra. |
| KH07 Thanh toán | Yêu cầu vẫn Chờ xử lý dù client gửi daNhanTien=true; thực thu vẫn 0; retry cùng key không tạo trùng; đổi nội dung key bị chặn; số tiền âm/0/quá nhiều chữ số thập phân/vượt còn thiếu bị chặn. Khách không tự lập hóa đơn, ghi nhận thu hoặc đọc sổ giao dịch nội bộ. |
| KH08 Hủy/hoàn | Chỉ hủy lượt của mình; chưa thu thì hoàn 0; hủy giải phóng giờ; không hủy lần hai; luồng xác nhận thu → khách hủy → kế toán hoàn có kiểm tra. Sáu biên tỷ lệ SQL: đúng 10h, trước 10h một giây, đúng 2h, trước 2h một giây, lúc bắt đầu và sau bắt đầu. |
| KH09 Dịch vụ đặt trước | Catalog khách truy cập được, giá chính thức/snapshot, đơn vị/lốc, dữ liệu sai và SKU ngừng, ownership dòng dịch vụ. Khách không được sửa dịch vụ qua API vận hành nhân viên. |
| KH10 Lịch sử/hóa đơn | Lịch và history chỉ có booking của khách; GET booking/dịch vụ/finance/cancel-preview của người khác đều 403. Browser lọc lịch sử với hai lượt hiện có và in đúng phiếu, không coi phiếu là biên nhận. |
| KH11 Đánh giá | Chỉ lượt đã dùng, đúng chủ sở hữu, đủ tiêu chí, điểm 1–5, lưu chi tiết và điểm trung bình; một lần/lượt; lượt đã hủy không đánh giá được. |
| KH12 Phản hồi | Nội dung rỗng bị chặn; không gắn lượt của khách khác, không xem phản hồi khách khác; nhận/xử lý/đóng phản hồi và không ghi đè lịch sử đã đóng. |

## Hai bài test xác thực được cập nhật

`AuthenticationTest` trước còn kỳ vọng HTML sai vai trò trả 403 trực tiếp và staff có CN07_XEM được xem danh sách tài khoản. Chính sách hiện tại là HTML chuyển về home của vai trò với accessDenied, API ngoài role vẫn 403. Đã sửa kỳ vọng, đặt servletPath để MockMvc mô phỏng HTML đúng và kiểm tra permission cập nhật qua auth/me nhưng không vượt role. Chạy lại đủ 7 ca, không sửa production security để làm test đạt.

## An toàn dữ liệu

Đã SELECT xác minh `SanBongEnvironment=dev`; bật SAN_BONG_TEST_MODE=dev và giữ TestDatabaseSafetyListener. Các integration test được chọn đều có transaction rollback. Không chạy các suite dùng fixture commit/cleanup bên ngoài transaction, không chạy DROP/reset, không đổi quyền/mật khẩu người dùng. Unicode của khách đăng ký mới được đối chiếu trực tiếp với SQL. Tên demo cũ sai dấu không được tự sửa.

Các audit login/logout của browser là thao tác thật và được giữ. Dữ liệu giả lập trong integration test rollback; kiểm tra còn fixture ở `exports/customer-audit-fixtures.txt`.

## File thay đổi và bằng chứng

- Production: `backend/src/main/java/com/sanbong/dto/RegisterRequest.java`, `CustomerProfileRequest.java`.
- Test: `backend/src/test/java/com/sanbong/CustomerJourneyIntegrationTest.java` (mới), `AuthenticationTest.java`.
- Browser: `backend/scripts/customer-browser-audit.js` (mới).
- Trước sửa: `exports/customer-audit-before.log`.
- Sau sửa: `exports/customer-audit-final.log`, `customer-audit-services.log`, `customer-audit-auth.log`.
- Tổng hợp ca XML: `exports/customer-audit-summary.json`.
- Browser: `exports/customer-audit-browser.log`, `customer-audit-experience.log`.
- Bản chạy, hash JAR và sao lưu: `exports/customer-audit-deployment.json`, `backend-before-customer-audit-20261016.jar`.

## Phần chưa được chứng nhận trong đợt này

- Không phải toàn bộ test suite của project; không chạy lại stress/concurrency nhiều khách thực sự gửi cùng lúc hoặc đăng ký trùng đồng thời. Ca overlap hiện tại là request tuần tự; test biên tỷ lệ đọc hàm SQL, không thay thế mọi tổ hợp HTTP hủy/hoàn sát giờ.
- Không có kiểm thử ngân hàng/thanh toán thật, LAN hay thiết bị điện thoại vật lý; app vẫn ghi nhận thu/hoàn nội bộ.
- Ghi nhớ đăng nhập/khôi phục mật khẩu khách chưa được chứng nhận là chức năng hoàn thành; không tự reset mật khẩu demo để kiểm tra.
- History chưa kiểm tra hiệu năng với hàng chục nghìn lượt; thông báo lỗi validation trên UI còn tổng quát. Font/Tailwind/icon tiếp tục phụ thuộc CDN hiện có; kiểm tra browser đợi DOM/API thay vì chờ mọi tài nguyên ngoài.
- Quy tắc số điện thoại khách đã sửa; DTO nhân viên/hồ sơ tại quầy có quy tắc riêng, chưa được chuẩn hóa toàn hệ thống trong đợt khách hàng này.
