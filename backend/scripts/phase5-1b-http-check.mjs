import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');
const password=process.env.AUTH_TEST_PASSWORD, stateFile=process.env.PHASE5_1B_TEST_STATE;
if(!password||!stateFile)throw Error('Set AUTH_TEST_PASSWORD and PHASE5_1B_TEST_STATE.');
const state={id:'SBH'+randomUUID().replaceAll('-','').slice(0,6).toUpperCase(),marker:'Phase5.1B HTTP temporary test',bookings:[]};
const save=()=>writeFileSync(stateFile,JSON.stringify(state));save();
function client(){
 let cookie='';
 async function request(path,options={}){
  const r=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});
  for(const v of r.headers.getSetCookie())if(v.startsWith('JSESSIONID='))cookie=v.split(';')[0];
  const raw=await r.text();let data;try{data=JSON.parse(raw);}catch{data=raw;}return {status:r.status,data};
 }
 async function write(path,body,method='POST'){const c=(await request('/auth/csrf')).data.data;return request(path,{method,headers:{[c.headerName]:c.token,'Content-Type':'application/json'},body:JSON.stringify(body)});}
 async function login(identifier='admin'){const c=(await request('/auth/csrf')).data.data;assert.equal((await request('/auth/login',{method:'POST',headers:{[c.headerName]:c.token},body:new URLSearchParams({identifier,password})})).status,200);}
 return {request,write,login};
}

const admin=client(), customer=client();await admin.login();await customer.login('khachhang');
const options=(await admin.request('/booking-options')).data.data;
const day=new Date(options.today+'T12:00:00Z');day.setUTCDate(day.getUTCDate()+25);state.date=day.toISOString().slice(0,10);save();
assert.equal((await admin.write('/pitches',{maSan:state.id,tenSan:'Phase5.1B HTTP sân',maLoaiSan:'LS01',trangThai:'Trống',moTa:state.marker})).status,200);
const catalog=(await customer.request('/booking-services')).data.data;
for(const [sku,price,pack] of [['SV02',5000,29100],['SV03',10000,58200],['SV07',12000,69840]]){
 const row=catalog.find(c=>c.maDV===sku);assert.equal(row.donGia,price);assert.equal(row.giaLoc,pack);
}
assert.equal((await customer.request('/services')).status,403);
assert.equal((await customer.write('/service-catalog/SV03',{donGia:11000,trangThai:true,hoTroLoc:true})).status,403);
const payload=(services)=>({maSan:state.id,maKH:'KH01',ngayChoi:state.date,gioBatDau:'08:00',gioKetThuc:'09:00',ghiChu:state.marker,dichVu:services});
const line=(sku,pack,qty)=>({maDV:sku,quyCach:pack,soLuong:qty});
for(const [lines,code] of [[[line('SV01','LOC_6',1)],400],[[line('SV03','DON_VI',0)],400],[[line('SV03','DON_VI',1),line('ZZMISSING','DON_VI',1)],404]])assert.equal((await customer.write('/bookings',payload(lines))).status,code);
assert.equal((await admin.request('/bookings?'+new URLSearchParams({date:state.date,pitch:state.id}))).data.data.length,0);
const created=await customer.write('/bookings',payload([line('SV03','DON_VI',1),line('SV03','LOC_6',1),line('SV07','LOC_6',1)]));
assert.equal(created.status,200);state.bookings.push(created.data.data.maDatSan);save();
assert.equal(created.data.data.tienDichVu,138040);assert.equal(created.data.data.tongTien,228040);
const id=state.bookings[0];const saved=(await customer.request('/bookings/'+id+'/services')).data.data;
assert.equal(saved.length,3);assert.ok(saved.every(l=>l.nguon==='DAT_TRUOC'&&l.maChiTiet));
assert.equal((await customer.write('/operations/bookings/'+id+'/services/SV03',{soLuong:1})).status,403);
assert.equal((await admin.request('/bookings/'+id)).data.data.tienDichVu,138040);
assert.equal((await customer.write('/bookings/'+id+'/cancel',{lyDo:state.marker})).status,200);
for(const page of ['/Man_hinh_chinh_Dat_san_KH.html'])assert.ok((await customer.request(page)).data.includes('id="prebookServices"'));

const clock=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Ho_Chi_Minh',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(new Date()).map(p=>[p.type,p.value]));
const minutes=Number(clock.hour)*60+Number(clock.minute)+10;
if(minutes>=420 && minutes+30<=1320){
 const time=m=>String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0');
 const staff=client();await staff.login('nvsan');
 const r=await admin.write('/bookings',{...payload([line('SV03','DON_VI',1),line('SV03','LOC_6',1)]),ngayChoi:options.today,gioBatDau:time(minutes),gioKetThuc:time(minutes+30)});
 assert.equal(r.status,200);const operational=r.data.data.maDatSan;state.bookings.push(operational);save();
 const path='/operations/bookings/'+operational;
 assert.equal((await admin.write('/bookings/'+operational+'/confirm',{})).status,200);
 assert.equal((await staff.write(path+'/check-in',{})).status,200);
 assert.equal((await staff.write(path+'/services/SV03',{soLuong:1,quyCach:'DON_VI'})).data.data.booking.tienDichVu,78200);
 const old=(await admin.request('/service-catalog')).data.data.find(x=>x.maDV==='SV03');state.catalogBefore=old;save();
 try{
  assert.equal((await admin.write('/service-catalog/SV03',{donGia:11000,trangThai:true,hoTroLoc:true},'PUT')).status,200);
  assert.equal((await staff.write(path+'/services/SV03',{soLuong:1,quyCach:'DON_VI'})).data.data.booking.tienDichVu,89200);
  const race=await Promise.all([staff.write(path+'/services/SV03',{soLuong:1,quyCach:'LOC_6'}),admin.write(path+'/services/SV03',{soLuong:1,quyCach:'LOC_6'})]);
  assert.deepEqual(race.map(x=>x.status).sort(),[200,409]);
  const details=(await staff.request(path)).data.data;assert.equal(details.services.length,5);assert.equal(details.booking.tienDichVu,153220);
  const original=details.services.find(x=>x.nguon==='DAT_TRUOC'&&x.quyCach==='DON_VI');assert.equal(original.donGia,10000);
  assert.equal((await admin.write(path+'/services/SV03',{soLuong:2},'PUT')).status,409);
  assert.equal((await admin.write(path+'/service-lines/'+original.maChiTiet,{soLuong:2},'PUT')).data.data.booking.tienDichVu,163220);
  assert.equal((await admin.write(path+'/service-lines/'+original.maChiTiet,{},'DELETE')).data.data.booking.tienDichVu,143220);
  assert.equal((await staff.write(path+'/check-out',{})).status,200);
  assert.equal((await admin.write(path+'/service-lines/'+details.services[1].maChiTiet,{soLuong:2},'PUT')).status,409);
  console.log('Staff HTTP PASS: receive/service sources/packs/catalog edit/history/race/line ID/ambiguous SKU/checkout freeze.');
 }finally{
  assert.equal((await admin.write('/service-catalog/SV03',{donGia:old.donGia,trangThai:old.trangThai,hoTroLoc:old.hoTroLoc},'PUT')).status,200);
 }
 await staff.write('/auth/logout',{});
}else console.log('Staff HTTP skipped outside operating-hour check-in window; covered by SQL integration tests.');
await admin.write('/auth/logout',{});await customer.write('/auth/logout',{});
console.log(`PHASE5_1B_HTTP_PASS pitch=${state.id} booking=${id}; catalog/pack prices/atomic rollback/prebooking/fresh snapshots/roles/cancel.`);
console.log('SQL verify, then cleanup only exact marked fixture. Catalog changes are restored in finally; state retains original values on failure.');
