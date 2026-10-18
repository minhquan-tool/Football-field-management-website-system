# Báo cáo nhóm nhân viên sân — 16/10/2026

## Kết quả backend

Tập được chọn có 58 ca. Lần đầu 55 đạt, 3 thất bại do Tạo khách tại quầy nhận điện thoại toàn dấu + hoặc + giữa số. Đã sửa `WalkInCustomerRequest` và tra cứu trong `BookingService.customers` để chỉ có tối đa một + ở đầu, giữ giới hạn 7–15 ký tự, số 0 đầu và số quốc tế. Không sửa hồ sơ cũ, schema hoặc quyền.

Chạy lại **58/58 đạt, 0 failure/error/skipped**, build JDK 24 thành công. Bằng chứng `exports/staff-audit-before.log`, `staff-audit-final.log`. Có 7 ca mới trong StaffRoleAuditTest; tập này cũng chứa các ca hỗ trợ kiểm tra vai trò khác khi chứng minh nhân viên bị chặn.

## Các luồng đã kiểm tra

| Luồng | Bằng chứng |
|---|---|
| Tạo/tra cứu khách tại quầy | Giữ Unicode; không tự tạo tài khoản; trùng điện thoại không thêm hồ sơ thứ hai; tạo/tra cứu điện thoại sai trả 400. |
| Lịch và xác nhận | Chỉ nhận booking đã xác nhận; booking chờ, đã hủy, ngày tương lai/quá giờ bị chặn theo quy tắc. |
| Nhận/trả sân | Không nhận hai lần; sân bảo trì/đang dùng không được nhận; trả sân giải phóng sân, chốt trạng thái và hóa đơn; không tự ghi nhận thanh toán. |
| Dịch vụ | Giá từ API, đơn vị/lốc và snapshot; trigger cập nhật tổng; kiểm tra số lượng, SKU ngừng/không tồn tại, sửa/xóa theo MaChiTiet và quyền; sau trả sân không sửa. |
| Đổi lịch | Cùng sân, booking tương lai chưa có lịch sử tài chính; tính lại giá, giữ dịch vụ, trở lại chờ xác nhận; không ghi đè legacy/hóa đơn. |
| Trạng thái sân | Nhân viên được đổi trạng thái theo quy tắc, không tạo/sửa danh mục sân; không dùng đổi trạng thái để vượt nhận/trả sân. |
| Phản hồi và báo cáo | Nhận/xử lý/đóng phản hồi; báo cáo sử dụng sân khớp booking của sân fixture; báo cáo tài chính bị chặn. |
| Phân quyền | Thiếu CSRF/quyền sửa bị chặn; nhân viên không quản lý tài khoản, không duyệt hoàn tiền. |

## An toàn và giới hạn

Browser VT02 đã PASS cả 6 mục menu ở 1440/1024/768/390px, sidebar nhất quán, menu mobile/Escape/logout hoạt động, không page error/GET lỗi. Bằng chứng `exports/staff-audit-browser.log`. Không tạo booking hoặc giao dịch trên browser.

Đã xác minh marker dev, bật opt-in; integration test dùng transaction rollback và giữ safety listener. Không chạy WalkInCustomerTest có fixture commit/cleanup; các ca tại quầy được viết mới theo rollback. Không chuyển tiền ngân hàng, không thay mật khẩu có sẵn. Audit browser được giữ.

Không chạy lại stress/concurrency nhận sân hoặc tạo khách đồng thời, không chứng nhận LAN/thiết bị thật. Chưa tự sửa dữ liệu điện thoại sai đã tồn tại. Bản sửa đã đưa lên cổng chính 8082 và sáu menu VT02 kiểm tra lại đạt; xem `exports/remaining-roles-live-VT02.log` và báo cáo tổng hợp ba nhóm.

## File kiểm thử mới

- `backend/src/test/java/com/sanbong/RoleAuditSupport.java`: hỗ trợ fixture transaction, không cleanup/delete.
- `backend/src/test/java/com/sanbong/StaffRoleAuditTest.java`.
- `backend/scripts/employee-role-browser-audit.js`: dùng lại cho ba vai trò, không ghi nghiệp vụ.
