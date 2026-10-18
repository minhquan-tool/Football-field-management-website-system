# Khách hàng: lịch sử phân trang và giảm tải truy vấn — 16/10/2026

## Kết quả triển khai

- Lịch sử được phân trang tại SQL Server qua JPA Pageable. API /customer/history nhận page (1–100000), size (1–50), q (tối đa 100 ký tự), state và order asc/desc. Mặc định API là trang 1/20; UI dùng 10 lượt/trang và cho chọn 10/20/50. Response giữ bookings/criteria/reviews, thêm page/size/total/totalPages/states. Client cũ không còn nhận tất cả lịch sử trong một response; phải dùng metadata để lấy các trang tiếp theo.
- Điều kiện chủ sở hữu được gắn từ phiên đăng nhập trước khi tìm/lọc/count; client không được chọn MaKH để xem hộ. Tìm mã đặt/tên sân và trạng thái áp dụng trước phân trang. LIKE escape %, _, [, !; không nối từ khóa người dùng vào SQL. Sắp xếp theo ngày, giờ và mã đặt để các dòng đồng giờ có thứ tự xác định trong tập dữ liệu không đổi.
- Chỉ đọc đánh giá của khách cho tối đa 50 mã đặt đang nằm trên trang. EntityGraph tải các quan hệ to-one cần cho BookingView, tránh gọi lặp từng quan hệ khi dựng response; không fetch collection qua pagination.
- UI giữ điều kiện tìm/lọc/sắp xếp khi chuyển trang và sau gửi đánh giá, hiển thị tổng số/trang, khóa nút biên. Tìm kiếm có debounce và bỏ phản hồi request cũ. Trang không còn tồn tại sau thay đổi dữ liệu sẽ được đưa về trang hợp lệ. Khi API lỗi, xóa các dòng cũ và hiển thị nút Tải lại lịch sử; không giữ chi tiết cũ như kết quả mới.
- Cập nhật hồ sơ dùng exists query loại trừ chính khách để kiểm tra trùng số điện thoại/email; bỏ customers.findAll(). Kiểm tra định danh đăng nhập của tài khoản khác vẫn giữ. Khách không có tài khoản (tạo tại quầy) vẫn được bảo vệ khỏi trùng liên hệ.
- Không thay schema, index, role/permission, stack hoặc snapshot tài chính. Không tự sửa tên/địa chỉ demo sai dấu.

## Kiểm chứng

- Một lệnh Maven JDK 24 package: **67 ca, 0 failure/error/skipped**, thuộc 6 lớp: CustomerHistoryPagingTest 13 mới, CustomerCompletionTest 13, CustomerJourneyIntegrationTest 24, CustomerCareTest 6, RoleBoundaryTest 4, AuthenticationTest 7. Đây là tập được chọn cho thay đổi, không phải toàn bộ suite.
- 13 ca mới: 23 lượt đặt trên ba trang không trùng/mất; mặc định API chặn ở 20; tìm đơn ngoài trang đầu; lọc trạng thái; ownership và payload MaKH giả; ký tự SQL wildcard và chuỗi injection được xem là dữ liệu; chỉ review hiện tại; 7 tổ hợp tham số sai; dữ liệu rỗng/trang vượt cuối/từ khóa dài; hồ sơ trùng khách không có tài khoản bị chặn.
- Lần compile đầu test dùng var trong khai báo nhiều biến; đã tách khai báo. Không sửa production để làm test đạt. Log cũ ở customer-history-compile-before.log.
- Playwright CLI: GET backend thật; bộ 23 dòng giả lập chỉ ở response UI để kiểm tra chuyển trang/tìm/lọc/sắp xếp. Đã kiểm tra phản hồi chậm không ghi đè truy vấn mới, lỗi 503 xóa dòng cũ và retry phục hồi; 1440/1024/768/390px không tràn ngang. Browser không tạo booking/thu/hoàn hoặc đổi mật khẩu thật.
- Chạy lại script hồ sơ/đổi mật khẩu/validation và điều hướng 25 mục thuộc 4 vai trò: đạt. Script cũ được sửa để chờ request tìm kiếm bất đồng bộ và đối chiếu kết quả theo trang/order từ backend.
- Chưa benchmark dữ liệu hàng chục nghìn lượt hoặc đo execution plan/index; giới hạn lượng dữ liệu response không đồng nghĩa đã chứng nhận mọi truy vấn là tối ưu. Chưa kiểm thử tải nhiều người đặt sân đồng thời trong đợt này.

## An toàn

Đã SELECT SanBongEnvironment=dev trước khi chạy, giữ SAN_BONG_TEST_MODE=dev và global safety listener. Các integration test được chọn có transaction rollback. Không chạy suite concurrency có commit/DELETE cleanup trên database hiện tại. Audit login/logout browser là thao tác thật và giữ lại; không thay mật khẩu demo hoặc thông tin thật.

## File thay đổi

- frontend/js/customer-care.js.
- backend/src/main/java/com/sanbong/controller/CustomerCareController.java.
- backend/src/main/java/com/sanbong/service/CustomerCareService.java.
- backend/src/main/java/com/sanbong/repository/DatSanRepository.java, CustomerCareRepository.java, KhachHangRepository.java.
- backend/src/test/java/com/sanbong/CustomerHistoryPagingTest.java (mới).
- backend/scripts/customer-history-browser.js (mới), customer-completion-browser.js (cập nhật kiểm tra bất đồng bộ).

## Bằng chứng

exports/customer-history-build.log, customer-history-package.log, customer-history-test-summary.json, customer-history-browser-preview.log, customer-history-account-regression.log, customer-history-navigation-preview.log. Metadata bản chính ở exports/customer-history-deployment.json, backup ở exports/backend-before-customer-history-20261016.jar. Kết quả kiểm tra bản chính và fixture sẽ ghi sau cập nhật.

## Còn lại

1. Kiểm thử đặt trùng/đăng ký/thanh toán đồng thời với fixture có cơ chế commit/cleanup được xem xét riêng; không dùng kiểm tra UI response chậm để thay cho kiểm thử concurrency nghiệp vụ.
2. Quên mật khẩu email/SMS cần kênh gửi, xác minh liên hệ và token dùng một lần có thời hạn; hiện chưa có cấu hình này. Không dùng email/PIN của cổng Cloudflare làm cơ chế đặt lại mật khẩu ứng dụng.
3. Ghi nhớ đăng nhập dài hạn cần quản lý/revoke token phù hợp; hiện vẫn phiên 30 phút, không lưu mật khẩu phía browser.
4. Ngân hàng thật, offline/CDN, điện thoại và mạng ngoài thực tế chưa được chứng nhận. Không tự sửa dữ liệu cá nhân cũ bị sai encoding.

## Xác nhận bản chính — 17/10/2026
Bản chính 8082 đã cập nhật, hash JAR khớp stage và có backup. Kiểm tra browser trên bản chính đạt cho lịch sử mới và 25 mục điều hướng; log ở customer-history-browser-live.log và customer-history-navigation-live.log. Lượt kiểm tra ngay sau start gặp ECONNREFUSED do server chưa mở cổng; đã chờ /api/health=200 rồi chạy lại đạt. Năm truy vấn fixture trong customer-history-fixtures.txt đều bằng 0. Listener wildcard vẫn giữ cấu hình LAN; không thay thế xác nhận từ thiết bị thứ hai. Server PID/hash ghi trong customer-history-deployment.json.

