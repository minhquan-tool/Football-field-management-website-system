/* Pitch management uses the existing authenticated same-origin API helper. */
document.body.dataset.pitchApi = 'true';
let pitchAccount, pitchTypes = [], pitchPrices = [], pitchRequestVersion = 0, pitchEditing = false;
const pitchElement = id => document.getElementById(id);
const pitchCan = action => pitchAccount?.permissions.includes('CN02_' + action);
const pitchMoney = amount => Number(amount).toLocaleString('vi-VN') + 'đ';

function showToast(message) {
    pitchElement('toastMessage').textContent = message;
    pitchElement('toast').classList.add('show');
    setTimeout(() => pitchElement('toast').classList.remove('show'), 3000);
}
function switchView(view) {
    pitchElement('pitchGrid').classList.toggle('hidden', view !== 'grid');
    pitchElement('pitchTable').classList.toggle('hidden', view !== 'table');
    ['Grid', 'Table'].forEach(name => {
        pitchElement('btn' + name).classList.toggle('bg-brand-50', name.toLowerCase() === view);
        pitchElement('btn' + name).classList.toggle('text-brand-600', name.toLowerCase() === view);
    });
}
function pitchNode(tag, className, text) {
    const element = document.createElement(tag); element.className = className;
    if (text !== undefined) element.textContent = text;
    return element;
}
function pitchAction(text, className, callback) {
    const button = pitchNode('button', className, text); button.type = 'button';
    button.addEventListener('click', callback); return button;
}
function pitchActions(san) {
    const actions = pitchNode('div', 'flex flex-wrap gap-2');
    actions.append(pitchAction('Chi tiết', 'text-brand-600 font-bold text-xs', () => openDetailModal(san.maSan)));
    if (pitchCan('SUA')) {
        if (pitchAccount.maVaiTro === 'VT04') actions.append(pitchAction('Sửa', 'px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-lg text-xs font-bold', () => openEditModal(san.maSan)));
        const select=document.createElement('select');select.className='pitch-status-action';
        select.setAttribute('aria-label','Đổi trạng thái '+san.tenSan);
        for(const state of ['Trống','Đang sử dụng','Bảo trì'])select.add(new Option(state,state));
        select.value=san.trangThai;
        select.addEventListener('change',async()=>{select.disabled=true;try{await changePitchStatus(san.maSan,select.value);}finally{select.value=san.trangThai;select.disabled=false;}});
        actions.append(select);
    }
    return actions;
}
function pitchMinimum(san) {
    const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }).format(new Date());
    return pitchPrices.filter(p => p.maLoaiSan === san.maLoaiSan && p.ngayHieuLuc <= today && (!p.ngayHetHieuLuc || p.ngayHetHieuLuc >= today))
        .sort((a, b) => Number(a.donGia) - Number(b.donGia))[0];
}
function renderPitches(pitches) {
    const grid = pitchElement('pitchGrid'), rows = pitchElement('pitchRows'); grid.replaceChildren(); rows.replaceChildren();
    pitches.forEach(san => {
        const card = pitchNode('div', 'bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow');
        const head = pitchNode('div', 'h-32 bg-gradient-to-r from-blue-700 to-indigo-800 p-4 text-white flex flex-col justify-between relative');
        const badges = pitchNode('div', 'flex justify-between items-start');
        badges.append(pitchNode('span', 'bg-white/20 px-2.5 py-1 rounded-md text-xs font-bold', 'Mã: ' + san.maSan));
        const color = san.trangThai === 'Bảo trì' ? 'bg-red-500' : san.trangThai === 'Đang sử dụng' ? 'bg-orange-500' : 'bg-green-500';
        badges.append(pitchNode('span', color + ' text-white text-xs font-bold px-2.5 py-1 rounded-full', san.trangThai));
        const label = pitchNode('div', ''); label.append(pitchNode('h3', 'text-xl font-bold', san.tenSan), pitchNode('p', 'text-xs text-blue-100', san.tenLoaiSan));
        head.append(badges, label);
        const body = pitchNode('div', 'p-5 space-y-3'); body.append(pitchNode('p', 'text-xs text-gray-600', san.moTa || 'Chưa có mô tả.'));
        const min = pitchMinimum(san);
        body.append(pitchNode('p', 'text-xs font-bold text-gray-500', min ? 'Giá từ: ' + pitchMoney(min.donGia) + '/' + min.thoiLuong + 'h · ' + min.loaiNgay : 'Chưa có giá hiệu lực.'));
        body.append(pitchActions(san)); card.append(head, body); grid.append(card);
        const row = pitchNode('tr', 'hover:bg-gray-50');
        [san.maSan, san.tenSan, san.tenLoaiSan, san.trangThai, san.moTa || ''].forEach(value => row.append(pitchNode('td', 'p-4', value)));
        const actions = pitchNode('td', 'p-4'); actions.append(pitchActions(san)); row.append(actions); rows.append(row);
    });

    pitchElement('pitchFeedback').textContent = pitches.length ? 'Hiển thị ' + pitches.length + ' sân theo bộ lọc.' : 'Không có sân phù hợp.';
}
async function loadPitches() {
    const version = ++pitchRequestVersion;
    const params = new URLSearchParams({ q: pitchElement('searchPitch').value.trim(), type: pitchElement('filterType').value, status: pitchElement('filterStatus').value });
    pitchElement('pitchFeedback').textContent = 'Đang tải danh sách sân...';
    try {
        const [pitches, all] = await Promise.all([SanBong.request('pitches?' + params), SanBong.request('pitches')]);
        if (version === pitchRequestVersion) {
            renderPitches(pitches);
            const counts={statTotalPitch:all.length,statEmptyPitch:all.filter(p=>p.trangThai==='Trống').length,statActivePitch:all.filter(p=>p.trangThai==='Đang sử dụng').length,statMaintPitch:all.filter(p=>p.trangThai==='Bảo trì').length};
            Object.entries(counts).forEach(([id,count])=>pitchElement(id).textContent=count);
        }
        return true;
    } catch (error) {
        if (version === pitchRequestVersion) { pitchElement('pitchFeedback').textContent = error.message; showToast(error.message); }
        return false;
    }
}
function closeModal() { pitchElement('pitchModal').classList.add('hidden'); }
function closeDetailModal() { pitchElement('pitchDetailModal').classList.add('hidden'); }
function openAddPitchModal() {
    if (!pitchCan('THEM')) return;
    pitchEditing = false; pitchElement('pitchForm').reset();
    pitchElement('modalTitle').textContent = 'Thêm Sân Bóng Mới'; pitchElement('modalPitchId').readOnly = false;
    pitchElement('modalPitchStatus').value = 'Trống'; pitchElement('pitchModal').classList.remove('hidden');
}
async function openEditModal(id) {
    if (!pitchCan('SUA')) return;
    try {
        const san = await SanBong.request('pitches/' + encodeURIComponent(id)); pitchEditing = true;
        pitchElement('modalTitle').textContent = 'Chỉnh Sửa Sân Bóng ' + san.maSan;
        for (const [field, value] of Object.entries({ modalPitchId: san.maSan, modalPitchName: san.tenSan, modalPitchType: san.maLoaiSan, modalPitchStatus: san.trangThai, modalPitchDesc: san.moTa || '' })) pitchElement(field).value = value;
        pitchElement('modalPitchId').readOnly = true; pitchElement('pitchModal').classList.remove('hidden');
    } catch (error) { showToast(error.message); }
}
async function changePitchStatus(id, status) {
    if (!pitchCan('SUA') || !confirm('Chuyển sân ' + id + ' sang trạng thái ' + status + '?')) return;
    try {
        await SanBong.request('pitches/' + encodeURIComponent(id) + '/status', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ trangThai: status }) });
        showToast('Đã cập nhật trạng thái sân.'); await loadPitches();
    } catch (error) { showToast(error.message); }
}
function renderPriceTable(prices) {
    const wrapper = pitchNode('div', 'overflow-x-auto');
    if (!prices.length) { wrapper.textContent = 'Chưa có bảng giá cho loại sân này.'; return wrapper; }
    const table = pitchNode('table', 'w-full text-left text-xs'), head = pitchNode('tr', 'border-b border-gray-200');
    ['Loại ngày', 'Khung giờ', 'Thời lượng', 'Đơn giá', 'Hiệu lực'].forEach(value => head.append(pitchNode('th', 'p-2', value)));
    const thead = pitchNode('thead', ''); thead.append(head); table.append(thead);
    const tbody = pitchNode('tbody', '');
    prices.forEach(p => {
        const row = pitchNode('tr', 'border-b border-gray-100');
        [p.loaiNgay, p.gioBatDau.slice(0, 5) + '–' + p.gioKetThuc.slice(0, 5), p.thoiLuong + 'h', pitchMoney(p.donGia),
            p.ngayHieuLuc + ' → ' + (p.ngayHetHieuLuc || 'chưa có ngày kết thúc')].forEach(value => row.append(pitchNode('td', 'p-2', value)));
        tbody.append(row);
    }); table.append(tbody); wrapper.append(table); return wrapper;
}
async function openDetailModal(id) {
    try {
        const [san, prices] = await Promise.all([SanBong.request('pitches/' + encodeURIComponent(id)), SanBong.request('pitches/' + encodeURIComponent(id) + '/prices')]);
        pitchElement('detailTitle').textContent = san.maSan + ' · ' + san.tenSan;
        pitchElement('detailDescription').textContent = san.tenLoaiSan + ' · ' + san.trangThai + ' · ' + (san.moTa || '');
        pitchElement('detailContent').replaceChildren(pitchNode('h4', 'font-bold mb-3', 'Bảng giá theo loại sân'), renderPriceTable(prices));
        pitchElement('pitchDetailModal').classList.remove('hidden');
    } catch (error) { showToast(error.message); }
}
function openPitchTypeModal() {
    pitchElement('detailTitle').textContent = 'Danh mục loại sân'; pitchElement('detailDescription').textContent = 'Danh mục hiện tại từ SQL Server';
    const content = pitchElement('detailContent'); content.replaceChildren();
    pitchTypes.forEach(type => content.append(pitchNode('p', 'mb-3', type.maLoaiSan + ' · ' + type.tenLoaiSan + ' · ' + type.soNguoi + ' người' + (type.moTa ? ' · ' + type.moTa : ''))));
    pitchElement('pitchDetailModal').classList.remove('hidden');
}
document.addEventListener('sanbong:authenticated', async event => {
    pitchAccount = event.detail;
    try {
        [pitchTypes, pitchPrices] = await Promise.all([SanBong.request('pitch-types'), SanBong.request('pitch-prices')]);
        for (const id of ['filterType', 'modalPitchType']) {
            const select = pitchElement(id); select.replaceChildren();
            if (id === 'filterType') select.add(new Option('Tất cả loại sân', ''));
            pitchTypes.forEach(type => select.add(new Option(type.tenLoaiSan, type.maLoaiSan)));
        }
        pitchElement('addPitchButton').hidden = pitchAccount.maVaiTro !== 'VT04';
        pitchElement('addPitchButton').disabled = pitchAccount.maVaiTro !== 'VT04' || !pitchCan('THEM');
        pitchElement('pitchForm').querySelector('[type="submit"]').disabled = !(pitchCan('THEM') || pitchCan('SUA'));
        const initialStatus=new URLSearchParams(location.search).get('status');if(initialStatus&&[...pitchElement('filterStatus').options].some(o=>o.value===initialStatus))pitchElement('filterStatus').value=initialStatus;
        await loadPitches();
    } catch (error) { pitchElement('pitchFeedback').textContent = error.message; showToast(error.message); }
});
let pitchSearchTimer;
pitchElement('searchPitch').addEventListener('input', () => { clearTimeout(pitchSearchTimer); pitchSearchTimer = setTimeout(loadPitches, 250); });
['filterType', 'filterStatus'].forEach(id => pitchElement(id).addEventListener('change', loadPitches));
pitchElement('pitchForm').addEventListener('submit', async event => {
    event.preventDefault(); const button = event.currentTarget.querySelector('[type="submit"]');
    const payload = { maSan: pitchElement('modalPitchId').value.trim(), tenSan: pitchElement('modalPitchName').value.trim(), maLoaiSan: pitchElement('modalPitchType').value, trangThai: pitchElement('modalPitchStatus').value, moTa: pitchElement('modalPitchDesc').value.trim() };
    button.disabled = true;
    try {
        await SanBong.request('pitches' + (pitchEditing ? '/' + encodeURIComponent(payload.maSan) : ''), { method: pitchEditing ? 'PUT' : 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
        closeModal(); showToast(pitchEditing ? 'Đã cập nhật sân.' : 'Đã thêm sân.'); await loadPitches();
    } catch (error) { showToast(error.message); }
    finally { button.disabled = false; }
});

function refreshPitchData() {
    if (!pitchAccount || document.hidden || document.querySelector('#pitchModal:not(.hidden),#pitchDetailModal:not(.hidden)') || document.activeElement?.matches('input,select,textarea')) return;
    loadPitches();
}
setInterval(refreshPitchData,30000);
window.addEventListener('focus',refreshPitchData);
document.addEventListener('visibilitychange',refreshPitchData);
