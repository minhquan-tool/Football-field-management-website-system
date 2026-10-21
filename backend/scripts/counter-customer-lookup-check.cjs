// All API calls are mocked; no requests to the project database.
const {chromium}=require('playwright');
const fs=require('fs'),path=require('path');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'msedge'});
 try{
  const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const root=path.resolve(__dirname,'../..');
  await page.setContent(fs.readFileSync(path.join(root,'frontend/Dat_san_tai_quay.html'),'utf8').replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi,''));
  await page.evaluate(()=>{
   window.lookupMode='normal';window.customerCalls=0;
   window.SanBong={bookingIntent:()=>new URLSearchParams(),request:async p=>{
    if(p==='booking-options')return {today:'2026-10-21',defaultDate:'2026-10-22',defaultStart:'08:00',defaultEnd:'09:00',pitches:[],types:[]};
    if(p.startsWith('availability?'))return [];
    if(p.startsWith('booking-customers?')){
     customerCalls++;const phone=new URLSearchParams(p.split('?')[1]).get('phone');
     if(lookupMode==='error')throw Error('Mất kết nối');
     if(phone==='0900000001'){await new Promise(r=>setTimeout(r,800));return [{maKH:'OLD',hoTen:'Khách cũ chậm',soDienThoai:phone}];}
     if(phone==='0900000002')return [{maKH:'KH2',hoTen:'Khách đã đăng ký',soDienThoai:phone}];
     if(phone==='0900000004')return [{maKH:'KH4',hoTen:'Khách tại quầy',soDienThoai:phone}];
     return [];
    }throw Error('Unexpected API '+p);
   }};
  });
  await page.addScriptTag({path:path.join(root,'frontend/js/bookings.js')});
  await page.evaluate(()=>document.dispatchEvent(new CustomEvent('sanbong:authenticated',{detail:{maVaiTro:'VT02',permissions:['CN02_THEM','CN02_XEM']}})));
  await page.locator('#customerPhone').fill('0900000002');
  await page.waitForFunction(()=>document.getElementById('customerName').value==='Khách đã đăng ký');
  if(!await page.locator('#customerName').evaluate(e=>e.readOnly))throw Error('Existing name editable');
  await page.locator('#customerPhone').fill('0900000004');
  await page.waitForFunction(()=>document.getElementById('customerName').value==='Khách tại quầy');
  await page.locator('#customerPhone').fill('0900000003');
  await page.waitForFunction(()=>document.getElementById('counterCustomerStatus').textContent.includes('Khách mới'));
  if(await page.locator('#customerName').evaluate(e=>e.readOnly))throw Error('New name locked');
  await page.locator('#customerName').fill('Khách mới');
  await page.evaluate(()=>lookupMode='error');await page.locator('#customerPhone').fill('0900000005');
  await page.waitForFunction(()=>document.getElementById('counterCustomerStatus').textContent.includes('Không tra cứu được'));
  if(await page.locator('#customerName').inputValue()!=='')throw Error('Stale name on API failure');
  await page.evaluate(()=>lookupMode='normal');await page.locator('#customerPhone').fill('0900000001');
  await page.waitForFunction(()=>document.getElementById('counterCustomerStatus').textContent==='Đang tra cứu khách hàng…');
  await page.locator('#customerPhone').fill('0900000002');
  await page.waitForFunction(()=>document.getElementById('customerName').value==='Khách đã đăng ký');
  await page.waitForTimeout(900);
  if(await page.locator('#customerName').inputValue()!=='Khách đã đăng ký')throw Error('Stale response overwrote latest phone');
  await page.locator('#customerPhone').fill('12');await page.locator('#customerPhone').blur();
  await page.waitForFunction(()=>document.getElementById('counterCustomerStatus').textContent.includes('hợp lệ'));
  if(errors.length)throw Error(errors.join('\n'));
  console.log('PASS: registered/walk-in customers reused; new customer; API failure; stale response; invalid phone. No DB writes.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
