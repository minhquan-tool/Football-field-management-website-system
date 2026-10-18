# Kiểm tra bốn vai trò và lỗi điều hướng ngày 15/10/2026

## Phát hiện và xử lý

1. **Menu khách hàng đổi ngang thành dọc khi mở Lịch đặt/Hóa đơn — đã sửa.** Trang chủ dùng top navigation, trang lịch dùng template sidebar. role-navigation trước đây chọn host theo thẻ aside/nav của trang, vì vậy cùng tài khoản nhưng bố cục đổi theo HTML. Ca tái hiện `navigation-consistency-check.js` đã chạy trên bản cũ và báo `NAV_LAYOUT_CHANGED`. Kết quả trước/sau ở `exports/navigation-before.log`, `navigation-after.log`.
2. **Bố cục của nhân viên/quản lý cũng không đồng nhất giữa các trang — đã sửa.** Các trang phản hồi, cấu hình, sao lưu trước đó có menu trên, trong khi dashboard/lịch dùng sidebar. Khung trang nay lấy từ vai trò: khách top navigation; nhân viên sân, kế toán, quản lý sidebar. Mobile có nút mở menu tương ứng, Escape và Đăng xuất. Nội dung chính, form và overlay được giữ nguyên DOM để bảo toàn handler nghiệp vụ. Nút Thêm sân từ header cũ được chuyển vào vùng hành động trong nội dung và được kiểm tra mở/đóng form.
3. **Tài khoản và Nhật ký có thể cùng active — đã sửa.** Xét thêm hash `#logs`, chỉ một mục được chọn; cập nhật cả khi hash đổi trong cùng trang.
4. **Tên khách demo sai dấu trong database — còn tồn tại.** Đối chiếu chỉ đọc tên của tài khoản `khachhang`: chuỗi UTF-16 bắt đầu `56000201B500` tương ứng `VĂµ`, trong khi seed ghi `Võ`. Đây là dữ liệu đã lưu, không phải CSS/font. Không tự thay toàn bộ dữ liệu hoặc chạy lại seed. Khách có thể sửa tên đúng tại Thông tin cá nhân; cần đối chiếu tên trước khi sửa những hồ sơ khác.

## Phạm vi kiểm tra logic

Chạy lại 12 lớp, **112 test, 0 failure, 0 error, 0 skipped**, Maven/JDK 24 build thành công: `exports/navigation-build-test.log`. Các integration test được chọn đều rollback transaction; đã đọc marker `SanBongEnvironment=dev` và bật opt-in. Không chạy fixture trên DB internal. Không đổi schema, quyền hoặc mật khẩu.

| Vai trò | Các luồng có bằng chứng kiểm tra |
|---|---|
| Khách hàng | Giữ lựa chọn qua đăng nhập, tra cứu/đặt, lịch sử, hồ sơ, phản hồi/đánh giá, sở hữu dữ liệu, yêu cầu thanh toán/hủy, chi tiết hóa đơn và in phiếu. |
| Nhân viên sân | Lịch, xác nhận/đổi lịch theo quy tắc, nhận/trả sân, dịch vụ, trạng thái sân, phản hồi; bị chặn chức năng kế toán/quản trị ngoài quyền. |
| Kế toán | Xem hóa đơn, xác minh thu, hoàn và retry idempotency, báo cáo/đối soát; bị chặn quản lý sân và hồ sơ khách. |
| Quản lý | Quản lý sân/giá/dịch vụ/khuyến mãi theo quyền, menu tài khoản/quyền/nhật ký, không được giả làm khách. Backup/restore vẫn là hướng dẫn cho DBA. |

Những bảo vệ snapshot giá, booking legacy, San → DatSan lock, trigger dịch vụ, điều kiện đổi lịch và chính sách hủy/hoàn được giữ. Tập test này không phải toàn bộ suite stress/concurrency hoặc tất cả 40 use case đã hoàn thành.

## Kiểm tra trình duyệt

- `role-navigation-audit.js`: bấm chuyển 25 mục menu thực tế; giữ hướng menu theo vai trò ở 1440/1024/768px; ở 390px mở menu, Escape và logout. Chỉ một active và đúng href/hash. Kiểm tra còn main, không tràn ngang, dữ liệu quản lý sân tải được, quản lý mở/đóng form Thêm sân, nhân viên không thấy nút này.
- `role-workflow-browser-check.js`: hồi quy bốn vai trò, 25 liên kết, lỗi sai quyền/dữ liệu, CSV, CSS in, báo cáo đối soát và trang tài chính.
- `experience-browser-check.js`: giữ sân/ngày/giờ qua đăng ký/đăng nhập, lọc lịch sử hai lượt hiện có, in đúng phiếu và dọn DOM sau in, nhân viên về đúng nơi.
- Browser không tạo booking, thu/hoàn hay sửa hồ sơ. Audit đăng nhập/đăng xuất thật được giữ.
- Kết quả preview ở `exports/navigation-audit.log`, `navigation-role-regression.log`, `navigation-experience-regression.log`.

## File mã nguồn thay đổi

- `frontend/js/role-navigation.js`: khung theo vai trò, giữ nội dung/nút nghiệp vụ, active theo hash.
- `frontend/js/auth.js`: khởi tạo menu mobile sau khi khung theo vai trò đã dựng xong.
- `frontend/css/fc-ute.css`: bố cục top/sidebar, responsive và CSS in phù hợp khung chung.
- Mới: `backend/scripts/navigation-consistency-check.js`, `role-navigation-audit.js` để bắt đúng lỗi đổi hướng menu và mất nút nghiệp vụ.

## Bản chạy đã xác minh

Đã cập nhật JAR và kiểm tra trực tiếp tại `http://127.0.0.1:8082/api/`. Cả ca tái hiện lỗi menu và kiểm tra 25 mục của bốn vai trò đều PASS; không có page error/API GET lỗi. Bằng chứng: `exports/navigation-live-repro.log`, `navigation-live-results.log`, `navigation-deployment.json`. Kiểm tra chọn đúng active/hash và nút Thêm sân cũng đạt trên bản live. Server preview 8084 và Playwright đã đóng; chỉ bản chính 8082 được giữ chạy. Bản trước nằm tại `exports/backend-before-navigation-fix-20261015.jar`. Tổng test backend trong `exports/navigation-test-summary.json`; truy vấn fixture sân còn 0 trong `exports/navigation-fixture-verification.txt`.

## Phần cần theo dõi

Ngoài dữ liệu tên demo cần đối chiếu, những giới hạn đã ghi trong báo cáo trước vẫn giữ: xóa loại sân chưa dùng, tự backup/restore từ web, đổi sang sân khác sau khi có tài chính, tích hợp ngân hàng, LAN và kiểm tra thiết bị thật. Không biến các giới hạn đó thành thông báo hoàn thành toàn bộ dự án.
