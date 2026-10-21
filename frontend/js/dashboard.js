document.addEventListener('sanbong:authenticated', async () => {
    const $=id=>document.getElementById(id), money=n=>Number(n).toLocaleString('vi-VN')+'đ';
    let busy=false;
    const targets={dashBooking:['dieu-phoi-san','Xem lượt đặt hôm nay'],dashUsing:['quan-ly-san?status='+encodeURIComponent('Đang sử dụng'),'Xem sân đang sử dụng'],dashMaintenance:['quan-ly-san?status='+encodeURIComponent('Bảo trì'),'Xem sân bảo trì'],dashNet:['bao-cao?type=finance','Xem tiền thu và thực nhận'],dashRevenue:['bao-cao?type=finance','Xem doanh thu khi trả sân'],dashRefund:['bao-cao?type=refunds','Xem báo cáo hoàn tiền'],dashOccupancy:['bao-cao?type=usage','Xem báo cáo sử dụng sân']};
    for(const [id,[href,label]] of Object.entries(targets)){
        const card=$(id).closest('.bg-white');if(!card)continue;
        const link=document.createElement('a');link.href=href;link.className=card.className+' dashboard-stat-link';link.setAttribute('aria-label',label);
        while(card.firstChild)link.append(card.firstChild);card.replaceWith(link);
    }
    const toolbar=document.createElement('div');toolbar.className='dashboard-toolbar';
    $('dashboardStatus').before(toolbar);toolbar.append($('dashboardStatus'));
    const refresh=document.createElement('button');refresh.type='button';refresh.className='admin-refresh-button';refresh.setAttribute('aria-label','Tải lại tổng quan');refresh.title='Tải lại tổng quan';refresh.innerHTML='<i class="fa-solid fa-arrow-rotate-right" aria-hidden="true"></i>';toolbar.append(refresh);
    async function load(){
        if(busy)return;busy=true;refresh.disabled=true;
        try{
            const r=await SanBong.request('reports/dashboard');$('dashboardStatus').textContent=r.today;$('dashboardStatus').className='text-sm text-gray-500';
            for(const [id,value]of [['dashBooking',r.usage.totals.soBooking],['dashUsing',r.pitches.sanDangSuDung],['dashMaintenance',r.pitches.sanBaoTri],['dashNet',money(r.finance.totals.thucNhan)],['dashRevenue',money(r.finance.totals.doanhThu)],['dashRefund',money(r.finance.totals.tienHoan)],['dashOccupancy',r.usage.totals.tyLeLapDay+'%']])$(id).textContent=value;
            $('dashBookings').replaceChildren();
            for(const b of r.bookings){const a=document.createElement('a');a.className='dashboard-booking-link';a.textContent=`${b.gioBatDau.slice(0,5)}–${b.gioKetThuc.slice(0,5)} · ${b.tenSan} · ${b.khachHang} · ${b.trangThai}`;a.href='dieu-phoi-san?'+new URLSearchParams({date:b.ngayChoi||r.today,pitch:b.maSan,booking:b.maDatSan});$('dashBookings').append(a);}
            if(!r.bookings.length)$('dashBookings').textContent='Chưa có lượt đặt hôm nay.';
            $('dashServices').replaceChildren();
            for(const item of r.topServices){const p=document.createElement('p');p.className='p-3 border rounded-xl';p.textContent=`${item.tenDV} · ${item.soDonVi} đơn vị · ${money(item.tienDichVu)}`;$('dashServices').append(p);}
            if(!r.topServices.length)$('dashServices').textContent='Chưa có dịch vụ trong ngày.';
        }catch(error){$('dashboardStatus').textContent=error.message;$('dashboardStatus').className='text-red-600';for(const id of Object.keys(targets))$(id).textContent='—';$('dashBookings').replaceChildren();$('dashServices').replaceChildren();}
        finally{busy=false;refresh.disabled=false;}
    }
    refresh.onclick=load;await load();
});
