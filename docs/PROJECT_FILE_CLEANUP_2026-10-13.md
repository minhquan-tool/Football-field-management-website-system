# Lọc file và thư mục San_Bong — 13/10/2026

## Phân loại

| Nhóm | Quyết định | Lý do |
|---|---|---|
| backend/src, backend/scripts, pom.xml, backend.ps1, README.md | Giữ | Source, tests, cấu hình build và lệnh chạy |
| html, Data, scripts, docs, AGENTS.md, .gitignore, config examples | Giữ | UI, schema/migrations, vận hành và hồ sơ đồ án |
| backend/target | Loại khỏi bản source sạch; có thể tái sinh | Classes/generated sources/Maven metadata; hiện không có JAR tại target. Không xóa bản gốc trong lượt này |
| logs, backend/logs, backend/*.log | Lưu riêng, không đưa vào source export | Output runtime/build; có thể chứa thông tin riêng, báo cáo còn tham chiếu |
| backend/phase*-results.json, runtime-evidence.json, ui-inventory.json, ui-changed.txt | Evidence riêng, không đưa vào source export | Kết quả kiểm tra lịch sử, không phải code cần để build |
| run | Lưu riêng, không đưa vào source export | Trạng thái tiến trình, probes, fixtures, screenshots, source copies, test logs và dữ liệu nhạy cảm có thể có |
| .playwright-cli | Evidence riêng, không đưa vào source export | Browser snapshot/console, không phải ứng dụng |
| releases | Giữ bản gốc, loại khỏi source export | Năm JAR khoảng245MB phục vụ release/rollback; không coi là file rác |
| .env, .env.*.local, deploy.env | Giữ private, loại khỏi source export | Cấu hình riêng; không xuất nội dung hoặc thay credentials |
| .vscode, .github, .agents, .playwright | Giữ thiết lập gốc, loại khỏi bản source nộp đồ án | IDE/tool/skill metadata không cần cho Maven build; không chứng nhận tất cả đều dư hoặc đã có CI |
| .bak/.mdf/.ldf/.trn | Không đụng | Không thấy trong project tại lúc quét; không quét backup ngoài project |

Inventory tại lúc quét: backend306file khoảng2,97MB; run772file khoảng12,06MB; releases5file khoảng245,18MB; html27file; Data16file; docs28file. Số này là snapshot trước khi bổ sung report/export và không phải số file source export.

## Bản source sạch

`scripts/export-source.ps1` tạo thư mục và ZIP timestamp riêng trong `exports/`, không move/delete/ghi đè source gốc. Allowlist giữ frontend/backend/tests/SQL/scripts/docs/config examples; bỏ toàn bộ private configs, output build/runtime, release JAR, IDE/tool metadata và evidence. Manifest CSV lưu đường dẫn tương đối, kích thước và hash file, không lưu nội dung credentials.

```powershell
./scripts/export-source.ps1
```

Bản xuất không phải release chạy ngay: cần JDK21, Maven và cấu hình SQL Server riêng như `TEST_ENVIRONMENT_SETUP.md`. Database/schema không tự tạo, migrate hoặc reset. Data bootstrap lịch sử vẫn được giữ phục vụ hồ sơ DBMS nhưng có DROP DATABASE; không chạy trên DB đang dùng.

Không xóa báo cáo phase/fix, SQL rollback/proposal hoặc UI prototype khi chưa kiểm dependencies/phạm vi. Có thể để chúng ngoài phần trình bày chính, nhưng vẫn giữ lịch sử và evidence. Source export được kiểm cấu trúc/manifest/private-file patterns; không gọi đây là audit mọi secret từng tồn tại trong nội dung source.

Lượt này chỉ lọc bằng cách tạo bản source riêng; số file gốc bị xóa hoặc di chuyển:0. Bản gốc giữ khả năng đối chiếu báo cáo và rollback. Nếu dọn trực tiếp về sau, cần review tiến trình đang chạy và tham chiếu rồi chọn exact paths; không xóa env/release/backup theo wildcard.
