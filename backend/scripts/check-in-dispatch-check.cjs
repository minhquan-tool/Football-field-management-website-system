// Browser-only fixtures: no requests or writes to a real database.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'msedge'});
 try{
  const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const root=path.resolve(__dirname,'../..');
  await page.goto('about:blank');
  await page.setContent(fs.readFileSync(path.join(root,'frontend/Quan_ly_lich_dat_san.html'),'utf8').replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi,''));
  await page.evaluate(()=>{
   window.confirm=()=>true;
   const booking={maDatSan:'MOCK1',maSan:'S1',tenSan:'Sân 1',hoTen:'Khách thử',ngayChoi:'2026-10-21',gioBatDau:'07:00',gioKetThuc:'08:00',trangThai:'Đã xác nhận',tienSan:100000,tienDichVu:0,tienGiam:0,tongTien:100000};
   window.fixture={booking,visit:null,reject:false,writes:0};
   window.SanBong={request:async(p,o={})=>{
    if(p==='booking-options')return {today:booking.ngayChoi,pitches:[booking],slots:[],states:['Đã xác nhận']};
    if(p.startsWith('bookings?'))return [{...booking}];
    if(p==='services')return [];
    if(p.endsWith('/check-in')){fixture.writes++;if(fixture.reject)throw Error('Sân đang sử dụng');fixture.visit={thoiGianKetThuc:null};return {};}
    if(p==='operations/bookings/MOCK1')return {booking:{...booking},visit:fixture.visit,services:[]};
    throw Error('Unexpected mock request '+p);
   }};
  });
  await page.addScriptTag({path:path.join(root,'frontend/js/bookings.js')});
  await page.addScriptTag({path:path.join(root,'frontend/js/operations.js')});
  await page.evaluate(()=>document.dispatchEvent(new CustomEvent('sanbong:authenticated',{detail:{maVaiTro:'VT02',permissions:['CN02_XEM','CN02_SUA','CN03_XEM','CN03_THEM']}})));
  await page.getByRole('button',{name:'Nhận sân',exact:true}).first().waitFor();
  await page.locator('[data-dispatch-tab="waiting"]').click();
  await page.evaluate(()=>fixture.reject=true);
  await page.locator('#bookingRows').getByRole('button',{name:'Nhận sân',exact:true}).click();
  await page.waitForFunction(()=>document.getElementById('calendarFeedback').textContent.includes('Sân đang sử dụng'));
  if(await page.locator('[data-dispatch-tab="playing"]').getAttribute('aria-pressed')==='true')throw Error('Failure moved to playing');
  await page.evaluate(()=>fixture.reject=false);
  await page.locator('#bookingRows').getByRole('button',{name:'Nhận sân',exact:true}).click();
  await page.waitForFunction(()=>document.querySelector('[data-dispatch-tab="playing"]').getAttribute('aria-pressed')==='true');
  await page.locator('#bookingRows').getByRole('button',{name:'Dịch vụ',exact:true}).waitFor();
  await page.locator('#bookingRows').getByRole('button',{name:'Trả sân',exact:true}).waitFor();
  if(await page.locator('#bookingRows').getByRole('button',{name:'Nhận sân',exact:true}).count())throw Error('Duplicate check-in offered');
  if(errors.length)throw Error(errors.join('\n'));
  console.log('PASS: failed check-in stays waiting; successful check-in moves to playing with service/checkout actions; no real DB writes');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
