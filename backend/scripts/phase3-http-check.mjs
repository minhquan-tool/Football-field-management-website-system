import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { writeFileSync } from 'node:fs';
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');
const password=process.env.AUTH_TEST_PASSWORD,stateFile=process.env.PHASE3_TEST_STATE;
if(!password||!stateFile)throw new Error('Set AUTH_TEST_PASSWORD and PHASE3_TEST_STATE.');
const id='T3T'+randomUUID().replaceAll('-','').slice(0,6).toUpperCase();
const marker='Phase3 automated temporary test';
writeFileSync(stateFile,JSON.stringify({id,marker}));
let cookie='';
async function request(path,options={}) {
    const response=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});
    for(const value of response.headers.getSetCookie())if(value.startsWith('JSESSIONID='))cookie=value.split(';')[0];
    const text=await response.text();let data;try{data=JSON.parse(text)}catch{data=text}
    return {status:response.status,data};
}
async function write(path,method,body) {
    const csrf=(await request('/auth/csrf')).data.data;
    return request(path,{method,headers:{[csrf.headerName]:csrf.token,'Content-Type':'application/json'},body:JSON.stringify(body)});
}
assert.equal((await request('/pitches')).status,401);
const csrf=(await request('/auth/csrf')).data.data;
assert.equal((await request('/auth/login',{method:'POST',headers:{[csrf.headerName]:csrf.token},body:new URLSearchParams({identifier:'admin',password})})).status,200);
const initial=await request('/pitches');assert.equal(initial.status,200);assert.ok(initial.data.data.length>=6);
assert.equal((await request('/pitches/S01')).status,200);
assert.ok((await request('/pitches/S01/prices')).data.data.length>0);
const payload={maSan:id,tenSan:'Phase3 HTTP sân test',maLoaiSan:'LS01',trangThai:'Trống',moTa:marker};
assert.equal((await write('/pitches','POST',payload)).status,200);
assert.equal((await write('/pitches','POST',payload)).status,409);
payload.tenSan='Phase3 HTTP sân đã sửa';
assert.equal((await write('/pitches/'+id,'PUT',payload)).status,200);
assert.equal((await request('/pitches?q='+id+'&type=LS01&status='+encodeURIComponent('Trống'))).data.data.length,1);
assert.equal((await write('/pitches/'+id+'/status','PATCH',{trangThai:'Bảo trì'})).status,200);
assert.equal((await request('/pitches/'+id)).data.data.trangThai,'Bảo trì');
assert.equal((await write('/pitches/'+id+'/status','PATCH',{trangThai:'Trống'})).status,200);
assert.equal((await write('/pitches/'+id+'/status','PATCH',{trangThai:'Đang sử dụng'})).status,200);
assert.equal((await write('/pitches/'+id+'/status','PATCH',{trangThai:'Bảo trì'})).status,409);
assert.equal((await write('/pitches/'+id+'/status','PATCH',{trangThai:'UNKNOWN'})).status,400);
// A new read, rather than an optimistic local update, proves persistence for refresh.
const reloaded=await request('/pitches/'+id);assert.equal(reloaded.data.data.tenSan,payload.tenSan);
assert.equal(reloaded.data.data.trangThai,'Đang sử dụng');
const page=await request('/Quan_ly_san.html');assert.equal(page.status,200);
assert.ok(page.data.includes('js/pitches.js')&&page.data.includes('id="pitchRows"'));
assert.ok(!page.data.includes('Mã: S01')&&!page.data.includes('150.000đ'));
console.log('PITCH_HTTP_OK id='+id+'; committed create/edit/status, duplicate/invalid/conflict, list/detail/filter/prices, fresh read.');
console.log('Cleanup is required for this exact generated ID after SQL verification.');
