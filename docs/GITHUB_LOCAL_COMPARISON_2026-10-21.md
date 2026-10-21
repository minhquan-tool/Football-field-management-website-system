# Đối chiếu GitHub và source trong máy — 21/10/2026

Repository: https://github.com/minhquan-tool/Football-field-management-website-system
Nhánh main từ git ls-remote: 8cb0dd32bb783a1b9178efd2bb944262769a1b84; HEAD local trùng commit này.

Phạm vi: so sánh nội dung file source với main; không kiểm chứng database hoặc toàn bộ hành vi runtime. Không bao gồm nội dung file bị gitignore (secrets, JAR, backup, logs, exports). Không commit/push.

## Kết quả
- 87 file đã có trên GitHub nhưng nội dung local thay đổi.
- 36 file mới trong máy, chưa có trên main.
- Không có file tracked bị xóa trong máy. Không phát hiện commit main mới hơn HEAD.

## Các phần local mới hoặc cập nhật so với GitHub

| Phần | Khác biệt local |
|---|---|
| Yêu cầu hủy | Thêm controller/service/repository, UI, bảng và migration quyền; khách gửi yêu cầu, kế toán/admin duyệt/từ chối; giữ tỷ lệ tại thời điểm gửi. GitHub có luồng hủy cũ, chưa có luồng yêu cầu duyệt này. |
| Hóa đơn kế toán | Thêm API danh sách tìm kiếm/lọc/phân trang, giao diện workspace mới. GitHub đã có nghiệp vụ hóa đơn, chưa có bản danh sách mới này. |
| Hoàn tiền kế toán | Thêm trang Hoan_tien_KT.html và API danh sách hoàn; tích hợp hàng đợi yêu cầu hủy. GitHub đã có nghiệp vụ hoàn tiền cũ. |
| Thanh toán và VietQR | Thêm trang Thanh_toan_VietQR_KT.html; QR theo số tiền và nội dung qua img.vietqr.io thay ảnh QR local; mở quyền tra QR cho kế toán/admin. Không có webhook ngân hàng mới. |
| Cọc 40% | Backend thêm ReservationPaymentAmounts và kiểm tra số tiền theo phương án cọc 40%/trả đủ; DTO và giao diện có cập nhật. |
| Điều phối sân | Thêm các tab chờ nhận/đang đá/đã trả/đã hủy, dịch vụ trong dòng, nhận sân trực tiếp và tự chuyển tab. API nhận/trả sân đã có trên GitHub. |
| Xác nhận muộn | Cho xác nhận trước giờ kết thúc thay vì chỉ trước giờ bắt đầu. |
| Lịch sân | Bổ sung chế độ sân × giờ trong ngày, lọc loại sân; giữ chế độ tuần. |
| URL và API | Thêm PageController, ApiRoutesConfig, route map; URL /trang-chu, /dang-nhap, /dieu-phoi-san...; API giữ /api, cập nhật security/menu/redirect/tests. |
| Trang công khai | Thêm API và vùng khuyến mãi công khai; chọn giờ/phút với nhãn sáng/chiều/tối. GitHub đã có tra cứu sân công khai. |
| Giao diện các vai trò | Thêm CSS cho khách, nhân viên, admin, kế toán; sửa trang chủ khách và các liên kết. |
| Chỉnh sửa theo ảnh | Bỏ ghim cột thao tác bảng hóa đơn, tăng rộng trạng thái; bỏ dòng Chưa chốt/Đã chốt; form đăng ký bỏ câu tối đa 72 byte UTF-8 (validation backend vẫn giữ). |
| Test và tài liệu | Thêm các test accounting/cancellation/payment/late confirmation/public promotion, browser check nhận sân; sửa test để theo route và constructor mới; thêm tài liệu hủy, URL và xác nhận muộn. |

## Phần chỉ có trên GitHub mà máy thiếu

Không có file tracked bị xóa; main và HEAD cùng commit. Một số cách làm cũ đã được thay thế trong local (ảnh QR local, URL .html/context cũ, giới hạn xác nhận trước giờ bắt đầu), đây là thay đổi cách triển khai, không phải file bị thiếu.

## Danh sách file mới (chỉ có local tại thời điểm đối chiếu)

| File |
|---|
| `backend/scripts/check-in-dispatch-check.cjs` |
| `backend/src/main/java/com/sanbong/config/ApiRoutesConfig.java` |
| `backend/src/main/java/com/sanbong/controller/CancellationRequestController.java` |
| `backend/src/main/java/com/sanbong/controller/PageController.java` |
| `backend/src/main/java/com/sanbong/controller/PublicPromotionController.java` |
| `backend/src/main/java/com/sanbong/repository/CancellationRequestRepository.java` |
| `backend/src/main/java/com/sanbong/service/CancellationRequestService.java` |
| `backend/src/main/java/com/sanbong/service/ReservationPaymentAmounts.java` |
| `backend/src/test/java/com/sanbong/AccountingReadModelTest.java` |
| `backend/src/test/java/com/sanbong/CancellationRequestTest.java` |
| `backend/src/test/java/com/sanbong/CustomerPaymentValidationTest.java` |
| `backend/src/test/java/com/sanbong/LateBookingConfirmationTest.java` |
| `backend/src/test/java/com/sanbong/PublicPromotionControllerTest.java` |
| `backend/src/test/java/com/sanbong/ReservationPaymentAmountsTest.java` |
| `database/migrations/CancellationRequests_20261021.sql` |
| `database/migrations/CancellationRequests_20261021_PROPOSAL.sql` |
| `database/migrations/CancellationRequests_20261021_Permissions.sql` |
| `docs/CANCELLATION-REQUESTS.md` |
| `docs/CLEAN-URLS.md` |
| `docs/LATE_CONFIRMATION_2026-10-21.md` |
| `docs/page-route-map.json` |
| `frontend/Hoan_tien_KT.html` |
| `frontend/Thanh_toan_VietQR_KT.html` |
| `frontend/css/accounting-pages.css` |
| `frontend/css/accounting-workspace.css` |
| `frontend/css/admin-workspace.css` |
| `frontend/css/cancellation-requests.css` |
| `frontend/css/customer-home.css` |
| `frontend/css/customer-pages.css` |
| `frontend/css/public-header.css` |
| `frontend/css/public-layout.css` |
| `frontend/css/staff-dashboard.css` |
| `frontend/css/staff-workspace.css` |
| `frontend/js/accounting-workspace.js` |
| `frontend/js/cancellation-requests.js` |
| `frontend/js/public-promotions.js` |

## Danh sách file đã sửa so với GitHub

| File |
|---|
| `.env.example` |
| `.env.test.example` |
| `README.md` |
| `backend/src/main/java/com/sanbong/config/LoginRateLimitFilter.java` |
| `backend/src/main/java/com/sanbong/config/SecurityConfig.java` |
| `backend/src/main/java/com/sanbong/controller/FinanceController.java` |
| `backend/src/main/java/com/sanbong/controller/HomeController.java` |
| `backend/src/main/java/com/sanbong/dto/PaymentRequest.java` |
| `backend/src/main/java/com/sanbong/repository/FinanceRepository.java` |
| `backend/src/main/java/com/sanbong/service/BankTransferService.java` |
| `backend/src/main/java/com/sanbong/service/BookingService.java` |
| `backend/src/main/java/com/sanbong/service/FinanceService.java` |
| `backend/src/main/java/com/sanbong/service/OperationsService.java` |
| `backend/src/main/resources/application.yml` |
| `backend/src/test/java/com/sanbong/AccountantRoleAuditTest.java` |
| `backend/src/test/java/com/sanbong/AdminRoleAuditTest.java` |
| `backend/src/test/java/com/sanbong/AuthenticationTest.java` |
| `backend/src/test/java/com/sanbong/BankTransferServiceTest.java` |
| `backend/src/test/java/com/sanbong/BookingConcurrencyTest.java` |
| `backend/src/test/java/com/sanbong/BookingManagementTest.java` |
| `backend/src/test/java/com/sanbong/CheckoutSnapshotTest.java` |
| `backend/src/test/java/com/sanbong/CustomerCompletionTest.java` |
| `backend/src/test/java/com/sanbong/CustomerHistoryPagingTest.java` |
| `backend/src/test/java/com/sanbong/CustomerJourneyIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/CustomerPromotionTest.java` |
| `backend/src/test/java/com/sanbong/FinanceIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/FreeTimeBookingTest.java` |
| `backend/src/test/java/com/sanbong/FutureBookingAvailabilityTest.java` |
| `backend/src/test/java/com/sanbong/LocalAssetsHttpTest.java` |
| `backend/src/test/java/com/sanbong/LoginRateLimitHttpTest.java` |
| `backend/src/test/java/com/sanbong/NormalizationIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/OperationsConcurrencyTest.java` |
| `backend/src/test/java/com/sanbong/OperationsManagementTest.java` |
| `backend/src/test/java/com/sanbong/PasswordPolicyIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/PaymentQrFlowTest.java` |
| `backend/src/test/java/com/sanbong/Phase6IntegrationTest.java` |
| `backend/src/test/java/com/sanbong/PitchManagementTest.java` |
| `backend/src/test/java/com/sanbong/PublicHomeRoutingTest.java` |
| `backend/src/test/java/com/sanbong/RescheduleTest.java` |
| `backend/src/test/java/com/sanbong/RoleAuditSupport.java` |
| `backend/src/test/java/com/sanbong/RoleBoundaryTest.java` |
| `backend/src/test/java/com/sanbong/RoleWorkflowIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/RubricSqlIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/SecurityUpgradeIntegrationTest.java` |
| `backend/src/test/java/com/sanbong/ServiceSalesTest.java` |
| `backend/src/test/java/com/sanbong/StaffRoleAuditTest.java` |
| `backend/src/test/java/com/sanbong/WalkInCustomerTest.java` |
| `backend/src/test/java/com/sanbong/WeeklyScheduleTest.java` |
| `deploy.env.example` |
| `frontend/Bao_cao.html` |
| `frontend/Dang_ky.html` |
| `frontend/Dang_nhap.html` |
| `frontend/Dat_san_tai_quay.html` |
| `frontend/Doanh_thu.html` |
| `frontend/Lich_da_bong.html` |
| `frontend/Man_hinh_Khuyen_mai_KH.html` |
| `frontend/Man_hinh_LS&ĐG_KH.html` |
| `frontend/Man_hinh_chinh.html` |
| `frontend/Man_hinh_chinh_Dat_san_KH.html` |
| `frontend/Man_hinh_chinh_KH.html` |
| `frontend/Man_hinh_chinh_NVKH.html` |
| `frontend/Man_hinh_chinh_NVKT.html` |
| `frontend/Man_hinh_chinh_TK&PQ_HT.html` |
| `frontend/Quan_ly_lich_dat_san.html` |
| `frontend/Quan_ly_san.html` |
| `frontend/Tai_khoan_KH.html` |
| `frontend/Trang_chu.html` |
| `frontend/css/experience.css` |
| `frontend/css/fc-ute.css` |
| `frontend/js/admin.js` |
| `frontend/js/auth.js` |
| `frontend/js/bookings.js` |
| `frontend/js/configuration.js` |
| `frontend/js/customer-care.js` |
| `frontend/js/customer-home.js` |
| `frontend/js/dashboard.js` |
| `frontend/js/finance.js` |
| `frontend/js/operations.js` |
| `frontend/js/public-home.js` |
| `frontend/js/reports.js` |
| `frontend/js/role-navigation.js` |
| `frontend/js/staff-operations.js` |
| `frontend/js/ui.js` |
| `frontend/js/weekly-schedule.js` |
| `scripts/deploy-ui-redesign.ps1` |
| `scripts/manage-demo-tunnel.ps1` |
| `scripts/server.ps1` |
