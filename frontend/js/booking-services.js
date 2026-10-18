/* Prices are supplied by API; final snapshots are determined in the booking transaction. */
(() => {
    const root = document.getElementById('prebookServices');
    if (!root) return;
    let catalog = [], ready = false;
    const money = n => Number(n).toLocaleString('vi-VN') + 'đ';
    const selected = () => {
        if (!ready) throw new Error('Danh mục dịch vụ chưa tải được. Vui lòng tải lại trang.');
        const result = [];
        for (const input of root.querySelectorAll('input[data-sku]')) {
            if (!input.checkValidity()) { input.reportValidity(); throw new Error('Số lượng dịch vụ phải là số nguyên không âm.'); }
            if (Number(input.value) > 0) result.push({ maDV: input.dataset.sku, quyCach: input.dataset.pack, soLuong: Number(input.value) });
        }
        return result;
    };
    const total = () => ready ? selected().reduce((sum, line) => {
        const item = catalog.find(c => c.maDV === line.maDV);
        return sum + line.soLuong * Number(line.quyCach === 'LOC_6' ? item.giaLoc : item.donGia);
    }, 0) : 0;
    window.SanBongPrebook = { selected, total };
    document.addEventListener('sanbong:authenticated', async () => {
        try {
            catalog = await SanBong.request('booking-services'); root.replaceChildren();
            for (const item of catalog) {
                const row = document.createElement('div'); row.className = 'border-b py-3 flex flex-wrap gap-3 items-center';
                const title = document.createElement('span'); title.className = 'font-bold'; title.textContent = item.tenDV; row.append(title);
                for (const pack of item.hoTroLoc ? ['DON_VI', 'LOC_6'] : ['DON_VI']) {
                    const label = document.createElement('label'); label.className = 'text-sm';
                    label.textContent = `${pack === 'LOC_6' ? 'Lốc 6' : item.donViTinh || 'Đơn vị'} · ${money(pack === 'LOC_6' ? item.giaLoc : item.donGia)} `;
                    const input = document.createElement('input'); input.type = 'number'; input.min = '0'; input.max = '2147483647'; input.step = '1'; input.value = '0';
                    input.dataset.sku = item.maDV; input.dataset.pack = pack; input.className = 'border rounded-lg p-2 w-20';
                    input.addEventListener('input', () => document.dispatchEvent(new Event('sanbong:service-selection')));
                    label.append(input); row.append(label);
                }
                root.append(row);
            }
            ready = true; document.dispatchEvent(new Event('sanbong:service-selection'));
        } catch (error) { root.textContent = error.message; }
    });
})();
