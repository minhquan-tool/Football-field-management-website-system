> Bản chụp kiểm tra trước đợt sửa mới. Ba mục chuẩn hóa/snapshot, view legacy và backup tự động đã được xử lý tiếp; xem [nghiệm thu 18/10/2026](DBMS_NORMALIZATION_VIEWS_BACKUP_2026-10-18.md) để biết trạng thái hiện hành và giới hạn.

# Đối chiếu rubric DBMS330284 — 17/10/2026

> **Cập nhật sau triển khai:** các thiếu hụt số lượng SP/function/trigger/SQL role trong bảng kiểm tra ban đầu bên dưới đã được bổ sung và áp dụng sau phê duyệt. Kết quả hiện hành: 5 SP, 5 function, 5 trigger đang bật, 4 SQL role nghiệp vụ; 130 test runtime và 119 test fixture đạt. Xem [kết quả triển khai và giới hạn](DBMS_IMPLEMENTATION_2026-10-17.md). Phần dưới giữ làm mốc trước sửa, không phải trạng thái lỗi hiện tại. Người dùng đã loại báo cáo cuối kỳ/slide khỏi phạm vi thực hiện.

Nguồn yêu cầu: `E:/DBMS/HuongDan_Project_Rubric_DBMS330284.docx (1).pdf`, 6 trang. Đã đọc toàn bộ văn bản và xem trang 2 để kiểm tra chính xác các định lượng. Đối chiếu metadata SQL Server trực tiếp bằng Windows Authentication, chỉ SELECT; đối chiếu source và các log kiểm chứng hiện có. Lượt này không sửa code hoặc database, không chạy lại toàn bộ test.

## 1. Kết luận

Web đã có nền tảng nghiệp vụ, transaction và bảo mật ứng dụng, nhưng **chưa đủ các định lượng SQL bắt buộc của rubric**. Khoảng thiếu rõ nhất: 4 trigger, 5 stored procedure nghiệp vụ, 4 function nghiệp vụ; bốn SQL role/login có quyền khác nhau chưa được triển khai tương ứng bốn vai trò web. Cần bổ sung hồ sơ thiết kế, đo index và gói báo cáo trước khi bảo vệ. Không suy ra điểm số từ số test đạt.

## 2. Ma trận yêu cầu và hiện trạng

| Yêu cầu trong PDF | Hiện trạng có bằng chứng | Còn thiếu / cần xác nhận |
|---|---|---|
| Mục 3.1, trang 1–2: ERD, lược đồ quan hệ, ≥8 bảng, ít nhất 3NF | 28 bảng dbo gồm sysdiagrams, tức 27 bảng dự án; có 37 FK và 28 PK tính cả bảng sơ đồ | Đủ số bảng. Cần ERD và từ điển dữ liệu **sau migrations**, phân tích khóa ứng viên/phụ thuộc hàm để chứng minh 3NF; giải thích snapshot lịch sử. Chưa chứng nhận toàn bộ schema đạt 3NF chỉ qua số bảng |
| Mục 3.2: ≥5 CHECK/UNIQUE/DEFAULT có ý nghĩa | Metadata: 48 CHECK, 43 DEFAULT, 7 UNIQUE; đủ CHECK nghiệp vụ độc lập như tiền, giờ, số lượng, trạng thái, thời gian hiệu lực | Chọn ít nhất 5 ví dụ, giải thích và demo dữ liệu bị từ chối; kiểm tra disabled/untrusted trước đóng gói |
| Mục 3.2: ≥5 trigger | 1 trigger nghiệp vụ đang bật: TRG_CapNhatTienDatSan | **Thiếu 4 trigger** có ý nghĩa, chạy đúng với lệnh nhiều dòng; không nhân bản tính tổng hoặc gây vòng cập nhật |
| Mục 3.2: ≥5 view | 6 view dbo của dự án | Đủ số lượng, chưa tự động đồng nghĩa cả 6 đều đáp ứng nghiệp vụ hiện hành. View khung giờ cũ không thay thế tra cứu sân trống theo ngày/khoảng giờ mới; view doanh thu cũ cần đối chiếu hóa đơn snapshot và thực thu/hoàn |
| Mục 3.2: ≥5 index, ít nhất 1 không phải PK, giải thích và chứng minh cải thiện | 13 non-PK index tính cả sysdiagrams; **12 trên bảng dự án**, có index sân/ngày/giờ, thanh toán và chi tiết dịch vụ | Đủ số lượng. **Thiếu minh chứng trước/sau bằng execution plan, logical reads, thời gian và bộ dữ liệu đại diện**. Không dùng phép đo HTTP thay cho đo index |
| Mục 3.3: ≥5 stored procedure nghiệp vụ, TRY…CATCH | 7 procedure được liệt kê đều là sp_*diagram do công cụ sơ đồ SSMS cung cấp | **0/5 procedure nghiệp vụ; thiếu cả 5**, kèm xử lý lỗi; không tính service Java hoặc script migration là stored procedure |
| Mục 3.3: ≥5 UDF | 2 scalar function gồm fn_diagramobjects và fn_TyLeHoan | Chỉ **1 function nghiệp vụ**, thiếu 4. Hàm hỗ trợ sơ đồ không tính |
| Mục 3.4: ≥5 nghiệp vụ transaction, BEGIN/COMMIT/ROLLBACK | Spring transaction ở đặt sân, nhận/trả sân, dịch vụ, thu/hoàn, tài khoản; có test rollback và concurrency | Cần chọn 5 luồng cụ thể và đóng gói kịch bản SQL minh họa commit/rollback. @Transactional là transaction thật nhưng chưa thay phần trình bày T-SQL theo hướng dẫn |
| Mục 3.4: đồng thời hoặc khôi phục sự cố | Có BookingConcurrencyTest/OperationsConcurrencyTest; đã có restore sang DB mới, CHECKDB và so dữ liệu trong log đợt high | Chuẩn bị demo 2 session, ảnh/log và lời giải thích khóa San → DatSan; ghi rõ môi trường và thời điểm restore, không coi VERIFYONLY đơn lẻ là restore drill |
| Mục 3.5: ≥4 Role/Login SQL có quyền khác nhau trên table/view/procedure | VaiTro có VT01–VT04. SQL DB có 2 custom database role và 2 custom SQL user; web dùng chung SanBongApp với quyền giới hạn | **Chưa đáp ứng minh chứng 4 vai trò SQL nghiệp vụ khác nhau**. Bảng VaiTro không phải SQL database role. Login fixture/QA không thay thế vai trò nghiệp vụ; cần thiết kế 4 database role và user kiểm chứng quyền, giữ service account hiện tại |
| Mục 3.5: GRANT/REVOKE/DENY và chính sách | Có migration whitelist và DENY sửa/xóa audit, probe quyền | Cần gom thành demo cấp → cho phép, thu hồi/từ chối → chặn đúng; chạy trên DB demo riêng, không mở rộng quyền runtime chỉ để đạt rubric |
| Mục 4, trang 2–3: kết nối cấu hình, CRUD, tìm kiếm/báo cáo, gọi SP/function, lỗi/đăng nhập | JPA/JDBC SQL Server, cấu hình môi trường; báo cáo gọi view; FinanceRepository gọi fn_TyLeHoan | **Chưa có gọi SP nghiệp vụ từ ứng dụng**. Cần tích hợp SP thật vào repository; lập ma trận CRUD. Hủy/khóa/ngừng là thiết kế giữ lịch sử, cần giải thích rõ với yêu cầu Xóa; không xóa giao dịch để đủ CRUD |
| Mục 5: Word/PDF 50–100 trang nội dung, TNR13, giãn 1.5, 6 chương | Có nhiều Markdown kỹ thuật. Word cũ E:/Nhom19_QuanLySanBong_14.10.docx tồn tại; báo cáo đối chiếu cũ ghi có sơ đồ | **Chưa kiểm chứng bản báo cáo cuối cập nhật đạt định dạng/số trang**. Không kết luận nhóm chưa từng vẽ ERD. Phải cập nhật sơ đồ và lời văn theo schema hiện tại; bổ sung tài liệu tham khảo, hình/bảng, phân công thật |
| Mục 6: slide ≤15 trang, backup hoặc SQL dựng đủ, source + README, quản lý Git | Có README/hướng dẫn, SQL/migrations, backup và restore đã kiểm chứng trước đây; thư mục hiện tại không có .git | Chưa thấy slide/báo cáo cuối trong workspace; chưa xác minh repo Git ở nơi khác. Cần gói nộp Nhom19_QuanLySanBong và thử cài trên DB mới; không chạy bootstrap DROP/reset trên DB hiện có |

## 3. Ưu tiên hoàn thiện

### Cao — thiếu trực tiếp theo rubric

1. Thiết kế 5 SP khác nghiệp vụ, có TRY…CATCH/THROW; chọn tra cứu sân trống, lịch sử khách, báo cáo sử dụng, đối soát, tổng hợp thu/hoàn làm ứng viên. Đây là phương án, chưa tạo hoặc tích hợp. Giữ kiểm tra role/ownership ở backend; SP không được biến thành đường vượt quyền. Nếu chuyển thao tác ghi sang SP, phải giữ thứ tự khóa, snapshot, idempotency và transaction hiện có.
2. Bổ sung 4 UDF hữu ích để đủ 5, ưu tiên TVF tái sử dụng truy vấn. Kiểm tra không tính trùng logic tiền hoặc làm chậm báo cáo. Hàm không dùng TRY…CATCH như procedure; phần xử lý lỗi thủ tục đặt trong SP theo rubric.
3. Đề xuất 4 trigger bảo vệ các bất biến độc lập, sau khi rà soát tương thích dữ liệu cũ và test nhiều dòng/rollback. Giữ trigger hiện tại làm nguồn duy nhất tính tổng dịch vụ. Chỉ thêm khi có mục đích thật; không tạo trigger rỗng để lấy số lượng. Migration ảnh hưởng tài chính cần được review trước áp dụng.
4. Thiết kế 4 SQL database role khách hàng/nhân viên sân/kế toán/quản trị với quyền riêng; minh họa bằng user kiểm thử trên bản copy. Có thể dùng database role, không bắt buộc đổi sang bốn connection pool hay để trình duyệt đăng nhập SQL. Row ownership của khách vẫn cần cơ chế backend; quyền SELECT bảng không tự giới hạn dữ liệu theo khách.
5. Tích hợp SP/function đã chọn vào chức năng web và lưu bằng chứng thực thi; không chỉ nộp file SQL không được ứng dụng gọi.

### Trung bình — bằng chứng và chất lượng DBMS

6. Đo ≥5 index với plan/STATISTICS IO/TIME trên dữ liệu demo đủ lớn; trước/sau trên DB copy, không DROP index nguồn hoặc đụng các index bảo vệ tính duy nhất để benchmark.
7. Chuẩn bị 5 kịch bản transaction thành công và lỗi/rollback: đặt sân, dịch vụ, trả sân/chốt hóa đơn, thu tiền, hủy/hoàn. Chỉ demo trên môi trường dev/test riêng; ghi rõ giao dịch do Spring quản lý hay T-SQL quản lý và tránh commit sai transaction bên ngoài.
8. Rà soát đủ 6 view; đặt tên/giải thích rõ view legacy, không dùng view chỉ liệt kê sân/khung làm bằng chứng sân thực sự trống.
9. Đồng bộ ERD, lược đồ, bảng thuộc tính, 3NF và sơ đồ luồng hiện hành. Cột snapshot là chủ ý giữ lịch sử, cần giải thích thay vì xóa để đơn giản sơ đồ.

### Hồ sơ nộp và cải tiến vận hành

10. Hoàn chỉnh Word/PDF theo mục 5, slide ≤15 trang, bảng phân công thật, trích dẫn tài nguyên, hướng dẫn demo trực tiếp và minh chứng Git nếu có. Đây là điều kiện nộp bài, không nên bỏ đến sát ngày bảo vệ.
11. Kiểm tra gói backup hoặc SQL dựng toàn bộ trên database **mới**; loại secrets/cookie/dữ liệu cá nhân khỏi gói công khai. Backup có dữ liệu thật chỉ nộp qua kênh hạn chế phù hợp.
12. Backup định kỳ/hash/archive/retention và xác minh máy ở xa vẫn chưa hoàn tất. Đây là hướng hardening thêm; rubric không ghi phải có lịch backup tự động, domain, cloud, tunnel, cursor, Playwright, Graphify hay framework mới.

## 4. Trọng số và bằng chứng sẵn có

Rubric trang 5–6: thiết kế 15%; constraint/trigger/view/index 15%; SP/function/lỗi 15%; transaction/bảo mật 10%; ứng dụng 20%; UI 5%; báo cáo 10%; bảo vệ/làm việc nhóm 10%. Các trọng số không phải điểm bị mất tự động; chưa đủ căn cứ dự đoán điểm giảng viên.

Các log mới nhất được tái sử dụng, không chạy lại ở lượt audit này:
- `exports/medium-verification.json`: runtime130 và fixture100, không failure; không cộng thành tỷ lệ hoàn thiện rubric.
- `exports/medium-final-runtime-tests.log`, `exports/medium-disposable-fixture-final-tests.log`: kiểm thử đã thực hiện trong đợt sửa trước.
- `exports/high-priority-restore-20261017.txt`, `exports/high-priority-verification-20261017.json`: phục hồi bản copy và đối chiếu tại thời điểm drill.
- `exports/medium-managed-backup-result.json`: SQL verify đạt, OS hash/archive chưa đạt.
- `docs/MEDIUM_FIXES_2026-10-17.md`: báo cáo hiện hành. Các báo cáo ngày 12–14/10 có nội dung cũ; không dùng các lỗi đã sửa trong đó làm kết luận hiện tại.

Đề xuất thứ tự: chốt thiết kế đối tượng SQL và ma trận quyền → review migration → thử trên DB copy → tích hợp repository → hồi quy nghiệp vụ → đo và đóng hồ sơ. Lượt này chỉ ghi báo cáo đối chiếu, chưa áp dụng migration nào.
