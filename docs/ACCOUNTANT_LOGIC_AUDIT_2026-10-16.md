# Báo cáo nhóm kế toán — 16/10/2026

## Kết quả

**15/15 ca backend đạt, không failure/error/skipped**, gồm 10 ca mới AccountantRoleAuditTest, 4 ca biên quyền và 1 luồng khách yêu cầu thanh toán → xác nhận thu → hủy → xác nhận hoàn. Không phát hiện lỗi production mới trong phạm vi này, không sửa quy tắc tiền để làm test đạt.

| Luồng | Kết quả kiểm tra |
|---|---|
| Phạm vi kế toán | Xem/lập hóa đơn, thu/hoàn và báo cáo; không vận hành sân, quản lý tài khoản/danh mục hay giả làm khách. |
| Hóa đơn | Một hóa đơn/booking, gọi lại không trùng, tổng giả từ trình duyệt bị bỏ qua. |
| Thu nhiều lần | Các lần thu tăng thực thu và giảm số còn thiếu; trả đủ không tự biến booking thành đã sử dụng; không thu vượt số còn thiếu. |
| Idempotency | Retry cùng nội dung chỉ một giao dịch; đổi số tiền hoặc dùng key cho booking khác bị chặn. |
| Xác minh tiền | Không đánh dấu đã nhận thì bị từ chối; tiền 0 không ghi; yêu cầu chờ không thành thực thu trước xác nhận; xác nhận lại không ghi trùng; từ chối yêu cầu không cộng tiền. |
| Hoàn tiền | Chờ hoàn chưa giảm thực nhận; phải xác nhận đã hoàn thực tế; retry không nhân đôi; lưu nhân viên xử lý; booking hủy không thu thêm. |
| Chốt snapshot | Lượt đã trả sân có hóa đơn chốt; thay bảng giá không sửa hóa đơn/ doanh thu cũ; không áp khuyến mãi sau chốt. Fixture mô phỏng lượt trả sân để cô lập kiểm tra tài chính, không thay kiểm tra thời gian nhận sân. |
| Báo cáo | Tiền thu trước là thực nhận, chưa là doanh thu; doanh thu lấy khi trả sân; tổng thu/hoàn/nhận của sân fixture khớp; khoảng ngày/phân trang sai bị chặn. |
| Đối soát | Dữ liệu đúng báo Khớp sổ nội bộ; cố ý làm sai số thu hóa đơn 1 đồng trong transaction được phát hiện. |

## Giao diện

Hai menu VT03 qua 1440/1024/768/390px đều PASS, giữ sidebar, mobile/Escape/logout đúng; không page error/GET lỗi. Hai bài Playwright giả lập UI tài chính cũng PASS: tải lại lỗi sau khi POST thành công, response bị mất, chuyển booking khi đang ghi, giữ idempotency key theo booking, không hiển thị tiền booking cũ khi tải lỗi. Phân biệt tiền chờ và tiền đã thu, hoàn chờ và hoàn xong.

## Bằng chứng

- `exports/accountant-audit.log`, `accountant-audit-browser.log`.
- `exports/accountant-ui-regression.log`, `accountant-ui-money.log` (dữ liệu giả lập, không DB).
- Test mới: `backend/src/test/java/com/sanbong/AccountantRoleAuditTest.java`, dùng RoleAuditSupport transaction rollback.

## Giới hạn

Không chạy lại FinanceIntegrationTest/CheckoutSnapshotTest nguyên bộ vì có fixture commit/cleanup và ca nhiều thread cần cách ly riêng. Chưa chứng nhận stress thu/hoàn đồng thời, tất cả tổ hợp boundary/legacy hoặc tích hợp ngân hàng. Những giao dịch trong test rollback; browser không xác nhận thu/hoàn thật. Không đổi schema, quyền, mật khẩu hay snapshot hiện có. Kết quả là tập ca chọn, không phải toàn bộ dự án đã không còn lỗi.
