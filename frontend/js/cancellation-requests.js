/* Real cancellation requests; approving a cancellation never confirms a bank refund. */
(() => {
 const main=document.querySelector('main');if(!main)return;
 const el=(tag,text)=>{const n=document.createElement(tag);if(text!=null)n.textContent=text;return n;};
 const money=n=>Number(n??0).toLocaleString('vi-VN')+' đ';
 let account,page=1,version=0,busy=false,pending=new Set(),section,body,status,previous,next,caption;
 window.SanBongCancellation={pending:id=>pending.has(id)};
 function button(text,fn){const b=el('button',text);b.type='button';b.onclick=fn;return b;}
 function setup(){
  const style=el('link');style.rel='stylesheet';style.href='css/cancellation-requests.css';document.head.append(style);
  section=el('section');section.className='cr-section';section.setAttribute('aria-label','Yêu cầu hủy đặt sân');
  const heading=el('div');heading.className='cr-heading';heading.append(el('h2',account.maVaiTro==='VT01'?'Yêu cầu hủy của tôi':'Yêu cầu hủy đặt sân'),button('Tải lại',load));
  status=el('p');status.setAttribute('role','status');status.setAttribute('aria-live','polite');
  const scroll=el('div');scroll.className='cr-scroll';scroll.tabIndex=0;scroll.setAttribute('role','region');scroll.setAttribute('aria-label','Danh sách yêu cầu hủy');
  const table=el('table'),head=el('thead'),row=el('tr');for(const label of ['Lượt đặt / Khách hàng','Sân / Giờ chơi','Gửi yêu cầu / Lý do','Ước tính hoàn lúc gửi','Trạng thái / Xử lý'])row.append(el('th',label));head.append(row);body=el('tbody');table.append(head,body);scroll.append(table);
  const nav=el('div');nav.className='cr-pages';previous=button('Trước',()=>{page--;load();});next=button('Sau',()=>{page++;load();});caption=el('span');nav.append(previous,caption,next);section.append(heading,status,scroll,nav);
  const headingNode=main.querySelector(account.maVaiTro==='VT01'?'.cp-calendar-heading':'.ac-heading');if(headingNode)headingNode.after(section);else main.prepend(section);
 }
 function render(rows){body.replaceChildren();for(const r of rows){const tr=el('tr');
  for(const values of [[r.maDatSan,r.hoTen,r.soDienThoai],[r.tenSan,String(r.ngayChoi),String(r.gioBatDau).slice(0,5)+'–'+String(r.gioKetThuc).slice(0,5)],[String(r.ngayGui).replace('T',' '),r.lyDo],[r.tiLeHoan+'% · '+money(r.tienHoanUocTinh),'Thực thu lúc gửi: '+money(r.thucThuTaiGui)]]){const td=el('td');for(const value of values)td.append(el('div',value));tr.append(td);}
  const actions=el('td'),badge=el('strong',({PENDING:'Chờ duyệt hủy',APPROVED:'Đã duyệt hủy',REJECTED:'Đã từ chối'})[r.trangThai]||r.trangThai);badge.dataset.state=r.trangThai;actions.append(badge);
  if(r.ghiChuXuLy)actions.append(el('p',r.ghiChuXuLy));
  if(r.trangThai==='PENDING'&&['VT03','VT04'].includes(account.maVaiTro)&&account.permissions.includes('CN04_SUA'))actions.append(button('Xem & xử lý',()=>decision(r)));
  if(r.trangThai==='APPROVED')actions.append(el('small','Khoản hoàn nếu có được xác nhận chi riêng bên dưới.'));tr.append(actions);body.append(tr);
 }if(!rows.length){const tr=el('tr'),td=el('td','Không có yêu cầu hủy.');td.colSpan=5;tr.append(td);body.append(tr);}}
 async function load(){if(!section)return;const token=++version;status.textContent='Đang tải yêu cầu hủy…';previous.disabled=next.disabled=true;
  try{const data=await SanBong.request('finance/cancellation-requests?'+new URLSearchParams({status:account.maVaiTro==='VT01'?'':'PENDING',page}));if(token!==version)return;
   if(!data.enabled){body.replaceChildren();status.textContent='Chức năng yêu cầu hủy chưa được kích hoạt. Vui lòng liên hệ nhân viên.';return;}
   // A separate pending query keeps booking badges correct even when history is paginated.
   const current=account.maVaiTro==='VT01'?await SanBong.request('finance/cancellation-requests?status=PENDING&page=1'):data;if(token!==version)return;
   pending=new Set(current.rows.map(r=>r.maDatSan));render(data.rows);status.textContent=data.pending+' yêu cầu chờ duyệt · Sân vẫn được giữ trong lúc chờ.';caption.textContent='Trang '+page+' · '+data.total+' yêu cầu';previous.disabled=page<=1;next.disabled=page*20>=data.total;document.dispatchEvent(new Event('sanbong:cancellation-loaded'));
  }catch(error){if(token===version){body.replaceChildren();status.textContent=error.message;}}
 }
 function decision(r){if(busy)return;const dialog=el('dialog');dialog.className='cr-dialog';const form=el('form'),title=el('h2','Xử lý yêu cầu '+r.maYeuCau),summary=el('p',r.maDatSan+' · '+r.hoTen+' · '+r.tenSan),reason=el('p','Lý do: '+r.lyDo),note=el('p','Tỷ lệ đã lưu: '+r.tiLeHoan+'%. Ước tính lúc gửi: '+money(r.tienHoanUocTinh)+'. Số hoàn khi duyệt được tính lại theo tiền thực thu. Duyệt hủy không xác nhận đã chuyển tiền hoàn.');
  const label=el('label','Quyết định'),select=el('select');select.name='approve';for(const [value,text]of [['true','Duyệt hủy sân'],['false','Từ chối yêu cầu']]){const o=el('option',text);o.value=value;select.append(o);}label.append(select);
  const notes=el('label','Ghi chú xử lý'),input=el('textarea');input.required=true;input.maxLength=255;input.rows=3;notes.append(input);const error=el('p');error.setAttribute('role','alert');const submit=el('button','Xác nhận quyết định');submit.type='submit';const close=button('Đóng',()=>{if(!busy)dialog.close();});form.append(title,summary,reason,note,label,notes,error,submit,close);dialog.append(form);document.body.append(dialog);dialog.addEventListener('cancel',e=>{if(busy)e.preventDefault();});dialog.addEventListener('close',()=>dialog.remove());dialog.showModal();
  form.onsubmit=async e=>{e.preventDefault();if(busy)return;busy=true;submit.disabled=close.disabled=true;try{await SanBong.request('finance/cancellation-requests/'+encodeURIComponent(r.maYeuCau)+'/decision',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({approve:select.value==='true',ghiChu:input.value})});dialog.close();document.dispatchEvent(new Event('sanbong:finance-updated'));document.dispatchEvent(new Event('sanbong:cancellation-updated'));}catch(err){error.textContent=err.message;}finally{busy=false;submit.disabled=close.disabled=false;}};
 }
 document.addEventListener('sanbong:authenticated',e=>{account=e.detail;if(!['VT01','VT03','VT04'].includes(account.maVaiTro))return;setup();load();});
 document.addEventListener('sanbong:cancellation-updated',()=>{page=1;load();});
 setInterval(()=>{if(section&&!busy&&document.visibilityState==='visible')load();},60000);
 window.addEventListener('focus',()=>{if(section&&!busy)load();});
})();
