/* Real invoice/refund read models. Mutations remain in the existing finance workflow. */
(() => {
 const kind=document.body.dataset.accountingWorkspace;if(!kind)return;
 const $=id=>document.getElementById(id),money=v=>Number(v??0).toLocaleString('vi-VN')+' đ';
 let page=1,pendingPage=1,state='',version=0,qrVersion=0,invoices=[],account;
 const el=(tag,text,cls='')=>{const n=document.createElement(tag);if(text!=null)n.textContent=text;n.className=cls;return n;};
 const allowed=p=>account?.permissions.includes(p);
 const labels={CHUA_THANH_TOAN:'Chưa thanh toán',THANH_TOAN_MOT_PHAN:'Thanh toán một phần',DA_THANH_TOAN:'Đã thanh toán',DA_HUY:'Đã hủy'};
 function badge(text,value){const n=el('span',text,'aw-badge');n.dataset.state=value;return n;}
 function button(text,fn,cls='aw-action'){const b=el('button',text,cls);b.type='button';b.onclick=fn;return b;}
 function td(...nodes){const n=el('td');n.append(...nodes);return n;}
 function cell(text){return td(el('span',text));}
 function empty(id,columns,text){const row=el('tr'),n=el('td',text,'aw-empty');n.colSpan=columns;row.append(n);$(id).replaceChildren(row);}
 function pager(prefix,data){$(prefix+'Previous').disabled=page<=1;$(prefix+'Next').disabled=page*data.size>=data.total;$(prefix+'Page').textContent=`Trang ${page} · ${data.total} kết quả`;}
 async function openFinance(id,refundId){$('financeBookingId').value=id;$('accountingDetailTitle').textContent=refundId?'Xác nhận hoàn tiền':'Chi tiết hóa đơn & Giao dịch';if(!$('accountingDetail').open)$('accountingDetail').showModal();const loaded=await window.SanBongFinance.open(id);if(loaded&&refundId){const launch=[...document.querySelectorAll('[data-refund-id]')].find(b=>b.dataset.refundId===refundId);if(launch){launch.click();document.querySelector('.finance-refund-confirmation:not([hidden])')?.scrollIntoView({block:'center'});}}}
 $('accountingDetailClose').onclick=()=>{if(!window.SanBongFinance.isBusy())$('accountingDetail').close();};
 $('accountingDetail').addEventListener('cancel',e=>{if(window.SanBongFinance.isBusy())e.preventDefault();});
 function invoiceRows(rows){const host=$('accountingRows');host.replaceChildren();for(const r of rows){
  const tr=el('tr'),code=el('div');code.append(button(r.maHoaDon,()=>openFinance(r.maDatSan),'aw-code'),el('small',r.maDatSan));
  const customer=el('div');customer.append(el('strong',r.hoTen),el('small',r.soDienThoai||''));
  const pitch=el('div');pitch.append(el('strong',r.tenSan),el('small',r.ngayChoi),el('small',r.gioBatDau.slice(0,5)+'–'+r.gioKetThuc.slice(0,5)));
  tr.append(td(code),td(customer),td(pitch),cell(money(r.tienSan)),cell(money(r.tienDichVu)),cell(money(r.tienGiam)),td(el('strong',money(r.tongTien))),td(el('strong',money(r.daThanhToan),'aw-paid')),td(el('strong',money(r.conLai),'aw-due')));
  const status=td(badge(labels[r.trangThai]||r.trangThai,r.trangThai));tr.append(status);
  const actions=el('div',null,'aw-actions');if(r.trangThai!=='DA_HUY'&&Number(r.conLai)>0&&allowed('CN04_THEM'))actions.append(button('Thu tiền',()=>openFinance(r.maDatSan),'aw-collect'));actions.append(button('Chi tiết',()=>openFinance(r.maDatSan)));tr.append(td(actions));host.append(tr);
 }if(!rows.length)empty('accountingRows',11,'Không có hóa đơn phù hợp.');}
 function refundRows(id,rows,pending){const host=$(id);host.replaceChildren();for(const r of rows){const tr=el('tr'),ids=el('div');ids.append(button(r.maDatSan,()=>openFinance(r.maDatSan),'aw-code'),el('small',r.maHT));const customer=el('div');customer.append(el('strong',r.hoTen),el('small',r.soDienThoai||''));
  if(pending){const pitch=el('div');pitch.append(el('strong',r.tenSan),el('small',r.ngayChoi+' · '+r.gioBatDau.slice(0,5)+'–'+r.gioKetThuc.slice(0,5)));tr.append(td(ids),td(customer),td(pitch),cell(r.thucThuTaiHuy==null?'Chưa có thông tin thực thu đã lưu':money(r.thucThuTaiHuy)),td(badge((r.tiLeHoan==null?'Chưa có tỷ lệ':r.tiLeHoan+'%')+' · '+money(r.soTienHoan),'refund')),cell(r.lyDo||''),td(button(allowed('CN04_SUA')?'Xác nhận hoàn thực tế':'Xem chi tiết',()=>openFinance(r.maDatSan,r.maHT),'aw-refund')));}
  else{const time=el('div');time.append(el('small',(r.ngayYeuCau||'').replace('T',' ')),el('small',r.ngayXacNhan?'Xác nhận: '+r.ngayXacNhan.replace('T',' '):'Chưa xác nhận'));tr.append(td(ids),td(customer),cell(r.tiLeHoan==null?'Chưa có':r.tiLeHoan+'%'),td(el('strong',money(r.soTienHoan),'aw-due')),cell(r.lyDo||''),td(badge(r.trangThai,r.trangThai)),td(time),td(button('Chi tiết',()=>openFinance(r.maDatSan))));}host.append(tr);
 }if(!rows.length)empty(id,pending?7:8,'Không có khoản hoàn phù hợp.');}
 function clearQr(){qrVersion++;$('accountingQr').hidden=true;$('accountingQr').removeAttribute('src');$('qrInvoiceSummary').replaceChildren();$('qrReceivingBank').hidden=true;$('qrReceivingBank').replaceChildren();$('qrOpenFinance').disabled=true;}
 async function qrSelection(){clearQr();const r=invoices.find(i=>i.maHoaDon===$('qrInvoice').value);if(!r){$('qrStatus').textContent='Chọn hóa đơn để xem thông tin chuyển khoản.';return;}const token=qrVersion;
  const dl=$('qrInvoiceSummary');for(const [name,value]of [['Mã hóa đơn',r.maHoaDon],['Khách hàng',r.hoTen+(r.soDienThoai?' · '+r.soDienThoai:'')],['Sân bóng',r.tenSan],['Tổng hóa đơn',money(r.tongTien)],['Đã thu',money(r.daThanhToan)],['Số tiền cần chuyển',money(r.conLai)]]){dl.append(el('dt',name),el('dd',value));}
  $('qrOpenFinance').disabled=false;$('qrOpenFinance').onclick=()=>openFinance(r.maDatSan);$('qrStatus').textContent='Đang tải VietQR…';
  try{const quote=await SanBong.request('finance/bookings/'+encodeURIComponent(r.maDatSan)+'/transfer-instructions?amount='+encodeURIComponent(r.conLai));if(token!==qrVersion)return;
   const bank=$('qrReceivingBank');bank.append(el('h3','Thông tin tài khoản nhận'));for(const line of [quote.bankName,quote.accountNumber+' · '+quote.accountName,'Nội dung: '+quote.description,'Số tiền: '+money(quote.amount)])bank.append(el('p',line));bank.hidden=false;
   const image=$('accountingQr');const url=new URL(quote.qrUrl,location.href);if(url.origin!==location.origin&&!(url.protocol==='https:'&&url.hostname==='img.vietqr.io'&&!url.port))throw Error('Địa chỉ VietQR không hợp lệ.');
   if(!quote.qrAvailable)throw Error('Chưa có ảnh QR. Đối chiếu thông tin tài khoản trước khi chuyển.');image.onload=()=>{if(token===qrVersion)$('qrStatus').textContent='Quét đúng số tiền và nội dung hiển thị.';};image.onerror=()=>{if(token===qrVersion){image.hidden=true;$('qrStatus').textContent='Không tải được VietQR. Kiểm tra kết nối mạng và thông tin tài khoản.';}};image.src=url.href;image.hidden=false;
  }catch(error){if(token===qrVersion)$('qrStatus').textContent=error.message;}
 }
 function qrPayments(rows){const host=$('qrPendingRows');host.replaceChildren();for(const r of rows.filter(r=>r.phuongThuc==='Chuyển khoản'&&r.trangThai==='Chờ xử lý')){const tr=el('tr');tr.append(cell(r.maTT),cell(r.maDatSan),cell(r.hoTen),cell(money(r.soTien)),cell((r.ngayThanhToan||'').replace('T',' ')),td(button(allowed('CN04_SUA')?'Đối chiếu & xác nhận':'Xem chi tiết',()=>openFinance(r.maDatSan))));host.append(tr);}if(!host.childElementCount)empty('qrPendingRows',6,'Không có chuyển khoản chờ xác minh.');}
 async function load(){const token=++version;$('accountingStatus').textContent='Đang tải dữ liệu…';$('accountingRefresh').disabled=true;const query=new URLSearchParams({search:$('accountingQuery').value.trim(),status:kind==='qr'?'DUE':state,page,size:20});
  if(kind==='qr'){clearQr();$('qrInvoice').replaceChildren(new Option('Đang tải…',''));$('qrPendingRows').replaceChildren();}else if(kind==='invoices')empty('accountingRows',11,'Đang tải…');else{empty('refundPendingRows',7,'Đang tải…');empty('accountingRows',8,'Đang tải…');}
  try{if(kind==='invoices'){const data=await SanBong.request('finance/invoices?'+query);if(token!==version)return;invoiceRows(data.rows);$('accountingTotal').textContent=data.total+' hóa đơn';pager('accounting',data);}
   else if(kind==='refunds'){const [history,pending]=await Promise.all([SanBong.request('finance/refund-items?'+query),SanBong.request('finance/refund-items?'+new URLSearchParams({search:$('accountingQuery').value.trim(),status:'Chờ duyệt',page:pendingPage,size:20}))]);if(token!==version)return;refundRows('accountingRows',history.rows,false);refundRows('refundPendingRows',pending.rows,true);$('refundPendingCount').textContent=pending.total+' khoản';$('accountingTotal').textContent=pending.pending+' khoản chờ hoàn';pager('accounting',history);$('refundPendingPrevious').disabled=pendingPage<=1;$('refundPendingNext').disabled=pendingPage*20>=pending.total;$('refundPendingPage').textContent='Trang '+pendingPage;}
   else{const [data,ledger]=await Promise.all([SanBong.request('finance/invoices?'+query),SanBong.request('finance/transactions')]);if(token!==version)return;invoices=data.rows;$('qrInvoice').replaceChildren(new Option('Chọn hóa đơn…',''));for(const r of invoices)$('qrInvoice').add(new Option(r.maDatSan+' · '+r.hoTen+' · Còn '+money(r.conLai),r.maHoaDon));$('accountingTotal').textContent=data.total+' hóa đơn còn thiếu';pager('accounting',data);qrPayments(ledger.payments);if(invoices.length){$('qrInvoice').value=invoices[0].maHoaDon;qrSelection();}}
   $('accountingStatus').textContent='';
  }catch(error){if(token===version){$('accountingStatus').textContent=error.message;if(kind==='qr'){$('qrInvoice').replaceChildren(new Option('Không tải được hóa đơn',''));$('qrStatus').textContent='Chưa có thông tin chuyển khoản hợp lệ.';}else if(kind==='invoices')empty('accountingRows',11,'Không tải được hóa đơn.');else{empty('refundPendingRows',7,'Không tải được khoản hoàn.');empty('accountingRows',8,'Không tải được lịch sử.');}}}
  finally{if(token===version)$('accountingRefresh').disabled=false;}
 }
 document.addEventListener('sanbong:authenticated',e=>{account=e.detail;if(!['VT03','VT04'].includes(account.maVaiTro)||!allowed('CN04_XEM')){$('accountingStatus').textContent='Bạn không có quyền truy cập kế toán.';return;}
  if(kind==='invoices')for(const [value,label]of [['','Tất cả'],['CHUA_THANH_TOAN','Chưa thu'],['THANH_TOAN_MOT_PHAN','Thu một phần'],['DA_THANH_TOAN','Đã thanh toán'],['DA_HUY','Đã hủy']]){const b=button(label,()=>{state=value;page=1;for(const tab of $('accountingTabs').children)tab.setAttribute('aria-pressed',String(tab===b));load();});b.setAttribute('aria-pressed',String(value===''));$('accountingTabs').append(b);}
  if($('accountingLookupOpen'))$('accountingLookupOpen').onclick=()=>{$('financeBookingId').value='';const old=$('financeHost').querySelector('section');if(old)old.hidden=true;if(!$('accountingDetail').open)$('accountingDetail').showModal();$('financeBookingId').focus();};
  $('accountingSearch')?.addEventListener('submit',e=>{e.preventDefault();page=1;load();});$('accountingRefresh').onclick=load;$('accountingPrevious').onclick=()=>{page--;load();};$('accountingNext').onclick=()=>{page++;load();};
  if(kind==='refunds'){$('accountingQuery').addEventListener('change',()=>{page=pendingPage=1;load();});$('refundHistoryState').onchange=()=>{state=$('refundHistoryState').value;page=1;load();};$('refundPendingPrevious').onclick=()=>{pendingPage--;load();};$('refundPendingNext').onclick=()=>{pendingPage++;load();};}if(kind==='qr')$('qrInvoice').onchange=qrSelection;
  document.addEventListener('sanbong:finance-updated',load);load();
 });
})();
