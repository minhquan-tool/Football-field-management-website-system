# Thanh toán sau đặt sân — 17/10/2026

## Luồng sử dụng

1. Đặt sân thành công → chọn **Thanh toán ngay** để mở chi tiết đúng lượt đặt.
2. **Tiền mặt** → khách chọn số tiền và gửi yêu cầu. Trạng thái là **Chờ xử lý**, thực thu chưa tăng. Nhân viên sân kiểm tra đã nhận tiền rồi chọn **Xác nhận đã nhận tiền mặt**. Kế toán/chủ sân có thể xử lý theo quyền tài chính hiện có.
3. **Chuyển khoản** → máy chủ kiểm tra chủ sở hữu lượt đặt, trạng thái, số còn thiếu và yêu cầu đang chờ. Trang hiển thị tài khoản nhận, số tiền và nội dung `FCUTE <mã đặt sân>`.
4. Nếu có ảnh QR xuất từ ứng dụng ngân hàng, ảnh được phục vụ qua endpoint có xác thực và kiểm tra quyền sở hữu. Đây là **QR nhận tiền tĩnh**: khách phải nhập/đối chiếu số tiền và nội dung trong ứng dụng ngân hàng. Thay đổi số tiền trên web không sửa nội dung ảnh QR.
5. Sau khi chuyển thực tế, khách bấm **Tôi đã chuyển khoản**. Yêu cầu vẫn **Chờ xử lý**. Kế toán/chủ sân đối chiếu giao dịch ngân hàng trước khi xác nhận thực thu. Nhân viên sân không được xác nhận chuyển khoản qua endpoint tiền mặt hay API thu trực tiếp.
6. Trong lúc có yêu cầu chờ, khách không gửi thêm yêu cầu; có nút tải lại trạng thái. Nếu bị từ chối, khách xem lại với nhân viên trước khi chuyển tiếp.

## Cấu hình riêng

Các mục trong `.env.example`:

```dotenv
APP_BANK_TRANSFER_ENABLED=false
APP_BANK_BIN=
APP_BANK_NAME=
APP_BANK_ACCOUNT_NUMBER=
APP_BANK_ACCOUNT_NAME=
APP_BANK_QR_FILE=
```

Điền thông tin nhận tiền trong file môi trường riêng, không commit. `APP_BANK_QR_FILE` là đường dẫn file PNG/JPEG đã xuất từ ứng dụng ngân hàng, tối đa 5 MB và 4096×4096 pixel. Đường dẫn tương đối được tính theo thư mục chạy backend; có thể dùng đường dẫn đầy đủ trong cấu hình riêng. Khởi động lại backend sau khi đổi cấu hình/ảnh vì ảnh được đọc khi khởi động.

Chưa có ảnh: để trống `APP_BANK_QR_FILE`; chuyển khoản thủ công vẫn dùng được nếu thông tin nhận tiền đã cấu hình đầy đủ. Không hiển thị ảnh giả. File ảnh được lưu riêng, ví dụ trong thư mục `run/` đã được Git ignore. Người vận hành phải xác minh QR thuộc đúng tài khoản nhận trước khi cấu hình; ứng dụng chỉ kiểm tra định dạng ảnh, không xác thực nội dung QR.

Không gửi thông tin nhận tiền/số tiền/mã đặt sân sang VietQR hoặc dịch vụ tạo QR bên ngoài. Không yêu cầu mật khẩu ngân hàng, OTP; không gọi ngân hàng để chuyển tiền hay tự nhận kết quả thanh toán. Máy chủ hiện chưa có webhook đối soát ngân hàng.

## Bảo vệ nghiệp vụ

- Backend kiểm tra quyền sở hữu trước khi trả hướng dẫn/ảnh; số tiền phải dương, nguyên VND, không vượt số còn thiếu. Không tự làm tròn hóa đơn có phần lẻ.
- Dữ liệu người nhận chỉ lấy từ cấu hình máy chủ. Client không được chọn file ảnh hoặc sửa tài khoản nhận qua API.
- Không tạo hóa đơn/giao dịch chỉ vì xem hướng dẫn hoặc ảnh QR. Endpoint ảnh không cache.
- Ghi thanh toán và xác nhận thực thu giữ transaction, khóa `San → DatSan`, kiểm tra số còn thiếu và idempotency hiện có. Khách không có quyền tự xác nhận thực thu.
- Giao diện xóa hướng dẫn cũ ngay khi đổi số tiền/lượt đặt và bỏ qua phản hồi đến trễ. Không hiện thành công nếu API thất bại.
- Không cần migration/schema hoặc cấp quyền SQL mới cho luồng này.

## Phạm vi kiểm tra

Kiểm thử SQL chỉ chạy trên database DEV có marker và opt-in; dữ liệu nghiệp vụ kiểm thử nằm trong transaction rollback. Kiểm thử trình duyệt bằng dữ liệu giả không chuyển tiền thật. Cần ảnh MB do người dùng cung cấp và kiểm tra quét thực tế trên ứng dụng ngân hàng để nghiệm thu nội dung QR cuối cùng.

Các file chính: `BankTransferService.java`, `FinanceController.java`, `FinanceService.java`, `application.yml`, `frontend/js/finance.js`, `frontend/js/bookings.js`, `.env.example`. Kiểm thử: `BankTransferServiceTest.java`, `PaymentQrFlowTest.java`, `backend/scripts/payment-qr-browser.js` và fixture UI.

Kết quả đợt này: 79 test backend đạt (14 test mới cho hướng dẫn/ảnh QR và xác nhận thanh toán); build JDK 24 thành công. UI giả lập và hồi quy hóa đơn/thực thu đều đạt. Điều hướng 25 trang của 4 vai trò đạt tại 1440/1024/768/390 px. Không còn khách/sân mang marker fixture sau rollback. Server chính cổng 8082 đã cập nhật và kiểm tra lại trang chủ, đăng nhập 4 vai trò, tài nguyên JS mới và hướng dẫn chuyển khoản của lượt đặt có sẵn; không tạo giao dịch tài chính thật. JAR trước cập nhật được sao lưu trong `exports/backend-before-payment-qr-20261017.jar`.

Trạng thái ảnh QR: **đã nhận ảnh người dùng cung cấp và cấu hình nội bộ** tại `run/mb-receiving-qr.jpg`; giữ nguyên JPEG gốc, không gửi sang dịch vụ tạo QR. File môi trường riêng trỏ tới ảnh này; backend đã khởi động lại và xác nhận trả ảnh JPEG có xác thực, không cache. Ảnh đã hiển thị trong màn hình thanh toán tại 1440 và 390 px, không tràn ngang. Hướng dẫn nhắc đây là QR tĩnh và khách cần nhập/đối chiếu số tiền, nội dung. Chưa kiểm thử quét bằng ứng dụng ngân hàng hoặc chuyển tiền thật. Không tự áp dụng migration phân quyền nhật ký đang chờ phê duyệt riêng.
