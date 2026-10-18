/* A booking slip is not evidence of receipt of money. Values come from the API. */
document.addEventListener('sanbong:authenticated', () => {
    const modal=document.getElementById('detailModal');if(!modal)return;
    const button=document.createElement('button');button.type='button';button.id='printBookingSlip';button.textContent='In / Lưu PDF phiếu đặt sân';button.className='border rounded-lg px-3 py-2 m-3';
    modal.querySelector('h3,h2')?.parentElement.append(button);
    button.addEventListener('click',async()=>{
        const id=document.getElementById('modalBookingId').textContent.replace(/^Chi tiết /,'').trim();
        if(!id)return;button.disabled=true;
        try{
            const booking=await SanBong.request('bookings/'+encodeURIComponent(id));
            const services=await SanBong.request('bookings/'+encodeURIComponent(id)+'/services');
            document.getElementById('bookingPrintSheet')?.remove();
            const sheet=document.createElement('section');sheet.id='bookingPrintSheet';
            function add(tag,text){const node=document.createElement(tag);node.textContent=text;sheet.append(node);}
            const money=n=>Number(n||0).toLocaleString('vi-VN')+' đ';
            add('h1','FC-UTE · Phiếu đặt sân');add('p','Mã lượt đặt: '+booking.maDatSan);
            add('p','Khách hàng: '+booking.hoTen);add('p',`Sân: ${booking.tenSan} (${booking.maSan})`);
            add('p',`Ngày chơi: ${booking.ngayChoi} · ${booking.gioBatDau}–${booking.gioKetThuc}`);
            add('p','Trạng thái lượt đặt: '+booking.trangThai);
            add('h2','Chi phí theo dữ liệu hiện tại');
            add('p','Tiền sân: '+money(booking.tienSan));
            for(const line of services)add('p',`${line.tenDV} · ${line.quyCach} × ${line.soLuong}: ${money(line.thanhTien)}`);
            add('p','Tổng dịch vụ: '+money(booking.tienDichVu));add('p','Giảm giá: '+money(booking.tienGiam));add('p','Tổng tiền: '+money(booking.tongTien));
            add('p','Phiếu thông tin đặt sân, không phải hóa đơn hoặc xác nhận đã thanh toán. Trạng thái thực thu và hoàn tiền xem tại mục Hóa đơn / Thanh toán / Hoàn tiền.');
            add('p','Thời điểm tra cứu: '+new Date().toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh'}));
            document.body.append(sheet);window.addEventListener('afterprint',()=>sheet.remove(),{once:true});window.print();
        }catch(error){alert('Chưa in được phiếu: '+error.message);}finally{button.disabled=false;}
    });
    const style=document.createElement('style');style.textContent='#bookingPrintSheet{display:none}@media print{body:has(>#bookingPrintSheet)>*{display:none!important}body>#bookingPrintSheet{display:block!important;color:#000;background:#fff;padding:15mm;font:12pt Arial,sans-serif}#bookingPrintSheet h1{font-size:20pt}#bookingPrintSheet h2{font-size:15pt;margin-top:1em}#bookingPrintSheet p{margin:.6em 0;overflow-wrap:anywhere}@page{size:A4;margin:10mm}}';document.head.append(style);
});
