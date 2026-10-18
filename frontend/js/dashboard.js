document.addEventListener('sanbong:authenticated',async()=>{
 const $=id=>document.getElementById(id),money=n=>Number(n).toLocaleString('vi-VN')+'đ';
 try{const r=await SanBong.request('reports/dashboard');$('dashboardStatus').textContent='Dữ liệu ngày '+r.today+' · giờ Việt Nam';
 for(const [id,v]of [['dashBooking',r.usage.totals.soBooking],['dashUsing',r.pitches.sanDangSuDung],['dashMaintenance',r.pitches.sanBaoTri],['dashNet',money(r.finance.totals.thucNhan)],['dashRevenue',money(r.finance.totals.doanhThu)],['dashRefund',money(r.finance.totals.tienHoan)],['dashOccupancy',r.usage.totals.tyLeLapDay+'%']])$(id).textContent=v;
 for(const [id,rows,format]of [['dashBookings',r.bookings,b=>`${b.maDatSan} · ${b.tenSan} · ${b.gioBatDau}–${b.gioKetThuc} · ${b.khachHang} · ${b.trangThai}`],['dashServices',r.topServices,b=>`${b.tenDV} · ${b.soDonVi} đơn vị · ${money(b.tienDichVu)}`]]){const host=$(id);host.replaceChildren();if(!rows.length)host.textContent='Chưa có dữ liệu trong ngày.';for(const row of rows){const p=document.createElement('p');p.className='p-3 border rounded-xl';p.textContent=format(row);host.append(p);}}
 }catch(err){$('dashboardStatus').textContent=err.message;$('dashboardStatus').className='text-red-600';for(const id of ['dashBooking','dashUsing','dashMaintenance','dashNet'])$(id).textContent='—';}
});
