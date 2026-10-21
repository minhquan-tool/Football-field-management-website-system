/* Only the operational cards are connected here; feedback/report modules stay in their own phases. */
document.addEventListener('sanbong:authenticated', async () => {
    try {
        const options = await SanBong.request('booking-options');
        const bookings = await SanBong.request('bookings?' + new URLSearchParams({ date: options.today }));
        const queue=document.createElement('section');queue.id='staffWorkQueue';queue.className='bg-white border rounded-xl p-4 mb-6';
        document.querySelector('main').prepend(queue);
        const toolbar=document.createElement('div');toolbar.className='staff-queue-toolbar';queue.append(toolbar);
        const title=document.createElement('h3');title.textContent='Việc cần xử lý hôm nay · '+options.today;title.className='font-bold text-lg';toolbar.append(title);
        const refresh=document.createElement('button');refresh.type='button';refresh.setAttribute('aria-label','Tải lại danh sách');refresh.title='Tải lại danh sách';refresh.className='staff-queue-refresh';refresh.innerHTML='<i class="fa-solid fa-arrow-rotate-right" aria-hidden="true"></i>';refresh.onclick=()=>{refresh.disabled=true;refresh.classList.add('is-refreshing');location.reload();};toolbar.append(refresh);
        for(const [state,label]of [['Chờ xác nhận','Chờ xác nhận'],['Đã xác nhận','Đã xác nhận']]){
            const heading=document.createElement('h4');const tasks=bookings.filter(b=>b.trangThai===state).sort((a,b)=>a.gioBatDau.localeCompare(b.gioBatDau));heading.textContent=label+' ('+tasks.length+')';heading.className='font-bold mt-3';queue.append(heading);
            if(!tasks.length){const empty=document.createElement('p');empty.textContent='Không có lượt đặt trong nhóm này.';queue.append(empty);}
            for(const b of tasks){const link=document.createElement('a');link.className='block border-b py-3 text-brand-700 underline';link.textContent=`${b.gioBatDau.slice(0,5)}–${b.gioKetThuc.slice(0,5)} · ${b.tenSan} · ${b.hoTen} · ${b.maDatSan}`;link.href='dieu-phoi-san?'+new URLSearchParams({date:b.ngayChoi,pitch:b.maSan,booking:b.maDatSan});queue.append(link);}
        }
        document.getElementById('staffBookingCount').textContent = bookings.length;
        document.getElementById('staffOccupiedCount').textContent = options.pitches.filter(p => p.trangThai === 'Đang sử dụng').length;
        document.getElementById('staffConfirmedCount').textContent = bookings.filter(b => b.trangThai === 'Đã xác nhận').length;
        const grid = document.getElementById('staffPitchCards'); grid.replaceChildren();
        for (const pitch of options.pitches) {
            const card = document.createElement('div'); card.className = 'border border-gray-200 bg-gray-50/40 rounded-xl p-4';
            const name = document.createElement('h4'); name.textContent = `${pitch.tenSan} (${pitch.tenLoaiSan})`; name.className = 'font-bold text-gray-800';
            const status = document.createElement('p'); status.textContent = pitch.trangThai; status.className = 'fc-status mt-2';status.dataset.state=pitch.trangThai;
            const link = document.createElement('a'); link.textContent = 'Quản lý lượt đặt'; link.className = 'block mt-4 bg-brand-600 text-white text-xs py-2 text-center rounded-lg font-bold';
            link.href = 'dieu-phoi-san?' + new URLSearchParams({ date: options.today, pitch: pitch.maSan }); card.append(name, status, link); grid.append(card);
        }
    } catch (error) { document.getElementById('staffOperationsFeedback').textContent = error.message; }
    const host=document.getElementById('staffFeedbackPreview');
    if(host)try{
        const rows=(await SanBong.request('feedback')).filter(r=>r.trangThai!=='Đã xử lý');
        document.getElementById('staffFeedbackCount').textContent=rows.length;
        if(!rows.length)host.textContent='Không có phản hồi chờ xử lý.';
        for(const row of rows.slice(0,5)){const p=document.createElement('p');p.className='text-sm border-b pb-2';p.textContent=`${row.maPhanHoi} · ${row.hoTen} · ${row.noiDung}`;host.append(p);}
    }catch(error){host.textContent=error.message;}
});
