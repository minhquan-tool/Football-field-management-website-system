# Khuyến mãi thanh toán và dịch vụ cùng hóa đơn

## Khách áp mã tại bước thanh toán

Mở **Lịch sử / Đánh giá → Xem chi tiết / Hóa đơn**, hoặc **Lịch đặt / Hóa đơn → Chi tiết**. Nhập mã tại **Hóa đơn / Thanh toán / Hoàn tiền → Mã khuyến mãi → Áp dụng mã** trước khi gửi yêu cầu thanh toán. Số giảm, tổng hóa đơn, số còn thiếu và thông tin chuyển khoản được tải lại từ backend.

Mỗi lượt đặt dùng một mã. Nhập lại cùng mã không cộng dồn; đổi mã hợp lệ sẽ thay thế mức giảm cũ. Giảm phần trăm tính trên tiền sân, giảm số tiền cố định tối đa bằng tiền sân. Tiền dịch vụ không hưởng giảm giá tiền sân. Không tin số giảm/tổng tiền client gửi lên.

Chỉ áp mã cho lượt đặt thuộc khách đang đăng nhập, dùng giá theo giờ mới, chưa hủy, chưa chốt và chưa có thực thu/yêu cầu thanh toán đang chờ. Booking legacy và hóa đơn đã chốt giữ nguyên snapshot. Mã phải hoạt động, còn hiệu lực tại ngày áp và bao phủ ngày chơi. Đổi lịch đã bị chặn khi có hóa đơn, tránh chuyển ưu đãi sang lịch không còn hợp lệ.

Hỗ trợ mã `MaKM` và mã trong dấu ngoặc cuối tên khuyến mãi hiện có; không phân biệt hoa/thường. Nếu trùng mã/alias thì từ chối, không chọn ngẫu nhiên. Cơ chế alias tái sử dụng schema hiện tại; nếu sau này quản lý nhiều mã công khai, nên đề xuất migration bổ sung cột mã duy nhất, không tiếp tục dựa vào tên.

## Các mã hiện có

| Mã nhập | Bản ghi | Điều kiện kiểm soát |
|---|---|---|
| VIP10 hoặc KM02 | Giảm 10% tiền sân | Chỉ ngày chơi thứ Tư, theo lựa chọn người dùng trong đợt sửa mức trung bình |
| UTE2026 hoặc KM01 | Giảm 20.000đ tiền sân | Nhân viên xác minh thẻ sinh viên rồi áp tại quầy; khách không tự vượt bước xác minh |
| CHAOSAN hoặc KM03 | Giảm 30.000đ tiền sân | Khách chưa có lượt đặt khác chưa hủy khi áp mã |

Điều kiện trong catalog vẫn là văn bản. Backend tự kiểm tra ba điều kiện đã định nghĩa: chỉ thứ Tư, ngày trong tuần và khách mới. Điều kiện khác/điều kiện cần bằng chứng phải qua nhân viên; không tự suy đoán khách đủ điều kiện. Khi nhân viên áp mã, giao diện yêu cầu xác nhận đã kiểm tra điều kiện; backend bắt buộc cờ `daXacMinhDieuKien=true` cho điều kiện cần xác minh và nhật ký ghi người chịu trách nhiệm. Khách không thể dùng cờ này để vượt điều kiện; nhân viên cũng không vượt được quy tắc thứ Tư bằng cờ xác minh. Không thêm cột xác minh thẻ sinh viên trong đợt này.

Trước đợt sửa mức trung bình, KM02 tên ghi “Giờ vàng thứ Tư” nhưng điều kiện là “Áp dụng ngày trong tuần”. Người dùng đã chốt **chỉ thứ Tư**; catalog và backend đã cập nhật, bảy ngày được kiểm thử và giao diện bản chính hiển thị điều kiện mới. Snapshot tiền lịch sử giữ nguyên. Xem [kết quả mới](MEDIUM_FIXES_2026-10-17.md); các số96test bên dưới là kết quả lịch sử trước đợt sửa này.

## Thêm dịch vụ vào cùng lượt đặt/hóa đơn

**Lúc đặt sân:** khách chọn số lượng dịch vụ trong mục dịch vụ đặt trước rồi xác nhận đặt. Backend lưu từng dòng `DAT_TRUOC`, snapshot giá/quy cách. Tổng dịch vụ do trigger tính.

**Sau khi nhận sân:** nhân viên sân mở **Lịch đặt → Nhận sân / Dịch vụ**, nhận sân đúng thời gian cho phép, chọn dịch vụ, đơn vị/lốc, số lượng rồi **Thêm dịch vụ**. Dòng phát sinh có nguồn `PHAT_SINH`; sửa/xóa theo `MaChiTiet`, giữ đơn giá đã lưu. Khách không có quyền tự ghi dịch vụ phát sinh sau nhận sân trong phiên bản này; báo nhân viên thêm.

Nếu khách đã trả tiền sân trước, thêm dịch vụ vẫn cập nhật **cùng hóa đơn** chưa chốt, giữ số tiền đã thu và giảm tiền sân. Ví dụ: tiền sân 300.000đ, mã giảm 10% → trả trước 270.000đ; dùng thêm nước 30.000đ → tổng 300.000đ, đã trả 270.000đ, còn thiếu 30.000đ. Không thu lại phần tiền sân đã trả.

Khi chọn **Trả sân / chốt dịch vụ**, hóa đơn chốt snapshot; không thêm/sửa/xóa dịch vụ sau đó theo luồng thông thường. Chốt hóa đơn không tự ghi nhận đã thu tiền. Tiền mặt chờ nhân viên xác nhận thực nhận; chuyển khoản chờ kế toán/chủ sân đối chiếu ngân hàng. Nếu quên dịch vụ sau khi đã chốt, cần quy trình điều chỉnh riêng, không sửa âm thầm lịch sử.

## Thay đổi và kiểm thử

Tái sử dụng controller/service/repository tài chính, khóa `San → DatSan`, transaction và trigger hiện có. Không migration, không thay schema, không cấp quyền SQL mới, không gọi ngân hàng.

File chính: `PromotionApplyRequest.java`, `FinanceController.java`, `FinanceService.java`, `FinanceRepository.java`, `CustomerCareRepository.java`, `frontend/js/finance.js`, `frontend/js/customer-care.js`.

Test mới `CustomerPromotionTest`: mã/alias, không cộng dồn, giới hạn giảm cố định, quyền sở hữu, mã hết hạn/ngừng/trùng, điều kiện ngày chơi/khách mới/thẻ sinh viên, chặn sau thanh toán/chốt/hủy, thêm dịch vụ khi đã trả trước rồi chốt hóa đơn. Fixture trong transaction rollback trên database DEV có opt-in. Kiểm thử UI mã sai không báo thành công và thông tin chuyển khoản đổi theo tiền sau giảm dùng dữ liệu giả, không tạo giao dịch ngân hàng.

Kết quả: **96 test backend đạt, không lỗi/bỏ qua**, gồm 8 test mới của `CustomerPromotionTest`; build JDK 24 thành công. Kiểm thử UI giả lập khuyến mãi, hồi quy QR/tiền mặt, hóa đơn và số liệu thực thu đạt. Điều hướng 25 trang của 4 vai trò đạt ở 1440/1024/768/390 px. Đọc kiểm tra SQL xác nhận marker DEV và không còn fixture mã khuyến mãi/khách/sân của đợt kiểm thử.

Trên bản preview thật, catalog đã hiển thị cả mã giảm tiền cố định và phần trăm cùng hướng dẫn áp mã. Tài khoản khách mẫu không có lượt đặt đủ điều kiện trong trang lịch sử được kiểm tra, nên không ép sửa dữ liệu để thử áp mã trên lượt đặt thật. Luồng ghi áp mã và dịch vụ đã được xác minh bằng API với transaction rollback và UI bằng dữ liệu giả. Chưa thực hiện chuyển tiền ngân hàng. Bản cũ được sao lưu tại `exports/backend-before-coupon-services-20261017.jar` trước khi cập nhật backend chính 8082.
