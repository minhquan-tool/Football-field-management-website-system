document.addEventListener('sanbong:authenticated', async () => {
    const accountBody = document.getElementById('accountRows');
    const permissionBody = document.getElementById('permissionRows');
    const roleSelect = document.getElementById('permissionRole');
    const saveButton = document.getElementById('savePermissions');
    const notify = (message, error = false) => error ? alert(message) : window.showToast ? showToast(message) : alert(message);
    const cell = (row, value, className = 'py-3 px-4') => {
        const td = document.createElement('td'); td.className = className; td.textContent = value; row.append(td);
    };
    async function loadPermissions() {
        const matrix = await SanBong.request('security/permissions?role=' + encodeURIComponent(roleSelect.value || 'VT02'));
        if (!roleSelect.options.length) matrix.roles.forEach(role => {
            const option = new Option(role.tenVaiTro, role.maVaiTro); roleSelect.add(option);
        });
        if (!roleSelect.dataset.loaded) { roleSelect.value = 'VT02'; roleSelect.dataset.loaded = 'true'; }
        permissionBody.replaceChildren();
        matrix.permissions.forEach((permission, index) => {
            const row = document.createElement('tr'); row.dataset.code = permission.MaChucNang;
            cell(row, index + 1); cell(row, permission.TenChucNang);
            ['Xem', 'Them', 'Sua', 'Xoa'].forEach(action => {
                const td = document.createElement('td'); td.className = 'py-3 px-4 text-center';
                const input = document.createElement('input'); input.type = 'checkbox';
                input.className = 'w-4 h-4 text-brand-600 rounded'; input.dataset.action = action.toLowerCase();
                input.checked = Boolean(permission[action]); td.append(input); row.append(td);
            });
            permissionBody.append(row);
        });
    }
    try {
        await loadPermissions(); saveButton.disabled = false;
    } catch (error) { notify(error.message, true); }
    roleSelect.addEventListener('change', async () => {
        saveButton.disabled = true;
        try { await loadPermissions(); saveButton.disabled = false; }
        catch (error) { permissionBody.replaceChildren(); notify(error.message, true); }
    });
    saveButton.addEventListener('click', async () => {
        const payload = [...permissionBody.rows].map(row => {
            const permission = { maChucNang: row.dataset.code };
            row.querySelectorAll('input').forEach(input => permission[input.dataset.action] = input.checked);
            return permission;
        });
        saveButton.disabled = true;
        try {
            await SanBong.request('security/permissions/' + roleSelect.value, {
                method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload)
            });
            notify('Đã lưu phân quyền thành công.');
        } catch (error) { notify(error.message, true); }
        finally { saveButton.disabled = false; }
    });
});
