import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';

const base = (process.env.AUTH_TEST_BASE_URL || 'http://127.0.0.1:8080/api').replace(/\/$/, '');
const password = process.env.AUTH_TEST_PASSWORD;
if (!password) throw new Error('Set AUTH_TEST_PASSWORD for the existing demo admin account.');
let cookie = '';
async function request(path, options = {}) {
    const response = await fetch(base + path, {
        ...options, redirect: 'manual', headers: { Cookie: cookie, ...options.headers }
    });
    for (const value of response.headers.getSetCookie()) {
        if (value.startsWith('JSESSIONID=')) cookie = value.split(';')[0];
    }
    const text = await response.text();
    let data; try { data = JSON.parse(text); } catch { data = text; }
    return { response, data };
}

assert.equal((await request('/Dang_nhap.html')).response.status, 200);
assert.equal((await request('/auth/me')).response.status, 401);
assert.equal((await request('/auth/login', { method: 'POST', body: new URLSearchParams({ identifier: 'admin', password }) })).response.status, 403);
const csrf = (await request('/auth/csrf')).data.data;
const before = cookie;
const login = await request('/auth/login', {
    method: 'POST', headers: { [csrf.headerName]: csrf.token },
    body: new URLSearchParams({ identifier: 'admin', password })
});
assert.equal(login.response.status, 200);
assert.equal(login.data.data.maVaiTro, 'VT04');
assert.notEqual(cookie, before, 'Session ID must rotate on authentication');
assert.ok(login.response.headers.getSetCookie().some(value => /HttpOnly/i.test(value) && /SameSite=Lax/i.test(value)));
assert.equal((await request('/auth/me')).response.status, 200);
const accounts = await request('/security/accounts');
assert.equal(accounts.response.status, 200);
assert.ok(accounts.data.data.length >= 4);
assert.ok(!/matkhau/i.test(JSON.stringify(accounts.data)));
assert.equal((await request('/Man_hinh_chinh_TK&PQ_HT.html')).response.status, 200);
const logoutCsrf = (await request('/auth/csrf')).data.data;
assert.equal((await request('/auth/logout', { method: 'POST', headers: { [logoutCsrf.headerName]: logoutCsrf.token } })).response.status, 200);
assert.equal((await request('/auth/me')).response.status, 401);
console.log('HTTP_AUTH_OK: CSRF, login, rotated HttpOnly session, real accounts, permissions page, logout.');
