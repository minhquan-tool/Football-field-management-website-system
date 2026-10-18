/* Phase 4: same-origin REST, server prices/ownership/transactions remain authoritative. */
(() => {
    'use strict';
    document.body.dataset.bookingApi = 'true';
    const $ = id => document.getElementById(id);
    const money = value => Number(value).toLocaleString('vi-VN') + 'đ';
    const time = value => value.slice(0, 5);
    const range = row => `${time(row.gioBatDau)} - ${time(row.gioKetThuc)}`;
    const calendar = Boolean($('bookingRows'));
    let account, options, rows = [], selectedPitch = '', selectedSlot = '', customer, loading = true, saving = false, sequence = 0;
    let customerBusy = false, customerSequence = 0, newCustomerMode = false;
    const allowed = action => account?.permissions.includes('CN02_' + action);
    function text(id, value) { if ($(id)) $(id).textContent = value; }
    function element(tag, value, css = '') {
        const el = document.createElement(tag); el.textContent = value; el.className = css; return el;
    }
    function feedback(message, error = false) {
        const el = $(calendar ? 'calendarFeedback' : 'bookingFeedback');
        el.textContent = message; el.className = error ? 'text-sm text-red-600' : 'text-sm text-brand-700';
    }
    async function write(path, body) {
        return SanBong.request(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    }
    function receipt() {
        const row = rows.find(r => r.maSan === selectedPitch);
        const pitch = options?.pitches.find(p => p.maSan === selectedPitch);
        text('receiptCustomer', customer ? `${customer.hoTen} (${customer.soDienThoai})` : 'Chưa chọn khách hàng');
        text('receiptPitch', pitch ? `${pitch.tenSan} (${pitch.maSan})` : 'Chưa chọn sân');
        text('receiptTime', row ? `${row.ngayChoi} ${range(row)} (${row.thoiLuong} giờ)` : 'Chưa chọn khung giờ');
        text('receiptPitchPrice', row ? money(row.donGia) : '—'); text('receiptTotal', row ? money(Number(row.tongTien) + (window.SanBongPrebook?.total() || 0)) : '—');
        const submit = document.querySelector('#bookingForm [type="submit"], #counterBookingForm [type="submit"]');
        if (submit) submit.disabled = !allowed('THEM') || loading || saving || customerBusy || !row || !customer;
    }
    function renderChoices() {
        const pitches = $('bookingPitches'); pitches.replaceChildren();
        const availablePitches = options.pitches.filter(p => rows.some(r => r.maSan === p.maSan));
        if (!loading && !availablePitches.some(p => p.maSan === selectedPitch)) selectedPitch = '';
        if (!rows.some(r => r.maSan === selectedPitch)) selectedSlot = '';
        for (const pitch of availablePitches) {
            const button = element('button', `${pitch.tenSan} (${pitch.maSan})`,
                `border rounded-xl p-3 text-sm font-bold ${selectedPitch === pitch.maSan ? 'border-brand-600 bg-brand-50 text-brand-700' : 'border-gray-200 hover:border-brand-500'}`);
            button.type = 'button'; button.disabled = loading || saving;
            button.setAttribute('aria-pressed',String(selectedPitch===pitch.maSan));
            button.addEventListener('click', () => { selectedPitch = pitch.maSan; selectedSlot = ''; renderChoices(); }); pitches.append(button);
        }
        text('availabilityFeedback', loading ? 'Đang tra cứu...' : rows.length ? 'Chọn sân còn trống cho khoảng giờ đã nhập.' : 'Không có sân khả dụng trong khoảng giờ này.');
        receipt();
    }
    async function search() {
        const version = ++sequence; loading = true; rows = []; renderChoices();
        const query = new URLSearchParams({ date: $('playDate').value, type: $('bookingType').value,
            start: $('startTime').value, end: $('endTime').value });
        try {
            const result = await SanBong.request('availability?' + query);
            if (version !== sequence) return; rows = result; loading = false; renderChoices();
        } catch (error) { if (version === sequence) { loading = false; renderChoices(); feedback(error.message, true); } }
    }
    function customerMode(create) {
        newCustomerMode = create; $('customerName').readOnly = !create;
        $('customerName').maxLength = 100;
        $('createCustomerButton').hidden = !create || !allowed('THEM');
    }
    function customerLoading(busy) {
        customerBusy = busy; $('lookupCustomerButton').disabled = busy || !allowed('THEM');
        $('lookupCustomerButton').textContent = busy ? 'Đang xử lý...' : 'Tra cứu';
        $('createCustomerButton').disabled = busy || !allowed('THEM'); receipt();
    }
    function chooseCustomer(value) {
        customer = value; $('customerName').value = value.hoTen; customerMode(false); receipt();
    }
    window.lookupCustomer = async () => {
        if (customerBusy || !allowed('THEM')) return;
        const phone = $('customerPhone').value.trim(), version = ++customerSequence;
        customer = null; $('customerName').value = ''; customerMode(false); customerLoading(true);
        try {
            const matches = await SanBong.request('booking-customers?' + new URLSearchParams({ phone }));
            if (version !== customerSequence || $('customerPhone').value.trim() !== phone) return;
            if (!matches.length) { customerMode(true); feedback('Chưa có khách hàng. Nhập họ tên rồi chọn Tạo khách để tiếp tục.'); $('customerName').focus(); return; }
            chooseCustomer(matches[0]); feedback('Đã tìm khách hàng từ SQL Server.');
        } catch (error) { if (version === customerSequence) feedback(error.message, true); }
        finally { customerLoading(false); }
    };
    window.createCounterCustomer = async () => {
        if (customerBusy || !newCustomerMode || !allowed('THEM')) return;
        const phone = $('customerPhone').value.trim(), name = $('customerName').value.trim(), version = ++customerSequence;
        if (!name || name.length > 100 || !/^[0-9+]{7,15}$/.test(phone)) { feedback('Nhập họ tên (tối đa 100 ký tự) và SĐT hợp lệ (7–15 ký tự).', true); return; }
        customerLoading(true);
        try {
            const created = await write('booking-customers', { hoTen: name, soDienThoai: phone });
            if (version !== customerSequence || $('customerPhone').value.trim() !== phone) return;
            chooseCustomer(created); feedback('Đã tạo hồ sơ khách. Có thể tiếp tục đặt sân.');
        } catch (error) {
            if (version !== customerSequence) return;
            feedback(error.message, true);
            if (error.status === 409) {
                try {
                    const matches = await SanBong.request('booking-customers?' + new URLSearchParams({ phone }));
                    if (version !== customerSequence) return;
                    if (matches.length) { chooseCustomer(matches[0]); feedback('Khách hàng với số điện thoại này đã tồn tại. Đã chọn hồ sơ hiện có.', true); }
                } catch (lookupError) { if (version === customerSequence) feedback(lookupError.message, true); }
            }
        } finally { customerLoading(false); }
    };
    async function submit(event) {
        event.preventDefault(); if (saving || loading) return;
        const row = rows.find(r => r.maSan === selectedPitch);
        if (!row || !customer) { feedback('Chọn khách hàng, sân và khung giờ khả dụng.', true); return; }
        saving = true; renderChoices();
        try {
            const booking = await write('bookings', { maSan: row.maSan, gioBatDau: row.gioBatDau, gioKetThuc: row.gioKetThuc,
                ngayChoi: row.ngayChoi, maKH: customer.maKH, ghiChu: $('customerNote')?.value || null, dichVu: window.SanBongPrebook.selected() });
            feedback(`Đã tạo ${booking.maDatSan}: ${booking.trangThai}, ${money(booking.tongTien)}. Chưa thanh toán.`);
            for (const input of document.querySelectorAll('#prebookServices input')) input.value = '0';
            const box = $('createdBooking'); box.replaceChildren();
            box.append(element('p', `Phiếu ${booking.maDatSan} đã lưu trong SQL Server.`));
            const link = element('a', 'Xem lịch đặt sân', 'underline font-bold');
            link.href = 'Quan_ly_lich_dat_san.html?' + new URLSearchParams({ date: booking.ngayChoi, pitch: booking.maSan, booking:booking.maDatSan }); box.append(link);
            if(account.maVaiTro==='VT01'){const pay=element('a','Thanh toán ngay','bg-brand-600 text-white rounded-lg px-3 py-2 inline-block ml-3');pay.href=link.href+'&payment=1';box.append(pay);}
            selectedSlot = ''; await search();
        } catch (error) { feedback(error.message, true); await search(); }
        finally { saving = false; renderChoices(); }
    }
    function fillSelect(id, data, key, label, first) {
        const select = $(id); select.replaceChildren();
        if (first) select.add(new Option(first, ''));
        for (const row of data) select.add(new Option(label(row), row[key]));
    }
    function action(label, callback, css = 'bg-gray-100 text-gray-700') {
        const button = element('button', label, `${css} text-xs px-2 py-1 rounded-lg font-bold mr-1`);
        button.type = 'button'; button.disabled = saving; button.addEventListener('click', callback); return button;
    }
    function renderCalendar() {
        const body = $('bookingRows'); body.replaceChildren(); text('bookingCount', rows.length);
        if (!rows.length) { const tr = document.createElement('tr'); const td = element('td', 'Không có booking theo bộ lọc.', 'p-4 text-gray-500'); td.colSpan = 7; tr.append(td); body.append(tr); }
        for (const row of rows) {
            const tr = document.createElement('tr');
            for (const value of [row.maDatSan, row.hoTen, `${row.tenSan} (${row.tenLoaiSan})`,
                `${row.ngayChoi} ${range(row)}`, money(row.tongTien)]) tr.append(element('td', value, 'p-4'));
            const stateCell=element('td','','p-4'),state=element('span',row.trangThai,'fc-status');state.dataset.state=row.trangThai;stateCell.append(state);tr.append(stateCell);
            const td = document.createElement('td'); td.className = 'p-4 text-center';
            td.append(action('Chi tiết', () => window.openDetailModal(row.maDatSan)));
            if (account.maVaiTro !== 'VT01' && window.SanBongOperations)
                td.append(action('Nhận sân / Dịch vụ', () => SanBongOperations.open(row.maDatSan), 'bg-green-50 text-green-700'));
            if (account.maVaiTro !== 'VT01' && allowed('SUA') && row.trangThai === 'Chờ xác nhận')
                td.append(action('Xác nhận', () => window.confirmBooking(row.maDatSan), 'bg-brand-600 text-white'));
            if (allowed('SUA') && ['Chờ xác nhận', 'Đã xác nhận'].includes(row.trangThai))
                td.append(action('Hủy', () => window.openCancelModal(row.maDatSan), 'bg-red-50 text-red-600'));
            if (account.maVaiTro !== 'VT01' && allowed('SUA') && ['Chờ xác nhận', 'Đã xác nhận'].includes(row.trangThai))
                td.append(action('Đổi lịch cùng sân', () => reschedule(row), 'bg-yellow-50 text-yellow-800'));
            tr.append(td); body.append(tr);
        }
    }
    function reschedule(row) {
        const dialog=document.createElement('dialog');dialog.className='rounded-xl p-6 max-w-lg w-full';
        const form=document.createElement('form');form.className='space-y-3';
        const title=element('h3','Đổi lịch '+row.maDatSan,'font-bold');
        const note=element('p','Chỉ đổi lịch trên cùng sân, booking giờ tự do chưa có hóa đơn/giao dịch. Giá được tính lại và cần xác nhận lại.','text-sm');form.append(title,note);
        for(const [name,label,type,value] of [['ngayChoi','Ngày mới','date',row.ngayChoi],['gioBatDau','Bắt đầu','time',time(row.gioBatDau)],['gioKetThuc','Kết thúc','time',time(row.gioKetThuc)],['lyDo','Lý do','text','']]){
            const wrap=element('label',label,'block'),input=document.createElement('input');input.name=name;input.type=type;input.value=value;input.required=true;input.className='border p-2 block w-full';if(name==='lyDo')input.maxLength=255;wrap.append(input);form.append(wrap);
        }
        const error=element('p','','text-red-700'),save=element('button','Lưu lịch mới','bg-brand-600 text-white p-2 rounded'),close=element('button','Đóng','p-2');close.type='button';close.onclick=()=>dialog.close();form.append(error,save,close);dialog.append(form);document.body.append(dialog);dialog.addEventListener('close',()=>dialog.remove());dialog.showModal();
        form.onsubmit=async e=>{e.preventDefault();if(saving)return;saving=true;save.disabled=true;try{await write('bookings/'+encodeURIComponent(row.maDatSan)+'/reschedule',Object.fromEntries(new FormData(form)));dialog.close();feedback('Đã đổi lịch, cần xác nhận lại.');await window.applyFilters();}catch(err){error.textContent=err.message;}finally{saving=false;save.disabled=false;renderCalendar();}};
    }
    window.applyFilters = async () => {
        const version = ++sequence;
        const query = new URLSearchParams({ date: $('filterDate').value, pitch: $('filterPitch').value,
            slot: $('filterSlot').value, status: $('filterStatus').value });
        rows = []; renderCalendar(); text('bookingCount', '—');
        try { const result = await SanBong.request('bookings?' + query); if (version !== sequence) return;
            rows = result; renderCalendar();
        } catch (error) { if (version === sequence) feedback(error.message, true); }
    };
    window.confirmBooking = async id => {
        if (saving || !confirm(`Xác nhận booking ${id}?`)) return; saving = true; renderCalendar();
        try { await write(`bookings/${encodeURIComponent(id)}/confirm`, {}); feedback(`Đã xác nhận ${id}.`); await window.applyFilters(); }
        catch (error) { feedback(error.message, true); await window.applyFilters(); }
        finally { saving = false; renderCalendar(); }
    };
    window.openDetailModal = async id => {
        try {
            const row = await SanBong.request('bookings/' + encodeURIComponent(id));
            text('modalBookingId', 'Chi tiết ' + row.maDatSan); text('detailCustomer', row.hoTen);
            text('detailPitch', `${row.tenSan} (${row.maSan})`); text('detailTime', `${row.ngayChoi} ${range(row)}`);
            text('detailStatus', row.trangThai); text('detailTotal', money(row.tongTien));
            text('detailAmounts', `Tiền sân ${money(row.tienSan)} · Dịch vụ ${money(row.tienDichVu)} · Giảm ${money(row.tienGiam)} · Giá đã lưu ${money(row.donGia)} / ${row.thoiLuong} giờ`);
            const services = await SanBong.request('bookings/' + encodeURIComponent(id) + '/services');
            text('detailNote', (row.ghiChu || '') + '\n' + services.map(l => `${l.tenDV} · ${l.nguon} · ${l.quyCach} × ${l.soLuong}: ${money(l.thanhTien)}`).join('\n'));  $('detailModal').classList.remove('hidden');
        } catch (error) { feedback(error.message, true); }
    };
    window.closeDetailModal = () => $('detailModal').classList.add('hidden');
    window.openCancelModal = id => {
        $('cancelBookingId').value = id; text('cancelBookingCode', id); $('cancelReason').value = '';
        $('cancelRequester').value = account.maVaiTro === 'VT01' ? 'Khách hàng' : 'Nhân viên'; $('cancelModal').classList.remove('hidden');
    };
    window.closeCancelModal = () => $('cancelModal').classList.add('hidden');
    async function cancel(event) {
        event.preventDefault(); if (saving) return; saving = true; const button = event.currentTarget.querySelector('[type="submit"]'); button.disabled = true;
        const id = $('cancelBookingId').value;
        try { await write(`bookings/${encodeURIComponent(id)}/cancel`, { lyDo: $('cancelReason').value });
            window.closeCancelModal(); feedback(`Đã hủy ${id}; xem chi tiết hóa đơn để kiểm tra khoản hoàn đang chờ xác nhận.`); await window.applyFilters();
        } catch (error) { feedback(error.message, true); alert(error.message); }
        finally { saving = false; button.disabled = false; renderCalendar(); }
    }
    document.addEventListener('sanbong:service-selection', () => { try { receipt(); } catch { text('receiptTotal', 'Kiểm tra số lượng dịch vụ'); } });
    document.addEventListener('sanbong:authenticated', async event => {
        account = event.detail;
        try {
            options = await SanBong.request('booking-options');
            if (calendar) {
                fillSelect('filterPitch', options.pitches, 'maSan', p => `${p.tenSan} (${p.maSan})`, 'Tất cả sân');
                fillSelect('filterSlot', options.slots, 'maKhungGio', range, 'Tất cả khung giờ');
                fillSelect('filterStatus', options.states.map(s => ({ id: s })), 'id', s => s.id, 'Tất cả trạng thái');
                const params = new URLSearchParams(location.search); $('filterDate').value = params.get('date') || options.today;
                $('filterPitch').value = params.get('pitch') || '';
                if (account.maVaiTro === 'VT01') document.querySelectorAll('a[href="Dat_san_tai_quay.html"]').forEach(a => a.href = 'Man_hinh_chinh_Dat_san_KH.html');
                $('cancelForm').addEventListener('submit', cancel); await window.applyFilters();
                if (params.get('booking')) await window.openDetailModal(params.get('booking'));
            } else {
                fillSelect('bookingType', options.types, 'maLoaiSan', t => t.tenLoaiSan, 'Tất cả loại sân');
                const homeParams = new URLSearchParams(location.search);
                selectedPitch = SanBong.bookingIntent(homeParams).get('pitch') || '';
                $('playDate').value = homeParams.get('date') || options.defaultDate || options.today; $('playDate').min = options.today;
                if(options.defaultStart)$('startTime').value=options.defaultStart.slice(0,5);
                if(options.defaultEnd)$('endTime').value=options.defaultEnd.slice(0,5);
                if (homeParams.has('start')) $('startTime').value = homeParams.get('start');
                if (homeParams.has('end')) $('endTime').value = homeParams.get('end');
                if (homeParams.has('type')) $('bookingType').value = homeParams.get('type');
                $('playDate').required = true;
                $('startTime').addEventListener('change', search); $('endTime').addEventListener('change', search);
                $('playDate').addEventListener('change', search); $('bookingType').addEventListener('change', search);
                if (options.customer) { customer = options.customer; text('bookingCustomerPhone', customer.soDienThoai); }
                if ($('customerPhone')) {
                    customerMode(false); customerLoading(false);
                    $('customerPhone').addEventListener('input', () => { ++customerSequence; customer = null; $('customerName').value = ''; customerMode(false); receipt(); });
                }
                ($('bookingForm') || $('counterBookingForm')).addEventListener('submit', submit); await search();
            }
        } catch (error) { feedback(error.message, true); }
    });
})();
