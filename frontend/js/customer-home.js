(() => {
    'use strict';
    const $ = id => document.getElementById(id);
    const money = value => Number(value).toLocaleString('vi-VN') + ' đ';
    function item(host, text, tag = 'p') {
        const node = document.createElement(tag); node.textContent = text; host.append(node); return node;
    }
    function link(host, text, href) {
        const node = item(host, text, 'a'); node.href = href; node.className = 'block text-sm text-brand-600 mt-2 hover:underline';
    }
    async function populate(host, load, render, empty) {
        try { const rows = await load(); host.replaceChildren(); if (!rows.length) item(host, empty); else rows.forEach(row => render(host, row)); }
        catch (error) { host.replaceChildren(); item(host, error.message); }
    }
    document.addEventListener('sanbong:authenticated', async () => {
        try {
            const options = await SanBong.request('booking-options');
            $('homeDate').value = options.defaultDate || options.today; $('homeDate').min = options.today;
            if(options.defaultStart)$('homeStart').value=options.defaultStart.slice(0,5);
            if(options.defaultEnd)$('homeEnd').value=options.defaultEnd.slice(0,5);
            $('homeType').replaceChildren(new Option('Tất cả loại sân', ''));
            options.types.forEach(type => $('homeType').add(new Option(type.tenLoaiSan, type.maLoaiSan)));
            $('homeSearchForm').addEventListener('submit', event => {
                event.preventDefault();
                if ($('homeEnd').value <= $('homeStart').value) { $('homeEnd').setCustomValidity('Giờ kết thúc phải sau giờ bắt đầu.'); $('homeEnd').reportValidity(); return; }
                const query = new URLSearchParams({date:$('homeDate').value, start:$('homeStart').value, end:$('homeEnd').value, type:$('homeType').value});
                location.href = 'Man_hinh_chinh_Dat_san_KH.html?' + query;
            });
            $('homeEnd').addEventListener('input', () => $('homeEnd').setCustomValidity(''));
            $('homeStart').addEventListener('input', () => $('homeEnd').setCustomValidity(''));
            await Promise.all([
                populate($('homeBookings'), () => SanBong.request('bookings?' + new URLSearchParams({date:options.today})), (host,row) => {
                    const card=item(host,'','div'); card.className='border-b border-gray-100 pb-3 mb-3';
                    item(card, `${row.tenSan} · ${row.gioBatDau}–${row.gioKetThuc}`);
                    item(card, `${row.maDatSan} · ${row.trangThai} · ${money(row.tongTien)}`);
                    link(card,'Xem lịch / Hóa đơn','Quan_ly_lich_dat_san.html?' + new URLSearchParams({date:row.ngayChoi,pitch:row.maSan,booking:row.maDatSan}));
                }, 'Hôm nay chưa có booking của bạn.'),
                populate($('homePitches'), async () => options.pitches, (host,row) => {
                    const card=item(host,'','div'); card.className='bg-white border border-gray-100 rounded-2xl p-5 shadow-sm';
                    item(card, `${row.tenSan} (${row.maSan})`, 'h3');
                    item(card,row.tenLoaiSan||'Sân bóng FC-UTE');
                    link(card,'Chọn ngày và giờ →','Man_hinh_chinh_Dat_san_KH.html?'+new URLSearchParams({pitch:row.maSan}));
                }, 'Chưa có sân khả dụng.'),
                populate($('homeServices'), () => SanBong.request('booking-services'), (host,row) => {
                    const li=item(host,`${row.tenDV}: ${money(row.donGia)}`, 'li'); li.className='text-sm border-b border-gray-50 pb-2';
                }, 'Chưa có dịch vụ đang bán.')
            ]);
        } catch(error) { ['homeBookings','homePitches','homeServices'].forEach(id => {$(id).textContent=error.message;}); $('homeSearchForm').querySelector('button').disabled=true; }
    });
})();
