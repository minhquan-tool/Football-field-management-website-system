import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');
const password=process.env.AUTH_TEST_PASSWORD, stateFile=process.env.PHASE5_1C_TEST_STATE;
if(!password||!stateFile)throw Error('Set AUTH_TEST_PASSWORD and PHASE5_1C_TEST_STATE.');
const state={id:'FCH'+randomUUID().replaceAll('-','').slice(0,6).toUpperCase(),marker:'Phase5.1C HTTP temporary test',bookings:[]};
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


const admin=client(), accountant=client(), customer=client(), staff=client();
await admin.login();await accountant.login('ketoan');await customer.login('khachhang');await staff.login('nvsan');
function sql(query){return execFileSync('sqlcmd',['-S','np:\\\\.\\pipe\\sql\\query','-E','-d','QuanLySanBong','-b','-h','-1','-W','-Q','SET NOCOUNT ON; '+query],{encoding:'utf8'});}
function verify(label){
 sql(`IF EXISTS(SELECT 1 FROM HoaDon h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan='${state.id}' AND (h.DaThanhToan<>(SELECT ISNULL(SUM(SoTien),0) FROM ThanhToan t WHERE t.MaDatSan=d.MaDatSan AND t.TrangThai=N'\u0054hành công') OR h.DaThanhToan>h.TongTien)) THROW 50601,'Invoice/payment mismatch',1;
 IF EXISTS(SELECT 1 FROM HuyDatSan h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan='${state.id}' AND h.SoTienHoan<>ROUND(h.SoTienThucThuSnapshot*h.TiLeHoan/100,2)) THROW 50602,'Refund policy mismatch',1;`);
 console.log('SQL verify PASS: '+label);
}
const options=(await admin.request('/booking-options')).data.data;
const day=new Date(options.today+'T12:00:00Z');day.setUTCDate(day.getUTCDate()+20);while([0,6].includes(day.getUTCDay()))day.setUTCDate(day.getUTCDate()+1);state.date=day.toISOString().slice(0,10);save();
assert.equal((await admin.write('/pitches',{maSan:state.id,tenSan:'Phase5.1C HTTP sân',maLoaiSan:'LS01',trangThai:'Trống',moTa:state.marker})).status,200);
const svc=[{maDV:'SV03',quyCach:'LOC_6',soLuong:1}];
async function create(date,start,end,services=[]){const r=await admin.write('/bookings',{maSan:state.id,maKH:'KH01',ngayChoi:date,gioBatDau:start,gioKetThuc:end,dichVu:services,ghiChu:state.marker});assert.equal(r.status,200);const id=r.data.data.maDatSan;state.bookings.push(id);save();return id;}
const path=id=>'/finance/bookings/'+id;
const payment=(n,method='Tiền mặt')=>({soTien:n,phuongThuc:method,idempotencyKey:state.id+'-'+randomUUID(),daNhanTien:true});
const id=await create(state.date,'13:00','15:00',svc);
let row=await admin.write(path(id)+'/invoice',{maKM:'KM02',tongTien:1});assert.equal(row.status,200);assert.equal(row.data.data.invoice.tongTien,292200);
row=await admin.write(path(id)+'/invoice',{});assert.equal(row.status,200);verify('one snapshot invoice, fake total ignored');
const first=payment(200000);assert.equal((await admin.write(path(id)+'/payments',first)).status,200);assert.equal((await admin.write(path(id)+'/payments',first)).status,200);verify('partial payment and idempotency retry');
const race=await Promise.all([admin.write(path(id)+'/payments',payment(92200)),accountant.write(path(id)+'/payments',payment(92200,'Chuyển khoản'))]);assert.deepEqual(race.map(r=>r.status).sort(),[200,409]);verify('double payment race');
assert.equal((await customer.write(path(id)+'/payments',payment(1))).status,403);
assert.equal((await customer.write('/bookings/'+id+'/cancel',{lyDo:state.marker})).status,200);verify('cancel full refund on actual receipts');
row=(await accountant.request(path(id))).data.data;assert.equal(row.cancellation.soTienHoan,292200);assert.equal(row.invoice.conLai,0);
const body={phuongThuc:'Chuyển khoản',daHoanTien:true,lyDo:state.marker};
const refund=row.refunds[0].maHT;assert.equal((await staff.write('/finance/refunds/'+refund+'/confirm',body)).status,403);assert.equal((await customer.write('/finance/refunds/'+refund+'/confirm',body)).status,403);
const rr=await Promise.all([admin.write('/finance/refunds/'+refund+'/confirm',body),accountant.write('/finance/refunds/'+refund+'/confirm',body)]);assert.ok(rr.every(r=>r.status===200));
assert.equal((await admin.write('/finance/refunds/'+refund+'/confirm',body)).status,200);verify('refund race and repeated confirmation');
for(const r of row.refunds)assert.equal((await accountant.write('/finance/refunds/'+r.maHT+'/confirm',body)).status,200);verify('all refunds bounded by policy and actual received');
const requestBooking=await create(state.date,'16:00','17:00');row=await customer.write(path(requestBooking)+'/payment-requests',payment(50000,'Chuyển khoản'));assert.equal(row.status,200);assert.equal(row.data.data.invoice.daThanhToan,0);
const pending=row.data.data.payments[0].maTT;assert.equal((await customer.write('/finance/payments/'+pending+'/confirm',{daNhanTien:true})).status,403);
assert.equal((await accountant.write('/finance/payments/'+pending+'/confirm',{daNhanTien:true})).status,200);verify('customer request does not set success; accountant confirms');
assert.equal((await customer.write('/bookings/'+requestBooking+'/cancel',{lyDo:state.marker})).status,200);verify('partial paid cancellation refunds only 50000');
const clock=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Ho_Chi_Minh',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(new Date()).map(p=>[p.type,p.value]));
const minutes=Number(clock.hour)*60+Number(clock.minute);const time=m=>String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0');
if(minutes<420||minutes+601+30>1320)throw Error('Run boundary HTTP in 07:00–11:29; deterministic exact boundary tests run in JUnit/SQL.');
for(const [offset,rate] of [[601,100],[598,50],[121,50],[118,0]]){
 const b=await create(options.today,time(minutes+offset),time(minutes+offset+30));assert.equal((await admin.write(path(b)+'/payments',payment(20000))).status,200);
 assert.equal((await customer.write('/bookings/'+b+'/cancel',{lyDo:state.marker})).status,200);row=(await accountant.request(path(b))).data.data;
 assert.equal(row.cancellation.tiLeHoan,rate);assert.equal(row.cancellation.soTienHoan,20000*rate/100);verify('HTTP around cancellation boundary '+offset+' minutes');
}
sql("IF dbo.fn_TyLeHoan('2026-10-28T18:00:00','2026-10-28T08:00:00')<>100 OR dbo.fn_TyLeHoan('2026-10-28T10:00:00','2026-10-28T08:00:00')<>50 THROW 50603,'Exact policy boundary failed',1;");
const operational=await create(options.today,time(minutes+10),time(minutes+40),svc);
assert.equal((await admin.write('/bookings/'+operational+'/confirm',{})).status,200);
row=await admin.write(path(operational)+'/payments',payment(103200));assert.equal(row.status,200);assert.equal(row.data.data.invoice.conLai,0);
assert.equal((await staff.write('/operations/bookings/'+operational+'/check-in',{})).status,200);
assert.equal((await staff.write('/operations/bookings/'+operational+'/services/SV03',{soLuong:1,quyCach:'DON_VI'})).status,200);
row=(await accountant.request(path(operational))).data.data;assert.equal(row.invoice.conLai,10000);verify('full prepayment plus supplement');
assert.equal((await staff.write('/operations/bookings/'+operational+'/check-out',{})).status,200);
row=(await accountant.request(path(operational))).data.data;assert.equal(row.invoice.hoanTatTaiChinh,false);
row=await accountant.write(path(operational)+'/payments',payment(10000,'Chuyển khoản'));assert.equal(row.status,200);assert.equal(row.data.data.invoice.hoanTatTaiChinh,true);verify('postgame balance and financial completion');
assert.equal((await customer.write('/bookings/'+operational+'/cancel',{lyDo:state.marker})).status,409);
for(const c of [admin,accountant,customer,staff])await c.write('/auth/logout',{});
console.log(`PHASE5_1C_HTTP_PASS pitch=${state.id}; ${state.bookings.length} fixtures. Manual internal confirmations, no bank transfer executed.`);
