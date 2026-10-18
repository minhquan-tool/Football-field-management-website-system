(() => {
    'use strict';
    const $ = id => document.getElementById(id);
    const money = value => Number(value).toLocaleString('vi-VN') + 'đ';
    let account, id, current, catalog = [], busy = false, version = 0;
    const allowed = permission => account?.permissions.includes(permission);
    const set = (name, text) => $(name).textContent = text;
    const editable = () => current?.visit && !current.visit.thoiGianKetThuc && current.booking.trangThai === 'Đã xác nhận';
    function feedback(message, error = false) { set('operationsFeedback', message); $('operationsFeedback').className = error ? 'text-sm text-red-600' : 'text-sm text-brand-700'; }
    function render() {
        if (!current) return;
        const booking = current.booking;
        $('confirmOperationsButton').hidden = booking.trangThai !== 'Chờ xác nhận';
        $('confirmOperationsButton').disabled = busy || !allowed('CN02_SUA');
        set('operationsTitle', 'Nhận sân / Dịch vụ · ' + id);
        set('operationsSummary', `${booking.tenSan} · ${booking.ngayChoi} · ${booking.trangThai} · ${current.visit ? current.visit.thoiGianKetThuc ? 'Đã trả sân' : 'Đã nhận sân' : 'Chưa nhận sân'}`);
        $('checkInButton').disabled = busy || !allowed('CN02_SUA') || Boolean(current.visit) || booking.trangThai !== 'Đã xác nhận';
        $('checkOutButton').disabled = busy || !allowed('CN02_SUA') || !editable();
        $('addServiceButton').disabled = busy || !allowed('CN03_THEM') || !editable() || !catalog.length;
        set('operationsAmounts', `Tiền sân ${money(booking.tienSan)} + Dịch vụ ${money(booking.tienDichVu)} − Giảm ${money(booking.tienGiam)} = ${money(booking.tongTien)}`);
        const body = $('serviceLines'); body.replaceChildren();
        for (const line of current.services) {
            const tr = document.createElement('tr');
            for (const value of [`${line.tenDV} · ${line.nguon} · ${line.quyCach}`, line.soLuong, money(line.donGia), money(line.thanhTien)]) { const td = document.createElement('td'); td.className = 'p-2'; td.textContent = value; tr.append(td); }
            const td = document.createElement('td'); td.className = 'p-2';
            if (allowed('CN03_SUA') && editable()) {
                const quantity = document.createElement('input'); quantity.type = 'number'; quantity.min = '1'; quantity.max = '2147483647'; quantity.value = line.soLuong;
                quantity.className = 'border rounded-lg p-1 w-20'; quantity.disabled = busy;
                const button = document.createElement('button'); button.type = 'button'; button.textContent = 'Lưu SL'; button.className = 'text-brand-600 font-bold px-2'; button.disabled = busy;
                button.addEventListener('click', () => { if (!quantity.checkValidity()) return quantity.reportValidity(); mutate(`/service-lines/${encodeURIComponent(line.maChiTiet)}`, 'PUT', { soLuong: Number(quantity.value) }, 'Đã sửa số lượng, giữ giá đã lưu.'); }); td.append(quantity, button);
            }
            if (allowed('CN03_XOA') && editable()) {
                const button = document.createElement('button'); button.type = 'button'; button.textContent = 'Xóa'; button.className = 'text-red-600 font-bold px-2'; button.disabled = busy;
                button.addEventListener('click', () => { if (confirm('Xóa dòng dịch vụ chưa chốt này?')) mutate(`/service-lines/${encodeURIComponent(line.maChiTiet)}`, 'DELETE', undefined, 'Đã xóa dòng dịch vụ.'); }); td.append(button);
            }
            tr.append(td); body.append(tr);
        }
        if (!current.services.length) { const tr = document.createElement('tr'), td = document.createElement('td'); td.colSpan = 5; td.className = 'p-2 text-gray-500'; td.textContent = 'Chưa có dịch vụ.'; tr.append(td); body.append(tr); }
    }
    async function open(bookingId) {
        const requestVersion = ++version; id = bookingId; current = null;
        $('operationsModal').classList.remove('hidden'); $('operationsModal').classList.add('flex');
        $('serviceLines').replaceChildren(); set('operationsAmounts', ''); set('operationsSummary', '');
        for (const button of $('operationsModal').querySelectorAll('button:not(#operationsClose)')) button.disabled = true;
        feedback('Đang tải...');
        try {
            const [details, services] = await Promise.all([SanBong.request(`operations/bookings/${encodeURIComponent(id)}`),
                allowed('CN03_XEM') ? SanBong.request('services') : Promise.resolve([])]);
            if (requestVersion !== version) return; current = details; catalog = services;
            $('serviceCatalog').replaceChildren(); for (const service of catalog) $('serviceCatalog').add(new Option(`${service.tenDV} · ${money(service.donGia)}`, service.maDV));
            preview(); feedback(''); render();
        } catch (error) { if (requestVersion === version) feedback(error.message, true); }
    }
    async function mutate(path, method, body, success) {
        if (busy || !current) return; busy = true; render(); const target = id;
        try {
            await SanBong.request(`operations/bookings/${encodeURIComponent(target)}${path}`, { method,
                headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) });
            current = await SanBong.request(`operations/bookings/${encodeURIComponent(target)}`); feedback(success);
            await window.applyFilters();
        } catch (error) { feedback(error.message, true); }
        finally { busy = false; render(); }
    }
    function preview() {
        const item = catalog.find(c => c.maDV === $('serviceCatalog').value);
        const pack = $('servicePack'); pack.querySelector('[value="LOC_6"]').disabled = !item?.hoTroLoc;
        if (!item?.hoTroLoc) pack.value = 'DON_VI';
        set('servicePreview', item ? money(Number(pack.value === 'LOC_6' ? item.giaLoc : item.donGia) * Number($('serviceQuantity').value)) : '');
    }
    for (const name of ['serviceCatalog', 'servicePack', 'serviceQuantity']) $(name).addEventListener('change', preview);
    $('operationsClose').addEventListener('click', () => { if (busy) return; ++version; $('operationsModal').classList.add('hidden'); $('operationsModal').classList.remove('flex'); });
    $('checkInButton').addEventListener('click', () => mutate('/check-in', 'POST', {}, 'Đã nhận sân.'));
    $('confirmOperationsButton').addEventListener('click', async () => {
        if (busy || !current || !allowed('CN02_SUA')) return;
        busy = true; render();
        try {
            await SanBong.request('bookings/' + encodeURIComponent(id) + '/confirm', { method:'POST' });
            current = await SanBong.request('operations/bookings/' + encodeURIComponent(id));
            feedback('Đã xác nhận lượt đặt.'); await window.applyFilters();
        } catch (error) { feedback(error.message, true); }
        finally { busy = false; render(); }
    });
    $('checkOutButton').addEventListener('click', () => { if (confirm('Trả sân và kết thúc chỉnh dịch vụ? Thao tác này không tự ghi nhận thanh toán mới.')) mutate('/check-out', 'POST', {}, 'Đã trả sân; xem hóa đơn để kiểm tra số còn thiếu.'); });
    $('serviceLineForm').addEventListener('submit', event => { event.preventDefault(); mutate(`/services/${encodeURIComponent($('serviceCatalog').value)}`, 'POST', { soLuong: Number($('serviceQuantity').value), quyCach: $('servicePack').value }, 'Đã ghi dịch vụ theo giá SQL Server.'); });
    document.addEventListener('sanbong:authenticated', event => { account = event.detail; });
    window.SanBongOperations = { open: bookingId => { if (!busy) open(bookingId); } };
})();
