import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
const base = (process.env.AUTH_TEST_BASE_URL || 'http://127.0.0.1:8080/api').replace(/\/$/, '');
const password = process.env.AUTH_TEST_PASSWORD, id = process.env.OPERATIONS_TEST_ID;
if (!password || !/^P5H[0-9A-F]{6}$/.test(id || '')) throw new Error('Set AUTH_TEST_PASSWORD and generated OPERATIONS_TEST_ID, prepare the isolated fixture first.');
function client() {
    let cookie = '';
    async function request(path, options = {}) {
        const response = await fetch(base + path, { ...options, redirect: 'manual', headers: { Cookie: cookie, ...options.headers } });
        for (const c of response.headers.getSetCookie()) if (c.startsWith('JSESSIONID=')) cookie = c.split(';')[0];
        const text = await response.text(); let data; try { data = JSON.parse(text); } catch { data = text; } return { status: response.status, data };
    }
    async function write(path, method, body) {
        const csrf = (await request('/auth/csrf')).data.data;
        return request(path, { method, headers: { [csrf.headerName]: csrf.token, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    }
    async function login() {
        const csrf = (await request('/auth/csrf')).data.data;
        assert.equal((await request('/auth/login', { method: 'POST', headers: { [csrf.headerName]: csrf.token }, body: new URLSearchParams({ identifier: 'admin', password }) })).status, 200);
    }
    return { request, write, login };
}
const a = client(), b = client(), path = '/operations/bookings/' + id;
assert.equal((await a.request('/services')).status, 401); await a.login(); await b.login();
const catalog = (await a.request('/services')).data.data; assert.equal(catalog.find(s => s.maDV === 'DV01').donGia, 10000);
let results = await Promise.all([a.write(path + '/check-in', 'POST', {}), b.write(path + '/check-in', 'POST', {})]);
assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
assert.equal((await a.write('/pitches/' + id + '/status', 'PATCH', { trangThai: 'Trống' })).status, 409);
results = await Promise.all([a.write(path + '/services/DV01', 'POST', { soLuong: 2, donGia: 1 }), b.write(path + '/services/DV01', 'POST', { soLuong: 2 })]);
assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
assert.equal((await b.request(path)).data.data.booking.tongTien, 170000);
assert.equal((await a.write(path + '/services/DV01', 'PUT', { soLuong: 3 })).data.data.booking.tongTien, 180000);
assert.equal((await a.write(path + '/services/DV03', 'POST', { soLuong: 1 })).data.data.booking.tongTien, 210000);
assert.equal((await a.write(path + '/services/DV03', 'DELETE', {})).data.data.booking.tongTien, 180000);
assert.equal((await a.write(path + '/services/DV02', 'POST', { soLuong: 0 })).status, 400);
assert.equal((await a.write(path + '/check-out', 'POST', {})).status, 200);
const reloaded = (await b.request(path)).data.data;
assert.equal(reloaded.booking.trangThai, 'Đã sử dụng'); assert.equal(reloaded.booking.tongTien, 180000);
assert.equal(reloaded.services.length, 1); assert.equal(reloaded.services[0].donGia, 10000); assert.ok(reloaded.visit.thoiGianKetThuc);
assert.equal((await a.write(path + '/check-out', 'POST', {})).status, 409);
assert.equal((await a.write(path + '/services/DV01', 'PUT', { soLuong: 4 })).status, 409);
assert.equal((await a.request('/Quan_ly_lich_dat_san.html')).status, 200);
await a.write('/auth/logout', 'POST', {}); await b.write('/auth/logout', 'POST', {});
console.log('OPERATIONS_HTTP_OK id=' + id + '; check-in/service race, snapshots/trigger, checkout/fresh read PASS. No invoice/payment/refund test performed.');
