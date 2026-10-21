# Xác nhận booking khi khách đến đúng giờ hoặc trễ

- Nhân viên/quản trị có quyền xác nhận booking đang chờ khi thời điểm hiện tại còn trước giờ kết thúc đặt sân. Đúng giờ kết thúc trở đi bị từ chối.
- Giữ kiểm tra trạng thái booking, sân hoạt động, phân quyền và transaction khóa San -> DatSan.
- Không đổi lịch, giá hoặc tiền booking khi xác nhận muộn.
- Nhận sân giữ quy tắc cùng ngày, từ 30 phút trước giờ bắt đầu đến trước giờ kết thúc, sân trống, không có lượt chưa trả hoặc yêu cầu hủy đang chờ.
- Không tự bù giờ cho khách đến trễ, không bổ sung phụ thu quá giờ.

Ví dụ 07:00–08:00: xác nhận lúc 06:50, 07:00, 07:01, 07:10, 07:59 được; từ 08:00 bị chặn. Nhận sớm chỉ khi đủ điều kiện vận hành.

Kiểm tra: LateBookingConfirmationTest (3), RescheduleTest (5), RoleBoundaryTest (7) đạt trên JDK24; test mock không ghi database. Test xác nhận muộn đã thất bại trước bản sửa với thông báo cũ rồi đạt sau khi sửa.

Artifact build riêng: exports/late-confirmation-stage/backend/target/san-bong-backend-1.0.0.jar. Không build đè JAR server đang chạy. Cần khởi động lại bằng đúng cấu hình runtime hiện có để áp dụng; build không đồng nghĩa đã triển khai.
