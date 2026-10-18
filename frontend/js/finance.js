/* Real internal receipts/refunds; no payment gateway and no client-authoritative totals. */
(() => {
    let account, bookingId, current, busy = false, version = 0, transactionRows = [];
    const paymentKeys = new Map();
    let transferQuote=null,transferVersion=0,transferTimer;
    function paymentKey() {
        if (!paymentKeys.has(bookingId)) paymentKeys.set(bookingId, SanBong.randomId());
        return paymentKeys.get(bookingId);
    }
    const money = n => Number(n || 0).toLocaleString('vi-VN') + 'đ';
    const allowed = p => account?.permissions.includes(p);
    const employee = () => account?.maVaiTro !== 'VT01';
    const panel = document.createElement('section'); panel.className = 'bg-white border rounded-2xl p-4 mt-4 space-y-3';
    panel.innerHTML = `<h3 class="font-bold">Hóa đơn / Thanh toán / Hoàn tiền</h3>
      <p id="financeSummary" class="text-sm"></p><div id="financeAmounts" class="fc-money-grid" aria-label="Các khoản tiền của lượt đặt" hidden></div><p id="financeStatus" class="text-sm" role="status"></p>
      <form id="financeInvoiceForm" data-api-ready="true" class="flex flex-wrap gap-2"><select id="financePromo" class="border rounded-lg p-2"><option value="">Giữ giảm giá hiện có</option></select><button class="bg-brand-600 text-white rounded-lg p-2">Lập / cập nhật hóa đơn</button></form>
      <form id="financeCouponForm" data-api-ready="true" class="flex flex-wrap gap-2 items-center" hidden><label>Mã khuyến mãi<input id="financeCoupon" maxlength="32" pattern="[A-Za-z0-9_-]+" required placeholder="Ví dụ: VIP10 hoặc KM02" autocomplete="off" class="border rounded-lg p-2 w-48"></label><button class="border rounded-lg p-2">Áp dụng mã</button></form><p id="financeCouponInfo" class="text-sm"></p>
      <form id="financePaymentForm" data-api-ready="true" class="flex flex-wrap gap-2 items-center"><label>Số tiền<input id="financeAmount" type="number" min="0.01" step="0.01" required class="border rounded-lg p-2 w-36"></label><label>Phương thức<select id="financeMethod" class="border rounded-lg p-2"><option>Tiền mặt</option><option>Chuyển khoản</option></select></label><label id="financeReceiptLabel"><input id="financeReceipt" type="checkbox"> Tôi đã thực nhận tiền</label><button id="financePayButton" class="bg-brand-600 text-white rounded-lg p-2">Ghi nhận</button></form>
      <label id="financeRefundMethodLabel" class="text-sm">Phương thức hoàn thực tế<select id="financeRefundMethod" class="border rounded-lg p-2"><option>Tiền mặt</option><option>Chuyển khoản</option></select></label><div id="financeHistory" class="text-sm space-y-2"></div><p id="financeCancelPolicy" class="text-sm"></p>
      <p class="text-xs text-gray-500">Ghi nhận thu/hoàn nội bộ. Ứng dụng không tự chuyển tiền ngân hàng.</p>`;
    const $ = id => panel.querySelector('#' + id);
    const transferBox=document.createElement('section');transferBox.id='financeTransfer';transferBox.hidden=true;transferBox.className='border rounded-xl p-3 space-y-2';
    transferBox.innerHTML='<h4 class="font-bold">Chuyển khoản ngân hàng</h4><p id="financeTransferStatus" role="status"></p><img id="financeQr" alt="QR chuyển khoản cho lượt đặt đang xem" width="300" height="356" referrerpolicy="no-referrer" hidden><p id="financeBankDetails"></p><p>Kiểm tra tên người nhận trong ứng dụng ngân hàng trước khi chuyển. Quét QR hoặc bấm “Tôi đã chuyển khoản” chưa có nghĩa sân đã nhận tiền.</p>';
    $('financePaymentForm').after(transferBox);
    const paymentHelp=document.createElement('p');paymentHelp.id='financePaymentHelp';paymentHelp.className='text-sm';transferBox.after(paymentHelp);
    const refreshButton=document.createElement('button');refreshButton.id='financeRefresh';refreshButton.type='button';refreshButton.textContent='Tải lại trạng thái thanh toán';refreshButton.className='border rounded p-2';refreshButton.onclick=()=>{if(!busy&&bookingId)load(bookingId);};paymentHelp.after(refreshButton);
    function clearTransfer(){clearTimeout(transferTimer);transferVersion++;transferQuote=null;$('financeQr').hidden=true;$('financeQr').removeAttribute('src');$('financeBankDetails').textContent='';$('financeTransferStatus').textContent='';$('financeTransfer').hidden=true;}
    function matchingTransfer(){return transferQuote&&transferQuote.booking===bookingId&&transferQuote.amount===Number($('financeAmount').value);}
    async function requestTransfer(){
        clearTransfer();render();
        if(!current||employee()||$('financePaymentForm').hidden||$('financeMethod').value!=='Chuyển khoản')return;
        $('financeTransfer').hidden=false;const id=bookingId,amount=Number($('financeAmount').value),token=transferVersion;
        if(!Number.isSafeInteger(amount)||amount<=0){$('financeTransferStatus').textContent='QR chỉ hỗ trợ số tiền nguyên VND. Không tự làm tròn hóa đơn; liên hệ nhân viên nếu số còn thiếu có phần lẻ.';return;}
        $('financeTransferStatus').textContent='Đang tải thông tin chuyển khoản…';
        try{const quote=await SanBong.request(`finance/bookings/${encodeURIComponent(id)}/transfer-instructions?amount=${encodeURIComponent(amount)}`);
            if(token!==transferVersion||bookingId!==id||Number($('financeAmount').value)!==amount||$('financeMethod').value!=='Chuyển khoản')return;
            transferQuote={booking:id,amount};$('financeBankDetails').textContent=`${quote.bankName} · ${quote.accountNumber} · ${quote.accountName} · ${money(quote.amount)} · Nội dung: ${quote.description}`;
            const image=$('financeQr');image.onload=()=>{if(token===transferVersion)$('financeTransferStatus').textContent='QR nhận tiền tĩnh từ ngân hàng. Nhập/đối chiếu số tiền và nội dung bên dưới trong ứng dụng ngân hàng; sau khi chuyển bấm “Tôi đã chuyển khoản”.';};image.onerror=()=>{if(token===transferVersion){image.hidden=true;$('financeTransferStatus').textContent='Không tải được ảnh QR. Có thể chuyển thủ công theo thông tin bên dưới và giữ nguyên nội dung.';}};
            if(quote.qrAvailable&&quote.qrUrl){const url=new URL(quote.qrUrl,location.href);if(url.origin!==location.origin)throw new Error('Ảnh QR phải được phục vụ từ máy chủ của sân.');image.src=url.href;image.hidden=false;}
            else $('financeTransferStatus').textContent='Sân chưa cung cấp ảnh QR từ ngân hàng. Có thể chuyển khoản thủ công theo đúng tài khoản, số tiền và nội dung bên dưới.';
            render();
        }catch(error){if(token===transferVersion){transferQuote=null;$('financeTransferStatus').textContent=error.message;render();}}
    }
    $('financeMethod').addEventListener('change',requestTransfer);
    $('financeAmount').addEventListener('input',()=>{clearTransfer();render();transferTimer=setTimeout(requestTransfer,300);});

    for (const id of ['financeInvoiceForm', 'financePaymentForm', 'financeRefundMethodLabel']) $(id).hidden = true;
    const status = (message, error = false) => { $('financeStatus').textContent = message; $('financeStatus').className = error ? 'text-sm text-red-600' : 'text-sm text-brand-700'; };
    async function post(path, body) { return SanBong.request(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }); }
    function button(label, fn) { const b = document.createElement('button'); b.type = 'button'; b.textContent = label; b.className = 'text-brand-600 font-bold px-2'; b.disabled = busy; b.addEventListener('click', fn); return b; }
    function render() {
        for (const b of document.querySelectorAll('#financeRefundQueue button')) b.disabled = busy;
        if (!current) return;
        const invoice = current.invoice, cancelled = current.booking.trangThai === 'Đã hủy';
        const amounts=$('financeAmounts');amounts.replaceChildren();amounts.hidden=false;
        const pendingRefund=current.refunds.filter(r=>r.trangThai==='Chờ duyệt').reduce((sum,r)=>sum+Number(r.soTienHoan),0);
        const paid=current.payments.filter(p=>p.trangThai==='Thành công').reduce((sum,p)=>sum+Number(p.soTien),0);
        const metrics=[['Đã xác nhận thu',paid,''],[cancelled?'Lượt đặt đã hủy':'Còn thiếu trên hóa đơn',cancelled?null:invoice?.conLai,'fc-money-due'],['Chờ xác nhận hoàn',pendingRefund,'fc-money-refund']];
        for(const [label,value,css]of metrics){const card=document.createElement('div');card.className=css;const caption=document.createElement('span');caption.textContent=label;const amount=document.createElement('strong');amount.textContent=value==null?(cancelled?'Xem chính sách hoàn':'Chưa lập hóa đơn'):money(value);card.append(caption,amount);amounts.append(card);}
        $('financeSummary').textContent = invoice ? `${invoice.maHoaDon} · Sân ${money(invoice.tienSan)} + Dịch vụ ${money(invoice.tienDichVu)} − Giảm ${money(invoice.tienGiam)} = ${money(invoice.tongTien)} · Đã trả ${money(invoice.daThanhToan)} · Còn thiếu ${money(invoice.conLai)} · ${invoice.trangThai} · ${invoice.daChot ? 'Đã chốt' : 'Có thể bổ sung khi sử dụng'} · ${invoice.hoanTatTaiChinh ? 'Hoàn tất tài chính' : 'Chưa hoàn tất tài chính'}` : `Chưa lập hóa đơn · Snapshot tổng booking ${money(current.booking.tongTien)}`;
        $('financeInvoiceForm').hidden = !employee() || !allowed('CN04_THEM') || cancelled || invoice?.daChot;
        const pending=current.payments.some(p=>p.trangThai==='Chờ xử lý');
        $('financeCouponForm').hidden=employee()||!allowed('CN04_THEM')||cancelled||pending||paid>0||invoice?.daChot||current.canApplyPromotion===false;
        $('financeCoupon').disabled=busy;
        $('financeCouponInfo').textContent=employee()?'':`${current.promotionCode?'Đã áp dụng '+current.promotionCode+' · Giảm tiền sân '+money(current.booking.tienGiam)+'. ':''}Mỗi lượt đặt dùng một mã, chỉ giảm tiền sân; áp dụng trước lần thanh toán đầu tiên và trước khi chốt hóa đơn. Dịch vụ tính riêng.`;
        $('financePaymentForm').hidden = !allowed('CN04_THEM') || cancelled || invoice && Number(invoice.conLai) === 0 || !employee()&&pending;
        $('financeRefundMethodLabel').hidden = !['VT03', 'VT04'].includes(account.maVaiTro) || !current.refunds.some(r => r.trangThai === 'Chờ duyệt');
        $('financeReceiptLabel').hidden = !employee(); $('financeReceipt').required = employee();
        $('financePayButton').textContent = employee() ? 'Ghi nhận đã nhận tiền' : $('financeMethod').value==='Chuyển khoản'?'Tôi đã chuyển khoản':'Chọn thanh toán tiền mặt';
        $('financePaymentHelp').textContent=employee()?'':pending?'Đang chờ nhân viên xác minh. Không chuyển thêm; bấm tải lại để xem kết quả.':$('financeMethod').value==='Chuyển khoản'?'Chuyển đúng số tiền/nội dung; kế toán hoặc chủ sân đối chiếu trước khi xác nhận đã thanh toán.':'Thanh toán tại sân. Chỉ ghi nhận đã thanh toán khi nhân viên xác nhận thực nhận tiền mặt.';
        if(employee()||$('financePaymentForm').hidden||$('financeMethod').value!=='Chuyển khoản')$('financeTransfer').hidden=true;
        $('financeAmount').step=!employee()&&$('financeMethod').value==='Chuyển khoản'?'1':'0.01';
        $('financeAmount').min=!employee()&&$('financeMethod').value==='Chuyển khoản'?'1':'0.01';
        $('financeHistory').replaceChildren();
        for (const row of current.payments) {
            const p = document.createElement('p'); p.textContent = `${row.maTT} · ${row.phuongThuc} · ${money(row.soTien)} · ${row.trangThai}`;
            if (employee() && allowed('CN04_SUA') && row.trangThai === 'Chờ xử lý' && (account.maVaiTro!=='VT02'||row.phuongThuc==='Tiền mặt')) {
                p.append(button('Xác nhận đã nhận tiền', () => { if (confirm('Bạn đã thực nhận khoản tiền này?')) mutate(`finance/payments/${encodeURIComponent(row.maTT)}/confirm`, { daNhanTien: true }, 'Đã xác nhận thực thu.'); }));
                p.append(button('Từ chối', () => mutate(`finance/payments/${encodeURIComponent(row.maTT)}/reject`, {}, 'Đã từ chối yêu cầu.')));
            }
            if(account.maVaiTro==='VT02'&&!allowed('CN04_SUA')&&allowed('CN04_THEM')&&row.phuongThuc==='Tiền mặt'&&row.trangThai==='Chờ xử lý')p.append(button('Xác nhận đã nhận tiền mặt',()=>{if(confirm('Bạn đã thực nhận đủ khoản tiền mặt này từ khách?'))mutate(`finance/payments/${encodeURIComponent(row.maTT)}/confirm-cash`,{daNhanTien:true},'Đã xác nhận thực nhận tiền mặt.');}));
            $('financeHistory').append(p);
        }
        for (const row of current.refunds) {
            const p = document.createElement('p'); p.textContent = `${row.maHT} · Hoàn ${money(row.soTienHoan)} · ${row.phuongThuc} · ${row.trangThai}${row.ngayXacNhan ? ' · ' + row.ngayXacNhan : ''}`;
            if (['VT03', 'VT04'].includes(account.maVaiTro) && allowed('CN04_SUA') && row.trangThai === 'Chờ duyệt') p.append(button('Xác nhận đã hoàn thực tế', () => {
                const reason = prompt('Lý do/ghi chú xác nhận đã trả tiền cho khách:');
                if (reason?.trim() && confirm('Xác nhận bạn đã trả tiền thực tế bằng phương thức đang chọn?')) mutate(`finance/refunds/${encodeURIComponent(row.maHT)}/confirm`, { phuongThuc: $('financeRefundMethod').value, daHoanTien: true, lyDo: reason.trim() }, 'Đã ghi nhận xác nhận hoàn thực tế.');
            }));
            $('financeHistory').append(p);
        }
        const c = current.cancellation;
        if (c) $('financeCancelPolicy').textContent = `Hủy lúc ${c.ngayHuy} · Tỷ lệ ${c.tiLeHoan}% · Thực thu tại hủy ${money(c.soTienThucThuSnapshot)} · Được hoàn ${money(c.soTienHoan)} · Thực thu còn lại ${money(current.thucThu)}`;
        for (const b of panel.querySelectorAll('button')) b.disabled = busy;
        if(!employee()&&$('financeMethod').value==='Chuyển khoản'&&!matchingTransfer())$('financePayButton').disabled=true;
    }
    async function load(id, mutationRefresh = false) {
        if (busy && !mutationRefresh) return false;
        const requestVersion = ++version; bookingId = id; current = null; status('Đang tải...');
        clearTransfer();$('financePaymentHelp').textContent='';
        $('financeSummary').textContent = ''; $('financeHistory').replaceChildren(); $('financeCancelPolicy').textContent = '';
        $('financeAmounts').hidden=true;$('financeAmounts').replaceChildren();
        $('financeInvoiceForm').hidden = true; $('financePaymentForm').hidden = true; $('financeRefundMethodLabel').hidden = true;
        $('financeCouponForm').hidden=true;$('financeCouponInfo').textContent='';$('financeCoupon').value='';
        try {
            const value = await SanBong.request('finance/bookings/' + encodeURIComponent(id)); if (requestVersion !== version) return false;
            current = value;
            const pendingKey = paymentKeys.get(id);
            if (pendingKey && value.payments.some(payment => payment.idempotencyKey === pendingKey)) paymentKeys.delete(id);
            $('financeAmount').value = value.invoice ? value.invoice.conLai : value.booking.tongTien; $('financeReceipt').checked = false; status(''); render();requestTransfer();
            if (panel.closest('#detailModal')) { document.getElementById('detailTotal').textContent = money(value.booking.tongTien); document.getElementById('detailAmounts').textContent = `Sân ${money(value.booking.tienSan)} · Dịch vụ ${money(value.booking.tienDichVu)} · Giảm ${money(value.booking.tienGiam)}`; }
            if (!value.cancellation) {
                const preview = await SanBong.request(`finance/bookings/${encodeURIComponent(id)}/cancel-preview`);
                if (requestVersion === version) $('financeCancelPolicy').textContent = `Nếu hủy tại ${preview.thoiDiem}: ${preview.tiLeHoan}% × thực thu ${money(preview.thucThu)} = ${money(preview.soTienHoan)}. Số chính thức tính lại khi hủy.`;
            }
            return requestVersion === version;
        } catch (error) {
            if (requestVersion === version) status(error.message, true);
            return false;
        }
    }
    async function mutate(path, body, message) {
        if (busy || !current) return; busy = true; render(); const id = bookingId;
        let committed = false;
        try {
            await post(path, body); committed = true;
            if (body?.idempotencyKey) paymentKeys.delete(id);
            if (!await load(id, true)) {
                status(`${message} Chưa tải lại được dữ liệu: ${$('financeStatus').textContent} Hãy tra cứu lại booking; không gửi lại khoản tiền đã ghi nhận.`, true);
                return;
            }
            if (window.applyFilters) await window.applyFilters();
            await ledger(); status(message);
        }
        catch (error) { status(committed ? `${message} Chưa cập nhật được danh sách: ${error.message}` : error.message, true); }
        finally { busy = false; render();if(path.endsWith('/promotion'))requestTransfer(); }
    }
    $('financeCouponForm').addEventListener('submit',e=>{e.preventDefault();if(busy)return;const code=$('financeCoupon').value.trim().toUpperCase();clearTransfer();mutate(`finance/bookings/${encodeURIComponent(bookingId)}/promotion`,{maKM:code},'Đã áp dụng mã giảm tiền sân; số còn thiếu đã cập nhật.');});
    $('financeInvoiceForm').addEventListener('submit', e => { e.preventDefault();const option=$('financePromo').selectedOptions[0];if(option?.dataset.condition&&!confirm('Bạn đã xác minh khách đáp ứng điều kiện: '+option.dataset.condition+'?'))return;mutate(`finance/bookings/${encodeURIComponent(bookingId)}/invoice`, { maKM: $('financePromo').value || null,daXacMinhDieuKien:Boolean(option?.dataset.condition) }, 'Đã lưu hóa đơn từ snapshot backend.'); });
    $('financePaymentForm').addEventListener('submit', e => { e.preventDefault(); if(!employee()&&$('financeMethod').value==='Chuyển khoản'&&!matchingTransfer()){status('Chưa có thông tin chuyển khoản hợp lệ cho số tiền đang chọn.',true);return;} mutate(`finance/bookings/${encodeURIComponent(bookingId)}/${employee() ? 'payments' : 'payment-requests'}`, { soTien: Number($('financeAmount').value), phuongThuc: $('financeMethod').value, idempotencyKey: paymentKey(), daNhanTien: employee() && $('financeReceipt').checked }, employee() ? 'Đã ghi nhận thực thu.' : 'Đang chờ nhân viên xác minh; chưa ghi nhận thực thu.'); });
    function renderTransactions() {
        const body = document.getElementById('financeTransactions'); if (!body) return;
        const date=document.getElementById('financeTransactionDate')?.value;
        const rows=transactionRows.filter(row=>!date||row.ngayThanhToan?.slice(0,10)===date);body.replaceChildren();
        for (const row of rows) { const tr = document.createElement('tr'); for (const value of [row.maTT, row.maDatSan, row.hoTen, row.phuongThuc, money(row.soTien), row.trangThai]) { const td = document.createElement('td'); td.className = 'p-3'; td.textContent = value; tr.append(td); } tr.lastChild.append(button('Xem hóa đơn',event=>{event.stopPropagation();load(row.maDatSan);}));tr.addEventListener('click',()=>load(row.maDatSan));body.append(tr); }
        if (!rows.length) { const tr = document.createElement('tr'), td = document.createElement('td'); td.colSpan = 6; td.textContent = date?'Không có giao dịch trong ngày đã chọn.':'Chưa có giao dịch.'; tr.append(td); body.append(tr); }
    }
    async function ledger() {
        const body = document.getElementById('financeTransactions'); if (!body) return;
        const result = await SanBong.request('finance/transactions');transactionRows=result.payments;renderTransactions();
        const gross = result.payments.filter(p => p.trangThai === 'Thành công').reduce((sum,p) => sum + Number(p.soTien), 0); const refunds = result.refunds.filter(p => p.trangThai === 'Đã hoàn').reduce((sum,p) => sum + Number(p.soTienHoan), 0);
        for (const [id,value] of [['financeGross',gross],['financeActual',result.thucNhan],['financeRefundTotal',refunds]]) if (document.getElementById(id)) document.getElementById(id).textContent = money(value);
        document.getElementById('financeNet').textContent = 'Thực nhận sau hoàn (toàn bộ): ' + money(result.thucNhan);
        const queue = document.getElementById('financeRefundQueue'); queue.replaceChildren();
        for (const row of result.refunds) { const p = document.createElement('p'); p.textContent = `${row.maHT} · ${row.maDatSan} · ${money(row.soTienHoan)} · ${row.trangThai}`; p.append(button('Xem booking', () => load(row.maDatSan))); queue.append(p); }
    }
    document.addEventListener('sanbong:authenticated', async e => {
        account = e.detail; if (!allowed('CN04_XEM')) return;
        if(account.maVaiTro==='VT02')for(const option of [...$('financeMethod').options])if(option.value==='Chuyển khoản')option.remove();
        if (document.getElementById('financeTransactions')) {
            const host = document.getElementById('financeHost'); host.append(panel);
            document.getElementById('financeLookup').addEventListener('submit', e => { e.preventDefault(); if (!busy) load(document.getElementById('financeBookingId').value.trim()); });
            document.getElementById('financeTransactionDate')?.addEventListener('change',renderTransactions);
            try { await ledger(); } catch (error) { status(error.message, true); }
        } else if (document.getElementById('detailModal')) {
            document.querySelector('#detailModal .p-6').append(panel);
            document.querySelector('#detailModal > div').classList.add('max-h-[90vh]', 'overflow-y-auto');
            const original = window.openDetailModal;
            window.openDetailModal = async id => { if (busy) return; await original(id); await load(id); if(!employee()&&new URLSearchParams(location.search).get('payment')==='1'){panel.scrollIntoView({block:'start'});if(!$('financePaymentForm').hidden)$('financeMethod').focus();} };
        }
        if (employee() && allowed('CN04_THEM')) try { for (const p of await SanBong.request('finance/promotions')) {const option=new Option(`${p.tenKM} · ${p.loaiGiam==='Số tiền'?money(p.mucGiam):p.mucGiam+'%'}`,p.maKM);option.dataset.condition=p.dieuKien||'';$('financePromo').add(option);} } catch (error) { status(error.message, true); }
    });
})();
