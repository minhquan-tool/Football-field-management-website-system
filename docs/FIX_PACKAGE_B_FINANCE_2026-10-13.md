# Gói B — Finance reload và request context (13/10/2026)

## Thay đổi

`frontend/js/finance.js`: load trả kết quả; mutation chỉ báo thành công đầy đủ sau refresh, vẫn giữ cảnh báo khi POST thành công nhưng GET/danh sách lỗi. Không tự POST lại. Selection bị chặn ở load trong lúc mutation, internal refresh được cho phép. Idempotency key được lưu theo booking, giữ khi phản hồi POST mất; chỉ xoay khi payment POST được xác nhận hoặc GET tìm thấy giao dịch mang key đó. Không đổi API, tiền, quyền, snapshot hoặc transaction backend.

Regression mới: `backend/scripts/fixtures/finance-ui.html`, `finance-ui-regression-server.cjs`, `finance-ui-regression.js`. Harness chỉ phục vụ trên loopback8093, dữ liệu giả, actual finance.js. Trước fix FAIL ở assertion R04; sau fix PASS reload failure/recovery, delayed POST/change selection, đổi booking sau hoàn tất và retry giữ key. Đây là browser regression, chưa phải E2E/SQL thật.

## Chuẩn bị test environment theo trao đổi với người dùng

Thêm `.env.test.example`, `docs/TEST_ENVIRONMENT_SETUP.md`, `scripts/verify-test-database.sql` (chỉ metadata read, không GRANT/DML). `backend/manage-backend.ps1` nhận `-EnvFile` explicit và từ chối đường dẫn không tồn tại; explicit file override process env để tránh nhầm target. Không tạo file credentials private, DB/login/role hoặc áp migration. README cập nhật cách dùng.

## Kiểm tra và giới hạn

Policy9SQLscripts PASS, Java version/parser PASS, node syntaxfinance/server PASS, Playwright finance regression PASS. Maven compile14unit đã PASS trong GóiA trên bản sao, không chạy lại Java tests cho thay đổi JS; frontend mới chưa được đóng gói release. Chưa có private DEV/test config và Java21 được xác nhận nên chưa full DB regression/runtime. Không deploy/restart internal, đổi secrets/password hoặc ghi dữ liệu thật.

Các backlog còn lại: quyền/schema thực tế, giờ mặc định/giá legacy, identity collision, concurrent quantity edits, rate limit, assets, backup target/TLS/client/recovery và hồ sơ/hiệu năng. Không coi tất cả đã được sửa. Nghiệm thu release F15 vẫn chưa hoàn tất.
