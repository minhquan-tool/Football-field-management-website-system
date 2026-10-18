document.addEventListener('sanbong:authenticated', async event => {
    const account=event.detail, $=id=>document.getElementById(id), status=$('careStatus');
    const tell=(text,error=false)=>{status.textContent=text;status.className=error?'text-red-700 my-3':'text-brand-700 my-3';};
    const forms=['profileForm','passwordForm','feedbackForm'].map($).filter(Boolean);
    for(const form of forms){form.querySelectorAll('button').forEach(button=>button.disabled=true);
        form.addEventListener('submit',e=>{if(form.dataset.careReady!=='true'){e.preventDefault();e.stopImmediatePropagation();tell('Chưa tải được dữ liệu. Vui lòng tải lại trang trước khi gửi.',true);}},true);
    }
    const write=(path,method,body)=>SanBong.request(path,{method,headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    function line(host,text,tag='p'){const node=document.createElement(tag);node.textContent=text;host.append(node);return node;}
    async function feedback(){const host=$('feedbackRows');if(!host)return;host.replaceChildren();const rows=await SanBong.request('feedback');
        if(!rows.length)line(host,'Chưa có phản hồi.');
        for(const row of rows){const article=document.createElement('article');article.className='border rounded-xl p-4 my-3';host.append(article);
            line(article,`${row.maPhanHoi} · ${row.hoTen} · ${row.maDatSan||'Không kèm lượt đặt'} · ${row.trangThai}`,'h3');
            line(article,`${row.loaiPhanHoi}: ${row.noiDung}`);if(row.ketQua)line(article,'Kết quả: '+row.ketQua);
            if(['VT02','VT04'].includes(account.maVaiTro)&&account.permissions.includes('CN05_SUA')&&row.trangThai!=='Đã xử lý'){
                const form=document.createElement('form');form.className='flex flex-wrap gap-2 mt-3';
                const state=document.createElement('select');for(const s of ['Đang xử lý','Đã xử lý'])state.add(new Option(s,s));
                const result=document.createElement('input');result.placeholder='Kết quả xử lý';result.required=true;result.maxLength=500;
                const button=document.createElement('button');button.textContent='Lưu xử lý';button.className='bg-brand-600 text-white px-3 py-2 rounded';form.append(state,result,button);article.append(form);
                form.onsubmit=async e=>{e.preventDefault();button.disabled=true;try{await write('feedback/'+encodeURIComponent(row.maPhanHoi),'PUT',{trangThai:state.value,ketQua:result.value});tell('Đã lưu xử lý.');await feedback();}catch(err){tell(err.message,true);}finally{button.disabled=false;}};
            }
        }
    }
    let historyUI,historyTimer,historySequence=0;
    const historyState={page:1,size:10,q:'',state:'',order:'desc'};
    async function history(pageNumber){
        const host=$('historyRows');if(!host)return;
        if(pageNumber!==undefined)historyState.page=pageNumber;
        if(!historyUI){
            host.replaceChildren();const controls=document.createElement('div');controls.className='flex flex-wrap gap-3 my-3';host.append(controls);
            const filter=document.createElement('select');filter.setAttribute('aria-label','Lọc trạng thái lượt đặt');filter.add(new Option('Tất cả trạng thái',''));
            for(const value of ['Chờ xác nhận','Đã xác nhận','Đã sử dụng','Đã hủy'])filter.add(new Option(value,value));
            const query=document.createElement('input');query.type='search';query.maxLength=100;query.placeholder='Tìm mã đặt hoặc tên sân';query.setAttribute('aria-label','Tìm lượt đặt');
            const sort=document.createElement('select');sort.setAttribute('aria-label','Sắp xếp lịch sử');sort.add(new Option('Ngày chơi mới nhất','desc'));sort.add(new Option('Ngày chơi cũ nhất','asc'));
            const size=document.createElement('select');size.setAttribute('aria-label','Số lượt mỗi trang');for(const n of [10,20,50])size.add(new Option(n+' lượt / trang',String(n)));
            for(const control of [filter,query,sort,size]){control.className='border rounded p-2';controls.append(control);}
            const summary=line(host,'','p');summary.setAttribute('role','status');summary.dataset.historySummary='';
            const cards=document.createElement('div');cards.dataset.historyCards='';host.append(cards);
            const pager=document.createElement('div');pager.className='flex flex-wrap items-center gap-3 my-4';pager.setAttribute('aria-label','Phân trang lịch sử');host.append(pager);
            function button(text){const b=line(pager,text,'button');b.type='button';b.className='border rounded px-3 py-2';return b;}
            const previous=button('Trang trước'),pageLabel=line(pager,'','span'),next=button('Trang sau'),retry=button('Tải lại lịch sử');retry.hidden=true;
            historyUI={cards,summary,previous,next,pageLabel,retry};
            const reload=()=>{clearTimeout(historyTimer);history(1);};
            query.oninput=()=>{historyState.q=query.value;historySequence++;clearTimeout(historyTimer);historyUI.previous.disabled=historyUI.next.disabled=true;historyTimer=setTimeout(()=>history(1),300);};
            query.onkeydown=e=>{if(e.key==='Enter'){e.preventDefault();reload();}};
            filter.onchange=()=>{historyState.state=filter.value;reload();};sort.onchange=()=>{historyState.order=sort.value;reload();};size.onchange=()=>{historyState.size=Number(size.value);reload();};
            previous.onclick=()=>history(historyState.page-1);next.onclick=()=>history(historyState.page+1);retry.onclick=()=>history();
        }
        const sequence=++historySequence;
        historyUI.previous.disabled=historyUI.next.disabled=true;historyUI.retry.hidden=true;historyUI.cards.replaceChildren();
        historyUI.summary.textContent='Đang tải lịch sử…';historyUI.cards.setAttribute('aria-busy','true');document.body.dataset.historyReady='false';
        try{
            const params=new URLSearchParams(historyState);const data=await SanBong.request('customer/history?'+params);
            if(sequence!==historySequence)return;
            if(data.totalPages>0&&historyState.page>data.totalPages){await history(data.totalPages);return;}
            if(data.total===0&&historyState.page!==1){await history(1);return;}
            historyUI.summary.textContent=`Hiển thị ${data.bookings.length}/${data.total} lượt đặt phù hợp`;
            historyUI.pageLabel.textContent=`Trang ${data.totalPages?data.page:1}/${Math.max(1,data.totalPages)}`;
            historyUI.previous.disabled=data.page<=1;historyUI.next.disabled=data.page>=data.totalPages;
            if(!data.bookings.length)line(historyUI.cards,'Không có lượt đặt phù hợp. Thử đổi trạng thái hoặc từ khóa.');
        for(const booking of data.bookings){const card=document.createElement('article');card.className='border rounded-xl p-4 my-3';historyUI.cards.append(card);
            line(card,`${booking.maDatSan} · ${booking.tenSan} · ${booking.ngayChoi} ${booking.gioBatDau}–${booking.gioKetThuc} · ${booking.trangThai}`,'h3');
            const badge=line(card,booking.trangThai,'span');badge.className='fc-status my-2';badge.dataset.state=booking.trangThai;
            const progress=line(card,'','ol');progress.setAttribute('aria-label','Tiến trình lượt đặt');progress.className='flex flex-wrap gap-3 text-sm my-3';
            if(booking.trangThai==='Đã hủy')line(progress,'Đã hủy · Xem hóa đơn để kiểm tra khoản hoàn.','li');
            else for(const [index,label]of ['Đã đặt','Đã xác nhận','Đã sử dụng / trả sân'].entries()){
                const step=booking.trangThai==='Đã sử dụng'?2:booking.trangThai==='Đã xác nhận'?1:0;
                const li=line(progress,(index<=step?'✓ ':'○ ')+label,'li');if(index===step)li.setAttribute('aria-current','step');
            }
            line(card,'Tiến trình sử dụng sân độc lập với thanh toán. Xem chi tiết để biết tiền đã thu, còn thiếu hoặc khoản hoàn.');
            const a=line(card,'Xem chi tiết / Hóa đơn','a');a.className='text-brand-600 underline';a.href='Quan_ly_lich_dat_san.html?'+new URLSearchParams({date:booking.ngayChoi,pitch:booking.maSan,booking:booking.maDatSan});
            const review=data.reviews.find(r=>r.maDatSan===booking.maDatSan);
            if(review){line(card,`Đã đánh giá ${review.diemTrungBinh}/5 · ${review.noiDung||''}`);continue;}
            if(booking.trangThai!=='Đã sử dụng'||!account.permissions.includes('CN05_THEM'))continue;
            const form=document.createElement('form');form.className='space-y-3 mt-3';const scores={};
            for(const criterion of data.criteria){const label=line(form,criterion.tenTieuChi+' ','label');label.className='block';const select=document.createElement('select');for(let n=1;n<=5;n++)select.add(new Option(String(n),String(n)));select.value='5';label.append(select);scores[criterion.maTieuChi]=select;}
            const content=document.createElement('textarea');content.maxLength=500;content.placeholder='Nhận xét';content.className='border p-2 block w-full';const button=document.createElement('button');button.textContent='Gửi đánh giá';button.className='bg-brand-600 text-white p-2 rounded';form.append(content,button);card.append(form);
            form.onsubmit=async e=>{e.preventDefault();button.disabled=true;try{await write('customer/bookings/'+encodeURIComponent(booking.maDatSan)+'/review','POST',{diem:Object.fromEntries(Object.entries(scores).map(([k,v])=>[k,Number(v.value)])),noiDung:content.value});tell('Đã lưu đánh giá.');await history();}catch(err){tell(err.message,true);}finally{button.disabled=false;}};
        }
        }catch(err){if(sequence===historySequence){historyUI.cards.replaceChildren();historyUI.summary.textContent='Không tải được lịch sử: '+err.message;historyUI.retry.hidden=false;}}
        finally{if(sequence===historySequence){historyUI.cards.setAttribute('aria-busy','false');document.body.dataset.historyReady='true';}}
    }
    try{
        if($('promotionRows')){const rows=await SanBong.request('customer/promotions');line($('promotionRows'),'Nhập mã tại chi tiết lượt đặt → Hóa đơn / Thanh toán, trước lần thanh toán đầu tiên và trước khi chốt hóa đơn. Chỉ giảm tiền sân, không cộng dồn. Mã sinh viên cần nhân viên xác minh thẻ.');if(!rows.length)line($('promotionRows'),'Hiện chưa có khuyến mãi áp dụng.');for(const row of rows){const card=line($('promotionRows'),'','article');card.className='border rounded-xl p-4 my-3';line(card,row.tenKM,'h2');line(card,`${row.maKM} · ${row.mucGiam} ${row.loaiGiam==='Phần trăm'?'%':'đ'} · ${row.tuNgay}–${row.denNgay}`);line(card,row.dieuKien||'Áp dụng trong thời gian hiệu lực và cho ngày chơi hợp lệ.');}const link=line($('promotionRows'),'Xem lịch sử đặt sân để chọn lượt đặt áp mã','a');link.href='Man_hinh_LS&ĐG_KH.html';link.className='text-brand-600 underline';}
        if($('profileForm')){const p=await SanBong.request('customer/profile');for(const k of ['hoTen','soDienThoai','email','diaChi'])$('profile_'+k).value=p[k]||'';
            $('profileForm').onsubmit=async e=>{e.preventDefault();const form=e.currentTarget,button=form.querySelector('button');SanBong.fieldErrors(form);button.disabled=true;try{const saved=await write('customer/profile','PUT',Object.fromEntries(['hoTen','soDienThoai','email','diaChi'].map(k=>[k,$('profile_'+k).value])));document.querySelectorAll('[data-account-name]').forEach(node=>node.textContent=saved.hoTen);tell('Đã lưu thông tin tài khoản.');}catch(err){SanBong.fieldErrors(form,err.fieldErrors,Object.fromEntries(['hoTen','soDienThoai','email','diaChi'].map(k=>[k,'profile_'+k])));tell(err.message,true);}finally{button.disabled=false;}};}
        if($('passwordForm'))$('passwordForm').onsubmit=async e=>{
            e.preventDefault();const form=e.currentTarget,button=form.querySelector('button'),message=$('passwordStatus');
            SanBong.fieldErrors(form);message.textContent='';
            const body={matKhauHienTai:$('password_current').value,matKhauMoi:$('password_new').value,xacNhanMatKhau:$('password_confirm').value};
            if(body.matKhauMoi!==body.xacNhanMatKhau){SanBong.fieldErrors(form,{password_confirm:'Xác nhận mật khẩu mới không khớp.'});message.textContent='Vui lòng kiểm tra xác nhận mật khẩu.';return;}
            button.disabled=true;
            try{await write('customer/password','POST',body);form.reset();message.textContent='Đã đổi mật khẩu. Vui lòng đăng nhập lại bằng mật khẩu mới.';
                form.querySelectorAll('input,button').forEach(node=>node.disabled=true);$('passwordRelogin').hidden=false;
                document.querySelectorAll('#profileForm input,#profileForm button,#feedbackForm input,#feedbackForm select,#feedbackForm textarea,#feedbackForm button').forEach(node=>node.disabled=true);
                $('passwordRelogin').focus();
            }catch(err){message.textContent=err.status===401?'Phiên đã hết hiệu lực. Vui lòng đăng nhập lại.':err.message;
                if(err.status===401)$('passwordRelogin').hidden=false;
                else if(!err.status||err.status>=500)message.textContent+=' Nếu phản hồi bị gián đoạn, hãy thử đăng nhập bằng mật khẩu mới trước khi gửi lại.';
                SanBong.fieldErrors(form,err.fieldErrors,{matKhauHienTai:'password_current',matKhauMoi:'password_new',xacNhanMatKhau:'password_confirm'});button.disabled=false;
            }
        };
        if($('feedbackForm'))$('feedbackForm').onsubmit=async e=>{e.preventDefault();const button=e.currentTarget.querySelector('button');button.disabled=true;try{await write('feedback','POST',{maDatSan:$('feedbackBooking').value.trim()||null,loaiPhanHoi:$('feedbackType').value,noiDung:$('feedbackContent').value});$('feedbackContent').value='';tell('Đã tiếp nhận phản hồi.');await feedback();}catch(err){tell(err.message,true);}finally{button.disabled=false;}};
        for(const form of forms)if(form.onsubmit){form.dataset.careReady='true';form.querySelectorAll('button').forEach(button=>button.disabled=false);}
        await Promise.all([history(),feedback()]);
    }catch(err){tell(err.message,true);}finally{document.body.dataset.careReady='true';}
});
