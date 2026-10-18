/* Display the existing booking rules; all checks remain authoritative on the server. */
(() => {
    let dialog;
    function showPolicy(event) {
        event.preventDefault();
        if (!dialog) {
            dialog = document.createElement('dialog'); dialog.className = 'booking-policy-dialog';
            dialog.setAttribute('aria-labelledby', 'bookingPolicyTitle');
            dialog.innerHTML = `<header><h2 id="bookingPolicyTitle">Chính sách đặt/hủy sân</h2></header>
<div class="booking-policy-content">
<section><h3>1. Đặt sân và giá thuê</h3><p>Chọn sân, ngày chơi và giờ còn trống trong 07:00–22:00. Tiền sân của lượt đặt mới tính theo số phút đặt / 60, với đơn giá tại giờ bắt đầu. Giá được lưu cùng lượt đặt; dịch vụ và giảm giá được tính riêng.</p></section>
<section><h3>2. Xác nhận và thanh toán</h3><p>Theo dõi trạng thái tại “Lịch đặt của tôi”. Bạn có thể chọn tiền mặt hoặc chuyển khoản. Yêu cầu thanh toán chỉ được tính là đã thu khi nhân viên xác nhận. Hóa đơn được chốt khi trả sân.</p></section>
<section><h3>3. Hủy và hoàn tiền</h3><p>Chỉ hủy lượt đặt chưa nhận sân, trước giờ bắt đầu và chưa bị hủy. Tỷ lệ hoàn tính theo thời điểm hủy so với giờ bắt đầu:</p><ul><li>Trước ít nhất 10 giờ: hoàn 100%.</li><li>Từ 2 giờ đến dưới 10 giờ: hoàn 50%.</li><li>Dưới 2 giờ: không hoàn.</li></ul><p>Tiền hoàn tính trên số tiền đã thực thu còn lại sau các khoản đã hoàn. Khoản hoàn chờ xác nhận chưa có nghĩa tiền đã được trả; nhân viên thực hiện và xác nhận hoàn thực tế.</p></section>
<section><h3>4. Dịch vụ, ưu đãi và đổi lịch</h3><p>Dịch vụ đặt trước được lưu cùng lượt đặt. Lốc 6 được giảm 3% theo danh mục hỗ trợ. Mỗi lượt đặt dùng một mã khuyến mãi hợp lệ, giảm tiền sân và không cộng dồn; áp dụng trước khi có thanh toán hoặc chốt hóa đơn. Cần đổi lịch hoặc hỗ trợ, vui lòng liên hệ nhân viên sân.</p></section>
</div><footer><button type="button">Đã hiểu</button></footer>`;
            dialog.querySelector('button').onclick = () => dialog.close();
            document.body.append(dialog);
        }
        dialog.showModal();
    }
    for (const link of document.querySelectorAll('a')) {
        if (!/Chính sách đặt\/hủy sân|Quy định và Chính sách đặt sân|Chính sách hủy sân/.test(link.textContent)) continue;
        link.removeAttribute('aria-disabled'); link.removeAttribute('tabindex'); link.removeAttribute('title');
        link.href = '#chinh-sach-dat-san'; link.addEventListener('click', showPolicy);
    }
})();
