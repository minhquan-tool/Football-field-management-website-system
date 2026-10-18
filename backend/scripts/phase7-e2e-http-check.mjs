import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');
const password=process.env.AUTH_TEST_PASSWORD,stateFile=process.env.PHASE7_TEST_STATE;
if(!password||!stateFile)throw Error('Set AUTH_TEST_PASSWORD and PHASE7_TEST_STATE');
const state={id:'P7H'+randomUUID().replaceAll('-','').slice(0,6).toUpperCase(),marker:'Phase7 E2E fixture',bookings:[]};
const save=()=>writeFileSync(stateFile,JSON.stringify(state));save();
function client(){let cookie='';async function request(path,options={}){const r=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});for(const h of r.headers.getSetCookie())if(h.startsWith('JSESSIONID='))cookie=h.split(';')[0];const raw=await r.text();let data;try{data=JSON.parse(raw);}catch{data=raw;}return {status:r.status,data};}
async function write(path,body,method='POST'){const c=(await request('/auth/csrf')).data.data;return request(path,{method,headers:{[c.headerName]:c.token,'Content-Type':'application/json'},body:JSON.stringify(body)});}
async function login(identifier,pw=password){const c=(await request('/auth/csrf')).data.data;return request('/auth/login',{method:'POST',headers:{[c.headerName]:c.token},body:new URLSearchParams({identifier,password:pw})});}return {request,write,login};}
function sql(query){return execFileSync('sqlcmd',['-S',process.env.SQLCMD_TEST_SERVER||'tcp:localhost,1433','-E','-d','QuanLySanBong','-b','-h','-1','-W','-Q','SET NOCOUNT ON; '+query],{encoding:'utf8'}).trim();}
function equalSql(query,value,label){assert.equal(Number(sql(query)),Number(value));console.log('HTTP = SQL PASS: '+label);}
function ok(r){assert.equal(r.status,200,typeof r.data==='object'?r.data.message:'HTTP failure');return r.data.data;}
const admin=client(),staff=client(),accountant=client(),customer=client();ok(await admin.login('admin'));ok(await staff.login('nvsan'));ok(await accountant.login('ketoan'));ok(await customer.login('khachhang'));
const options=ok(await admin.request('/admin/options'));state.today=options.today;
const employeeBody={hoTen:state.marker+' '+state.id,boPhan:'Nhân viên sân bóng',trangThai:true,ngayVaoLam:state.today};
state.nv=ok(await admin.write('/admin/employees',employeeBody)).MaNV;save();
const list=ok(await admin.request('/admin/employees?q='+state.nv));equalSql(`SELECT COUNT(*) FROM NhanVien WHERE MaNV='${state.nv}'`,list.total,'employee create/search');
state.username='test_'+state.id;const tempPassword=randomUUID(),nextPassword=randomUUID();
state.tk=ok(await admin.write('/admin/accounts',{maNV:state.nv,tenDangNhap:state.username,matKhau:tempPassword,maVaiTro:'VT02'})).MaTK;save();
assert.match(sql(`SELECT MatKhau FROM TaiKhoan WHERE MaTK='${state.tk}'`),/^\$2/);
const accounts=ok(await admin.request('/security/accounts'));assert.ok(accounts.every(a=>!('MatKhau' in a)));console.log('HTTP = SQL PASS: account BCrypt/no hash in API');
let temp=client();ok(await temp.login(state.username,tempPassword));
for(const c of [staff,accountant,customer])assert.equal((await c.write('/admin/employees',employeeBody)).status,403);
assert.equal((await customer.request(`/reports/finance?from=${state.today}&to=${state.today}`)).status,403);
assert.equal((await temp.request(`/reports/usage?from=${state.today}&to=${state.today}`)).status,403);
ok(await admin.write('/admin/accounts/'+state.tk,{hoatDong:true,maVaiTro:'VT03'},'PUT'));assert.equal(ok(await temp.request('/auth/me')).maVaiTro,'VT03');ok(await temp.request(`/reports/finance?from=${state.today}&to=${state.today}`));
ok(await admin.write('/admin/accounts/'+state.tk,{hoatDong:true,maVaiTro:'VT02'},'PUT'));assert.equal((await temp.request(`/reports/finance?from=${state.today}&to=${state.today}`)).status,403);console.log('HTTP = SQL PASS: role reload, four actors, 403');
ok(await admin.write('/admin/accounts/'+state.tk,{hoatDong:false,maVaiTro:'VT02'},'PUT'));assert.equal((await temp.request('/auth/me')).status,401);assert.equal((await client().login(state.username,tempPassword)).status,401);
ok(await admin.write('/admin/accounts/'+state.tk,{hoatDong:true,maVaiTro:'VT02'},'PUT'));temp=client();ok(await temp.login(state.username,tempPassword));
ok(await admin.write('/admin/accounts/'+state.tk+'/reset-password',{matKhau:nextPassword}));assert.equal((await temp.request('/auth/me')).status,401);assert.equal((await client().login(state.username,tempPassword)).status,401);temp=client();ok(await temp.login(state.username,nextPassword));console.log('HTTP = SQL PASS: lock/unlock/reset and session invalidation');
ok(await admin.write('/admin/employees/'+state.nv,{...employeeBody,trangThai:false},'PUT'));assert.equal((await temp.request('/auth/me')).status,401);assert.equal((await admin.write('/admin/accounts/'+state.tk,{hoatDong:true,maVaiTro:'VT02'},'PUT')).status,409);ok(await admin.write('/admin/employees/'+state.nv,employeeBody,'PUT'));ok(await admin.write('/admin/accounts/'+state.tk,{hoatDong:true,maVaiTro:'VT02'},'PUT'));
assert.equal((await admin.write('/admin/accounts/TK01',{hoatDong:false,maVaiTro:'VT04'},'PUT')).status,409);
const logs=ok(await admin.request(`/admin/logs?from=${state.today}&to=${state.today}&target=${state.tk}&module=${encodeURIComponent('Quản trị')}`));assert.ok(logs.total>=5);assert.ok(!JSON.stringify(logs).includes(nextPassword));assert.ok(!JSON.stringify(logs).includes(tempPassword));equalSql(`SELECT COUNT(*) FROM NhatKyHeThong WHERE DoiTuong='${state.tk}' AND ChucNang=N'Quản trị'`,logs.total,'audit without password');
ok(await admin.write('/pitches',{maSan:state.id,tenSan:'Phase7 E2E sân',maLoaiSan:'LS01',trangThai:'Trống',moTa:state.marker}));
const parts=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Ho_Chi_Minh',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(new Date()).map(x=>[x.type,x.value]));
const start=Number(parts.hour)*60+Number(parts.minute)+10,end=start+60;if(start<420||end>1320)throw Error('Operational fixture requires07:00–20:50; inspect state and clean safely.');
const hm=n=>String(Math.floor(n/60)).padStart(2,'0')+':'+String(n%60).padStart(2,'0');
async function create(date,from,to,services=[]){const d=ok(await (date===state.today?staff:customer).write('/bookings',{maSan:state.id,maKH:'KH01',ngayChoi:date,gioBatDau:from,gioKetThuc:to,dichVu:services,ghiChu:state.marker}));state.bookings.push(d.maDatSan);save();return d;}
const used=await create(state.today,hm(start),hm(end),[{maDV:'SV03',soLuong:1,quyCach:'LOC_6'}]);
assert.equal((await customer.write('/bookings',{maSan:state.id,ngayChoi:state.today,gioBatDau:hm(start+15),gioKetThuc:hm(end+15),ghiChu:state.marker})).status,409);console.log('Connected E2E PASS: interval overlap rejected');
const pay=(amount,method='Tiền mặt')=>({soTien:amount,phuongThuc:method,idempotencyKey:state.id+'-'+randomUUID(),daNhanTien:true});
ok(await admin.write('/finance/bookings/'+used.maDatSan+'/payments',pay(100000)));
const intent=ok(await customer.write('/finance/bookings/'+used.maDatSan+'/payment-requests',pay(20000,'Chuyển khoản')));const tt=intent.payments.find(p=>p.trangThai==='Chờ xử lý').maTT;ok(await accountant.write('/finance/payments/'+tt+'/confirm',{daNhanTien:true}));
ok(await admin.write('/bookings/'+used.maDatSan+'/confirm',{}));ok(await staff.write('/operations/bookings/'+used.maDatSan+'/check-in',{ghiChu:state.marker}));const extra=ok(await staff.write('/operations/bookings/'+used.maDatSan+'/services/SV03',{soLuong:1,quyCach:'DON_VI'}));assert.equal(extra.booking.tienDichVu,68200);
ok(await staff.write('/operations/bookings/'+used.maDatSan+'/check-out',{}));
const invoice=ok(await accountant.request('/finance/bookings/'+used.maDatSan));const owed=extra.booking.tongTien-120000;assert.ok(owed>0);ok(await accountant.write('/finance/bookings/'+used.maDatSan+'/payments',pay(owed)));assert.equal(ok(await accountant.request('/finance/bookings/'+used.maDatSan)).invoice.conLai,0);
let next=new Date(state.today+'T12:00:00Z');next.setUTCDate(next.getUTCDate()+20);const future=next.toISOString().slice(0,10);
const canceled=await create(future,'16:00','17:00');ok(await admin.write('/finance/bookings/'+canceled.maDatSan+'/payments',pay(50000,'Chuyển khoản')));ok(await customer.write('/bookings/'+canceled.maDatSan+'/cancel',{lyDo:state.marker}));
const detail=ok(await accountant.request('/finance/bookings/'+canceled.maDatSan));ok(await accountant.write('/finance/refunds/'+detail.refunds[0].maHT+'/confirm',{phuongThuc:'Chuyển khoản',lyDo:state.marker,daHoanTien:true}));
const filter=`?from=${state.today}&to=${state.today}&pitch=${state.id}`;
const usage=ok(await admin.request('/reports/usage'+filter));assert.equal(usage.totals.phutDat,60);assert.equal(usage.totals.soDaSuDung,1);equalSql(`SELECT SUM(PhutDat) FROM V_Phase6_UsageBooking WHERE MaSan='${state.id}' AND NgayChoi='${state.today}'`,usage.totals.phutDat,'usage minutes/occupancy');assert.equal(usage.totals.tyLeLapDay,6.67);
const finance=ok(await accountant.request('/reports/finance'+filter));assert.equal(finance.totals.doanhThu,extra.booking.tongTien);assert.equal(finance.totals.tienDichVu,68200);assert.equal(finance.totals.tienThu,170000+owed);assert.equal(finance.totals.tienHoan,50000);assert.equal(finance.totals.thucNhan,120000+owed);
equalSql(`SELECT SUM(v.SoTienThucNhan) FROM V_ThuChiThucNhan v JOIN DatSan d ON d.MaDatSan=v.MaDatSan WHERE d.MaSan='${state.id}'`,finance.totals.thucNhan,'actual receipts minus confirmed refunds');
equalSql(`SELECT SUM(DoanhThu) FROM V_Phase6_Revenue WHERE MaSan='${state.id}'`,finance.totals.doanhThu,'revenue only returned booking');
assert.equal(finance.methods.find(m=>m.phuongThuc==='Tiền mặt').tienThu,100000+owed);assert.equal(finance.methods.find(m=>m.phuongThuc==='Chuyển khoản').tienHoan,50000);console.log('HTTP = SQL PASS: Cash/Transfer separated refunds');
const refunds=ok(await accountant.request(`/reports/refunds?from=${state.today}&to=${state.today}&booking=${canceled.maDatSan}&status=${encodeURIComponent('Đã hoàn')}&method=${encodeURIComponent('Chuyển khoản')}`));assert.equal(refunds.total,1);assert.equal(refunds.rows[0].soTienHoan,50000);assert.ok(refunds.rows[0].nguoiXuLy);console.log('HTTP = SQL PASS: refund filters/actor/time');
const dash=ok(await admin.request('/reports/dashboard'));equalSql(`SELECT COUNT(*) FROM DatSan WHERE NgayChoi='${state.today}'`,dash.usage.totals.soBooking,'dashboard today booking');equalSql(`SELECT ISNULL(SUM(SoTienThucNhan),0) FROM V_ThuChiThucNhan WHERE ThoiDiem>='${state.today}' AND ThoiDiem<DATEADD(day,1,CAST('${state.today}' AS date))`,dash.finance.totals.thucNhan,'dashboard net');assert.ok(dash.topServices.some(r=>r.maDV==='SV03'&&r.soDonVi>=6));
assert.equal(ok(await accountant.request(`/reports/finance?from=${future}&to=${future}&pitch=${state.id}`)).totals.thucNhan,0);assert.equal((await accountant.request(`/reports/finance?from=${future}&to=${state.today}`)).status,400);console.log('HTTP = SQL PASS: date and range filters');
for(const [path,text]of [['/Bao_cao.html','reportFilter'],['/Man_hinh_chinh_TK&PQ_HT.html','employeeForm'],['/Man_hinh_chinh.html','dashRevenue']]){const r=await admin.request(path);assert.equal(r.status,200);assert.ok(String(r.data).includes(text));}
console.log('PHASE7_E2E_PASS pitch='+state.id+' employee='+state.nv+' account='+state.tk+'; clean exact fixture with guarded SQL.');
