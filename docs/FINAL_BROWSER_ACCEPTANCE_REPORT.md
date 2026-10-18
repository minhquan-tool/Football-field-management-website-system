# FINAL BROWSER ACCEPTANCE REPORT

Ngày: 09/10/2026. Nghiệm thu Chrome thật bằng **Playwright CLI**, session riêng `final-accept`, trên JAR Fix04. Không sửa source, không deploy/restart, không truy cập port8080/database internal. Server DEV vẫn chạy sau nghiệm thu.

## Safety và phương pháp

Đã đọc AGENTS.md, skill playwright-cli và báo cáo Fix01–04. Health `http://127.0.0.1:8082/api/health` trả database/statusUP. Browser login admin bằng form rồi kiểm tra GET `/admin/test-safety`: databaseName=QuanLySanBong, fixtureTestsAllowed=true. Database marker dev được kiểm tra lại trong cleanup.

Mọi mutation nghiệp vụ đều qua **click/fill/form/navigation trên browser**: đăng ký, tạo sân/khách, đặt/xác nhận/nhận/trả sân, dịch vụ và thanh toán. Không gọi REST trực tiếp để thay thế workflow; HTTP dùng cho safety/health, SQL READ chỉ để verify. Không chỉnh giờ/DB để ép check-in. Route delay700ms giữ request thật đi đến backend, chỉ phục vụ kiểm tra loading/stale response.

Desktop1366×768; mobile390×844. Screenshots đã xem trực tiếp tại các checkpoint quan trọng. Không xuất cookie/storage state, HAR, trace, password, SQL credentials hoặc private env. Password test mới chỉ sinh/giữ trong bộ nhớ browser automation, không đưa vào manifest/report. Chỉ browser session của lượt test được đóng; server DEV giữ chạy.

## PASS/FAIL matrix

| Hạng mục | Kết quả | Bằng chứng/phạm vi |
|---|---|---|
| Customer | PASS | Register/login đúng role, availability, booking, lịch/chi tiết, pending transfer; không thấy menu đặc quyền |
| Staff | PASS | Walk-in create/select/book/confirm; check-in thật; thêm dịch vụ; checkout |
| Accountant | PASS | Tra cứu hóa đơn, cash từng phần, reload balance, transfer phần còn lại, confirm pending; staff/admin page403 |
| Admin | PASS | Dashboard, create/detail/edit pitch fixture, maintenance/reopen; account list, permission matrix/select role và report chỉ đọc |
| F01 | PASS | Checkout chốt188.200, chưa tự thu; service disabled/promotion form hidden; thu sau checkout được; SQL tiền/revenue không đổi |
| F02 | PASS | Browser chặn password quá ngắn; password hợp lệ đăng ký/login thành công; không reset account cũ |
| F03 | PASS | Khi sân đang dùng, browser vẫn đặt ngày+30; overlap excluded; maintenance excluded |
| F04 | PASS | Khách cũ readonly, create mới, loading/disable, double-click, race hai tab/409 recovery, stale response và input sai |
| Desktop | PASS | Các trang chính và modal dùng được ở1366×768 |
| Mobile | PASS | Login/register/customer booking/staff counter/finance/admin dùng được ở390×844; không overflow toàn trang; bảng admin có scroll ngang hợp lệ; có cosmetic issue BA05 |
| Console | FAIL | Asset404 và external image failures; không uncaught/pageerror; warning CDN; xem BA01/BA02 |
| Network | FAIL | Favicon404 và ảnh ngoài domain ERR_BLOCKED_BY_ORB; không5xx/CORS/CSRF failure; negative400/403/409 xử lý đúng |
| SQL consistency | PASS | Mỗi phone1customer; liên kết đúngMaKH; overlap0/orphan0; invoice/payment đúng; F01 bất biến; cleanup scoped0fixture còn lại |

Không có mục bắt buộc bị NOT EXECUTABLE do time window: booking hiện tại16:59–17:59 được tạo/xác nhận/nhận trước giờ chơi theo rule30phút. Không test toàn bộ refund/role mutation/password reset trong vòng này; chỉ đọc account/permission để tránh thay đổi account thực. Mutation tài chính/dịch vụ khác thuộc regression212 test trước, không được coi là đã tái chạy qua browser.

## Workflow và bằng chứng

Customer fixture `BFA1791539387703` được đăng ký bằng browser, không dùng khách thực. Booking `DS89815a48` ngày08/11/2026 08:00–09:00; lịch/chi tiết đúng khách; tạo yêu cầu chuyển khoản10.000 chờ xử lý. Khi tìm lại cùng khoảng, sân fixture không còn lựa chọn. Không xuất password.

Staff tạo khách vãng lai và đặt `DS6332cb1b` ngày09/10/2026 16:59–17:59. Form create giữ nguyên trang, tự chọn hồ sơ. Khi delay request, hai nút disabled. Double-click không tạo thêm row. Hai tab cùng SĐT: một hiện tạo thành công, một hiện “Khách hàng với số điện thoại này đã tồn tại. Đã chọn hồ sơ hiện có.”; tab thua không báo tạo mới thành công. Đổi SĐT lúc create đang xử lý khiến response cũ không điền/chọn sai khách.

Staff confirm/check-in qua lịch, thêm Coca LOC_6 giá58.200 rồi checkout. Khi sân đang dùng, tab khác vẫn đặt `DS64a9c035` ngày08/11/2026 10:00–11:00 trên cùng sân — chứng minh F03 trực tiếp qua browser.

Snapshot sau checkout: DonGia130.000; TienSan130.000; TienDichVu58.200; TienGiam0; TongTien188.200. Invoice DaChot=true, DaThanhToan=0. Service button disabled; promotion/invoice form hidden. Accountant thu50.000 tiền mặt; reload còn138.200; thu phần còn lại chuyển khoản; trạng thái hoàn tất. Sau đó xác nhận10.000 pending của customer. Không fake payment qua SQL.

Admin thêm/sửa sân fixture, mở chi tiết và bảo trì/mở lại bằng UI. Sân bảo trì fixture riêng không xuất hiện trong availability customer. Account list/permission matrix theo role và báo cáo được tải; không bấm reset password/lưu role/lưu quyền trên account thực.

Bằng chứng chính trong `run/final-browser/`:

- `browser-result.json`: kết quả assertions, manifest fixture, layout, console/network metadata đã giới hạn field.
- `screenshots/staff-create-loading.png`, `staff-race-tab1.png`, `staff-race-tab2.png`, `staff-stale-response.png`: F04.
- `screenshots/f03-used-pitch-future-available.png`: F03.
- `screenshots/f01-checkout-sealed.png`, `f01-invoice-before-payment.png`, `accountant-paid.png`, `accountant-confirmed-pending.png`: finance.
- `screenshots/login-mobile.png`, `register-mobile.png`, `customer-booking-mobile-final.png`, `staff-counter-mobile.png`, `accountant-mobile.png`, `admin-management-mobile.png`: responsive.
- `console/events.json`, `console/initial.log`, `network/events.json`: không chứa request bodies/headers/cookies/CSRF.

## Issues phát hiện — không auto-fix

### BA01 — LOW — favicon404

Role/page: trang login ban đầu. Steps: mở login trong Chrome mới. Expected: favicon tải hoặc không yêu cầu file thiếu. Actual: `/favicon.ico` trả404; console resource error. Không chặn đăng nhập. Evidence: `console/initial.log`, screenshot `login-desktop.png`. Không source fix.

### BA02 — LOW — ảnh avatar ngoài domain bị chặn

Role/page: customer/staff/admin và các trang dùng avatar. Steps: login/mở dashboard hoặc booking. Expected: ảnh tải hoặc fallback rõ. Actual: ảnh `hcmute.edu.vn/.../PVH-7.jpg` bị `net::ERR_BLOCKED_BY_ORB` (7 request failures trong capture); icon fallback vẫn hiện, workflow dùng được. Evidence: `network/events.json`, screenshot `customer-home.png`/`staff-home.png`. Không kết luận lỗi API/CORS backend.

### BA03 — LOW — tên khách seed sai encoding

Role/page: admin account list, account khách seed. Steps: mở quản lý tài khoản. Expected: tên tiếng Việt đúng. Actual: tên hiển thị `VĂµ Minh QuĂ¢n`. SQL READ KhachHang KH01 cũng trả cùng chuỗi, nên đây là dữ liệu seed đã lỗi, không chứng cứ browser sai font/charset cho dữ liệu mới. Evidence: screenshot `admin-accounts-desktop.png`/`admin-management-mobile.png`; SQL read trong lượt nghiệm thu. Không sửa seed/history.

### BA04 — LOW — ngày/giờ mặc định quá khứ khi mở form buổi chiều

Role/page: customer booking/staff counter. Steps: mở form lúc16h–17h với ngày hôm nay. Expected: default hợp lệ hoặc hướng dẫn chọn giờ trước khi tự query. Actual: default08:00–09:00 gây availability400 và thông báo giờ bắt đầu phải trong tương lai; sau chọn giờ hợp lệ form hoạt động. 9 availability400 còn bao gồm các trạng thái trung gian khi thay start/end; backend validation đúng, không giả thành công. Evidence: `network/events.json`, `screenshots/staff-new-customer-form.png`. Không bypass guard hoặc auto-fix UX.

### BA05 — LOW — header staff mobile chật/cắt subtitle

Role/page: staff counter390×844. Steps: mở trang quầy mobile. Expected: tiêu đề/subtitle nằm gọn trong header. Actual: tiêu đề wrap hai dòng, subtitle sát/cắt ở đáy header cố định; các control form vẫn thao tác được. Evidence: `screenshots/staff-counter-mobile.png`. Bảng admin811px trong vùng340px có overflow-x:auto, là scroll ngang hợp lệ, không ghi nhầm thành lỗi overflow toàn trang. Không cosmetic fix.

Warning Tailwind CDN xuất hiện23 lần; đây là carry-over dependency/asset deployment, không đổi thư viện trong acceptance. Negative tests phone400, race409, accountant privileged navigation403 không tính là bug. Capture không có pageerror/uncaught exception, HTTP5xx, CSRF failure hoặc backend CORS failure.

## SQL verification và cleanup

READ trực tiếp DEV sau browser:

- Bốn SĐT fixture mỗi số đúng1KhachHang; customer registration có account riêng, ba walk-in/race/stale profile không tạo account.
- Ba booking đúng khách và khoảng thời gian; overlap0, orphan0.
- Staff invoice188.200, đã trả188.200, DaChot1; payment cash50.000 + transfer138.200 đều thành công.
- Customer invoice90.000, thực thu10.000, chưa chốt; pending đã được accountant confirm đúng một giao dịch.
- `sql-before-payment.txt` và `sql-after-payment.txt` giống nhau cho DatSan snapshot và SUM(DoanhThu)=188.200. Tiền thực thu thay đổi, giá trị gốc/revenue không đổi.

Đóng riêng browser acceptance rồi cleanup bằng `run/final-browser/cleanup.sql`: bắt đúng database QuanLySanBong + markerdev, kiểm tên/phone/ID và dependency, từ chối booking/profile ngoài manifest hoặc visit đang mở. Transaction xóa chỉ3booking,2pitch,4customer,1account và finance/audit liên quan fixture đã tạo bằng browser. Không cleanup dữ liệu khác/internal. `cleanup-verify.txt` trả bốn số0 cho customer, booking, pitch, account fixture. DEV health vẫnUP sau cleanup; server giữ chạy để người dùng tiếp tục sử dụng.

Source so với build Fix04: **0 file backend/src/html thay đổi**. Không chạy lại Maven vì không sửa code; baseline212/212 vẫn là kết quả build Fix04 trước acceptance, không gọi đó là test run mới. Không làm F15/F16/F21 và không tuyên bố production-ready.

## Final verdict

**BROWSER ACCEPTANCE PASS WITH ISSUES**

Các workflow nghiệp vụ được nghiệm thu qua browser và SQL; những issue ghi trên hiện không chặn việc hoàn thành flow. Chỉ ghi nhận, chưa sửa và chưa deploy internal.
