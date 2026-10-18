# Chuyển San_Bong sang JDK24 — 13/10/2026

Theo yêu cầu người dùng, build source/bytecode và runtime chuẩn của dự án đổi từJava21 sangJava24. Không đổi Spring Boot3.5.16, SQL Server, schema, JDBC driver, framework hoặc dependency runtime. Spring Boot3.5.16 hỗ trợ Java17–25 theo [system requirements chính thức](https://docs.spring.io/spring-boot/3.5/system-requirements.html).

## File cập nhật

- backend/pom.xml: java.version24, giữ processor Lombok explicit theo BOM.
- scripts/java-toolchain.ps1, scripts/server.ps1, backend/manage-backend.ps1: guard/call Java24, pin JAVA_HOME tới installation được kiểm.
- backend/scripts/java-toolchain-check.ps1: chấp nhận24, từ chối21/17/240/unknown.
- AGENTS.md: ghi phiên bản được người dùng chốt; backend/README.md, docs/TEST_ENVIRONMENT_SETUP.md, INTERNAL_DEPLOYMENT_GUIDE.md, CAU_TRUC_THU_MUC_SAN_BONG.md cập nhật hướng dẫn hiện hành.
- .env.example, .env.test.example, deploy.env.example cập nhật mẫu Java24. Chỉ JAVA_HOME trong các config private local được đặt tới JDK24 hiện có; không thay username/password/JDBC target hoặc secrets khác. Đường dẫn máy chỉ nằm trong config private, không đưa vào source/template.

Báo cáo audit/fix trước chuyển phiên bản và ZIP/release lịch sử giữ mốc cũ; các kết quả đó không được gọi là Java24 full regression. JAR mới có bytecode24, không chạy trênJava21. Artifact cũ không tự đổi target bytecode.

## Kiểm tra

- Guard JDK24 thật PASS; Java version policy và parser launcher PASS.
- Maven build/package PASS bằng Oracle24.0.2; compile source mục tiêu24;14unit BCrypt/PasswordPolicy PASS,0failure/error/skipped.
- JAR `backend/target/san-bong-backend-1.0.0.jar` được tạo; SanBongApplication.class major68 đúngJava24; đủ27HTML/JS đóng gói.
- Log: exports/java24-build-validation-20261013.log. Metadata/hash: exports/java24-artifact-validation-20261013.json.

Chưa full integration test, startup/API/browser/SQL thật hoặc deploy; DBtest config còn placeholder. Không chạy bằngsa để thay runtime identity, không đổi mật khẩu/migration/database. Unit/package PASS không chứng nhận mọi nghiệp vụ hoặc mọi dependency hết advisory.

## Chạy

Sau khi điền DB DEV/test thật và xác nhận quyền/marker:

```powershell
./backend/manage-backend.ps1 -Action run -EnvFile ./.env.test.local
```

Full regression sau này dùng Actionbuild với DEV/test đúng identity và SAN_BONG_TEST_MODE. Lệnh run không chạy test fixture nhưng vẫn cần datasource/schema hợp lệ. Java24 đã được cấu hình, không còn yêu cầu càiJava21.
