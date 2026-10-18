import assert from 'node:assert/strict';
export async function assertFixtureTarget(){
 assert.ok(['dev','test'].includes(process.env.SAN_BONG_TEST_MODE),'Set SAN_BONG_TEST_MODE=dev/test explicitly; fixture tests are forbidden on internal.');
 const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8080/api').replace(/\/$/,'');let cookie='';
 async function send(path,options={}){const r=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});for(const h of r.headers.getSetCookie())if(h.startsWith('JSESSIONID='))cookie=h.split(';')[0];return r;}
 let c=(await (await send('/auth/csrf')).json()).data;
 const r=await send('/auth/login',{method:'POST',headers:{[c.headerName]:c.token},body:new URLSearchParams({identifier:'admin',password:process.env.AUTH_TEST_PASSWORD||''})});
 assert.equal(r.status,200,'Cannot authenticate test preflight.');
 const check=await send('/admin/test-safety');assert.equal(check.status,200);const safety=await check.json();
 c=(await (await send('/auth/csrf')).json()).data;await send('/auth/logout',{method:'POST',headers:{[c.headerName]:c.token}});
 assert.equal(safety.fixtureTestsAllowed,true,'App/database are not classified dev/test.');
 assert.equal(safety.databaseName,process.env.SQLCMD_TEST_DATABASE||'QuanLySanBong','API database differs from expected test database.');
}
