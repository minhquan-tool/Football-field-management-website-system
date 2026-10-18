// Read-only runtime policy probe; never enables fixture mode or calls business APIs.
import assert from 'node:assert/strict';
assert.equal(process.env.APP_ENV,'internal');
const base=process.env.AUTH_TEST_BASE_URL;
assert.ok(base && process.env.AUTH_TEST_PASSWORD && process.env.SQLCMD_TEST_DATABASE);
let cookie='';
async function request(path,options={}) {
    const r=await fetch(base+path,{...options,redirect:'manual',headers:{Cookie:cookie,...options.headers}});
    for(const h of r.headers.getSetCookie())if(h.startsWith('JSESSIONID='))cookie=h.split(';')[0];
    assert.equal(r.status,200,'Runtime policy probe HTTP failed');return r.json();
}
let csrf=(await request('/auth/csrf')).data;
await request('/auth/login',{method:'POST',headers:{[csrf.headerName]:csrf.token},body:new URLSearchParams({identifier:'admin',password:process.env.AUTH_TEST_PASSWORD})});
const policy=await request('/admin/test-safety');
assert.equal(policy.databaseName,process.env.SQLCMD_TEST_DATABASE);
assert.equal(policy.fixtureTestsAllowed,false);
csrf=(await request('/auth/csrf')).data;
await request('/auth/logout',{method:'POST',headers:{[csrf.headerName]:csrf.token}});
console.log('INTERNAL_RUNTIME_GUARD_PASS: authenticated read-only policy reports fixtures disabled.');
