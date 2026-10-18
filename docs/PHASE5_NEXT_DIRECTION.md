# Hướng hoàn thiện Phase 5

Ngày kiểm tra: 06/10/2026. Đây là đề xuất để người dùng xem trước, chưa phải quyết định được duyệt và chưa có migration được áp dụng.

## Kết luận

Tiếp tục code hiện tại, giữ nhận/trả sân và dịch vụ. Bổ sung hóa đơn nội bộ chốt sau trả sân, ghi nhận khoản thu thật, hủy trước sử dụng và hoàn khoản đã thu. Tách trạng thái sử dụng sân khỏi trạng thái tiền. Giữ Java Spring Boot → SQL Server, Controller → Service → Repository, UI hiện tại và ddl-auto=validate.

Kiểm tra chỉ đọc lần này: HoaDon chưa tồn tại; ThanhToan, HoanTien và HuyDatSan đều chưa có dòng dữ liệu. ThanhToan/HoanTien hiện chưa có khóa duy nhất cho yêu cầu gửi lại. Không chạy lại test/build trong bước đề xuất; 58 tests PASS là kết quả của lần triển khai vận hành trước.

## Quy tắc nghiệp vụ đề xuất

1. Khách chọn sân/ngày/khung cố định. Nhân viên xác nhận giữ lịch, không coi đó là xác nhận đã thu tiền.
2. Không bắt buộc đặt cọc, không tự chọn tỷ lệ cọc. Luồng thường: xác nhận → nhận sân → dịch vụ → trả sân → lập hóa đơn → thu đủ tiền.
3. Nếu khách thực sự trả trước, nhân viên/kế toán có quyền ghi một khoản thu trước trong ThanhToan. Đây là tiền đã nhận, không tự động phát hành hóa đơn cuối cùng, không tự tuyên bố ngân hàng đã chuyển tiền.
4. Tiền sân tiếp tục là giá cả khung theo dữ liệu hiện tại. Không nhân thêm 1,5 và không sửa snapshot cũ. Cập nhật Word sang đơn vị giá này sau khi người dùng chấp thuận.
5. Dịch vụ tiếp tục lấy giá tại lúc ghi nhận. Khi chưa chốt hóa đơn và còn lượt sử dụng đang mở, tiền thu trước không tự cấm thêm dịch vụ. Thay điều kiện hasPayment hiện tại bằng điều kiện hóa đơn đã chốt; vẫn cấm sửa sau trả sân như hiện nay. Không thêm/sửa khuyến mãi trong Phase 5 này.
6. Sau trả sân, thao tác lập hóa đơn lưu tổng cuối cùng, người lập, thời điểm và booking. Mỗi booking có tối đa một hóa đơn; bấm lại trả về hóa đơn đã có. Từ lúc lập hóa đơn, không sửa/xóa dịch vụ hoặc tiền giảm của booking qua ứng dụng.
7. Tiền còn phải thu = tổng hóa đơn − tổng ThanhToan Thành công cho booking. Thu trước được khấu trừ đúng một lần. Chỉ cho thu đúng số còn lại ở bước quyết toán; không mở luồng trả góp, sửa/xóa khoản thu hoặc tự động hoàn tiền thừa. Nếu đã thu vượt tổng, chặn quyết toán và báo quản lý xử lý sai lệch.
8. Tổng hóa đơn bằng 0 hoặc đã được thu đủ trước đó: không tạo ThanhToan 0 đồng vì CHECK SQL yêu cầu >0; ghi trạng thái hóa đơn đã thanh toán khi đối soát đủ, có audit.
9. Đề xuất chính sách hủy tối giản: chỉ trước giờ bắt đầu và chưa từng nhận sân. Chưa thu tiền thì hủy không hoàn. Đã thu tiền thì hủy và tạo yêu cầu hoàn 100% khoản thực thu thành công; không dùng tỷ lệ 80% từ UI mẫu. Chính sách này cần người dùng duyệt, chưa áp dụng.
10. Hủy và tạo yêu cầu hoàn trong một transaction; hoàn thực tế là bước riêng có quyền kế toán/admin. Chỉ đánh dấu Đã hoàn sau khi người có quyền xác nhận đã trả tiền. Mỗi khoản thu được hoàn tối đa một lần theo chính sách hoàn toàn bộ của Phase 5. Không hủy/xóa ThanhToan gốc; yêu cầu gửi lại trả về kết quả trước đó.
11. Khi hủy booking có nhiều khoản thu trước, tạo một yêu cầu hoàn cho từng khoản thu Thành công, tổng không vượt thực thu. Booking Đã hủy không đồng nghĩa tiền Đã hoàn. Yêu cầu bị từ chối vẫn phải hiện rõ, không tự coi là đã trả tiền.
12. Booking đã nhận/đã sử dụng không đi qua luồng hủy trước sử dụng. Khiếu nại, giảm trừ sau chốt và hoàn một phần sau sử dụng cần quy trình điều chỉnh riêng; không âm thầm sửa hóa đơn hoặc suy đoán chính sách trong Phase 5.

## Thay đổi schema tối thiểu cần xem trước

- Giữ đề xuất một bảng HoaDon, MaDatSan UNIQUE, snapshot các khoản tiền, trạng thái riêng. ThanhToan tiếp tục tham chiếu MaDatSan, không chuyển toàn bộ schema tài chính sang thiết kế khác.
- Bổ sung khóa yêu cầu nullable trên ThanhToan và HoanTien, unique filtered cho các giá trị khác NULL. Request ghi tiền/hoàn phải mang khóa ổn định để retry không tạo giao dịch mới. Giữ MaGiaoDich cho mã tham chiếu giao dịch hiện có, không dùng lẫn với khóa retry.
- Với chính sách hoàn toàn bộ một lần, đề xuất UNIQUE(MaTT,MaHuy) trên HoanTien; kiểm tra dependency và dữ liệu trùng trước khi đưa DDL chính thức. Ràng buộc này không phù hợp nếu sau này chọn hoàn nhiều đợt; không giả định hỗ trợ điều đó.
- Không DROP/reset, không backfill hóa đơn hoặc khoản thu từ booking cũ, không sửa giá/lịch sử, không đổi trigger tính tiền dịch vụ.
- File Phase5_HoaDon_PROPOSAL.sql hiện chỉ chứa bảng HoaDon: **chưa đủ cho toàn bộ hướng này**. Cần chuẩn bị bản migration bổ sung và rà soát cụ thể trước khi xin áp dụng. Không chạy file hiện tại như thể đã đáp ứng tất cả yêu cầu.
- Chi tiết dịch vụ tiếp tục lưu ở ChiTietDichVu và bị khóa sửa qua ứng dụng sau chốt, chưa cần bảng dòng hóa đơn trùng dữ liệu. Phải xem lại mọi API dịch vụ khi thêm điều kiện này.

## Quyền và tính toàn vẹn

Nhân viên sân/admin giữ quyền nhận/trả và dịch vụ. Nhân viên sân được lập hóa đơn/thu tại quầy nếu được cấp quyền tài chính; kế toán/admin có quyền thu/đối soát/xác nhận hoàn theo ma trận hiện có. Khách chỉ xem tiền/booking của chính mình và yêu cầu hủy hợp lệ; không tự ghi Thành công hay Đã hoàn.

Mọi mutation tài chính dùng cùng thứ tự khóa San → DatSan → HoaDon khi có; khóa khoản thu/hoàn sau đó theo thứ tự ổn định. Kiểm tra tiền, trạng thái, ownership và permission ở backend; transaction bao gồm chứng từ, giao dịch, trạng thái và audit. Unique constraints hỗ trợ chống lặp, không thay thế khóa và kiểm tra tổng tiền.

Không lấy số tiền/trạng thái do frontend gửi làm nguồn chuẩn. Giá từ snapshot booking/dịch vụ, tổng đã thu từ SQL, tính toán BigDecimal. Khoản hoàn phải tham chiếu khoản thu Thành công của đúng booking bị hủy. API/UI chỉ báo thành công sau commit; chuyển khoản là ghi nhận nội bộ sau xác minh, chưa tích hợp ngân hàng.

## Thứ tự triển khai và nghiệm thu

1. Duyệt quy tắc giá, thu trước/thu còn lại, chính sách hủy/hoàn và phương án schema trên. Chuẩn bị migration đầy đủ có kiểm tra dependency, dữ liệu, rollback và phần DDL cụ thể để người dùng xem trước khi thực thi.
2. Làm hóa đơn: đọc tạm tính, lập sau trả sân, snapshot, chống lập trùng, đóng băng tiền/dịch vụ. Build/test và báo file thay đổi.
3. Làm ghi nhận thu trước và quyết toán: tiền mặt/chuyển khoản đã xác minh, số còn lại, request retry, hai request đồng thời, rollback/audit và tổng bằng 0. Sửa đúng guard dịch vụ liên quan, không refactor ngoài scope.
4. Làm hủy có tiền và hoàn: điều kiện thời gian/chưa nhận, yêu cầu hoàn theo khoản thực thu, quyền xử lý, chống hoàn hai lần, bảo toàn lịch sử, trạng thái hủy khác trạng thái hoàn.
5. Nối các vùng chức năng tương ứng vào UI cũ; hiển thị rõ tạm tính, đã chốt, đã thu, còn thu, chờ hoàn/đã hoàn. Chưa làm báo cáo tổng hợp Phase 6.
6. Chạy regression Phase 1–4 và vận hành Phase 5; test tài chính bằng API/SQL thật với fixture riêng, test concurrency/rollback, kiểm tra trình duyệt/F5 và cleanup. Báo đúng phần hoàn thành, không suy ra test thanh toán từ test check-in.

Nguồn kiểm tra: OperationsRepository/OperationsService, BookingWorkflowRepository/BookingService, SecurityConfig, schema SQL thực tế, PHASE5_REPORT.md và WORD_PROJECT_COMPARISON.md. Việc người dùng yêu cầu một hướng đi chưa phải là phê duyệt thay đổi database.
