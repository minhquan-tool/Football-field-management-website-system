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
    let customerBusy = false;
    let counterCustomerLookup;
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
        text('availabilityFeedback', loading ? 'Đang tra cứu...' : rows.length ? '' : 'Không có sân khả dụng trong khoảng giờ này.');
        receipt();
    }
    function enhanceTimePickers() {
        for (const id of ['startTime', 'endTime']) {
            const input = $(id);
            if (input.dataset.enhanced) continue;
            input.dataset.enhanced = 'true';
            const end = id === 'endTime', label = end ? 'Giờ kết thúc' : 'Giờ bắt đầu';
            const group = document.createElement('fieldset'); group.className = 'booking-time-picker';
            const legend = document.createElement('legend'); legend.textContent = label; group.append(legend);
            const controls = document.createElement('div'); controls.className = 'booking-time-controls';
            const hour = document.createElement('select'), minute = document.createElement('select');
            hour.setAttribute('aria-label', label + ' — giờ'); minute.setAttribute('aria-label', label + ' — phút');
            for (let h = 7; h <= (end ? 22 : 21); h++) {
                const period = h < 12 ? 'Sáng' : h < 18 ? 'Chiều' : 'Tối';
                hour.add(new Option(`${String(h).padStart(2, '0')} · ${period}`, String(h).padStart(2, '0')));
            }
            for (let m = 0; m < 60; m++) minute.add(new Option(String(m).padStart(2, '0') + ' phút', String(m).padStart(2, '0')));
            const initial = input.value.split(':'); hour.value = initial[0]; minute.value = initial[1];
            const separator = document.createElement('span'); separator.textContent = ':'; separator.setAttribute('aria-hidden', 'true');
            controls.append(hour, separator, minute); group.append(controls);
            input.parentElement.replaceWith(group); input.type = 'hidden'; input.required = false; group.append(input);
            function constrain() {
                for (const option of minute.options) option.disabled = end && ((hour.value === '22' && option.value !== '00') || (hour.value === '07' && option.value === '00'));
                if (minute.selectedOptions[0]?.disabled) minute.value = hour.value === '22' ? '00' : '01';
            }
            function update() { constrain(); input.value = `${hour.value}:${minute.value}`; input.dispatchEvent(new Event('change', { bubbles: true })); }
            hour.addEventListener('change', update); minute.addEventListener('change', update); constrain();
        }
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
    async function resolveCounterCustomer() {
        const phone = $('customerPhone').value.trim(), name = $('customerName').value.trim();
        const match = rows => {
            if (rows.length !== 1) throw new Error('Số điện thoại khớp nhiều khách hàng. Vui lòng kiểm tra lại.');
            const found = rows[0];
            if (found.hoTen.trim().normalize('NFC').toLocaleLowerCase('vi-VN') !== name.normalize('NFC').toLocaleLowerCase('vi-VN'))
                throw new Error('Số điện thoại đã thuộc khách hàng ' + found.hoTen + '. Vui lòng kiểm tra họ tên và số điện thoại.');
            return found;
        };
        const existing = await SanBong.request('booking-customers?' + new URLSearchParams({ phone }));
        if (existing.length) return match(existing);
        try { return await write('booking-customers', { hoTen: name, soDienThoai: phone }); }
        catch (error) {
            if (error.status !== 409) throw error;
            const concurrent = await SanBong.request('booking-customers?' + new URLSearchParams({ phone }));
            if (!concurrent.length) throw error;
            return match(concurrent);
        }
    }
    async function submit(event) {
        event.preventDefault(); if (saving || loading || customerBusy) return;
        const row = rows.find(r => r.maSan === selectedPitch);
        if (!row || !customer) { feedback('Chọn khách hàng, sân và khung giờ khả dụng.', true); return; }
        saving = true; renderChoices();
        try {
            if ($('counterBookingForm')) {
                $('customerPhone').readOnly = $('customerName').readOnly = true;
                customer = await resolveCounterCustomer();
            }
            const booking = await write('bookings', { maSan: row.maSan, gioBatDau: row.gioBatDau, gioKetThuc: row.gioKetThuc,
                ngayChoi: row.ngayChoi, maKH: customer.maKH, ghiChu: $('customerNote')?.value || null, dichVu: window.SanBongPrebook.selected() });
            feedback(`Đã tạo ${booking.maDatSan}: ${booking.trangThai}, ${money(booking.tongTien)}. Chưa thanh toán.`);
            for (const input of document.querySelectorAll('#prebookServices input')) input.value = '0';
            const box = $('createdBooking'); box.replaceChildren();
            box.append(element('p', `Phiếu ${booking.maDatSan} đã được lưu.`));
            const link = element('a', 'Xem lịch đặt sân', 'underline font-bold');
            link.href = (account.maVaiTro==='VT01'?'lich-dat-cua-toi?':'dieu-phoi-san?') + new URLSearchParams({ date: booking.ngayChoi, pitch: booking.maSan, booking:booking.maDatSan }); box.append(link);
            if (account.maVaiTro === 'VT01') { window.location.assign(link.href + '&payment=1'); return; }
            if(account.maVaiTro==='VT01'){const pay=element('a','Thanh toán ngay','bg-brand-600 text-white rounded-lg px-3 py-2 inline-block ml-3');pay.href=link.href+'&payment=1';box.append(pay);}
            selectedSlot = ''; await search();
        } catch (error) { feedback(error.message, true); await search(); }
        finally { saving = false; if ($('counterBookingForm')) { $('customerPhone').readOnly = false; if(counterCustomerLookup) await counterCustomerLookup(); } renderChoices(); }
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
    let staffDetails=new Map(),staffTab='all';
    function renderCalendar() {
        if(['VT02','VT04'].includes(account.maVaiTro)){renderStaffCalendar();return;}
        const body = $('bookingRows'); body.replaceChildren(); const staff=['VT02','VT04'].includes(account.maVaiTro);const query=staff?($('staffBookingSearch')?.value||'').trim().toLocaleLowerCase('vi-VN'):'';const visibleRows=rows.filter(r=>!query||[r.maDatSan,r.hoTen,r.tenSan].some(v=>String(v||'').toLocaleLowerCase('vi-VN').includes(query)));text('bookingCount', visibleRows.length);if(staff&&!document.getElementById('staffServiceHeading')){const head=body.closest('table').querySelector('thead tr');const th=element('th','Dịch vụ','p-4');th.id='staffServiceHeading';head.insertBefore(th,head.children[5]);}
        if (!visibleRows.length) { const tr = document.createElement('tr'); const td = element('td', 'Không có lượt đặt phù hợp.', 'p-4 text-gray-500'); td.colSpan = staff?8:7; tr.append(td); body.append(tr); }
        for (const row of visibleRows) {
            const tr = document.createElement('tr');
            for (const value of [row.maDatSan, row.hoTen, `${row.tenSan} (${row.tenLoaiSan})`,
                `${row.ngayChoi} ${range(row)}`, money(row.tongTien)]) tr.append(element('td', value, 'p-4'));
            if(staff)tr.append(element('td',Number(row.tienDichVu)>0?money(row.tienDichVu):'Không phát sinh','p-4'));
            const stateCell=element('td','','p-4'),state=element('span',row.trangThai,'fc-status');state.dataset.state=row.trangThai;stateCell.append(state);tr.append(stateCell);
            const td = document.createElement('td'); td.className = 'p-4 text-center';
            const actions=document.createElement('div');actions.className='booking-actions';td.append(actions);
            actions.append(action('Chi tiết', () => window.openDetailModal(row.maDatSan)));
            if (account.maVaiTro !== 'VT01' && window.SanBongOperations)
                actions.append(action(staff?'Nhận / Trả sân · Dịch vụ':'Nhận sân / Dịch vụ', () => SanBongOperations.open(row.maDatSan), 'bg-green-50 text-green-700'));
            if (account.maVaiTro !== 'VT01' && allowed('SUA') && row.trangThai === 'Chờ xác nhận')
                actions.append(action('Xác nhận', () => window.confirmBooking(row.maDatSan), 'bg-brand-600 text-white'));
            if (allowed('SUA') && ['Chờ xác nhận', 'Đã xác nhận'].includes(row.trangThai))
                actions.append(action(window.SanBongCancellation?.pending(row.maDatSan)?'Chờ duyệt hủy':'Yêu cầu hủy', () => {if(!window.SanBongCancellation?.pending(row.maDatSan))window.openCancelModal(row.maDatSan);}, 'bg-red-50 text-red-600'));
            if (account.maVaiTro !== 'VT01' && allowed('SUA') && ['Chờ xác nhận', 'Đã xác nhận'].includes(row.trangThai))
                actions.append(action('Đổi lịch cùng sân', () => reschedule(row), 'bg-yellow-50 text-yellow-800'));
            tr.append(td); body.append(tr);
        }
    }

    function staffState(row){
        if(row.trangThai==='Đã hủy')return 'cancelled';
        const d=staffDetails.get(row.maDatSan);if(!d||d.error)return 'unknown';
        if(d.visit?.thoiGianKetThuc||row.trangThai==='Đã sử dụng')return 'returned';
        if(d.visit)return 'playing';
        return 'waiting';
    }
    function renderStaffCalendar(){
        const body=$('bookingRows'),table=body.closest('table');table.classList.add('staff-dispatch-table');const filters=document.querySelector('.booking-search-panel');if(filters&&!filters.closest('details')){const advanced=document.createElement('details');advanced.className='dispatch-advanced';advanced.append(element('summary','Lọc theo ngày, sân và trạng thái'));filters.before(advanced);advanced.append(filters);}
        const head=table.querySelector('thead tr');head.replaceChildren();for(const title of ['Mã đơn','Khách hàng','Sân bóng','Ngày & giờ','Dịch vụ đính kèm','Trạng thái','Hành động điều phối'])head.append(element('th',title));
        const toolbar=$('staffDispatchTabs');if(toolbar&&!toolbar.childElementCount){toolbar.setAttribute('aria-label','Lọc trạng thái điều phối');for(const [value,label]of [['all','Tất cả'],['waiting','Chờ nhận sân'],['playing','Đang đá trên sân'],['returned','Đã trả sân'],['cancelled','Đã hủy']]){const button=element('button',label);button.type='button';button.dataset.dispatchTab=value;button.onclick=()=>{staffTab=value;renderCalendar();};toolbar.append(button);}}
        toolbar?.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.dispatchTab===staffTab)));
        const query=($('staffBookingSearch')?.value||'').trim().toLocaleLowerCase('vi-VN');
        const visible=rows.filter(r=>(staffTab==='all'||staffState(r)===staffTab)&&(!query||[r.maDatSan,r.hoTen,r.tenSan].some(v=>String(v||'').toLocaleLowerCase('vi-VN').includes(query))));
        text('bookingCount',visible.length);body.replaceChildren();
        for(const row of visible){
            const tr=document.createElement('tr'),code=element('td',''),link=element('button',row.maDatSan,'dispatch-code');link.type='button';link.onclick=()=>window.openDetailModal(row.maDatSan);code.append(link);tr.append(code);
            const customer=element('td','');customer.append(element('strong',row.hoTen));tr.append(customer,element('td',row.tenSan));
            const when=element('td','');when.append(element('span',row.ngayChoi),element('small',range(row),'dispatch-time'));tr.append(when);
            const details=staffDetails.get(row.maDatSan),services=element('td','');
            if(!details)services.append(element('span','Đang tải…','dispatch-muted'));
            else if(details.error)services.append(element('span','Không tải được dịch vụ','dispatch-error'));
            else if(!details.services.length)services.append(element('em','Không có','dispatch-muted'));
            else{const list=document.createElement('ul');for(const line of details.services)list.append(element('li',`${line.tenDV} · ${line.quyCach==='LOC_6'?'lốc 6':'đơn vị'} × ${line.soLuong} (${money(line.thanhTien)})`));services.append(list);}tr.append(services);
            const phase=staffState(row),state=element('td',''),badge=element('span',({playing:'Đang sử dụng',returned:'Đã trả sân',cancelled:'Đã hủy'})[phase]||row.trangThai,'dispatch-state');badge.dataset.phase=phase;state.append(badge);tr.append(state);
            const cell=element('td',''),actions=element('div','','dispatch-actions');
            const op=(label,focus,css)=>{const b=action(label,()=>SanBongOperations.open(row.maDatSan,focus),css);actions.append(b);};
            if(phase==='playing'){
                if(account.permissions.includes('CN03_THEM'))op('Dịch vụ','serviceCatalog','dispatch-service');
                if(allowed('SUA'))op('Trả sân','checkOutButton','dispatch-return');
            }else if(phase==='waiting'&&row.trangThai==='Đã xác nhận'&&allowed('SUA'))actions.append(action('Nhận sân',()=>window.receivePitch(row.maDatSan),'dispatch-checkin'));
            if(phase==='unknown')op('Xem vận hành','operationsClose','dispatch-secondary');
            if(row.trangThai==='Chờ xác nhận'&&allowed('SUA'))actions.append(action('Xác nhận',()=>window.confirmBooking(row.maDatSan),'dispatch-checkin'));
            // Preserve less frequent actions without competing with handover controls.
            const more=document.createElement('details'),summary=element('summary','Thao tác khác');more.append(summary,action('Chi tiết',()=>window.openDetailModal(row.maDatSan)));
            if(allowed('SUA')&&['Chờ xác nhận','Đã xác nhận'].includes(row.trangThai)){more.append(action('Hủy',()=>window.openCancelModal(row.maDatSan),'text-red-700'),action('Đổi lịch cùng sân',()=>reschedule(row)));}
            actions.append(more);cell.append(actions);tr.append(cell);body.append(tr);
        }
        if(!visible.length){const tr=document.createElement('tr'),td=element('td',loading?'Đang tải lượt đặt…':'Không có lượt đặt phù hợp.');td.colSpan=7;tr.append(td);body.append(tr);}
    }
    document.addEventListener('sanbong:check-in',()=>{staffTab='playing';renderCalendar();});
    document.addEventListener('sanbong:check-out',()=>{staffTab='returned';renderCalendar();});
    window.receivePitch=async id=>{
        if(saving||!allowed('SUA')||!confirm(`Xác nhận khách đã đến và nhận sân cho ${id}?`))return;
        saving=true;renderCalendar();
        try{
            await write(`operations/bookings/${encodeURIComponent(id)}/check-in`,{});
            staffTab='playing';await window.applyFilters();
            feedback(`Đã nhận sân ${id}. Khách đang đá trên sân; chọn Dịch vụ để thêm phát sinh.`);
        }catch(error){feedback(error.message,true);}
        finally{saving=false;renderCalendar();}
    };
    async function loadStaffDetails(version){
        let index=0;const targets=[...rows];
        await Promise.all(Array.from({length:Math.min(4,targets.length)},async()=>{while(index<targets.length){if(version!==sequence)return;const row=targets[index++];try{const d=await SanBong.request('operations/bookings/'+encodeURIComponent(row.maDatSan));if(version!==sequence)return;staffDetails.set(row.maDatSan,d);}catch(error){if(version!==sequence)return;staffDetails.set(row.maDatSan,{error:error.message});}renderCalendar();}}));
    }
    $('staffBookingSearch')?.addEventListener('input',()=>{if(['VT02','VT04'].includes(account?.maVaiTro))renderCalendar();});
    function reschedule(row) {
        const dialog=document.createElement('dialog');dialog.className='rounded-xl p-6 max-w-lg w-full';
        const form=document.createElement('form');form.className='space-y-3';
        const title=element('h3','Đổi lịch '+row.maDatSan,'font-bold');
        const note=element('p','Chỉ đổi lịch trên cùng sân, lượt đặt giờ tự do chưa có hóa đơn hoặc giao dịch. Giá được tính lại và cần xác nhận lại.','text-sm');form.append(title,note);
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
        rows = []; loading=true;staffDetails=new Map();renderCalendar(); text('bookingCount', '—');
        try { const result = await SanBong.request('bookings?' + query); if (version !== sequence) return;
            rows = result;loading=false;renderCalendar();if(['VT02','VT04'].includes(account.maVaiTro))await loadStaffDetails(version);
        } catch (error) { if (version === sequence){loading=false;renderCalendar();feedback(error.message, true);} }
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
            const customerView = ['VT01','VT02'].includes(account.maVaiTro);
            text('detailAmounts', customerView ? `Tiền sân: ${money(row.tienSan)}${Number(row.tienDichVu) ? ' · Dịch vụ: ' + money(row.tienDichVu) : ''}${Number(row.tienGiam) ? ' · Giảm giá: ' + money(row.tienGiam) : ''}` : `Tiền sân ${money(row.tienSan)} · Dịch vụ ${money(row.tienDichVu)} · Giảm ${money(row.tienGiam)} · Giá đã lưu ${money(row.donGia)} / ${row.thoiLuong} giờ`);
            const services = await SanBong.request('bookings/' + encodeURIComponent(id) + '/services');
            text('detailNote', (row.ghiChu || '') + '\n' + services.map(l => customerView ? `${l.tenDV} · ${l.quyCach === 'LOC_6' ? 'Lốc 6' : 'Đơn vị'} × ${l.soLuong}: ${money(l.thanhTien)}` : `${l.tenDV} · ${l.nguon} · ${l.quyCach} × ${l.soLuong}: ${money(l.thanhTien)}`).join('\n'));  $('detailModal').classList.remove('hidden');
        } catch (error) { feedback(error.message, true); }
    };
    window.closeDetailModal = () => $('detailModal').classList.add('hidden');
    window.openCancelModal = id => {
        $('cancelBookingId').value = id; text('cancelBookingCode', id); $('cancelReason').value = '';
        const customer=account.maVaiTro==='VT01';$('cancelForm').querySelector('p').firstChild.textContent=customer?'Gửi yêu cầu hủy lượt đặt ':'Hủy lượt đặt ';$('cancelModal').querySelector('h3').textContent=customer?'Gửi yêu cầu hủy':'Hủy đặt sân';$('cancelForm').querySelector('[type=submit]').textContent=customer?'Gửi yêu cầu':'Xác nhận hủy';$('cancelRefundRate').closest('.grid').children[1].hidden=customer;
        $('cancelRequester').value = account.maVaiTro === 'VT01' ? 'Khách hàng' : 'Nhân viên'; $('cancelModal').classList.remove('hidden');
    };
    window.closeCancelModal = () => $('cancelModal').classList.add('hidden');
    async function cancel(event) {
        event.preventDefault(); if (saving) return; saving = true; const button = event.currentTarget.querySelector('[type="submit"]'); button.disabled = true;
        const id = $('cancelBookingId').value;
        const customer=account.maVaiTro==='VT01';
        try { await write(`bookings/${encodeURIComponent(id)}/${customer?'cancellation-requests':'cancel'}`, { lyDo: $('cancelReason').value });
            window.closeCancelModal(); feedback(customer?`Đã gửi yêu cầu hủy ${id}; sân vẫn được giữ trong lúc chờ duyệt.`:`Đã hủy ${id}; xem chi tiết hóa đơn để kiểm tra khoản hoàn đang chờ xác nhận.`); document.dispatchEvent(new Event('sanbong:cancellation-updated')); await window.applyFilters();
        } catch (error) { feedback(error.message, true); alert(error.message); }
        finally { saving = false; button.disabled = false; renderCalendar(); }
    }
    document.addEventListener('sanbong:service-selection', () => { try { receipt(); } catch { text('receiptTotal', 'Kiểm tra số lượng dịch vụ'); } });
    document.addEventListener('sanbong:authenticated', async event => {
        account = event.detail;
        try {
            options = await SanBong.request('booking-options');
            if (calendar) {
                if (['VT02','VT04'].includes(account.maVaiTro)) document.body.classList.add('staff-booking-calendar');
                fillSelect('filterPitch', options.pitches, 'maSan', p => `${p.tenSan} (${p.maSan})`, 'Tất cả sân');
                fillSelect('filterSlot', options.slots, 'maKhungGio', range, 'Tất cả khung giờ');
                fillSelect('filterStatus', options.states.map(s => ({ id: s })), 'id', s => s.id, 'Tất cả trạng thái');
                const params = new URLSearchParams(location.search); $('filterDate').value = params.get('date') || options.today;
                $('filterPitch').value = params.get('pitch') || '';
                if (account.maVaiTro === 'VT01') {
                    document.body.classList.add('customer-booking-calendar');
                    document.title = 'Lịch đặt của tôi - FC-UTE';
                    const heading = document.querySelector('body > div > header h2');
                    if (heading) { heading.textContent = 'Lịch đặt của tôi'; if (heading.nextElementSibling) heading.nextElementSibling.textContent = 'Xem lượt đặt, trạng thái và chi tiết hóa đơn của bạn.'; }
                    document.querySelectorAll('a[href="dat-san-tai-quay"]').forEach(a => { a.href = 'dat-san'; a.textContent = 'Đặt sân mới'; });
                    const listHeading = document.querySelector('main h3'); if (listHeading) listHeading.textContent = 'Các lượt đặt của bạn';
                }
                document.addEventListener('sanbong:cancellation-loaded',()=>window.applyFilters()); $('cancelForm').addEventListener('submit', cancel); await window.applyFilters();
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
                enhanceTimePickers();
                $('startTime').addEventListener('change', search); $('endTime').addEventListener('change', search);
                $('playDate').addEventListener('change', search); $('bookingType').addEventListener('change', search);
                if (options.customer) { customer = options.customer; text('bookingCustomerPhone', customer.soDienThoai); }
                if ($('customerPhone')) {
                    const phoneInput=$('customerPhone'),nameInput=$('customerName');
                    const status=element('p','','text-sm text-gray-600');status.id='counterCustomerStatus';status.setAttribute('role','status');status.setAttribute('aria-live','polite');
                    phoneInput.setAttribute('aria-describedby',status.id);phoneInput.parentElement.append(status);
                    const retry=element('button','Thử tra cứu lại','text-sm text-brand-700 underline');retry.type='button';retry.hidden=true;status.after(retry);
                    let timer,lookupVersion=0,matchedPhone='',existingCustomer=null,lookupState='idle';
                    function syncCustomer(){
                        const phone=phoneInput.value.trim(),name=nameInput.value.trim();
                        customer=matchedPhone===phone&&lookupState==='existing'?existingCustomer:
                            matchedPhone===phone&&lookupState==='new'&&name?{hoTen:name,soDienThoai:phone}:null;
                        receipt();
                    }
                    async function lookup(){
                        clearTimeout(timer);timer=null;const version=++lookupVersion,phone=phoneInput.value.trim();
                        customer=null;existingCustomer=null;matchedPhone='';retry.hidden=true;
                        nameInput.value='';nameInput.readOnly=true;lookupState='loading';
                        if(!phone||!phoneInput.checkValidity()){
                            customerBusy=false;lookupState='idle';status.textContent=phone?'Nhập số điện thoại hợp lệ để tra cứu.':'Nhập số điện thoại để tìm hồ sơ khách hàng.';receipt();return;
                        }
                        customerBusy=true;status.textContent='Đang tra cứu khách hàng…';receipt();
                        try{
                            const found=await SanBong.request('booking-customers?'+new URLSearchParams({phone}));
                            if(version!==lookupVersion||phone!==phoneInput.value.trim())return;
                            if(found.length>1)throw Error('Số điện thoại khớp nhiều hồ sơ. Vui lòng liên hệ quản lý.');
                            matchedPhone=phone;
                            if(found.length){existingCustomer=found[0];lookupState='existing';nameInput.value=existingCustomer.hoTen;status.textContent='Khách đã có hồ sơ tại sân.';}
                            else{lookupState='new';nameInput.readOnly=false;status.textContent='Khách mới — vui lòng nhập họ tên.';}
                        }catch(error){
                            if(version!==lookupVersion||phone!==phoneInput.value.trim())return;
                            lookupState='error';matchedPhone='';status.textContent='Không tra cứu được: '+error.message;retry.hidden=false;
                        }finally{if(version===lookupVersion){customerBusy=false;syncCustomer();}}
                    }
                    phoneInput.addEventListener('input',()=>{
                        clearTimeout(timer);++lookupVersion;customer=null;matchedPhone='';existingCustomer=null;lookupState='idle';
                        nameInput.value='';nameInput.readOnly=true;retry.hidden=true;customerBusy=true;
                        status.textContent='Đang chờ tra cứu số điện thoại…';receipt();timer=setTimeout(lookup,400);
                    });
                    phoneInput.addEventListener('blur',()=>{if(timer){clearTimeout(timer);timer=null;lookup();}});
                    nameInput.addEventListener('input',syncCustomer);retry.addEventListener('click',lookup);
                    counterCustomerLookup=lookup;await lookup();
                }
                ($('bookingForm') || $('counterBookingForm')).addEventListener('submit', submit); await search();
            }
        } catch (error) { feedback(error.message, true); }
    });
})();
