# Đối chiếu rubric DBMS330284 — 19/10/2026

Nguồn: `E:/DBMS/HuongDan_Project_Rubric_DBMS330284.docx (1).pdf`, 6 trang. Đã trích văn bản toàn bộ và render/xem trang 2 để xác nhận các định lượng. Đây là hướng dẫn/rubric của môn học, không phải bản báo cáo cuối kỳ của nhóm.

## Kết luận

Dự án phù hợp hướng đề tài ứng dụng kết nối SQL Server và đạt các định lượng đối tượng DB đã kiểm đếm. Chưa thể kết luận đạt toàn bộ rubric hoặc chấm điểm: cần kiểm chứng demo thật, CRUD, concurrency, hồ sơ nộp và khả năng trình bày. Những kiểm thử UI mô phỏng gần đây không thay cho demo trực tiếp SQL Server theo mục 6.2.

Theo yêu cầu giao diện, bỏ mục “Báo cáo sử dụng sân” khỏi menu VT02. Giữ báo cáo quản trị/kế toán, API, SP, view và dữ liệu. Không thay đổi permission/backend hoặc xóa lịch sử; người có quyền vẫn có thể truy cập báo cáo theo chính sách hiện có. Đây là thay đổi menu, không phải thu hồi quyền.

## Đối chiếu yêu cầu

| Yêu cầu trong PDF | Bằng chứng hiện tại | Đánh giá / giới hạn |
|---|---|---|
| Trang 1–2: ERD, lược đồ, >=8 bảng, >=3NF | 27 bảng nghiệp vụ (loại sysdiagrams); docs/DBMS_SCHEMA_DICTIONARY.md, docs/DBMS_NORMALIZATION_MODEL.md; công cụ kiểm tra FD chạy đạt | Đủ số bảng; 3NF đạt theo tập FD đã công bố. 9 computed persisted và snapshot lịch sử cần giải thích, không gọi toàn bộ lưu trữ vật lý là 3NF thuần túy |
| Trang 2: PK/FK và >=5 CHECK/UNIQUE/DEFAULT | Metadata trực tiếp: 49 CHECK, 7 UNIQUE, 40 DEFAULT; không có CHECK/FK bị disabled hoặc untrusted | Đủ định lượng; chưa rà từng ràng buộc về ý nghĩa nghiệp vụ trong lượt này |
| Trang 2: >=5 trigger | 5 trigger đang bật: TRG_AuditContentImmutable, TRG_CapNhatTienDatSan, TRG_SealedInvoiceSnapshot, TRG_ServicePriceSnapshot, TRG_SuccessfulPaymentSnapshot | Đủ số lượng; chưa chạy lại các ca nhiều dòng/rollback |
| Trang 2: >=5 view | 9 view nghiệp vụ | Đủ số lượng; view doanh thu legacy và doanh thu phát sinh có ý nghĩa khác nhau, phải trình bày đúng |
| Trang 2: >=5 index, >=1 không phải PK, có chứng minh hiệu năng | 41 index trên bảng ứng dụng theo truy vấn metadata; 13 không phải PK (có thể gồm index UNIQUE). exports/rubric-indexes có 5 bộ before/after, actual plan và kết quả | Đủ số lượng. Benchmark là fixture tổng hợp, không khẳng định tốc độ vận hành thực tế. Chưa chạy lại benchmark |
| Trang 2: >=5 SP, >=5 UDF, TRY/CATCH | 5 usp_Report*; 6 UDF nghiệp vụ. Tất cả 5 SP có BEGIN TRY/BEGIN CATCH theo định nghĩa live | Không tính 7 sp_*diagram và fn_diagramobjects. SP phục vụ các nghiệp vụ báo cáo khác nhau; nên demo dữ liệu và giải thích từng SP |
| Trang 2: >=5 transaction, minh chứng concurrency hoặc recovery | database/migrations/legacy/rubric-transactions.sql có 5 tình huống COMMIT/ROLLBACK; BookingService khóa San, kiểm tra interval; có test concurrency và hồ sơ restore | Có source và hồ sơ kiểm chứng trước; không chạy giao dịch/fixture/restore trong lượt này |
| Trang 2: >=4 SQL Role/Login, GRANT/REVOKE/DENY | Live: SB_Customer, SB_PitchStaff, SB_Accountant, SB_Manager; 4 SB_Demo* WITHOUT LOGIN; script RubricDatabaseRoles_20261017.sql | Có 4 role SQL thật; phân biệt với VaiTro ứng dụng và SQL login dùng chung. Demo user WITHOUT LOGIN không phải 4 tài khoản đăng nhập SQL độc lập |
| Trang 2–3: kết nối cấu hình được, CRUD, tìm kiếm, báo cáo, gọi SP/UDF | Spring Boot/JPA/JDBC SQL Server; ReportRepository EXEC 5 SP; FinanceRepository gọi fn_TyLeHoan; các API nghiệp vụ tìm kiếm/thêm/sửa, xóa dòng dịch vụ, hủy/khóa theo nghiệp vụ | Đúng hướng; cần demo CRUD trên đối tượng chính. Giải thích vì sao hủy/ngừng thay cho xóa cứng dữ liệu lịch sử. Chưa xác nhận toàn bộ CRUD bằng thao tác DB thật lần này |
| Trang 3: xử lý lỗi DB/validation, UI thân thiện | Backend validation/exception handler, frontend báo lỗi; giao diện theo vai trò | Có source và test trước; UI đã thay đổi nhiều nên cần một lượt nghiệm thu thật 4 vai trò sau khi chốt |
| Trang 3: báo cáo 50–100 trang, TNR 13, giãn dòng 1.5, đủ chương/phụ lục | File người dùng đưa là rubric, chưa phải báo cáo của nhóm | Chưa thể xác minh bản báo cáo cuối kỳ, định dạng/số trang/các ảnh màn hình |
| Trang 3: slide <=15 trang, BAK hoặc SQL đầy đủ, source ZIP/README/Git, tên gói Nhom_STT_TenDeTai | Có scripts export/backup/schema và README; git rev-parse xác nhận workspace là Git repository | Chưa nghiệm thu gói nộp cuối cùng, remote Git/commit, slide hay khả năng cài mới trên máy khác |
| Trang 3–6: demo trực tiếp, thuyết trình/vấn đáp/nhóm | Có docs/DEMO_4_VAI_TRO.md và hồ sơ kiểm thử trước | Không thể đánh giá thay giảng viên; từng thành viên cần hiểu phần phụ trách |

## Phạm vi kiểm tra trong lượt này

- Đọc đủ 6 trang PDF, xem hình trang định lượng.
- Chỉ đọc metadata SQL Server QuanLySanBong bằng Windows Authentication; không sửa DB.
- Đếm đối tượng nghiệp vụ và kiểm tra TRY/CATCH của 5 SP.
- Chạy `python scripts/verify-normalization-model.py`: PASS, 27 quan hệ và 9 computed theo mô hình công bố.
- Đọc source tích hợp SP/UDF, transaction, phân quyền và hồ sơ benchmark index.
- Không chạy fixture/cleanup, không reset/restore DB, không đổi mật khẩu, không chạy lại toàn bộ test hay benchmark.

## Việc còn lại trước nộp

1. Chốt giao diện và chụp lại hình minh họa đúng bản hiện tại; bỏ mô tả cũ không còn khớp.
2. Demo trực tiếp CRUD, tìm kiếm/báo cáo qua SP, transaction rollback, hai phiên đặt trùng và quyền SQL trên DB dev/test riêng được xác minh.
3. Chuẩn bị báo cáo 50–100 trang và slide <=15 trang đúng rubric; đối chiếu số liệu live ở trên.
4. Kiểm tra ZIP/README/BAK hoặc SQL dựng lại, tên gói nộp và lịch sử Git; không đóng gói secrets.
