/* Small catalog editor on the existing calendar; only exposed to ADMIN. */
(() => {
    document.addEventListener('sanbong:authenticated', async event => {
        if (event.detail.maVaiTro !== 'VT04') return;
        const panel = document.createElement('details'); panel.className = 'bg-white rounded-2xl border p-6 mb-4';panel.id='serviceCatalogPanel';
        const title = document.createElement('summary'); title.textContent = 'Quản lý danh mục dịch vụ'; title.className = 'font-bold cursor-pointer'; panel.append(title);
        const status = document.createElement('p'); status.className = 'text-sm my-2'; panel.append(status);
        if(event.detail.permissions.includes('CN03_THEM')) {
            const create=document.createElement('form');create.className='flex flex-wrap gap-2 my-3';
            create.innerHTML='<label>Mã SKU<input name="maDV" required pattern="[A-Za-z0-9_-]{1,10}" maxlength="10" class="border p-2 block"></label><label>Tên dịch vụ<input name="tenDV" required maxlength="100" class="border p-2 block"></label><label>Đơn vị<input name="donViTinh" required maxlength="20" class="border p-2 block"></label><label>Giá đơn vị<input name="donGia" type="number" min="0.01" step="0.01" required class="border p-2 block"></label><label><input name="hoTroLoc" type="checkbox"> Lốc 6 giảm 3% (Chai/Lon)</label><button class="bg-brand-600 text-white rounded p-2">Thêm dịch vụ mới</button>';
            create.onsubmit=async e=>{e.preventDefault();const button=create.querySelector('button');button.disabled=true;const body=Object.fromEntries(new FormData(create));body.donGia=Number(body.donGia);body.hoTroLoc=create.elements.hoTroLoc.checked;
                try{await SanBong.request('service-catalog',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});create.reset();await load();status.textContent='Đã thêm SKU mới.';}catch(error){status.textContent=error.message;}finally{button.disabled=false;}};
            panel.append(create);
        }
        const rows = document.createElement('div'); panel.append(rows); document.querySelector('main').append(panel);
        async function load() {
            const catalog = await SanBong.request('service-catalog'); rows.replaceChildren();
            for (const item of catalog) {
                const form = document.createElement('form'); form.dataset.apiReady = 'true'; form.className = 'flex flex-wrap items-center gap-3 py-2 border-b';
                const name = document.createElement('span'); name.className = 'font-bold'; name.textContent = `${item.maDV} · ${item.tenDV} (${item.donViTinh || 'Đơn vị'})`; form.append(name);
                const priceLabel = document.createElement('label'); priceLabel.textContent = 'Giá đơn vị ';
                const price = document.createElement('input'); price.type = 'number'; price.min = '0.01'; price.step = '0.01'; price.required = true; price.value = item.donGia; price.className = 'border rounded-lg p-2 w-32'; priceLabel.append(price); form.append(priceLabel);
                const checkbox = (text, checked) => { const label = document.createElement('label'), input = document.createElement('input'); input.type = 'checkbox'; input.checked = checked; label.append(input, document.createTextNode(' ' + text)); form.append(label); return input; };
                const active = checkbox('Kinh doanh', item.trangThai), pack = checkbox('Hỗ trợ lốc 6', item.hoTroLoc);
                pack.disabled = !['Chai', 'Lon'].includes(item.donViTinh);
                const save = document.createElement('button'); save.type = 'submit'; save.textContent = 'Lưu'; save.className = 'bg-brand-600 text-white rounded-lg px-3 py-2'; save.disabled = !event.detail.permissions.includes('CN03_SUA'); form.append(save);
                form.addEventListener('submit', async e => {
                    e.preventDefault(); save.disabled = true;
                    try { await SanBong.request('service-catalog/' + encodeURIComponent(item.maDV), { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ donGia: Number(price.value), trangThai: active.checked, hoTroLoc: pack.checked }) }); await load(); status.textContent = 'Đã lưu catalog; giá lịch sử giữ nguyên.'; }
                    catch (error) { status.textContent = error.message; save.disabled = !event.detail.permissions.includes('CN03_SUA'); }
                }); rows.append(form);
            }
        }
        try { await load(); } catch (error) { status.textContent = error.message; }
    });
})();
