/* Public read-only catalog. Never calculate or apply a booking discount here. */
document.addEventListener('DOMContentLoaded', () => {
    const host = document.getElementById('publicPromotions');
    const status = document.getElementById('publicPromotionsStatus');
    const retry = document.getElementById('publicPromotionsRetry');
    if (!host || !status || !retry) return;

    function element(tag, text, className = '') {
        const node = document.createElement(tag);
        node.textContent = text;
        node.className = className;
        return node;
    }

    function date(value) {
        const match = String(value || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
        return match ? `${match[3]}/${match[2]}/${match[1]}` : 'Chưa có thông tin';
    }

    function card(row) {
        const article = element('article', '', 'guest-promotion-card');
        const icon = element('i', '', 'fa-solid fa-gift');
        icon.setAttribute('aria-hidden', 'true');
        article.append(icon, element('h3', row.tenKM));
        const detail = element('div', '', 'guest-promotion-detail');
        const amount = Number(row.mucGiam).toLocaleString('vi-VN');
        detail.append(element('span', 'Mức ưu đãi'), element('strong',
            row.loaiGiam === 'Phần trăm' ? `Giảm ${amount}%` : `Giảm ${amount} đ`));
        article.append(detail, element('p', row.dieuKien || 'Điều kiện áp dụng được kiểm tra khi đặt sân.'));
        article.append(element('p', `Hiệu lực: ${date(row.tuNgay)} – ${date(row.denNgay)}`, 'guest-promotion-dates'));

        const actions = element('div', '', 'guest-promotion-actions');
        const code = element('code', row.maKM, 'guest-promotion-code');
        const copy = element('button', 'Sao chép mã', 'guest-promotion-copy');
        copy.type = 'button';
        copy.setAttribute('aria-label', `Sao chép mã ${row.maKM}`);
        copy.addEventListener('click', async () => {
            try {
                if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
                await navigator.clipboard.writeText(String(row.maKM));
                status.textContent = `Đã sao chép mã ${row.maKM}. Hệ thống sẽ kiểm tra điều kiện khi bạn áp dụng mã.`;
            } catch {
                const selection = window.getSelection();
                if (selection) {
                    const range = document.createRange();
                    range.selectNodeContents(code);
                    selection.removeAllRanges();
                    selection.addRange(range);
                }
                status.textContent = `Chưa sao chép được. Bạn có thể sao chép mã ${row.maKM} đang hiển thị.`;
            }
        });
        actions.append(code, copy);
        const link = element('a', 'Đăng nhập để đặt sân →');
        link.href = 'dang-nhap';
        article.append(actions, link);
        return article;
    }

    async function load() {
        host.replaceChildren();
        host.setAttribute('aria-busy', 'true');
        retry.hidden = true;
        retry.disabled = true;
        status.textContent = 'Đang tải chương trình ưu đãi…';
        try {
            const rows = await SanBong.request('public/promotions');
            if (!Array.isArray(rows) || rows.some(row => !row || !row.maKM || !row.tenKM ||
                !['Phần trăm', 'Số tiền'].includes(row.loaiGiam) ||
                !Number.isFinite(Number(row.mucGiam)) || Number(row.mucGiam) <= 0 ||
                (row.loaiGiam === 'Phần trăm' && Number(row.mucGiam) > 100))) {
                throw new Error('Dữ liệu ưu đãi chưa hợp lệ. Vui lòng thử lại.');
            }
            rows.forEach(row => host.append(card(row)));
            status.textContent = rows.length
                ? `Có ${rows.length} chương trình đang áp dụng. Sao chép mã và kiểm tra điều kiện trước khi đặt sân.`
                : 'Hiện chưa có chương trình ưu đãi đang áp dụng.';
        } catch (error) {
            host.replaceChildren();
            status.textContent = error.message || 'Chưa tải được chương trình ưu đãi.';
            retry.hidden = false;
        } finally {
            host.setAttribute('aria-busy', 'false');
            retry.disabled = false;
        }
    }
    retry.addEventListener('click', load);
    load();
});
