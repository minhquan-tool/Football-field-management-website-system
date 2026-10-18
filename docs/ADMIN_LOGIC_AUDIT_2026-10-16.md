# Báo cáo quản lý hệ thống — 16/10/2026

## Phát hiện

Lần chạy đầu có 5 lỗi chuẩn bị dữ liệu test do sửa Map bất biến; đã sửa mã test, không coi là lỗi web. Lần tái hiện sau: 21 ca, 18 đạt và 3 failure thực sự — thêm nhân viên chấp nhận điện thoại toàn dấu +/dấu + giữa số. Bằng chứng `exports/admin-audit-before.log`, `admin-audit-reproduced.log`.

Đã sửa EmployeeRequest: số chỉ có tối đa một + ở đầu, có thể phân nhóm bằng khoảng trắng, giữ giới hạn 8–15 ký tự và trường điện thoại tùy chọn. Thêm 3 ca số nội địa, quốc tế và có khoảng trắng để tránh chặn nhầm. Không sửa dữ liệu nhân viên đã tồn tại.

Kiểm tra mở rộng phát hiện thêm lỗi xung đột định danh: tạo tài khoản cho nhân viên có phone/email trùng khách hoặc đổi liên hệ của nhân viên có tài khoản thành liên hệ khách được chấp nhận (4/4 ca thất bại, `exports/admin-alias-before.log`). Khi đó AuthService có thể tìm thấy nhiều tài khoản và từ chối đăng nhập bằng liên hệ. Đã sửa kiểm tra tại AdminService/AdminRepository: đối chiếu username/phone/email của các tài khoản khác trước tạo tài khoản và trước đổi liên hệ của nhân viên đã liên kết; bỏ qua chính nhân viên, email so sánh không phân biệt hoa/thường. Chỉ kiểm tra trường liên hệ thay đổi khi sửa, để vẫn ngừng được fixture có alias legacy trùng đã tồn tại. Không tự sửa dữ liệu trùng cũ.

## Phạm vi kiểm tra

| Chức năng | Ca kiểm tra |
|---|---|
| Nhân viên | Tạo/tra cứu/sửa Unicode; điện thoại hợp lệ/sai; bộ phận sai và ngày vào làm tương lai bị chặn. |
| Tài khoản | Tạo liên kết nhân viên, hash và không lộ mật khẩu; không tạo hai tài khoản cho một nhân viên; không chuyển chủ sở hữu nhân viên sang khách. |
| Khóa/ngừng | Khóa hủy phiên đang mở; ngừng nhân viên khóa tài khoản, không mở lại khi còn ngừng. |
| Reset | Chỉ reset tài khoản fixture: mật khẩu mới hash, phiên cũ bị thu hồi, đăng nhập mật khẩu mới; nhật ký không chứa mật khẩu/hash. Không reset người dùng thật. |
| Vai trò | Phiên hiện có nạp lại vai trò; đổi fixture từ nhân viên sang kế toán được báo cáo tài chính và bị chặn booking-options. |
| Tự bảo vệ | Không tự khóa/hạ quyền hoặc ngừng nhân viên của chính quản trị đang thao tác. |
| Permission | Grant/revoke tác động phiên đang mở; quyền CN07 không cho nhân viên vượt role; ma trận thiếu/sai và bỏ quyền phục hồi quản trị bị chặn. |
| Nhật ký | Tìm theo đối tượng trả đúng sự kiện; DELETE log trả 405, dữ liệu còn nguyên. |
| Danh mục/giá/dịch vụ | Các ca hồi quy cấu hình mới, giá/khung legacy chưa dùng, giữ giá lịch sử, thêm SKU, dừng khuyến mãi đã dùng không sửa snapshot. |

23 ca mới trong AdminRoleAuditTest, cộng các ca biên quyền và cấu hình trong tập kiểm tra chung. Có kiểm tra sửa email của chính fixture sang chữ hoa không bị chặn nhầm và các login liên quan vẫn hoạt động sau request trùng bị từ chối. Các integration test dùng transaction rollback và global DEV/test guard; không dùng Phase6IntegrationTest có cleanup commit. Quyền của role VT02 được thay tạm trong transaction để kiểm tra reload, rồi rollback; không lưu thay đổi quyền thật.

## Giao diện

Kết quả cuối: **23/23 ca AdminRoleAuditTest đạt**, cùng các ca biên quyền/cấu hình trong lần chạy chung **95/95 ca ba nhóm đạt, 0 failure/error/skipped**. Build JDK 24 thành công. Không coi các lần test lỗi trước sửa là PASS; log trước/sau được giữ riêng.

VT04 đã PASS 11 mục menu ở 1440/1024/768/390px: sidebar, active theo hash Nhật ký, mobile/Escape/logout; không page error/GET lỗi. Không bấm reset/khóa người dùng thật trên browser. Bằng chứng `exports/admin-audit-browser.log`.

## Mã và bằng chứng

- `backend/src/test/java/com/sanbong/AdminRoleAuditTest.java`, dùng RoleAuditSupport.
- `backend/src/main/java/com/sanbong/dto/EmployeeRequest.java`.
- `backend/src/main/java/com/sanbong/service/AdminService.java`, `backend/src/main/java/com/sanbong/repository/AdminRepository.java`: bảo vệ alias đăng nhập.
- Kết quả bản sửa cuối trong `exports/remaining-roles-final.log`; phần tổng hợp ghi riêng số ca và phạm vi.

## Giới hạn

Không chạy stress nhiều quản trị viên đồng thời, không thử ngừng quản trị viên cuối bằng dữ liệu người dùng thật. Backup/restore web vẫn là trang hướng dẫn và script DBA, không chạy backup/restore hay cấp quyền SQL mới trong đợt này. Không xóa lịch sử hoặc triển khai LAN. Các giới hạn nghiệp vụ đã ghi ở báo cáo trước vẫn giữ nguyên.
