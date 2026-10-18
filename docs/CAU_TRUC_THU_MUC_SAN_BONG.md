# Cấu trúc thư mục dự án San_Bong

Tên đề tài: Hệ thống quản lý sân bóng. Cây rút gọn theo cấu trúc hiện tại sau dọn/đổi tên ngày13/10/2026.

```text
San_Bong/
├── backend/                        # Java Spring Boot: REST API và nghiệp vụ
│   ├── pom.xml                     # Maven; frontend được đóng gói vào static
│   ├── manage-backend.ps1           # Build/chạy, kiểm Java24 và cấu hình môi trường
│   ├── README.md                   # Hướng dẫn backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/sanbong/
│   │   │   │   ├── SanBongApplication.java
│   │   │   │   ├── config/          # Security/session/Clock/readiness
│   │   │   │   ├── controller/      # REST API và exception handler
│   │   │   │   ├── dto/             # Request/response và validation
│   │   │   │   ├── model/           # Entity JPA
│   │   │   │   ├── repository/      # JPA/JDBC
│   │   │   │   ├── security/        # PasswordPolicy và BCrypt
│   │   │   │   └── service/         # Nghiệp vụ/transaction/ownership/audit
│   │   │   └── resources/          # application.yml, profile internal, logback
│   │   └── test/                   # Unit/integration/concurrency và test guard
│   └── scripts/                    # HTTP/SQL policy/browser regression và fixtures
├── frontend/                       # 15 trang HTML và 15 file JavaScript
│   ├── Trang_chu.html               # Trang chủ khách vãng lai, tìm sân công khai
│   ├── css/public-home.css          # CSS local cho trang công khai
│   ├── assets/football-field.svg    # Minh họa sân bóng local
│   ├── Dang_nhap.html
│   ├── Dang_ky.html
│   ├── Dat_san_tai_quay.html
│   ├── Quan_ly_san.html
│   ├── Quan_ly_lich_dat_san.html
│   ├── Bao_cao.html
│   ├── ...                         # Trang chính từng role và các trang khách hàng
│   └── js/                         # auth, booking, operations, finance, admin, reports
├── database/                       # SQL Server schema và migrations
│   ├── schema-bootstrap.sql        # Bootstrap lịch sử; KHÔNG chạy trên DB đang dùng
│   ├── security-permissions.sql    # Quyền nghiệp vụ
│   ├── seed-data.sql               # Dữ liệu mẫu
│   └── migrations/                 # Migration/proposal/rollback theo phase
├── scripts/                        # Toolchain, start/stop/restart, backup/restore, export
├── docs/                           # Báo cáo CNPM/DBMS, audit/fix, hướng dẫn
├── releases/                       # JAR lịch sử giữ để rollback
├── exports/                        # ZIP source, backup evidence private, manifest/log kiểm tra
├── .agents/                        # Skill hỗ trợ phát triển
├── .env.example                    # Mẫu cấu hình dev
├── .env.test.example               # Mẫu cấu hình test
├── deploy.env.example              # Mẫu cấu hình triển khai
├── .gitignore
└── AGENTS.md                       # Quy tắc phát triển và phạm vi project
```

Private env files có trên máy nhưng không liệt kê trong bản cây dùng để chia sẻ. `backend/target`, `logs`, `run` là output sinh lại khi build/chạy; đã dọn, không phải source bắt buộc. IDE/tool metadata và artifacts Playwright được loại khỏi cây hiện tại.

Tên trang HTML và URL vẫn giữ để không phá navigation/phân quyền. Tên folder source đã đổi từ html/Data sang frontend/database; Maven vẫn đưa HTML/JS vào static. Script build/chạy hiện là backend/manage-backend.ps1. Xem STRUCTURE_CLEANUP_2026-10-13.md để tra mapping tên cũ và ảnh hưởng.
