# Kiểm thử database

Chỉ chạy trên QuanLySanBong_Test hoặc QuanLySanBong_Fixtures_* do bộ cài mới tạo, có marker test.
Chạy 00..07, 09, 10 bằng sqlcmd -b hoặc SSMS cả file. Mọi lỗi THROW là FAIL.
08_transactions.sql: đổi @EnableDemo=1 sau khi chọn đúng database test. Có 5 COMMIT_PASS và 5 ROLLBACK_PASS; giữ dữ liệu tổng hợp để xem.
11A/11B: sau 08, mở hai cửa sổ cùng DB; bật @EnableDemo=1; chạy A rồi B trong 20 giây. Đây là minh họa khóa SQL, không thay kiểm thử API chống đặt trùng.
Các kiểm tra SP/view là smoke test thực thi; chưa chứng minh mọi số liệu báo cáo hay toàn bộ nghiệp vụ.
Không chạy riêng đoạn thân để bỏ qua guard. Không đặt marker test lên database vận hành.

Chạy tự động bằng Windows Authentication: .\database\tests\Run-Tests.ps1 -Database QuanLySanBong_Test -IncludeTransactions. Log ở run/database-tests/ (không commit). Kiểm tra đồng thời 11A/11B chạy riêng.
