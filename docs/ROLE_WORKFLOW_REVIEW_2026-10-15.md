# Kết quả sửa chức năng theo bốn vai trò

Đối chiếu với `Nhom19_QuanLySanBong_14.10.docx`: 12 use case khách hàng, 9 nhân viên sân, 6 kế toán và 13 quản trị hệ thống. Báo cáo này phân biệt code đã sửa, chức năng được giữ từ các phase trước, kết quả kiểm thử và giới hạn còn lại. File Word nguồn được giữ nguyên.

## Chức năng theo vai trò

| Nhóm | Kết quả |
|---|---|
| Khách hàng | Menu riêng; hồ sơ cá nhân; tra cứu/đặt sân; lịch và hóa đơn đúng booking; lịch sử toàn bộ của tài khoản; đánh giá sau khi trả sân, đủ tiêu chí và mỗi lượt một lần; gửi/theo dõi phản hồi; khuyến mãi phù hợp chính sách hiện tại. Yêu cầu thanh toán chờ nhân viên xác minh, không tự nhận là đã thu tiền. |
| Nhân viên sân | Menu riêng; lịch; đặt tại quầy; trạng thái sân; nhận/trả sân và dịch vụ; tiếp nhận/đóng phản hồi; báo cáo sử dụng sân. Đổi ngày/giờ trên cùng sân cho lượt đặt giờ tự do chưa nhận sân, chưa có hóa đơn/giao dịch, chưa đến giờ chơi; kiểm tra trùng, tính lại giá, yêu cầu xác nhận lại và ghi nhật ký trước/sau. |
| Kế toán | Giao dịch/hóa đơn/thu/hoàn; lọc giao dịch theo ngày; báo cáo doanh thu, thực nhận và phương thức; đối soát sổ theo lượt đặt; báo cáo tiền hoàn; in và xuất CSV. Chỉ kế toán/quản trị xác nhận hoàn tiền. |
| Quản trị | Giữ quản lý nhân viên/tài khoản/quyền/nhật ký; danh mục sân; thêm/sửa loại sân; giá theo ca; khung giờ chưa sử dụng; thêm bảng giá cũ không chồng hiệu lực; khuyến mãi phần trăm, bật/ngừng áp dụng mà không thay chính sách cũ; tạo dịch vụ mới và sửa/ngừng dịch vụ hiện có, giữ SKU/giá lịch sử. |

## Những lỗi đã sửa

1. Menu dùng lẫn giữa các nhóm, nút bị khóa dù đã có API, liên kết sang trang không đúng chức năng. `role-navigation.js` tạo menu từ vai trò và quyền hiện tại; backend vẫn quyết định quyền truy cập.
2. Nhập URL của nhóm khác trả JSON lỗi trực tiếp: HTML được đưa về trang của tài khoản kèm thông báo; API vẫn trả 401/403 đúng nghĩa.
3. Nhân viên sân có thể gọi API thêm/sửa danh mục sân: giới hạn các thao tác này cho quản trị, giữ quyền trạng thái vận hành của nhân viên.
4. Hồ sơ cá nhân trả entity JPA làm lỗi xuất JSON: chuyển sang DTO, không trả proxy hoặc ghi chú nội bộ.
5. Lịch sử/đánh giá và phản hồi chưa có luồng lưu thật: bổ sung Controller → Service → Repository, validation, kiểm tra sở hữu và transaction/audit.
6. Phản hồi đã đóng bị báo lỗi database chung chung: kiểm tra nghiệp vụ ở Service, trả xung đột đúng và không ghi đè lịch sử.
7. Trang đặt sân mặc định 08:00 hôm nay gây lỗi khi mở buổi chiều: dùng mặc định chung từ server, trong tương lai và trong 07:00–22:00, chuyển sang ngày sau khi đóng cửa.
8. Thẻ kế toán gọi tổng tiền thu toàn bộ là doanh thu hôm nay: sửa đúng tên và phạm vi; doanh thu theo ngày trả sân nằm trong báo cáo riêng.
9. Bộ lọc ngày giao dịch bị vô hiệu hóa: bổ sung ngày thanh toán trong API đọc, nối bộ lọc và nút xem hóa đơn có thể dùng bàn phím.
10. Menu mobile làm rộng trang hoặc bị nền tối che: chuyển sidebar thành lớp nổi, thêm nút mở ở các trang còn thiếu và kiểm thử bấm liên kết thật.
11. Nút xuất Excel chưa có file Excel: ghi đúng CSV/In báo cáo. CSV tiền hoàn ghi rõ chỉ xuất trang đang xem; nút in/xuất bị khóa khi đang tải hoặc lỗi. Bố cục in bỏ menu và không cắt bảng theo chiều cao màn hình.
12. Đối soát chỉ có đoạn mô tả: bổ sung báo cáo đọc hóa đơn, giao dịch thành công, hoàn thực tế và sổ thực nhận. Hiển thị chênh lệch, không nhầm nợ hoặc hoàn đang chờ với sai lệch. Lọc theo ngày chơi rồi kiểm tra toàn bộ giao dịch của mỗi booking, tránh so thu theo ngày với doanh thu theo ngày khác nhau.

## Ranh giới nghiệp vụ được giữ

- Booking mới tính theo phút và giá tại giờ bắt đầu, 07:00–22:00; booking `GIA_KHUNG` giữ khung giờ và tiền cũ.
- Ghi booking/đổi lịch dùng khóa sân trước khóa booking. Dịch vụ/thu/hoàn giữ luồng transaction và khóa từ các phase trước.
- Không đổi lịch trực tiếp cho booking đã có hóa đơn/giao dịch; xử lý hủy/hoàn theo chính sách rồi tạo lượt mới khi cần.
- Tiền dịch vụ giữ trigger và snapshot; không sửa SKU, hóa đơn hoặc giá lịch sử để khớp dữ liệu mới.
- Đánh giá chỉ của khách sở hữu, booking đã sử dụng, đúng tiêu chí 1–5 và không lặp.
- Phản hồi đã đóng không được mở lại/ghi đè qua API mới.
- Không sửa khung giờ đã được booking hoặc bảng giá sử dụng; không ghi đè bảng giá cũ; không sửa chính sách khuyến mãi đã dùng. Có thể bật/ngừng khuyến mãi riêng mà giữ nguyên mức giảm và hiệu lực.
- Không xóa lịch sử, không đổi password người dùng, không đổi stack hoặc `ddl-auto=validate`.

## Quyền database đã được phê duyệt và áp dụng

Hai lần phê duyệt trực tiếp trong chat ngày 15/10/2026:

- `database/migrations/RoleWorkflows_20261015.sql`: quyền tối thiểu cho các bảng đánh giá/phản hồi/cấu hình hiện có; thêm hàng quyền CN06 cho VT02 nếu chưa tồn tại, không ghi đè quyền đã bị thu hồi.
- `database/migrations/RoleCatalogCreate_20261015.sql`: INSERT trên DichVu để tạo SKU mới.

Áp dụng trên `QuanLySanBong`, runtime user `SanBongApp`. Không thêm bảng/cột, không DROP/reset, không cấp sysadmin/db_owner, không cấp quyền xóa lịch sử hoặc quyền BACKUP/RESTORE cho tài khoản web.

## Kiểm thử và bằng chứng

- JDK 24 build/package.
- 112 testcase thuộc 12 lớp kiểm thử liên quan có kết quả cuối đạt, 0 failure/error, tổng hợp trong `exports/role-validation-summary.json`. Đây là tập kiểm thử chọn lọc từ nhiều lần chạy; không gọi là toàn bộ suite của dự án.
- Integration test dùng marker DEV và opt-in; tất cả dữ liệu thử nằm trong transaction rollback. Bao gồm hồ sơ/trùng liên hệ, đánh giá lặp, phản hồi đóng, đổi lịch, bảo vệ hóa đơn, cấu hình giá/khung giờ/khuyến mãi/SKU và thu–hủy–hoàn liên quan nhiều vai trò.
- Đối soát có kiểm thử số đúng và cố ý lệch số thu hóa đơn trong transaction thử để xác nhận cảnh báo.
- Playwright kiểm tra link và JavaScript trên mọi trang menu của bốn nhóm; request sai bị từ chối, không tạo nghiệp vụ thật. Kiểm tra desktop/mobile 390px, bấm liên kết menu mobile, tải CSV và CSS in.
- Kiểm thử UI tài chính dùng dữ liệu giả lập cho lọc ngày, lỗi tải lại sau ghi, chống đổi booking khi đang ghi và khóa idempotency theo booking.
- File log: `exports/role-release-final.log`, `exports/role-release-last-check.log`, `exports/role-browser-results.log`, `exports/role-finance-ui-results.log`; bản kiểm tra sau triển khai ghi riêng trong `exports/role-live-browser-results.log`.
- Screenshot và CSV trong exports chỉ là bằng chứng kiểm tra nội bộ; không thay báo cáo tài chính chính thức.

## Các file chính

Frontend: `js/role-navigation.js`, `js/auth.js`, `js/customer-care.js`, `js/configuration.js`, `js/bookings.js`, `js/customer-home.js`, `js/staff-operations.js`, `js/finance.js`, `js/reports.js`, `js/service-catalog.js`; các HTML nghiệp vụ dùng menu chung; trang hồ sơ, phản hồi, lịch sử, khuyến mãi, cấu hình và hướng dẫn sao lưu.

Backend: `CustomerCareController/Service/Repository`, các DTO tương ứng; `ConfigurationController/Service/Repository`; `BookingTimeDefaults`; thay đổi ở `BookingService`, `BookingController`, `BookingWorkflowRepository`, `PublicPitchService`, `SecurityConfig`, `PermissionController`, `PitchController`, `ServiceCatalogController`, `OperationsService/Repository`, `FinanceRepository`, `ReportController/Service/Repository`.

Tests: `RoleBoundaryTest`, `CustomerCareTest`, `RescheduleTest`, `RoleWorkflowIntegrationTest`, `BookingTimeDefaultsTest`; sửa kỳ vọng phân quyền trong `PitchManagementTest`. Scripts browser: `role-workflow-browser-check.js`, `finance-ui-regression.js` và fixture giả lập.

## Phần còn lại và giới hạn

| Mục | Tình trạng |
|---|---|
| UC-QT-05 xóa loại sân chưa sử dụng | Chưa có thao tác xóa vật lý. Đã có xem/thêm/sửa, không cấp DELETE. Nếu cần đủ biến thể này theo tài liệu phải bổ sung kiểm tra không có liên kết và duyệt riêng quyền DELETE tối thiểu. Loại đang có lịch sử không được xóa. |
| UC-QT-10/11 sao lưu/phục hồi trên giao diện | Có trang hướng dẫn và script quản trị hiện có; chưa có công việc BACKUP/RESTORE tự động từ web. Không cấp quyền phục hồi cho runtime; không restore đè database hiện tại. |
| Đổi sang sân khác hoặc đổi booking đã có tài chính | Chưa đổi trực tiếp; hiện chỉ đổi thời gian trên cùng sân, chưa có tài chính. Booking legacy giữ nguyên. Hủy/hoàn và tạo mới là luồng đang hỗ trợ. |
| Ngân hàng/đối soát sao kê | Chưa kết nối ngân hàng; thu/hoàn là nhân viên xác minh nội bộ. Báo cáo đối soát mới kiểm tra sổ nội bộ, không chứng minh tiền có trong tài khoản ngân hàng. |
| LAN/triển khai thực tế nhiều máy | Chưa làm trong đợt này; phải xác minh từ client thật và có cấu hình triển khai riêng theo AGENTS.md. |
| Độ phủ kiểm thử | Chưa chạy toàn bộ suite/concurrency trong đợt sửa này. Tập được chạy và giới hạn dữ liệu thử được ghi rõ ở trên. |

Các mục chưa làm không được trình bày là hoàn thành 100% toàn bộ tài liệu Word. Những bảo vệ giá cũ, chứng từ cũ và lịch sử không phải nút hỏng cần gỡ bỏ.

## Bản chạy

Trạng thái triển khai và hash JAR cuối được ghi trong `exports/role-deployment-result.json`. Bản chạy thông thường dùng `backend/target/san-bong-backend-1.0.0.jar`; chỉ thay JAR khi tiến trình cũ đã dừng, có bản sao lưu để quay lại. URL sử dụng sau cập nhật là `http://127.0.0.1:8082/api/`.

Đã triển khai và xác nhận trực tiếp trên cổng 8082 ngày 15/10/2026. Health ứng dụng/database đều UP; địa chỉ gốc mở trang chủ khách vãng lai. Browser kiểm tra 4 vai trò và tổng 25 liên kết menu: 6 khách hàng, 6 nhân viên sân, 2 kế toán, 11 quản trị; 0 page error và 0 API tải trang thất bại. Menu mobile đã kiểm tra bấm thực tế, không chỉ kiểm tra hiển thị. CSV, CSS in, đối soát và các request sai quyền/dữ liệu cũng đã được kiểm tra trên bản chạy này.

JAR được đối chiếu SHA-256 `5486790CAE9ECB0904B148A3588AE3D19F9B738AA45E4375FA8F571B6FBCB178`. Bản trước khi cập nhật được giữ tại `exports/backend-before-role-workflows-20261015.jar`. Các server preview 8084 và dữ liệu giả lập 8093 đã dừng sau kiểm tra; backend 8082 được giữ chạy nền.

Đã SELECT xác nhận không còn fixture hồ sơ, sân, dịch vụ, phản hồi, đánh giá hoặc khuyến mãi của các integration test, xem `exports/role-fixture-verification.txt`. Audit đăng nhập/đăng xuất của kiểm tra trình duyệt vẫn là nhật ký thật và được giữ, không cleanup lịch sử.
