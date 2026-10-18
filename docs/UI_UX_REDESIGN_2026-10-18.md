# FC-UTE — bàn giao thiết kế UI/UX ngày 18/10/2026

Đã áp dụng UI UX Pro Max vào dự án HTML/CSS/JavaScript hiện có. Đây là thay đổi giao diện và khả năng sử dụng thuộc CNPM; không có migration, đổi schema, quyền SQL hoặc công thức tài chính DBMS.

## Hướng thiết kế

Giữ nhận diện xanh dương FC-UTE, font Montserrat có sẵn, nền sáng và khoảng trắng theo nhịp 4/8px. Bổ sung thanh bên xanh navy cho nhân viên/kế toán/quản lý; khách hàng giữ menu ngang trên desktop. Màu trạng thái vẫn đi kèm chữ. Form có nhãn rõ, focus ring, điều khiển 44px và padding riêng cho icon. Không thêm framework, CDN, font tải từ mạng hoặc thư viện animation.

Skill được tra cứu với “sports booking dashboard accessible”, sau đó thu hẹp “facility management dashboard clean”. Hệ thống gợi ý bố cục hero/CTA, flat surfaces và responsive phù hợp; màu đỏ/teal và font biên tập không phù hợp nhận diện hiện có nên không áp dụng máy móc. Quyết định thực thi được lưu tại `design-system/fc-ute/MASTER.md`.

## Phần đã thay đổi

| Nhóm | Thiết kế được áp dụng |
|---|---|
| Khách vãng lai | Hero xanh navy, minh họa SVG sân bóng cục bộ, tìm sân nổi bật, thẻ sân thống nhất, khu bản đồ và hướng dẫn đặt sân |
| Đăng nhập / Đăng ký | Bố cục câu chuyện thương hiệu + biểu mẫu hai cột trên desktop, một cột trên điện thoại; có đường về trang chủ; icon không che chữ |
| Khách hàng | Menu ngang đồng nhất giữa các trang, menu thu gọn trên tablet/mobile, form tìm nhanh 4 trường cân đối, thẻ sân/lịch sử/hóa đơn dễ đọc |
| Nhân viên sân | Thanh bên navy, mục được chọn rõ, nội dung công việc/bảng/lịch dùng bộ kiểu chung |
| Kế toán | Thanh bên cùng hệ thống, bảng và nhóm số tiền thống nhất, màu thu/hoàn/còn thiếu giữ chữ mô tả |
| Quản lý | Tổng quan, tài khoản/nhân viên, catalog, phản hồi, báo cáo, nhật ký và backup dùng cùng bộ giao diện |

`experience.css` được gắn đúng một lần vào **20 file HTML**. Các màn hình dùng chung được hiển thị theo vai trò đã đăng nhập, không theo tên file. Không chuyển menu khách hàng thành thanh bên khi vào lịch sử/hóa đơn.

Các giá trị về số sân, giá, lịch trống, trạng thái và số tiền vẫn lấy từ API thật. Minh họa SVG chỉ là hình trang trí; không giả lập ảnh sân thật hoặc lịch trống. Không sửa URL chức năng, chính sách role/permission, nội dung nhập liệu, form submit handler, password policy hoặc công thức nghiệp vụ.

## File chính

- `frontend/css/experience.css`: tokens, public/auth/workspace/forms/tables/schedule, responsive, focus, reduced-motion và in.
- `frontend/assets/pitch-blueprint.svg`: minh họa vector cục bộ, không có request bên thứ ba.
- `frontend/Trang_chu.html`, `Dang_nhap.html`, `Dang_ky.html`, `Man_hinh_chinh_KH.html`: bố cục và nội dung giao diện; giữ ID chức năng.
- Toàn bộ 20 HTML: thêm stylesheet chung; icon tiền không có trong Font Awesome 6.0 được thay bằng icon sẵn có.
- `frontend/js/role-navigation.js`: thêm logo/icon trang trí; giữ routes, permission filtering và logic shell theo vai trò.
- `frontend/js/ui.js`: thêm skip link đến nội dung chính; giữ quy trình nâng cấp form hiện có.
- `scripts/check-ui-redesign.ps1`, `backend/scripts/ui-redesign-browser.js`, `ui-redesign-forms-browser.js`: kiểm tra trình duyệt, truyền credential riêng và che credential khỏi log.
- `scripts/deploy-ui-redesign.ps1`: đối chiếu candidate với source, lưu JAR cũ, triển khai và kiểm tra health/assets, phục hồi JAR cũ nếu startup thất bại. Không chạy migration.

## Kiểm tra đã thực hiện

1. Build candidate bằng JDK24/Maven offline: đạt. Không chạy lại 205 test DBMS để tính thành kết quả mới của đợt UI; đợt này ưu tiên kiểm tra đúng phần giao diện thay đổi.
2. Cú pháp JavaScript: đạt. Cả 20 HTML giữ mọi ID gốc, không có ID trùng, mỗi trang gắn một stylesheet mới.
3. Browser candidate và server chính: **27 lượt trang theo menu của 4 vai trò**, ở chiều rộng **375, 390, 768, 1024, 1440**. Không tràn ngang document; bảng/lịch rộng vẫn cuộn trong vùng riêng. Không có pageerror JavaScript trong lượt kiểm tra.
4. Khách hàng: menu desktop vẫn là hàng ngang trên mọi trang và không chồng link. Mobile menu, đóng bằng Escape và đăng xuất có vô hiệu phiên hoạt động.
5. Forms: kiểm tra biểu mẫu đăng nhập/đăng ký, icon/padding, hiện/ẩn mật khẩu, nhãn phía trên ô, focus ring, mở/đóng/tạo/reset biểu mẫu tài khoản, biểu mẫu nhân viên và các form khách hàng. Không submit reset mật khẩu hoặc ghi bản ghi nghiệp vụ. Ca lỗi đăng ký dùng response mock để kiểm tra UI, không tạo tài khoản thật.
6. Modal hóa đơn khách: nhóm số tiền, nút in và độ rộng mobile được kiểm tra nếu có booking trong dữ liệu hiện hành.
7. Tương phản token: trắng/xanh primary 6,70:1; trắng/navy 13,85:1; chữ muted/nền trắng 6,21:1; các cặp chữ/nền trạng thái từ 5,64:1 trở lên. Đây là kiểm tra các token cụ thể, không phải chứng nhận WCAG toàn bộ ứng dụng.
8. Đã xem trực quan screenshot trang chủ, đăng nhập, khách hàng và quản lý; bổ sung kiểm tra quanh breakpoint 760–768px. Hành vi API bị cấm không được đổi thành thành công trên giao diện.

Browser checks không tạo booking/thanh toán/hoàn hay reset tài khoản; các thao tác login/logout vẫn có thể tạo nhật ký bảo mật bình thường. Không thay thế kiểm thử nghiệp vụ ghi và nghiệm thu bằng thiết bị thật.

## Chạy lại và xem giao diện

Web chính: `http://127.0.0.1:8082/api/`. Dùng **Ctrl+F5** nếu trình duyệt còn giữ CSS cũ.

```powershell
# Từ thư mục gốc, với một phiên Playwright CLI đang mở:
.\scripts\check-ui-redesign.ps1 -EnvFile .\.env.test.local -Port 8082 -Check pages -UseLegacyDemoPassword
.\scripts\check-ui-redesign.ps1 -EnvFile .\.env.test.local -Port 8082 -Check forms -UseLegacyDemoPassword
```

Chỉ dùng opt-in demo trên DEV/test đã review và credential demo hiện có. Nếu tài khoản đã đổi mật khẩu, điền AUTH_TEST_PASSWORD riêng vào profile; không chia sẻ mật khẩu. Không chạy lại deploy chỉ để mở trang web. Giữ JAR cũ trong exports nếu cần quay lại giao diện trước.

Chứng cứ: `exports/ui-redesign-deployment.json`, `ui-redesign-verification.json`, `ui-redesign-package.log`, `ui-redesign-pages-8082.log`, `ui-redesign-forms-8082.log`. Screenshot có tiền tố `exports/redesign-`; một số ảnh màn hình đã đăng nhập chứa dữ liệu nhóm nên cần xem xét trước khi chia sẻ công khai.

## Giới hạn

Đã kiểm tra trên trình duyệt Playwright desktop với viewport giả lập, chưa chứng nhận Safari/iPhone thật hoặc mọi cỡ màn hình. Bộ màu/spacing đã phủ tất cả trang, nhưng chưa thay mỗi màn hình thành một thiết kế nghiệp vụ riêng hoàn toàn. Không bổ sung tính năng hoặc thay luồng thanh toán trong đợt thiết kế này. Không tự thay logo trường hoặc số liệu để làm giao diện đẹp hơn.
