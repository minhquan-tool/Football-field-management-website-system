# San_Bong: nguyên tắc phát triển

Đây là dự án hiện có, vừa phục vụ đồ án CNPM vừa hướng tới Web App nội bộ.
Người dùng đã chốt chuyển toàn bộ build/runtime sang JDK 24 ngày 13/10/2026.
Giữ HTML/CSS/JavaScript → REST API → Java Spring Boot → JPA/JDBC → SQL Server.
Không tạo lại dự án, đổi stack, dùng SqlProxy làm dependency hoặc đổi UI tùy ý.
Một server phục vụ trình duyệt các máy nhân viên; chưa triển khai LAN lúc này.

Backend tổ chức Controller → Service → Repository. Xác thực/phân quyền và
validation phải thực hiện ở backend. Password dùng hash; secrets từ môi trường.
Không báo thành công khi API/database thất bại. Dùng transaction cho nghiệp vụ
quan trọng, bảo vệ chống đặt trùng, xử lý exception rõ ràng và ghi nhật ký.
Không đưa đường dẫn máy phát triển vào code. Host/port/database phải cấu hình được.
Giữ `ddl-auto=validate`, không chạy script DROP/reset database hiện có.
Không thêm framework/dependency hoặc kiến trúc phân tán không cần thiết.

Chỉ làm từng phase, tái sử dụng code/UI, build/test và báo file thay đổi trước
khi chuyển phase. Phase 1 đã đạt: JDBC TCP trực tiếp và validate schema.
Phase 2 đã đạt: authentication, login/logout, role/permission.
Phase 3 đã được người dùng xác nhận kiểm tra: quản lý sân, chỉ đọc bảng giá.
Phase 4: tra cứu sân trống, đặt sân, lịch, xác nhận/hủy; giữ schema và lịch sử.
Phase 5 được giao: nhận/trả sân, dịch vụ, hóa đơn/thanh toán/hủy/hoàn tiền.
Nếu schema chưa đủ cho tài chính, dừng phần đó và đưa migration đề xuất để người dùng
xem trước; không tự áp dụng. Hoàn thiện các phần độc lập, build/test và báo đúng giới hạn.
Không tự chuyển Phase 6 hoặc triển khai LAN.

Phase 5.1A được phê duyệt riêng: booking mới giờ tự do 07:00–22:00, giá theo
giờ bắt đầu từ GiaTheoCa, tính tiền theo phút thực/60 và snapshot trong DatSan.
Legacy giữ MaKhungGio, CheDoGia=GIA_KHUNG và tiền cũ; không đổi sang giá theo giờ.
Giữ khóa San + transaction để chống interval overlap, không chỉ dựa vào index.
Không làm 5.1B, tài chính/dịch vụ mới hoặc Phase 6 khi chưa được giao tiếp.

Phase 5.1B đã được giao riêng: dịch vụ đặt trước/phát sinh, quy cách đơn vị/lốc 6
giảm 3%, snapshot giá và quản lý catalog. Giữ trigger làm nguồn tính tổng duy nhất,
thao tác dòng bằng MaChiTiet, giữ SKU/tiền legacy. Không tự làm 5.1C hoặc Phase 6.

Phase 5.1C đã được giao: hóa đơn snapshot, thanh toán nội bộ nhiều lần, hủy theo
10h/2h và hoàn theo thực thu. Một hóa đơn/booking; chốt khi trả sân. Giữ khóa
San -> DatSan cho mọi ghi tài chính/dịch vụ, idempotency thanh toán và hoàn.
Không tự chuyển tiền ngân hàng, không đổi snapshot legacy hoặc sang Phase 6.

Phase 6 đã được giao riêng: nhân viên/tài khoản/permission/nhật ký và báo cáo.
Giữ role/permission Phase2, không xóa lịch sử, khóa phiên khi ngừng/reset tài khoản.
Phân biệt doanh thu phát sinh tại trả sân với thực nhận thu trừ hoàn.
Không triển khai LAN/server sau Phase6.

Phase7 đã được giao: hardening/E2E/backup-restore/deployment nội bộ.
Không chạy fixture/cleanup trên DB internal; cần marker dev/test và test opt-in.
Không tự đổi password người dùng hoặc restore đè DB hiện có; LAN phải xác minh từ client thật.
