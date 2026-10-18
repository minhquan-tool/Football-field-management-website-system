import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');
const password=process.env.AUTH_TEST_PASSWORD, stateFile=process.env.PHASE5_1A_TEST_STATE;
if(!password||!stateFile)throw Error('Set AUTH_TEST_PASSWORD and PHASE5_1A_TEST_STATE.');
const state={id:'FAH'+randomUUID().replaceAll('-','').slice(0,6).toUpperCase(),marker:'Phase5.1A HTTP temporary test',bookings:[]};
const save=()=>writeFileSync(stateFile,JSON.stringify(state));save();
function client(){
 let cookie='';
 async function request(path,options={}){
  const r=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});
  for(const v of r.headers.getSetCookie())if(v.startsWith('JSESSIONID='))cookie=v.split(';')[0];
  const raw=await r.text();let data;try{data=JSON.parse(raw);}catch{data=raw;}return {status:r.status,data};
 }
 async function write(path,body){const c=(await request('/auth/csrf')).data.data;return request(path,{method:'POST',headers:{[c.headerName]:c.token,'Content-Type':'application/json'},body:JSON.stringify(body)});}
 async function login(identifier='admin'){const c=(await request('/auth/csrf')).data.data;assert.equal((await request('/auth/login',{method:'POST',headers:{[c.headerName]:c.token},body:new URLSearchParams({identifier,password})})).status,200);}
 return {request,write,login};
}
const a=client(),b=client();await a.login();await b.login();
const options=(await a.request('/booking-options')).data.data;
const day=new Date(options.today+'T12:00:00Z');day.setUTCDate(day.getUTCDate()+20);state.date=day.toISOString().slice(0,10);save();
assert.equal((await a.write('/pitches',{maSan:state.id,tenSan:'Phase5.1A HTTP sân',maLoaiSan:'LS01',trangThai:'Trống',moTa:state.marker})).status,200);
const payload=(start,end)=>({maSan:state.id,maKH:'KH01',ngayChoi:state.date,gioBatDau:start,gioKetThuc:end,ghiChu:state.marker});
async function record(r){if(r.status===200){state.bookings.push(r.data.data.maDatSan);save();}return r;}
for(const [start,end,total] of [['08:00','12:30',405000],['12:20','14:20',180000],['13:00','15:00',260000],['18:30','20:00',195000],['19:00','20:00',180000]]){
 const r=await record(await a.write('/bookings',payload(start,end)));assert.equal(r.status,200);assert.equal(r.data.data.tienSan,total);
 assert.equal((await b.request('/bookings/'+r.data.data.maDatSan)).data.data.tienSan,total);
 assert.equal((await a.write('/bookings/'+r.data.data.maDatSan+'/cancel',{lyDo:state.marker})).status,200);
}
for(const [start,end] of [['06:59','08:00'],['21:00','22:01'],['22:00','22:00'],['10:00','09:00']])assert.equal((await a.write('/bookings',payload(start,end))).status,400);
const results=await Promise.all([a.write('/bookings',payload('08:00','10:00')),b.write('/bookings',payload('09:00','11:00'))]);
for(const r of results)await record(r);assert.deepEqual(results.map(r=>r.status).sort(),[200,409]);
const winner=results.find(r=>r.status===200).data.data;
assert.ok((await a.request('/bookings?'+new URLSearchParams({date:state.date,pitch:state.id}))).data.data.some(r=>r.maDatSan===winner.maDatSan));
assert.equal((await a.request('/availability?'+new URLSearchParams({date:state.date,start:'08:30',end:'09:30'}))).data.data.some(p=>p.maSan===state.id),false);
const customer=client();await customer.login('khachhang');
for(const [c,page] of [[a,'/Dat_san_tai_quay.html'],[customer,'/Man_hinh_chinh_Dat_san_KH.html']]){
 const r=await c.request(page);assert.equal(r.status,200);assert.ok(r.data.includes('id="startTime"')&&r.data.includes('id="endTime"'));
}
await customer.write('/auth/logout',{});
assert.equal((await a.write('/bookings/'+winner.maDatSan+'/confirm',{})).status,200);
assert.equal((await a.write('/bookings/'+winner.maDatSan+'/cancel',{lyDo:state.marker})).status,200);
assert.equal((await b.request('/bookings/'+winner.maDatSan)).data.data.trangThai,'Đã hủy');
await a.write('/auth/logout',{});await b.write('/auth/logout',{});
console.log(`PHASE5_1A_HTTP_PASS pitch=${state.id} date=${state.date} bookings=${state.bookings.length}; price/boundary/race/availability/calendar/confirm/cancel/fresh read.`);
console.log('Verify SQL and clean exact marked fixture; state file retains IDs on failure.');
