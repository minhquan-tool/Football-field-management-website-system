# Dọn project và chuẩn hóa tên — 13/10/2026

## Đã xóa thực tế

Sau khi xác minh không có tiến trình Java San_Bong đang chạy, lưu backup và đối chiếu hash của từng file:

- 9 thư mục: `backend/target`, `run`, `logs`, `backend/logs`, `.playwright-cli`, `.playwright`, `.vscode`, `.github`, bản source giải nén cũ trong `exports/San_Bong_Source_20261013-224417`.
- 25 file `backend/phase*.log/json/txt`: log và evidence lịch sử, không phải mã ứng dụng.
- Tổng1215file đã được backup trước dọn. Manifest đường dẫn và hash backup: `exports/cleanup-plan-20261013.json`.

Backup riêng: `exports/Private_Cleanup_Backup_20261013.zip`. Có thể chứa log và dữ liệu cấu hình phục hồi/audit nhạy cảm; giữ private, không nộp hoặc chia sẻ như source. Các đường dẫn run/log/evidence trong báo cáo lịch sử nay được tra cứu bên trong ZIP, không còn file loose ở vị trí cũ. Xóa evidence không đổi nghiệp vụ nhưng ảnh hưởng việc đối chiếu báo cáo nếu không giữ backup này.

## Tên đã chuẩn hóa

| Tên cũ | Tên hiện tại |
|---|---|
| html/ | frontend/ |
| Data/ | database/ |
| backend/backend.ps1 | backend/manage-backend.ps1 |
| QuanLySanBong_Nhom19.sql | database/migrations/legacy/schema-bootstrap.sql |
| SecuritySetup.sql | database/migrations/legacy/security-permissions.sql |
| SeedData.sql | database/migrations/legacy/seed-data.sql |

Cập nhật Maven resource path, frontend static check, finance regression server, source exporter, Java launcher check, README và đường dẫn source trong tài liệu. Tên bảng/database/Java package không đổi. HTML vẫn đóng gói vào `static`, nên URL `/api/Dang_nhap.html` và các route cũ vẫn giữ nguyên.

Lệnh mới:

```powershell
./backend/manage-backend.ps1 -Action build -EnvFile ./.env.test.local
./backend/manage-backend.ps1 -Action run -EnvFile ./.env.test.local
```

Máy vẫn cần JDK21, cấu hình database thật và build thành công; cleanup/rename không tự khắc phục các placeholder trong env. `backend/target` sẽ được Maven tạo lại khi build. `logs/run` sẽ được server script tạo lại khi cần.

## Các mục giữ vì có tác động

- Private env files: xóa sẽ mất cấu hình chạy. Không đổi credentials.
- 5 JAR trong releases: giữ rollback và các artifact được báo cáo lịch sử tham chiếu. Xóa sẽ mất khả năng chạy bản đã build/rollback dù không đổi mã nghiệp vụ.
- .agents: giữ skill hỗ trợ các lượt phát triển, không phải dependency runtime.
- Tên14HTML và13JS: giữ vì gắn navigation/Spring Security/route; đổi URL cần migration tương thích riêng. Chỉ đổi thư mục chứa source.
- Source/tests, SQL migrations/proposals/rollback, báo cáo: không xóa. Bootstrap SQL có DROP DATABASE vẫn là tài liệu/script khởi tạo lịch sử, không chạy trên DB đang dùng.
- Không thấy .bak/.mdf/.ldf/.trn trong project khi quét; không đụng backup hoặc DB ngoài project.

## Kiểm tra

SQL source-policy9script và Java version/PowerShell syntax PASS. Static frontend14HTML và syntax13JS PASS. Maven package PASS trong bản sao riêng ở exports với `-DskipTests`, JDK24; không test DB/deploy. Lần offline đầu thiếu artifact plugin, lần có mạng tải dependency plugin đã khai báo và BUILD SUCCESS. Artifact check đối chiếu hash của đủ27HTML/JS dưới BOOT-INF/classes/static với frontend source: PASS. Log package và kết quả frontend được lưu riêng trong exports. Không dùng kiểm tra package này để chứng nhận full regression hoặc runtime Java21.

Bản sao build/source export dùng kiểm tra sẽ được dọn sau khi xác minh, giữ ZIP source và bằng chứng cần thiết; tránh tạo lại nhiều bản source loose trong project.
