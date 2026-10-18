import {assertFixtureTarget} from './test-safety.mjs';
await assertFixtureTarget();
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { writeFileSync } from 'node:fs';
const base = (process.env.AUTH_TEST_BASE_URL || 'http://127.0.0.1:8080/api').replace(/\/$/, '');
const password = process.env.AUTH_TEST_PASSWORD, stateFile = process.env.PHASE4_TEST_STATE;
if (!password || !stateFile) throw new Error('Set AUTH_TEST_PASSWORD and PHASE4_TEST_STATE.');
const id = 'P4H' + randomUUID().replaceAll('-', '').slice(0, 6).toUpperCase();
const marker = 'Phase4 HTTP automated temporary test';
const state = { id, marker, bookings: [] };
const save = () => writeFileSync(stateFile, JSON.stringify(state)); save();
function client() {
    let cookie = '';
    async function request(path, options = {}) {
        const res = await fetch(base + path, { ...options, redirect: 'manual', headers: { Cookie: cookie, ...options.headers } });
        for (const value of res.headers.getSetCookie()) if (value.startsWith('JSESSIONID=')) cookie = value.split(';')[0];
        const text = await res.text(); let data; try { data = JSON.parse(text); } catch { data = text; }
        return { status: res.status, data };
    }
    async function write(path, method, body) {
        const c = (await request('/auth/csrf')).data.data;
        return request(path, { method, headers: { [c.headerName]: c.token, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    }
    async function login() {
        const c = (await request('/auth/csrf')).data.data;
        assert.equal((await request('/auth/login', { method: 'POST', headers: { [c.headerName]: c.token }, body: new URLSearchParams({ identifier: 'admin', password }) })).status, 200);
    }
    return { request, write, login };
}
const a = client(), b = client();
assert.equal((await a.request('/bookings?date=2026-10-05')).status, 401);
await a.login(); await b.login();
const options = (await a.request('/booking-options')).data.data;
// Choose a future Monday based on server-local date, not client timezone.
const day = new Date(options.today + 'T12:00:00Z'); day.setUTCDate(day.getUTCDate() + 14);
while (day.getUTCDay() !== 1) day.setUTCDate(day.getUTCDate() + 1);
state.date = day.toISOString().slice(0, 10); save();
assert.equal((await a.write('/pitches', 'POST', { maSan: id, tenSan: 'Phase4 HTTP sân test', maLoaiSan: 'LS01', trangThai: 'Trống', moTa: marker })).status, 200);
const available = () => a.request('/availability?' + new URLSearchParams({ date: state.date, slot: 'KG03', type: 'LS01' }));
assert.ok((await available()).data.data.some(r => r.maSan === id));
const payload = { maSan: id, maKhungGio: 'KG03', ngayChoi: state.date, maKH: 'KH01', ghiChu: marker, tongTien: 1, trangThai: 'Đã xác nhận' };
const created = await a.write('/bookings', 'POST', payload); assert.equal(created.status, 200);
let booking = created.data.data; state.bookings.push(booking.maDatSan); save();
assert.equal(booking.trangThai, 'Chờ xác nhận'); assert.equal(booking.tongTien, 195000);
assert.ok(!(await available()).data.data.some(r => r.maSan === id));
assert.equal((await a.write('/bookings', 'POST', payload)).status, 409);
assert.equal((await a.write(`/pitches/${id}/status`, 'PATCH', { trangThai: 'Bảo trì' })).status, 409);
assert.equal((await a.write(`/bookings/${booking.maDatSan}/confirm`, 'POST', {})).status, 200);
assert.equal((await b.request('/bookings/' + booking.maDatSan)).data.data.trangThai, 'Đã xác nhận');
const calendar = () => a.request('/bookings?' + new URLSearchParams({ date: state.date, pitch: id }));
assert.ok((await calendar()).data.data.some(r => r.maDatSan === booking.maDatSan));
assert.equal((await a.write(`/bookings/${booking.maDatSan}/cancel`, 'POST', { lyDo: marker })).status, 200);
assert.equal((await b.request('/bookings/' + booking.maDatSan)).data.data.trangThai, 'Đã hủy');
assert.ok((await available()).data.data.some(r => r.maSan === id));
const replacement = await a.write('/bookings', 'POST', payload); assert.equal(replacement.status, 200);
booking = replacement.data.data; state.bookings.push(booking.maDatSan); save();
assert.equal((await a.write(`/bookings/${booking.maDatSan}/cancel`, 'POST', { lyDo: marker })).status, 200);
const racing = { ...payload, maKhungGio: 'KG02' };
const race = await Promise.all([a.write('/bookings', 'POST', racing), b.write('/bookings', 'POST', racing)]);
assert.deepEqual(race.map(r => r.status).sort(), [200, 409]);
booking = race.find(r => r.status === 200).data.data; state.bookings.push(booking.maDatSan); save();
assert.equal((await a.write(`/bookings/${booking.maDatSan}/cancel`, 'POST', { lyDo: marker })).status, 200);
for (const page of ['/Dat_san_tai_quay.html', '/Quan_ly_lich_dat_san.html']) {
    const result = await a.request(page); assert.equal(result.status, 200);
    assert.ok(result.data.includes('js/bookings.js')); assert.ok(!result.data.includes('setTimeout') && !result.data.includes('230.000đ'));
}
assert.equal((await calendar()).data.data.length, 3);
for (const row of (await calendar()).data.data) assert.equal(row.trangThai, 'Đã hủy');
await a.write('/auth/logout', 'POST', {}); await b.write('/auth/logout', 'POST', {});
console.log(`BOOKING_HTTP_OK pitch=${id} date=${state.date}; create/price/duplicate/confirm/cancel/fresh read/rebook/race/maintenance guard PASS.`);
console.log('Run exact-ID SQL verification and cleanup; browser UI verification remains separate.');
