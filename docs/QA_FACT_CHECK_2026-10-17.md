# Kiểm định đồ án San_Bong — 17/10/2026

> **Đợt mới nhất — mức trung bình:** Đã cập nhật bản chính với VIP10 thứ Tư, tài nguyên UI local, whitelist runtime và môi trường fixture riêng.130test runtime và100test fixture đạt; xem [báo cáo mức trung bình](MEDIUM_FIXES_2026-10-17.md). Kết quả99ca ở cập nhật kế tiếp thuộc đợt mức cao trước đó.

> **Cập nhật sau kiểm định:** Người dùng đã giao sửa nhóm cao. Quyền sửa/xóa audit đã được chặn; lượt cuối 99 ca đạt (92 hồi quy và 7 test guard cleanup), restore backup mới đã được xác minh. Phân loại CNPM/DBMS, mức cao–trung bình–thấp và kết quả mới ở [báo cáo xử lý](KE_HOACH_SUA_LOI_CNPM_DBMS_2026-10-17.md). Các bảng bên dưới giữ trạng thái trước sửa; không dùng FAIL/NOT RUN cũ làm kết luận hiện tại cho các mục đã xử lý.

## 1. Executive Summary

Áp dụng bộ tiêu chí QA người dùng cung cấp, bỏ hai mục điền nội dung/tiêu chí còn trống theo yêu cầu. Đối tượng là đồ án hiện tại và các tuyên bố trong báo cáo gần đây; tiêu chí đối chiếu là AGENTS.md và hành vi mã nguồn. Đây là đợt kiểm định có giới hạn, không phải chứng nhận toàn bộ nghiệp vụ hay pentest.

Đã đọc mã nguồn, tài liệu, truy vấn SQL chỉ đọc; chạy static checks, 25 unit/MVC tests không dùng database và Playwright trên server chính 8082. Điều hướng 27 mục thuộc bốn vai trò đạt tại 1440/1024/768/390px. Form/icon đạt tại 1440/768/390px. Chưa phát hiện lỗi chặn sử dụng trong phạm vi giao diện đã chạy.

Vấn đề ưu tiên cao đã xác nhận: runtime SQL vẫn được UPDATE/DELETE nhật ký. Có mâu thuẫn giữa tên và điều kiện KM02. Giao diện còn phụ thuộc tài nguyên bên ngoài. Không sửa mã nghiệp vụ, tài khoản, schema, quyền SQL hoặc thực hiện chuyển tiền trong đợt này. Đăng nhập/đăng xuất kiểm tra có thể tạo nhật ký thông thường.

## 2. Fact-Checking Table

| ID | Tuyên bố | Bằng chứng trực tiếp | Trạng thái | Rủi ro |
|---|---|---|---|---|
| F01 | Build cấu hình Java 24, Hibernate validate | backend/pom.xml; backend/src/main/resources/application.yml; Maven chạy bằng JDK24 | VERIFIED | High nếu bị đổi |
| F02 | Mật khẩu mới được mã hóa BCrypt cost 12 | security/BoundedBcryptPasswordEncoder.java | VERIFIED về triển khai; không kiểm kê tất cả hash trong DB | High |
| F03 | Icon đăng nhập/đăng ký không che chữ và form có bố cục phù hợp | exports/qa-form-live-20261017.log | VERIFIED trong các viewport đã thử | Medium |
| F04 | Menu bốn vai trò đúng hướng, đúng trang và một mục active | exports/qa-navigation-live-20261017.log: 27 mục, không pageerror/API GET thất bại | VERIFIED trong lượt kiểm tra | High |
| F05 | Runtime database không thể sửa/xóa nhật ký | exports/qa-sql-readonly-20261017.txt: audit_update=1, audit_delete=1 | CONTRADICTED | High |
| F06 | Tài khoản mẫu nvsan hiện bị khóa | SQL mới: cả bốn tài khoản mẫu Hoạt động; đăng nhập NV đạt | CONTRADICTED tại thời điểm mới; báo cáo cũ phản ánh thời điểm trước | Medium |
| F07 | VIP10 chỉ dành cho thứ Tư | KM02 tên Giờ vàng thứ Tư, DieuKien là Áp dụng ngày trong tuần; FinanceService xử lý thứ Hai–Sáu | CONTRADICTED nếu diễn giải chỉ thứ Tư | Medium |
| F08 | Có giới hạn đăng nhập sai ở backend | LoginAttemptLimiterTest 13 ca + LoginRateLimitHttpTest 7 ca đạt | VERIFIED ở unit/MVC mock | High |
| F09 | QR là ảnh local, xem QR không tự ghi nhận thực thu | BankTransferService.java; BankTransferServiceTest 5 ca đạt | VERIFIED về mã và unit test | High |
| F10 | Toàn bộ thanh toán/khuyến mãi/dịch vụ đã được kiểm thử lại trên DB trong đợt này | Không chạy lại integration ghi DB; tài liệu có bằng chứng lịch sử riêng | UNVERIFIED cho đợt hiện tại | High |
| F11 | Backup hiện tại chắc chắn khôi phục được | Có hướng dẫn và ghi nhận drill cũ; không thực hiện restore mới | PARTIALLY VERIFIED | High |
| F12 | Giao diện hoạt động đầy đủ khi không có Internet | Static inventory có Tailwind CDN, CDN icon/font và ảnh ngoài | UNVERIFIED; có phụ thuộc cần thử offline | Medium |

Nguồn bằng chứng là file dự án và kết quả thực thi tại máy này; không dùng nguồn web hay nguồn trích dẫn tự tạo.

## 3. Logic & Consistency Review

- Báo cáo “20 trang/3 tài khoản, nvsan bị khóa” trước đây không được dùng thay trạng thái mới. Đợt này đăng nhập và điều hướng được cả bốn tài khoản, 27 mục. Không tự mở khóa tài khoản; trạng thái đã như vậy khi truy vấn.
- Các số 79/91/96/101 test trong tài liệu là những tập kiểm tra, thời điểm khác nhau, không cộng lại hoặc diễn giải thành số test mới chạy. Lượt này chỉ chạy 25 unit/MVC tests được chọn.
- Menu đúng không chứng minh mọi API ghi đều đúng quyền. Nhận xét F04 chỉ bao gồm điều hướng, GET dữ liệu và hành vi menu đã thử.
- UI báo đã chuyển khoản chỉ là yêu cầu chờ xác minh, không thể dùng nó làm bằng chứng ngân hàng đã nhận tiền. QR tĩnh không nhúng động số tiền/nội dung; phải nhập và đối chiếu theo hướng dẫn hiện có.
- Mâu thuẫn KM02 là mâu thuẫn dữ liệu nghiệp vụ, không nên âm thầm đổi chính sách bằng cách sửa tên hoặc sửa điều kiện khi chưa thống nhất.
- Không chạy ba biến thể prompt hoặc mô hình thứ hai: mục tiêu ở đây là phần mềm có hành vi kiểm tra trực tiếp, chưa có thí nghiệm so sánh mô hình. Không đưa ra chỉ số ổn định mô hình.

## 4. Test Case Results

| ID | Input / quy tắc | Expected | Actual | Status |
|---|---|---|---|---|
| T01 | Static: link HTML, API same-origin, 100 UUID | Link tồn tại; không ghim API máy phát triển; UUID hợp lệ/khác nhau | Script phase7-frontend-check.mjs đạt; kết quả backend/phase7-frontend-results.json | PASS |
| T02 | 9 SQL prepare/cleanup scripts | Guard marker và opt-in trước ghi; không đổi DB sau preflight | fixture-sql-safety-check.mjs đạt; không thực thi SQL fixture | PASS |
| T03 | Giới hạn đăng nhập: ngưỡng, thời hạn, đồng thời, dung lượng | Không vượt ngưỡng; xử lý trạng thái đúng | 13/13 unit tests đạt | PASS |
| T04 | MVC: CSRF, header IP giả, thất bại/thành công, context path | Status và ngân sách đúng, không tin header client | 7/7 tests đạt với users mock | PASS |
| T05 | BankTransferService dữ liệu mock | Điều kiện ảnh/hướng dẫn/số tiền theo assertions | 5/5 tests đạt | PASS |
| T06 | Auth/form ở 1440/768/390px | Icon không đè chữ; controls44px; nhãn trên; reset/đóng giữ đúng UI | Script main smoke đạt; lỗi đăng ký được mock, không tạo tài khoản | PASS |
| T07 | Bốn tài khoản,27 mục,1440/1024/768/390px | Menu KH ngang desktop, vai trò khác sidebar, mobile mở/Escape/đăng xuất | 0 pageerror,0 API GET failures; active/menu đúng | PASS |
| T08 | SQL runtime permissions | Không được UPDATE/DELETE audit | Cả hai quyền bằng1; db_owner0, BACKUP DATABASE0 | FAIL |
| T09 | Đối chiếu tên KM02 với điều kiện | Thông điệp khuyến mãi và quy tắc thống nhất | Thứ Tư khác ngày trong tuần | FAIL |
| T10 | Chuyển khoản ngân hàng thật, quét QR trên điện thoại | Đúng người nhận/số tiền/nội dung, đối soát đúng | Chưa thực hiện trong đợt này | NOT RUN |
| T11 | Restore backup mới sang DB khác và đối soát | CHECKDB/validate/đối soát đạt | Chỉ đọc hướng dẫn và kết quả lịch sử | NOT RUN |
| T12 | Integration đầy đủ đặt/nhận/trả sân, dịch vụ, thu/hoàn, tranh chấp | Transaction, khóa và snapshot đúng | Không chạy lại trong đợt này | NOT RUN |
| T13 | Offline, tải nhiều người và máy từ xa thực | Giao diện/độ trễ/kết nối đạt tiêu chí được chốt | Chưa có lượt đo trong đợt này | NOT RUN |

Maven: exports/qa-audit-unit-20261017.log — 25 tests,0 failures,0 errors,0 skipped, BUILD SUCCESS. Form được chạy hai lượt trong đợt này và cùng đạt; đây không phải phép đo ổn định tổng thể.

## 5. Root Cause Analysis

| Vấn đề | Nguyên nhân có bằng chứng / giới hạn | Tác động | Ưu tiên |
|---|---|---|---|
| Audit còn sửa/xóa được | Effective SQL permissions rộng; proposal ProtectAuditPermissions chưa áp dụng. Chưa phân tích đầy đủ nguồn grant/role trong lượt này | Mất tính toàn vẹn nhật ký khi runtime bị lạm dụng | P1 |
| KM02 tên/điều kiện khác nhau | Quy tắc dựa cột DieuKien; tên quảng bá ghi thứ Tư | Khách/nhân viên hiểu khác chính sách giảm | P2 |
| Báo cáo trạng thái có thể lỗi thời | Trạng thái tài khoản/dữ liệu thay đổi sau lần kiểm tra | Giảng viên/người vận hành hiểu nhầm tình trạng hiện tại | P2 |
| Tài nguyên giao diện ngoài máy | HTML nạp CDN/font/ảnh ngoài | Có thể giảm khả năng dùng khi Internet lỗi; chưa tái hiện offline | P2 |
| favicon404 | Trình duyệt yêu cầu /favicon.ico ngoài context; request quan sát trả404 | Lỗi phụ trong console, không chặn trang | P3 |

Không ghi nhận lỗi nghiệp vụ mới chỉ dựa trên một test chưa chạy. Truy vấn ban đầu dùng nhầm tên cột DieuKienApDung đã lỗi compile; đã kiểm tra schema và chạy lại với DieuKien, không sửa schema để khớp truy vấn.

## 6. Corrected Output

Đồ án hiện phục vụ được giao diện và điều hướng bốn vai trò trong lượt kiểm tra local. Form/icon đã đạt các viewport đã thử. Backend có BCrypt, kiểm tra quyền và các kiểm tra QR/giới hạn đăng nhập được chọn đạt 25/25. Tuy nhiên chưa đủ căn cứ kết luận toàn bộ sản phẩm hoàn thiện hoặc an toàn để công khai Internet: quyền audit SQL còn rộng, chính sách KM02 chưa thống nhất, và các kịch bản tài chính tích hợp/restore/tải/máy từ xa cần bằng chứng mới. Thông tin nvsan bị khóa trong báo cáo trước không còn là trạng thái hiện tại.

## 7. Optimized Prompt

> Kiểm định đồ án San_Bong hiện tại theo AGENTS.md. Đọc mã và kiểm tra trạng thái thực tế trước khi lặp lại kết luận cũ. Chỉ chạy test không ghi nghiệp vụ hoặc test đã xác minh marker DEV/test, opt-in và rollback; không reset tài khoản, đổi quyền SQL, schema hay chuyển tiền. Mỗi phát hiện ghi file/dòng hoặc log, tác động, độ ưu tiên và trạng thái VERIFIED/PARTIALLY VERIFIED/UNVERIFIED/CONTRADICTED. Tách unit, API integration, UI mock và UI server thật; ghi rõ thời điểm và phạm vi. Test chưa chạy phải ghi NOT RUN. Báo cáo chín mục: tổng quan, bảng kiểm chứng, logic/nhất quán, test cases, nguyên nhân, kết luận đã hiệu chỉnh, prompt, kế hoạch và đánh giá cuối. Không cộng số test từ các lần cũ và không khẳng định hoàn thiện toàn hệ thống chỉ vì menu đạt.

Prompt này là đề xuất; chưa chạy thí nghiệm trước/sau nên không tuyên bố hiệu quả đo được.

## 8. Improvement Plan

1. P1: Sau phê duyệt riêng, DBA rà quyền trực tiếp/role, lưu bằng chứng và áp dụng proposal ProtectAuditPermissions_20261017.sql; xác minh chỉ INSERT/SELECT audit và chạy hồi quy đăng nhập/ghi nhật ký. Đợt kiểm định này không thay quyền đang chờ duyệt.
2. P2: Chủ sân thống nhất KM02 là thứ Tư hay ngày làm việc; chuẩn bị thay đổi catalog và test đúng ngày/ngoài ngày theo chính sách chốt.
3. P2: Chạy lại bộ integration bốn vai trò trên database DEV/test được đánh dấu, fixture rollback và tài khoản test riêng; thêm ma trận truy cập trái quyền/khác chủ sở hữu cho API ghi. Giữ lịch sử và chống đặt trùng.
4. P2: Đề xuất phục vụ tài nguyên giao diện cần thiết từ local, sau đó thử offline/throttling mà không thêm framework mới.
5. P2: Làm restore drill mới sang database tên mới; lưu CHECKDB và đối soát số tiền/booking/audit; không restore đè nguồn.
6. Trước triển khai từ xa: kiểm tra QR bằng app ngân hàng và người nhận thực, HTTPS/cookie/proxy/IP limit, máy client thật và tải theo tiêu chí được thống nhất. Không tự tạo giao dịch ngân hàng.
7. P3: Bổ sung favicon đúng context nếu được triển khai trong đợt UI tiếp theo; ghi timestamp/phạm vi vào mọi báo cáo sau này.

## 9. Final Quality Assessment

- Factual Accuracy: Các kết luận có nguồn local trực tiếp; đã hiệu chỉnh trạng thái tài khoản cũ.
- Evidence Quality: Có Maven log, browser assertions và SQL read-only; unit mock không thay cho integration thật.
- Logical Consistency: Phạm vi/số test được tách theo thời điểm; mâu thuẫn KM02 được giữ làm phát hiện, chưa tự đổi chính sách.
- Requirement Compliance: Giữ JDK24, stack, schema, tài khoản và quyền hiện có; không ghi fixture hoặc thực hiện thanh toán.
- Test Coverage: Tốt cho điều hướng/form và ba lớp backend được chọn; chưa đủ cho toàn bộ tài chính, đồng thời, restore và vận hành từ xa hiện tại.
- Clarity & Usefulness: Có danh sách P1–P3 và bước xác minh. Không chấm điểm phần trăm chất lượng vì chưa có rubric/coverage toàn hệ thống.

Kết luận: Có thể tiếp tục demo và hoàn thiện; chưa đủ bằng chứng để công bố toàn bộ đồ án đã tối ưu hoặc không còn lỗi.
