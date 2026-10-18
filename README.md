# Football Field Management Website System — FC-UTE

Đồ án quản lý sân bóng dành cho Công nghệ phần mềm và Hệ quản trị cơ sở dữ liệu. Một backend phục vụ giao diện khách vãng lai, khách hàng, nhân viên sân, kế toán và quản lý.

## Công nghệ

- HTML/CSS/JavaScript; Tailwind CSS và font/icon được lưu cục bộ.
- JDK **24**, Spring Boot 3.5.16, REST API, JPA/JDBC.
- SQL Server; `ddl-auto=validate`, không tự tạo hoặc reset schema khi chạy web.
- Xác thực phiên, CSRF, BCrypt và phân quyền backend; transaction và khóa để xử lý đặt sân/tài chính.

## Chức năng chính

| Vai trò | Chức năng |
|---|---|
| Khách vãng lai | Xem/tìm sân, tra cứu giờ trống, bản đồ và chỉ đường |
| Khách hàng | Đăng ký/đăng nhập, đặt sân, lịch sử/hóa đơn, khuyến mãi, phản hồi/đánh giá |
| Nhân viên sân | Lịch tuần, đặt tại quầy, xác nhận/nhận/trả sân, dịch vụ và trạng thái sân |
| Kế toán | Hóa đơn, khoản thu, hoàn tiền, doanh thu và đối soát |
| Quản lý | Tổng quan, nhân viên/tài khoản/phân quyền, catalog/giá, báo cáo và nhật ký |

QR chuyển khoản dùng ảnh ngân hàng cấu hình riêng; không tự xác nhận tiền vào tài khoản. Backup SQL chạy bằng công cụ quản trị/Windows Task Scheduler, không cấp quyền backup cho tài khoản web.

## Cấu trúc

```text
backend/        Spring Boot: Controller → Service → Repository, model và tests
frontend/       20 trang HTML, CSS/JavaScript, asset và vendor cục bộ
database/       SQL, migrations và metadata schema không có bản ghi người dùng
scripts/        Công cụ build, kiểm tra, backup/restore và triển khai
docs/           Thiết kế, hướng dẫn và bàn giao kỹ thuật theo từng đợt
design-system/  Bộ quy tắc UI/UX FC-UTE
```

## Chạy trên Windows / VS Code

**Cần chuẩn bị:** JDK24, Maven trên PATH hoặc MAVEN_HOME, SQL Server và database đã được chuẩn bị đúng schema/quyền. Clone mã nguồn không tự tạo database, login hay tài khoản ứng dụng.

```powershell
git clone https://github.com/minhquan-tool/Football-field-management-website-system.git
cd Football-field-management-website-system
Copy-Item .env.test.example .env.test.local
notepad .env.test.local
```

Điền JAVA_HOME, APP_DB_URL, APP_DB_USER, APP_DB_PASSWORD theo môi trường riêng. Dùng tài khoản runtime được giới hạn quyền, không dùng sa. Database chạy test phải có marker DEV/test; tài khoản và dữ liệu test phải được chuẩn bị riêng. Các mẫu không chứa mật khẩu thật.

```powershell
# Build/kiểm tra bằng profile runtime DEV/test đã chuẩn bị:
.\backend\manage-backend.ps1 -Action build -EnvFile .\.env.test.local

# Chạy web; giữ terminal mở:
.\backend\manage-backend.ps1 -Action run -EnvFile .\.env.test.local

# Mở bằng terminal thứ hai (cổng mẫu là 8082):
Start-Process "http://127.0.0.1:8082/api/"
```

Nếu APP_PORT khác 8082, dùng đúng cổng cấu hình. `127.0.0.1` chỉ trỏ về máy đang mở trình duyệt. GitHub lưu mã nguồn; push repository không triển khai Spring Boot/SQL Server thành website online.

## Database và khởi tạo môi trường

- [Hướng dẫn môi trường test](docs/TEST_ENVIRONMENT_SETUP.md).
- [Từ điển schema và ERD](docs/DBMS_SCHEMA_DICTIONARY.md).
- [Hướng dẫn DBMS](docs/DBMS_TECHNICAL_GUIDE.md).
- [Chuẩn hóa, snapshot, view và backup](docs/DBMS_NORMALIZATION_VIEWS_BACKUP_2026-10-18.md).

`database/rubric-schema-new-only.sql` là snapshot schema hiện hành, chỉ tạo database rỗng với tên mới theo guard của script; không nạp danh mục, login, dữ liệu hoặc cấp quyền. Đây là điểm tham khảo để DBA chuẩn bị môi trường mới, không phải lệnh sửa database đang có.

`schema-bootstrap.sql` và `seed-data.sql` là tài liệu/seed **schema legacy trước nâng cấp**. Không chạy seed legacy lên schema computed hiện hành; không chạy toàn bộ migration hàng loạt hoặc dùng bootstrap/reset để sửa database đang hoạt động. Các tài khoản/credential demo trong test chỉ phục vụ môi trường DEV/test riêng.

Metadata tại `database/metadata/` chỉ chứa định nghĩa schema/module. Công cụ sinh SQL/tài liệu có thể dùng metadata này khi checkout không có `exports/`. Backup `.bak`, database thực, private profile và chứng cứ kiểm thử có dữ liệu người dùng không được phát hành.

## Kiểm tra

```powershell
.\backend\run-verification.ps1 -Suite runtime -EnvFile .\.env.test.local -Offline

# Chỉ trên database fixture riêng có marker và identity phù hợp:
.\backend\run-normalization-verification.ps1 -EnvFile .\.env.fixture.local -Offline -IncludeLegacyViews
```

`-Offline` yêu cầu dependencies đã có trong Maven cache; lần đầu cần build online để tải dependencies. Không chạy fixture/cleanup trên database vận hành hoặc nâng quyền runtime chỉ để chạy test.

## Giao diện và phạm vi nghiệm thu

[Bàn giao UI/UX](docs/UI_UX_REDESIGN_2026-10-18.md) mô tả giao diện 20 trang và kiểm tra trình duyệt theo 4 vai trò. [Design system](design-system/fc-ute/MASTER.md) ghi màu, typography, form và responsive.

Các số kiểm thử trong tài liệu là kết quả trên môi trường phát triển tại thời điểm ghi nhận; không có nghĩa mọi máy clone đều đã được cấu hình hoặc kiểm thử. Backup định kỳ cần cài trên máy SQL riêng; không được tự cài khi clone. Chưa chứng nhận Internet production hoặc mọi thiết bị thật.
