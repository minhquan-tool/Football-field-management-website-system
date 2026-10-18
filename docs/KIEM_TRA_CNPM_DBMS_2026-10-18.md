# Kiểm tra CNPM và DBMS — 18/10/2026

## Kết luận và phạm vi

Phần triển khai có nền tảng tốt cho cả hai môn. Chưa đủ căn cứ xác nhận đạt toàn bộ tiêu chí chấm hoặc chấm điểm: lượt này kiểm tra source, SQL, hồ sơ nghiệm thu trong workspace, build và các kiểm tra tĩnh; không truy vấn metadata database trực tiếp, chạy lại toàn bộ integration/E2E hoặc đọc lại Word/PDF rubric bên ngoài workspace.

Không sửa source nghiệp vụ, UI, schema, dữ liệu, mật khẩu hay cấu hình triển khai. Chỉ thêm bản kiểm tra này và log build; Maven cập nhật artifact trong backend/target, chưa triển khai artifact đó.

## CNPM

| Hạng mục | Nhận xét có bằng chứng |
|---|---|
| Stack/kiến trúc | pom.xml đặt Java 24; có controller/service/repository, DTO và model. application.yml dùng SQL Server/JPA, ddl-auto=validate, host/port/secrets cấu hình qua môi trường. Chưa chứng nhận mọi lớp đều tuân thủ tuyệt đối phân tầng. |
| Phân quyền | SecurityConfig bật method security, denyAll mặc định; ReportController kiểm tra cả role và CN06_XEM. PasswordEncoder dùng BoundedBcryptPasswordEncoder. |
| Nghiệp vụ/đồng thời | BookingService có transaction, khóa San trước kiểm tra interval overlap; DatSanRepository có PESSIMISTIC_WRITE. Source và test chuyên biệt tồn tại; chưa chạy lại concurrency ở lượt này. |
| Tích hợp DBMS | ReportRepository thực thi 5 SP báo cáo qua tham số bind; ReportService kiểm tra khoảng ngày và phân biệt doanh thu/thu/hoàn. |
| Bảo trì code | Một số lớp như ReportRepository/ReportService/ReportController nén nhiều câu lệnh vào một dòng, khó đọc và bảo vệ đồ án. Nên format riêng, giữ nguyên hành vi. Đây là vấn đề khả năng bảo trì, không phải bằng chứng sai nghiệp vụ. |
| Hồ sơ thiết kế | Có tài liệu đối chiếu Word và 40 use case, nhưng tài liệu cũ chứa trạng thái đã lỗi thời. Chưa xác minh bản SRS/use case/sequence hiện hành và ma trận yêu cầu → API/UI → test → kết quả đầy đủ. Không kết luận nhóm chưa từng làm sơ đồ: tài liệu đối chiếu ghi nhận Word có sơ đồ. |
| Quản lý phiên bản | git status xác nhận workspace hiện không phải Git repository. Chưa xác minh repository ở nơi khác; không suy ra nhóm không dùng Git. |

## DBMS

Theo exports/normalization-views-backup-verification.json và SQL schema hiện có: 27 bảng nghiệp vụ, 9 view, 6 function nghiệp vụ, 5 SP nghiệp vụ, 5 trigger bật và 9 computed persisted. Hồ sơ triển khai ghi 4 SQL role nghiệp vụ; chúng khác role ứng dụng và các demo user là WITHOUT LOGIN.

- Có ERD và từ điển trong DBMS_SCHEMA_DICTIONARY.md; có mô hình khóa/phụ thuộc hàm trong DBMS_NORMALIZATION_MODEL.md.
- Kiểm tra mô hình vừa chạy đạt trên 27 quan hệ và 9 cột computed. Kết quả phụ thuộc tập FD công bố và metadata export; không chứng minh toàn bộ schema vật lý là 3NF thuần túy hoặc database hiện tại không drift.
- Snapshot legacy, snapshot giá bán và các tổng liên bảng có chủ đích cần giải thích khi bảo vệ. Computed persisted vẫn lưu dữ liệu dẫn xuất; không nên gọi là loại mọi dư thừa vật lý.
- Có SQL demo 5 transaction commit/rollback, kiểm thử concurrency và probe quyền. Hồ sơ trước ghi đủ CHECK/FK trusted; chưa kiểm tra metadata trực tiếp lại trong lượt này.
- Có đo 5 index trên bảng tổng hợp 50.000 dòng. Đây là minh chứng phương pháp/index trên fixture, chưa phải benchmark tải dữ liệu vận hành thật; covering variant dịch vụ khác index nguồn.
- Có bằng chứng restore sang DB mới, CHECKDB, so dữ liệu và JPA validate. Theo biên nhận gần nhất, backup tự động chạy 02:00 nhưng yêu cầu người dùng đăng nhập; chưa có bản ngoài máy và chưa bật xóa theo retention. Không xem lịch task trong lượt này.
- SQL dựng schema mới không có đầy đủ seed/tài khoản/grants để tự đăng nhập ngay. Cần phân biệt gói schema-only với gói cài đặt/demo đầy đủ.
- Tỷ lệ sử dụng lấy công suất từ danh mục sân hiện tại, chưa phản ánh chính xác lịch sử bảo trì/ngừng sân. Giới hạn đã được ghi trong code/tài liệu.

Các nhận xét cũ như thiếu 5 SP, thiếu 4 trigger, chưa có SQL role, chưa có lịch backup không được dùng làm lỗi hiện hành; đã có thay đổi sau đó.

## Kiểm chứng trong lượt này

1. Build offline bằng JDK 24: BUILD SUCCESS, có compile/test-compile/package, bỏ qua thực thi test. Log: exports/cnpm-dbms-review-build-20261018.log.
2. backend/scripts/verification-suite-check.ps1: PASS, kiểm tra phân tách runtime/fixture và opt-in; không truy cập DB.
3. scripts/verify-normalization-model.py: NORMALIZATION_MODEL_PASS, 27 quan hệ và 9 computed theo mô hình/metadata đã export.

Đã đọc log nghiệm thu trước: 205 test fixture, 130 runtime, 37 hồi quy view/chuẩn hóa, không lỗi hoặc bỏ qua theo hồ sơ gần nhất. Các nhóm giao nhau, không cộng thành tổng độc lập; không phải kết quả chạy lại trong lượt này. Không chạy fixture/cleanup trên database internal.

## Ưu tiên trước bảo vệ

1. Đối chiếu bản Word/rubric CNPM hiện hành với source mới: giờ tự do, giá theo phút, dịch vụ lốc 6, hóa đơn snapshot, thu nhiều lần, hủy/hoàn và bốn vai trò. Chốt SRS, sơ đồ, ma trận truy vết; chưa tự viết báo cáo cuối kỳ hoặc slide.
2. Chuẩn bị bộ demo tái lập trên DB riêng: quyền SQL, 5 SP/UDF, trigger nhiều dòng, rollback, hai session đặt trùng, index và restore. Giữ log thực thi, không chỉ file script.
3. Kiểm tra gói bàn giao trên máy/DB mới, cấp cấu hình/seed/quyền cần thiết và giữ secrets/BAK thật riêng tư. Bổ sung liên kết Git thật nếu có.
4. Nếu dùng nội bộ thực tế: xác minh client LAN thật, backup ngoài máy và điều kiện chạy khi sign out. Chưa chứng nhận các phần này; không tự triển khai.

Chưa phát hiện lỗi nghiệp vụ mới đủ bằng chứng để yêu cầu sửa ngay trong phạm vi đọc này. Điều đó không thay cho kiểm thử đầy đủ hoặc chứng nhận không còn lỗi.
