(() => {
    const trigger = document.getElementById('forgotPassword');
    if (!trigger) return;
    const dialog = document.createElement('dialog');
    dialog.className = 'booking-policy-dialog login-support-dialog';
    dialog.setAttribute('aria-labelledby', 'loginSupportTitle');
    dialog.innerHTML = `<header><h2 id="loginSupportTitle">Bạn quên mật khẩu?</h2></header>
<div class="booking-policy-content"><p>Liên hệ nhân viên FC-UTE để được xác minh tài khoản và hỗ trợ đặt lại mật khẩu.</p>
<a class="login-support-phone" href="tel:0373855657">0373 855 657</a><span class="login-support-hours">Hỗ trợ 24/7</span>
<ol><li>Cung cấp tên đăng nhập hoặc số điện thoại đã đăng ký.</li><li>Nhân viên hướng dẫn xác minh; người có quyền quản lý tài khoản sẽ đặt lại mật khẩu.</li><li>Đăng nhập bằng mật khẩu được cấp rồi vào “Thông tin tài khoản” để đổi mật khẩu mới.</li></ol>
<p>Không cung cấp mật khẩu hiện tại cho người hỗ trợ.</p></div>
<footer><button type="button">Đã hiểu</button></footer>`;
    document.body.append(dialog);
    trigger.addEventListener('click', () => dialog.showModal());
    dialog.querySelector('footer button').onclick = () => dialog.close();
})();
