# San_Bong — triển khai nội bộ Phase 7

## Trạng thái và mô hình
HTML/CSS/JS được đóng gói cùng JAR; trình duyệt → Spring Boot → SQL Server trực tiếp. Không SqlProxy, không dependency mới. Một server Windows, Java 24, SQL Server và Task Scheduler có sẵn. Chưa xác nhận máy khác trong LAN. Không chạy fixture/cleanup trên database internal.

## Máy mới
1. Cài Java 24; cấu hình JAVA_HOME hoặc java.exe trong PATH. Chép project/artifact và scripts; không chép thư mục target đang chạy rồi build đè JAR. Maven chỉ cần trên máy build. Giữ JAR release immutable ở thư mục releases, cấu hình APP_JAR relative đường dẫn đó; lưu release cũ trước upgrade và không build đè artifact đang chạy.
2. Cài SQL Server, bật TCP/IP, xác định port SQL đang listen. SQL dùng localhost trên server; client không cần kết nối SQL. Restore backup theo BACKUP_RESTORE_GUIDE; không chạy schema DROP/reset. Kiểm tra lịch sử migration trong docs Phase 1–6 và database/migrations trước khi mở app; Hibernate chỉ validate, không migrate tự động.
3. SQL administrator tạo SQL login riêng với mật khẩu mạnh, không sysadmin/db_owner. Áp dụng `database/migrations/Phase7_LeastPrivilege.sql` bằng sqlcmd `-v AppLogin="LOGIN_DA_TAO" -b` vào đúng database. Quyền SELECT schema dbo, DML chỉ bảng nghiệp vụ được liệt kê; không DELETE lịch sử/audit. Không truyền mật khẩu qua command line hoặc lưu trong SQL source.
4. Khởi động trên loopback để người quản lý thay mật khẩu demo của mọi tài khoản hoạt động qua quản trị tài khoản. Không dùng 123456 trong LAN. Kiểm tra BCrypt, khóa tài khoản không còn sử dụng. Sau backup/review, SQL administrator mới chuyển classification sang internal:
   ```sql
   -- Chỉ trong database đã được chủ hệ thống xác nhận đưa vào sử dụng nội bộ.
   EXEC sys.sp_updateextendedproperty @name=N'SanBongEnvironment',@value=N'internal';
   -- Database mới chưa có marker: dùng Phase7_EnvironmentMarker.sql -v Environment=internal.
   ```
   Script marker tự từ chối thay đổi classification đã tồn tại. Không sửa dữ liệu demo tự động; internal startup từ chối marker sai, quyền SQL cao, debug, plaintext hoặc các mật khẩu demo phổ biến.
5. Chép `deploy.env.example` thành file riêng `deploy.env`; điền APP_DB_URL, APP_DB_USER, APP_DB_PASSWORD, APP_ENV=internal, APP_HOST=0.0.0.0, APP_PORT=8080, APP_CONTEXT_PATH=/api. APP_JAR tùy chọn; không cần đường dẫn máy phát triển. JDBC encrypt=true; mặc định ví dụ yêu cầu certificate SQL tin cậy. Nếu SQL dùng self-signed, quyết định cấu hình trustServerCertificate=true rõ ràng chỉ cho local SQL, không đổi mặc định âm thầm. Hạn chế ACL file env cho đúng tài khoản vận hành, SYSTEM, Administrators; không commit/chia sẻ file secret.
6. Từ thư mục project: `scripts\start-server.bat -EnvFile "PATH_TO_PRIVATE_ENV"`. GET `http://localhost:8080/api/health` phải trả status/database UP. Truy cập `http://localhost:8080/api/` để login. JAR chứa frontend nên không dùng Live Server/file://. Error startup ở logs; không vô hiệu validate để vượt lỗi.
7. Quyền Administrator Windows: chạy PowerShell elevated, xem lại scripts rồi chạy:
   ```powershell
   .\scripts\configure-firewall.ps1 -Port 8080
   .\scripts\register-server-task.ps1 -EnvFile (Resolve-Path .\deploy.env).Path -TaskUser 'SERVER\ServiceUser'
   Start-ScheduledTask -TaskName SanBongInternal
   ```
   Dừng phiên chạy tay trước khi Start-ScheduledTask. TaskUser cần quyền đọc env/JAR và ghi logs/run; chạy mức Limited, S4U, SQL authentication local. Rule chỉ Domain/Private, LocalSubnet TCP port app; không mở SQL 1433 hoặc Public/router. Scripts không thay task/rule đã tồn tại. Trước khi đưa vào LAN, Administrator mở wf.msc → Inbound Rules, kiểm tra rule enabled/Allow áp dụng sqlservr.exe hoặc port1433/Any và RemoteAddress/Profile. Client của app không cần SQL; bỏ hoặc giới hạn rule SQL mở ra LAN sau khi xác nhận không có ứng dụng khác cần chúng. Không tắt rule không liên quan. Máy hiện tại không đủ quyền audit firewall (Access denied); mục này chưa được xác nhận.
8. Dùng `Get-NetIPConfiguration`, chọn IPv4 của card mạng LAN thực sự, không lấy IP VMware/VirtualBox. Client cùng mạng truy cập `http://SERVER_IP:8080/api/`. Ping có thể bị chặn; TCP/browser là kiểm chứng chính. Không hard-code IP vào frontend.

## Vận hành
- Health anonymous chỉ UP/DOWN, lỗi DB trả 503; `/admin/test-safety` chỉ ADMIN.
- Restart: `scripts\restart-server.bat -EnvFile "PATH_TO_PRIVATE_ENV"`. Stop: `scripts\stop-server.bat`.
- Task startup sau reboot và retry tối đa 3 lần, cách 1 phút. Khi bảo trì, `Disable-ScheduledTask -TaskName SanBongInternal` trước khi stop để tránh recovery tự khởi động lại. Khôi phục task bằng Enable/Start sau bảo trì.
- Stop script Windows dùng Stop-Process, không phải graceful shutdown JVM. Ngừng nhận thao tác ghi và chờ request hoàn tất trước khi stop/restart; SQL rollback transaction bị ngắt. Foreground java -jar có thể Ctrl+C để Spring graceful shutdown 20s. Chưa kiểm chứng reboot/recovery thực tế hoặc Windows service SCM.
- logs/application.log và .error: xoay ngày/kích thước 10MB, 14 ngày, tổng 200MB/100MB. Startup stdout/stderr theo lần chạy cần lịch lưu trữ/dọn có kiểm soát; audit nghiệp vụ ở NhatKyHeThong.
- Session HttpOnly, SameSite=Lax, timeout 30m; CSRF giữ nguyên. HTTP LAN không mã hóa mật khẩu/session: nếu mạng có người không tin cậy, cấu hình HTTPS/certificate tin cậy và APP_SECURE_COOKIE=true trước vận hành. Không bật secure cookie khi dùng HTTP vì login không giữ session.
- HTTPS Tomcat dùng SERVER_SSL_ENABLED, SERVER_SSL_KEY_STORE, SERVER_SSL_KEY_STORE_PASSWORD, SERVER_SSL_KEY_STORE_TYPE và APP_PORT tương ứng. Certificate phải đúng hostname; APP_HEALTH_URL có thể chỉ định URL readiness có hostname hợp lệ. Không đưa secret vào .bat.
- Backup hằng ngày theo tài liệu riêng; lưu bản sao ngoài máy SQL, kiểm tra restore định kỳ. Database SIMPLE không hỗ trợ point-in-time bằng transaction-log backup.

## Build/test tách khỏi server thực tế
Chỉ database DEV/TEST đã review, marker dev/test, APP_ENV=dev/test; set SAN_BONG_TEST_MODE=dev/test và AUTH_TEST_PASSWORD riêng. `backend/manage-backend.ps1 -Action build` chạy clean verify; không build đè JAR đang chạy. HTTP checks cần cùng database với SQL verification; preflight từ chối internal. Cleanup chỉ exact fixture IDs/marker, administrator SQL, không dùng tài khoản runtime để xóa lịch sử. Không gán marker dev/test cho database thật nhằm chạy test.

## CDN và UI
Giữ CDN hiện tại vì chưa có yêu cầu offline: Tailwind, cdnjs Font Awesome, Google Fonts, ảnh Wikimedia. Nếu LAN mất Internet, CSS/font/icon có thể không đủ; cần chốt yêu cầu offline rồi đóng gói asset local đúng license, không thay UI trong Phase 7. Các trang khuyến mãi/đánh giá còn prototype được đánh dấu rõ; navigation chưa triển khai bị vô hiệu, lịch/hóa đơn thật nằm ở lịch đặt sân.

## Checklist máy client — chưa PASS
- [ ] Server SQL chạy; health localhost UP; port app listen đúng card LAN.
- [ ] Trình duyệt máy KHÁC mở /api/, login từng vai trò.
- [ ] Nhập ngày/start/end tự do, đặt sân; F5 thấy database đã lưu.
- [ ] Hai máy đặt overlap đồng thời: chỉ một thành công; sát biên hợp lệ.
- [ ] Dịch vụ đặt trước/phát sinh, nhận/trả sân, hóa đơn, thu phần thiếu.
- [ ] Hủy và xác nhận hoàn; chưa xác nhận không hiển thị đã hoàn.
- [ ] Kế toán xem thu/hoàn/báo cáo; khách và nhân viên thiếu quyền bị 403.
- [ ] Khóa/reset tài khoản vô hiệu session cũ.
- [ ] DevTools console/network không lỗi, trạng thái loading/empty/API error rõ; resize điện thoại/tablet/desktop.
- [ ] Stop/restart và reboot: task hồi phục, health UP, log/audit/booking giữ nguyên.
- [ ] Client không cần và không truy cập TCP SQL1433; từ máy client `Test-NetConnection SERVER_IP -Port 1433` phải không thành công theo cấu hình dành riêng cho hệ thống này. Kiểm tra cả rule theo program/port và profile, không chỉ rule port rõ ràng.
Ghi máy/IP/thời điểm/người kiểm tra và kết quả thật vào PHASE7_DEPLOYMENT_REPORT.
