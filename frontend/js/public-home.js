/* Public FC-UTE landing page. Booking mutations remain behind existing authentication. */
document.addEventListener('DOMContentLoaded', () => {
    SanBongVenueMap.init();
    const toggle = document.getElementById('navToggle');
    const nav = document.getElementById('mainNav');
    toggle.addEventListener('click', () => {
        const open = nav.classList.toggle('open');
        toggle.setAttribute('aria-expanded', String(open));
    });
    nav.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
        nav.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false');
    }));
    const $ = id => document.getElementById(id);
    const money = value => Number(value).toLocaleString('vi-VN') + ' đ';
    let version = 0, options;
    function status(message, error = false) {
        $('publicStatus').textContent = message; $('publicStatus').className = error ? 'status error' : 'status';
    }
    function node(tag, text, cls = '') {
        const element = document.createElement(tag); element.textContent = text; element.className = cls; return element;
    }
    function render(rows, searching) {
        const host = $('publicPitches'); host.replaceChildren();
        $('resultsTitle').textContent = searching ? 'Sân còn trống theo khoảng giờ' : 'Danh mục sân FC-UTE';
        $('resultsNote').textContent = searching ? 'Giá tính theo giờ bắt đầu và số phút thực. Kết quả có thể thay đổi trước khi bạn đặt sân.' : 'Trạng thái hiện tại của sân khác với lịch trống theo ngày và giờ bạn chọn.';
        if (!rows.length) { host.append(node('p', searching ? 'Không có sân phù hợp trong khoảng giờ này. Thử đổi ngày, giờ hoặc loại sân.' : 'Không có sân phù hợp với bộ lọc.', 'empty-state')); return; }
        for (const pitch of rows) {
            const card = node('article', '', 'pitch-card');
            card.append(node('div', pitch.tenLoaiSan, 'pitch-picture'));
            const content = node('div', '', 'pitch-content'); content.append(node('h3', pitch.tenSan));
            content.append(node('p', `${pitch.maSan} · ${pitch.tenLoaiSan}${pitch.soNguoi ? ' · ' + pitch.soNguoi + ' người' : ''}`, 'pitch-meta'));
            content.append(node('span', searching ? 'Còn trống theo giờ đã chọn' : pitch.trangThai, 'pitch-status' + (pitch.trangThai === 'Bảo trì' ? ' maintenance' : '')));
            if (searching) {
                content.append(node('p', `${pitch.ngayChoi} · ${pitch.gioBatDau.slice(0,5)}–${pitch.gioKetThuc.slice(0,5)}`, 'pitch-meta'));
                content.append(node('p', money(pitch.tongTien), 'pitch-price'));
                content.append(node('p', `${money(pitch.donGia)}/giờ · Chưa gồm dịch vụ`, 'pitch-meta'));
            } else if (pitch.moTa) content.append(node('p', pitch.moTa, 'pitch-description'));
            const link = node('a', searching ? 'Đăng nhập để đặt sân' : 'Tra cứu giờ trống', 'button');
            link.href = searching ? 'Dang_nhap.html?' + new URLSearchParams({date:pitch.ngayChoi,start:pitch.gioBatDau.slice(0,5),end:pitch.gioKetThuc.slice(0,5),pitch:pitch.maSan,type:$('publicType').value}) : '#tim-san'; content.append(link); card.append(content); host.append(card);
        }
    }
    async function catalog() {
        const requestVersion = ++version;
        status('Đang tải danh mục sân…'); $('publicPitches').replaceChildren();
        try {
            const params = new URLSearchParams({ q: $('publicQuery').value.trim(), type: $('publicType').value });
            const rows = await SanBong.request('public/pitches?' + params);
            if (requestVersion !== version) return;
            render(rows, false); status(`Đã tải ${rows.length} sân. Chọn ngày và giờ để kiểm tra sân còn trống.`);
        } catch (error) { if (requestVersion === version) { status(error.message, true); $('publicPitches').append(node('p', 'Chưa tải được danh mục sân. Vui lòng thử lại.', 'empty-state')); } }
    }
    $('publicSearchForm').addEventListener('submit', async event => {
        event.preventDefault();
        if ($('publicEnd').value <= $('publicStart').value) { $('publicEnd').setCustomValidity('Giờ kết thúc phải sau giờ bắt đầu.'); $('publicEnd').reportValidity(); return; }
        const requestVersion = ++version;
        $('publicSearchButton').disabled = true; status('Đang tra cứu giờ trống…'); $('publicPitches').replaceChildren();
        try {
            const params = new URLSearchParams({ q: $('publicQuery').value.trim(), type: $('publicType').value,
                date: $('publicDate').value, start: $('publicStart').value, end: $('publicEnd').value });
            const rows = await SanBong.request('public/availability?' + params);
            if (requestVersion !== version) return;
            render(rows, true); status(`Có ${rows.length} sân phù hợp với khoảng giờ đã chọn.`);
            $('loai-san').scrollIntoView({ block: 'start' });
        } catch (error) { if (requestVersion === version) { status(error.message, true); $('publicPitches').append(node('p', 'Chưa có kết quả. Kiểm tra ngày, giờ hoặc thử lại.', 'empty-state')); } }
        finally { if (requestVersion === version) $('publicSearchButton').disabled = false; }
    });
    for (const id of ['publicStart','publicEnd']) $(id).addEventListener('input', () => $('publicEnd').setCustomValidity(''));
    $('showAllPitches').addEventListener('click', () => {
        $('publicQuery').value = ''; $('publicType').value = ''; $('publicSearchButton').disabled = !options; catalog();
    });
    async function init() {
        try {
            options = await SanBong.request('public/options');
            $('pitchCount').textContent = options.pitchCount; $('typeCount').textContent = options.typeCount;
            for (const type of options.types) $('publicType').add(new Option(type.tenLoaiSan, type.maLoaiSan));
            $('publicDate').value = options.defaultDate; $('publicDate').min = options.today;
            $('publicStart').value = options.defaultStart.slice(0,5); $('publicEnd').value = options.defaultEnd.slice(0,5);
            $('publicSearchButton').disabled = false; await catalog();
        } catch (error) { status(error.message, true); }
    }
    init();
});
