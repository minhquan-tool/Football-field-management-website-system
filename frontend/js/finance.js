/* Real internal receipts/refunds; no payment gateway and no client-authoritative totals. */
(() => {
    let account, bookingId, current, busy = false, version = 0, transactionRows = [];
    const paymentKeys = new Map();
    let transferQuote=null,transferVersion=0,transferTimer,customerPlan="DEPOSIT_40";
    function paymentKey() {
        if (!paymentKeys.has(bookingId)) paymentKeys.set(bookingId, SanBong.randomId());
        return paymentKeys.get(bookingId);
    }
    const money = n => Number(n || 0).toLocaleString('vi-VN') + 'đ';
    const allowed = p => account?.permissions.includes(p);
    const employee = () => account?.maVaiTro !== 'VT01';
    const staffTransfer = () => account?.maVaiTro === 'VT02' && $('financeMethod').value === 'Chuyển khoản';
    const panel = document.createElement('section'); panel.className = 'bg-white border rounded-2xl p-4 mt-4 space-y-3';
    panel.innerHTML = `<h3 class="font-bold">Thông tin thanh toán</h3>
      <p id="financeSummary" class="text-sm"></p><div id="financeAmounts" class="fc-money-grid" aria-label="Các khoản tiền của lượt đặt" hidden></div><p id="financeStatus" class="text-sm" role="status"></p>
      <form id="financeInvoiceForm" data-api-ready="true" class="flex flex-wrap gap-2"><select id="financePromo" class="border rounded-lg p-2"><option value="">Giữ giảm giá hiện có</option></select><button class="bg-brand-600 text-white rounded-lg p-2">Lập / cập nhật hóa đơn</button></form>
      <form id="financeCouponForm" data-api-ready="true" class="flex flex-wrap gap-2 items-center" hidden><label>Mã khuyến mãi<input id="financeCoupon" maxlength="32" pattern="[A-Za-z0-9_-]+" required placeholder="Ví dụ: VIP10 hoặc KM02" autocomplete="off" class="border rounded-lg p-2 w-48"></label><button class="border rounded-lg p-2">Áp dụng mã</button></form><p id="financeCouponInfo" class="text-sm"></p>
      <form id="financePaymentForm" data-api-ready="true" class="flex flex-wrap gap-2 items-center"><label>Số tiền<input id="financeAmount" type="number" min="0.01" step="0.01" required class="border rounded-lg p-2 w-36"></label><label>Phương thức<select id="financeMethod" class="border rounded-lg p-2"><option>Tiền mặt</option><option>Chuyển khoản</option></select></label><label id="financeReceiptLabel"><input id="financeReceipt" type="checkbox"> Tôi đã thực nhận tiền</label><button id="financePayButton" class="bg-brand-600 text-white rounded-lg p-2">Ghi nhận</button></form>
      <label id="financeRefundMethodLabel" class="text-sm">Phương thức hoàn thực tế<select id="financeRefundMethod" class="border rounded-lg p-2"><option>Tiền mặt</option><option>Chuyển khoản</option></select></label><div id="financeHistory" class="text-sm space-y-2"></div><p id="financeCancelPolicy" class="text-sm"></p>
      <p class="text-xs text-gray-500">Ghi nhận thu/hoàn nội bộ. Ứng dụng không tự chuyển tiền ngân hàng.</p>`;
    const $ = id => panel.querySelector('#' + id);
    const transferBox=document.createElement('section');transferBox.id='financeTransfer';transferBox.hidden=true;transferBox.className='border rounded-xl p-3 space-y-2';
    transferBox.innerHTML='<p id="financeTransferStatus" role="status"></p><img id="financeQr" alt="QR chuyển khoản cho lượt đặt đang xem" width="300" height="356" referrerpolicy="no-referrer" hidden><p id="financeBankDetails"></p>';
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
            transferQuote={booking:id,amount};$('financeBankDetails').textContent=`${quote.bankName}: ${quote.accountNumber} (${quote.accountName})\nTiền: ${money(quote.amount)}\nNội dung: ${quote.description}`;
            const image=$('financeQr');image.onload=()=>{if(token===transferVersion)$('financeTransferStatus').textContent='';};image.onerror=()=>{if(token===transferVersion){image.hidden=true;$('financeTransferStatus').textContent='Không tải được ảnh QR. Bạn có thể chuyển khoản theo thông tin bên dưới.';}};
            if(quote.qrAvailable&&quote.qrUrl){const url=new URL(quote.qrUrl,location.href);if(url.origin!==location.origin&&!(url.protocol==='https:'&&url.hostname==='img.vietqr.io'&&url.port===''))throw new Error('Địa chỉ VietQR không hợp lệ.');image.src=url.href;image.hidden=false;}
            $('financeTransferStatus').textContent='';
            render();
        }catch(error){if(token===transferVersion){transferQuote=null;$('financeTransferStatus').textContent=error.message;render();}}
    }
    $('financeMethod').addEventListener('change',requestTransfer);
    $('financeAmount').addEventListener('input',()=>{clearTransfer();render();transferTimer=setTimeout(requestTransfer,300);});

    for (const id of ['financeInvoiceForm', 'financePaymentForm', 'financeRefundMethodLabel']) $(id).hidden = true;
    const status = (message, error = false) => { $('financeStatus').textContent = message; $('financeStatus').className = error ? 'text-sm text-red-600' : 'text-sm text-brand-700'; };
    async function post(path, body) { return SanBong.request(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }); }
    function button(label, fn) { const b = document.createElement('button'); b.type = 'button'; b.textContent = label; b.className = 'text-brand-600 font-bold px-2'; b.disabled = busy; b.addEventListener('click', fn); return b; }

    function setupReservationChoices(){
        if(document.getElementById('reservationPaymentChoices'))return;
        $('financeAmount').readOnly=true;$('financeAmount').setAttribute('aria-readonly','true');
        $('financeAmount').parentElement.firstChild.textContent='Số tiền cần thanh toán';
        refreshButton.hidden=true;
        const choices=document.createElement('fieldset');choices.id='reservationPaymentChoices';choices.innerHTML='<legend>Mức thanh toán giữ chỗ</legend><div class="reservation-plans"><label><input type="radio" name="reservationPlan" value="DEPOSIT_40" checked><span><strong>Cọc 40%</strong><small data-plan-amount="DEPOSIT_40"></small></span></label><label><input type="radio" name="reservationPlan" value="FULL"><span><strong>Trả đủ 100%</strong><small data-plan-amount="FULL"></small></span></label></div><p>Cọc tính trên tổng tiền sau giảm giá, gồm dịch vụ đặt trước. Phần đã thu được trừ vào số cần thanh toán. Mức cọc được làm tròn lên 1đ; chi phí phát sinh được tính riêng.</p>';
        $('financePaymentForm').before(choices);
        choices.addEventListener('change',event=>{if(!event.target.matches('input[name=reservationPlan]'))return;customerPlan=event.target.value;clearTransfer();render();requestTransfer();});
        const methods=document.createElement('fieldset');methods.id='customerPaymentMethods';methods.innerHTML='<legend>Phương thức thanh toán</legend><label><input type="radio" name="customerPaymentMethod" value="Chuyển khoản" checked><i class="fa-solid fa-qrcode" aria-hidden="true"></i><span>Chuyển khoản VietQR</span></label><label><input type="radio" name="customerPaymentMethod" value="Tiền mặt"><i class="fa-solid fa-money-bill-wave" aria-hidden="true"></i><span>Tiền mặt tại quầy</span></label>';
        $('financeMethod').parentElement.hidden=true;$('financeMethod').parentElement.before(methods);$('financeMethod').value='Chuyển khoản';
        methods.addEventListener('change',event=>{if(event.target.matches('input[name=customerPaymentMethod]')){$('financeMethod').value=event.target.value;$('financeMethod').dispatchEvent(new Event('change'));}});
    }
    function renderReservationChoices(){
        const values=current.paymentOptions||{};const deposit=Number(values.DEPOSIT_40||0);
        if(deposit<=0)customerPlan='FULL';
        const field=document.getElementById('reservationPaymentChoices');
        for(const input of field.querySelectorAll('input')){input.checked=input.value===customerPlan;input.disabled=busy||!current.paymentOptions||Number(values[input.value])<=0;}
        for(const label of field.querySelectorAll('[data-plan-amount]'))label.textContent=current.paymentOptions?money(values[label.dataset.planAmount]):'Chưa tải được mức thanh toán';
        $('financeAmount').value=values[customerPlan]??'';
        for(const input of document.getElementById('customerPaymentMethods').querySelectorAll('input'))input.disabled=busy;
    }
    function render() {
        for (const b of document.querySelectorAll('#financeRefundQueue button')) b.disabled = busy;
        if (!current) return;
        if(!employee())renderReservationChoices();
        const invoice = current.invoice, cancelled = current.booking.trangThai === 'Đã hủy';
        const amounts=$('financeAmounts');amounts.replaceChildren();amounts.hidden=false;
        const pendingRefund=current.refunds.filter(r=>r.trangThai==='Chờ duyệt').reduce((sum,r)=>sum+Number(r.soTienHoan),0);
        const paid=current.payments.filter(p=>p.trangThai==='Thành công').reduce((sum,p)=>sum+Number(p.soTien),0);
        const metrics=[['Đã xác nhận thu',paid,''],[cancelled?'Lượt đặt đã hủy':'Còn thiếu trên hóa đơn',cancelled?null:invoice?.conLai,'fc-money-due'],['Chờ xác nhận hoàn',pendingRefund,'fc-money-refund']];
        for(const [label,value,css]of metrics){const card=document.createElement('div');card.className=css;const caption=document.createElement('span');caption.textContent=label;const amount=document.createElement('strong');amount.textContent=value==null?(cancelled?'Xem chính sách hoàn':'Chưa lập hóa đơn'):money(value);card.append(caption,amount);amounts.append(card);}
        $('financeSummary').textContent = invoice ? `${invoice.maHoaDon} · Sân ${money(invoice.tienSan)} + Dịch vụ ${money(invoice.tienDichVu)} − Giảm ${money(invoice.tienGiam)} = ${money(invoice.tongTien)} · Đã trả ${money(invoice.daThanhToan)} · Còn thiếu ${money(invoice.conLai)} · ${invoice.trangThai} · ${invoice.daChot ? 'Đã chốt' : 'Có thể bổ sung khi sử dụng'} · ${invoice.hoanTatTaiChinh ? 'Hoàn tất tài chính' : 'Chưa hoàn tất tài chính'}` : `Chưa lập hóa đơn · Tổng tiền đặt sân ${money(current.booking.tongTien)}`;
        if (account.maVaiTro === 'VT03') {
            panel.querySelector('h3').textContent = 'Thanh toán · ' + bookingId;
            $('financeSummary').textContent = invoice ? `${invoice.maHoaDon} · ${invoice.daChot ? 'Đã chốt' : 'Chưa chốt'}` : '';
        }
        $('financeInvoiceForm').hidden = !employee() || !allowed('CN04_THEM') || cancelled || invoice?.daChot;
        if (account.maVaiTro === 'VT02') $('financeSummary').textContent = invoice ? `Đã thu: ${money(paid)} · Còn lại: ${money(invoice.conLai)}` : '';
        const pending=current.payments.some(p=>p.trangThai==='Chờ xử lý');
        $('financeCouponForm').hidden=employee()||!allowed('CN04_THEM')||cancelled||pending||paid>0||invoice?.daChot||current.canApplyPromotion===false;
        $('financeCoupon').disabled=busy;
        $('financeCouponInfo').textContent=employee()?'':`${current.promotionCode?'Đã áp dụng '+current.promotionCode+' · Giảm tiền sân '+money(current.booking.tienGiam)+'. ':''}Mỗi lượt đặt dùng một mã, chỉ giảm tiền sân; áp dụng trước lần thanh toán đầu tiên và trước khi chốt hóa đơn. Dịch vụ tính riêng.`;
        $('financePaymentForm').hidden = !allowed('CN04_THEM') || cancelled || invoice && Number(invoice.conLai) === 0 || !employee()&&pending;
        $('financeRefundMethodLabel').hidden = !['VT03', 'VT04'].includes(account.maVaiTro) || !current.refunds.some(r => r.trangThai === 'Chờ duyệt');
        $('financeReceiptLabel').hidden = !employee() || staffTransfer(); $('financeReceipt').required = employee() && !staffTransfer();
        $('financePayButton').textContent = staffTransfer() ? 'Gửi kế toán xác minh' : employee() ? 'Ghi nhận đã nhận tiền' : $('financeMethod').value==='Chuyển khoản'?'Tôi đã chuyển khoản':'Chọn thanh toán tiền mặt';
        $('financePaymentHelp').textContent=employee()?'':pending?'Đang chờ nhân viên xác minh. Không chuyển thêm; mở lại lượt đặt để xem kết quả.':$('financeMethod').value==='Chuyển khoản'?'':'Thanh toán tại sân. Chỉ ghi nhận đã thanh toán khi nhân viên xác nhận thực nhận tiền mặt.';
        if(employee()||$('financePaymentForm').hidden||$('financeMethod').value!=='Chuyển khoản')$('financeTransfer').hidden=true;
        if(!employee())document.getElementById('reservationPaymentChoices').hidden=$('financePaymentForm').hidden;
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
            if (['VT03', 'VT04'].includes(account.maVaiTro) && allowed('CN04_SUA') && row.trangThai === 'Chờ duyệt') {
                const launch=button('Xác nhận đã hoàn thực tế',()=>{form.hidden=false;note.focus();});launch.dataset.refundId=row.maHT;
                const form=document.createElement('form');form.className='finance-refund-confirmation';form.hidden=true;form.dataset.apiReady='true';
                const heading=document.createElement('strong');heading.textContent='Xác nhận '+row.maHT+' · '+money(row.soTienHoan);
                const methodLabel=document.createElement('label');methodLabel.textContent='Phương thức đã hoàn thực tế';
                const method=document.createElement('select');method.required=true;method.setAttribute('aria-label','Phương thức hoàn '+row.maHT);for(const value of ['Tiền mặt','Chuyển khoản'])method.add(new Option(value,value));method.value=row.phuongThuc;methodLabel.append(method);
                const noteLabel=document.createElement('label');noteLabel.textContent='Ghi chú xác nhận';const note=document.createElement('textarea');note.required=true;note.maxLength=255;note.rows=2;note.placeholder='Ghi rõ cách đối chiếu hoặc mã giao dịch hoàn';noteLabel.append(note);
                const receiptLabel=document.createElement('label');receiptLabel.className='finance-refund-receipt';const receipt=document.createElement('input');receipt.type='checkbox';receipt.required=true;receiptLabel.append(receipt,document.createTextNode('Tôi đã hoàn tiền thực tế cho khách.'));
                const submit=document.createElement('button');submit.type='submit';submit.textContent='Ghi nhận đã hoàn '+money(row.soTienHoan);submit.disabled=busy;
                const cancel=document.createElement('button');cancel.type='button';cancel.textContent='Để sau';cancel.onclick=()=>{form.hidden=true;launch.focus();};
                form.append(heading,methodLabel,noteLabel,receiptLabel,submit,cancel);form.onsubmit=event=>{event.preventDefault();if(busy)return;if(!note.value.trim()){note.setCustomValidity('Nhập ghi chú xác nhận.');note.reportValidity();return;}note.setCustomValidity('');mutate(`finance/refunds/${encodeURIComponent(row.maHT)}/confirm`,{phuongThuc:method.value,daHoanTien:receipt.checked,lyDo:note.value.trim()},'Đã ghi nhận xác nhận hoàn thực tế.');};note.oninput=()=>note.setCustomValidity('');
                p.append(launch);$('financeHistory').append(p,form);continue;
            }
            $('financeHistory').append(p);
        }
        const c = current.cancellation;
        if (c) $('financeCancelPolicy').textContent = `Hủy lúc ${c.ngayHuy} · Tỷ lệ ${c.tiLeHoan}% · Thực thu tại hủy ${money(c.soTienThucThuSnapshot)} · Được hoàn ${money(c.soTienHoan)} · Thực thu còn lại ${money(current.thucThu)}`;
        for (const b of panel.querySelectorAll('button')) b.disabled = busy;
        if(!employee()&&(!current.paymentOptions||Number(current.paymentOptions[customerPlan])<=0||$('financeMethod').value==='Chuyển khoản'&&!matchingTransfer()))$('financePayButton').disabled=true;
    }
    async function load(id, mutationRefresh = false) {
        panel.hidden = false;
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
            if (panel.closest('#detailModal')) { document.getElementById('detailTotal').textContent = money(value.booking.tongTien); document.getElementById('detailAmounts').textContent = `Tiền sân: ${money(value.booking.tienSan)}${Number(value.booking.tienDichVu) ? ' · Dịch vụ: ' + money(value.booking.tienDichVu) : ''}${Number(value.booking.tienGiam) ? ' · Giảm giá: ' + money(value.booking.tienGiam) : ''}`; }
            if (!value.cancellation) {
                const preview = await SanBong.request(`finance/bookings/${encodeURIComponent(id)}/cancel-preview`);
                if (requestVersion === version) $('financeCancelPolicy').textContent = account?.maVaiTro==='VT01'?`Nếu gửi yêu cầu lúc ${preview.thoiDiem}: tỷ lệ ${preview.tiLeHoan}%, ước tính ${money(preview.soTienHoan)}. Tỷ lệ được lưu khi gửi; số hoàn tính theo thực thu khi duyệt.`:`Nếu hủy tại ${preview.thoiDiem}: ${preview.tiLeHoan}% × thực thu ${money(preview.thucThu)} = ${money(preview.soTienHoan)}. Số chính thức tính lại khi hủy.`;
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
            await ledger(); status(message);document.dispatchEvent(new Event('sanbong:finance-updated'));
        }
        catch (error) { status(committed ? `${message} Chưa cập nhật được danh sách: ${error.message}` : error.message, true); }
        finally { busy = false; render();if(path.endsWith('/promotion'))requestTransfer(); }
    }
    $('financeCouponForm').addEventListener('submit',e=>{e.preventDefault();if(busy)return;const code=$('financeCoupon').value.trim().toUpperCase();clearTransfer();mutate(`finance/bookings/${encodeURIComponent(bookingId)}/promotion`,{maKM:code},'Đã áp dụng mã giảm tiền sân; số còn thiếu đã cập nhật.');});
    $('financeInvoiceForm').addEventListener('submit', e => { e.preventDefault();const option=$('financePromo').selectedOptions[0];if(option?.dataset.condition&&!confirm('Bạn đã xác minh khách đáp ứng điều kiện: '+option.dataset.condition+'?'))return;mutate(`finance/bookings/${encodeURIComponent(bookingId)}/invoice`, { maKM: $('financePromo').value || null,daXacMinhDieuKien:Boolean(option?.dataset.condition) }, 'Đã cập nhật hóa đơn.'); });
    $('financePaymentForm').addEventListener('submit', e => { e.preventDefault(); if(!employee()&&$('financeMethod').value==='Chuyển khoản'&&!matchingTransfer()){status('Chưa có thông tin chuyển khoản hợp lệ cho số tiền đang chọn.',true);return;} mutate(`finance/bookings/${encodeURIComponent(bookingId)}/${employee() && !staffTransfer() ? 'payments' : 'payment-requests'}`, { soTien: Number($('financeAmount').value), phuongThuc: $('financeMethod').value, idempotencyKey: paymentKey(), paymentPlan:employee()?null:customerPlan, daNhanTien: employee() && !staffTransfer() && $('financeReceipt').checked }, employee() && !staffTransfer() ? 'Đã ghi nhận thực thu.' : 'Đang chờ nhân viên xác minh; chưa ghi nhận thực thu.'); });
    function renderTransactions() {
        const body = document.getElementById('financeTransactions'); if (!body) return;
        const date=document.getElementById('financeTransactionDate')?.value;
        const state=document.getElementById('financeTransactionState')?.value || '';
        const rows=transactionRows.filter(row=>(!date||row.ngayThanhToan?.slice(0,10)===date)&&(!state||row.trangThai===state));body.replaceChildren();
        for (const row of rows) {
            const tr=document.createElement('tr');
            for(const value of [row.maTT,row.maDatSan,row.hoTen,row.phuongThuc,money(row.soTien)]){const td=document.createElement('td');td.textContent=value;tr.append(td);}
            const stateCell=document.createElement('td'),badge=document.createElement('span');badge.textContent=row.trangThai;badge.className='fc-status';badge.dataset.state=row.trangThai;stateCell.append(badge);tr.append(stateCell);
            const time=document.createElement('td');time.textContent=(row.ngayThanhToan||'').replace('T',' ');tr.append(time);
            const action=document.createElement('td');action.append(button('Xem chi tiết',()=>load(row.maDatSan)));tr.append(action);body.append(tr);
        }
        if(!rows.length){const tr=document.createElement('tr'),td=document.createElement('td');td.colSpan=8;td.textContent='Không có giao dịch phù hợp.';tr.append(td);body.append(tr);}
    }

    async function ledger() {
        const body = document.getElementById('financeTransactions'); if (!body) return;
        const result = await SanBong.request('finance/transactions');transactionRows=result.payments;renderTransactions();
        const gross = result.payments.filter(p => p.trangThai === 'Thành công').reduce((sum,p) => sum + Number(p.soTien), 0); const refunds = result.refunds.filter(p => p.trangThai === 'Đã hoàn').reduce((sum,p) => sum + Number(p.soTienHoan), 0);
        for (const [id,value] of [['financeGross',gross],['financeActual',result.thucNhan],['financeRefundTotal',refunds]]) if (document.getElementById(id)) document.getElementById(id).textContent = money(value);
        document.getElementById('financeNet').textContent = 'Thực nhận sau hoàn (toàn bộ): ' + money(result.thucNhan);
        const queue = document.getElementById('financeRefundQueue'); queue.replaceChildren();
        if(result.refunds.length){const title=document.createElement('h3');title.textContent='Yêu cầu hoàn tiền';title.className='font-bold mt-5 mb-3';queue.append(title);}
        for (const row of result.refunds) { const p = document.createElement('p'); p.textContent = `${row.maHT} · ${row.maDatSan} · ${money(row.soTienHoan)} · ${row.trangThai}`; p.append(button('Xem chi tiết', () => load(row.maDatSan))); queue.append(p); }
    }
    window.SanBongFinance={open:id=>{if(!busy)return load(id);},isBusy:()=>busy};
    document.addEventListener('sanbong:authenticated', async e => {
        account = e.detail; if (!allowed('CN04_XEM')) return;

        if (document.getElementById('financeTransactions')) {
            document.body.classList.add('accountant-workspace');
            document.title=(({invoices:'Quản lý hóa đơn',refunds:'Hoàn tiền',qr:'Thanh toán VietQR'})[document.body.dataset.accountingWorkspace]||'Thu tiền & Hoàn tiền')+' - FC-UTE';
            panel.classList.add('accountant-payment-panel'); panel.hidden=true;
            panel.querySelector('h3').textContent='Chi tiết thanh toán';
            const host = document.getElementById('financeHost'); host.append(panel);
            document.getElementById('financeLookup').addEventListener('submit', e => { e.preventDefault(); if (!busy) load(document.getElementById('financeBookingId').value.trim()); });
            document.getElementById('financeTransactionDate')?.addEventListener('change',renderTransactions);
            document.getElementById('financeTransactionState')?.addEventListener('change',renderTransactions);
            document.getElementById('financeLedgerRefresh')?.addEventListener('click',async event=>{
                event.currentTarget.disabled=true;
                try{await ledger();document.getElementById('financeLedgerStatus').textContent='';}
                catch(error){document.getElementById('financeLedgerStatus').textContent=error.message;}
                finally{document.getElementById('financeLedgerRefresh').disabled=false;}
            });
            try { await ledger(); } catch (error) { document.getElementById('financeLedgerStatus').textContent=error.message; }
        } else if (document.getElementById('detailModal')) {
            if (!employee()) {
                panel.classList.add('customer-payment-panel');setupReservationChoices();
                panel.querySelector('h3').textContent = 'Phương thức thanh toán';
                panel.lastElementChild.hidden = true;
                document.querySelector('#detailModal .p-6 > .flex.justify-end').before(panel);
            } else if (account.maVaiTro === 'VT02') {
                panel.classList.add('staff-payment-panel');
                panel.querySelector('h3').textContent = 'Thanh toán tại quầy';
                document.querySelector('#detailModal .p-6 > .flex.justify-end').before(panel);
            } else document.querySelector('#detailModal .p-6').append(panel);
            document.querySelector('#detailModal > div').classList.add('max-h-[90vh]', 'overflow-y-auto');
            const original = window.openDetailModal;
            window.openDetailModal = async id => { if (busy) return; await original(id); await load(id); if(!employee()&&new URLSearchParams(location.search).get('payment')==='1'){panel.scrollIntoView({block:'start'});if(!$('financePaymentForm').hidden)$('financeMethod').focus();} };
        }
        if (employee() && allowed('CN04_THEM')) try { for (const p of await SanBong.request('finance/promotions')) {const option=new Option(`${p.tenKM} · ${p.loaiGiam==='Số tiền'?money(p.mucGiam):p.mucGiam+'%'}`,p.maKM);option.dataset.condition=p.dieuKien||'';$('financePromo').add(option);} } catch (error) { status(error.message, true); }
    });
})();
