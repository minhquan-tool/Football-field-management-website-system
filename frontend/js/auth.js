/* Same-origin API: no fixed host, port, database credentials or client-side role trust. */
window.SanBong = (() => {
    const base = new URL('./', window.location.href);
    async function request(path, options = {}) {
        const method = (options.method || 'GET').toUpperCase();
        const headers = new Headers(options.headers || {});
        if (!['GET', 'HEAD'].includes(method)) {
            const csrfResponse = await fetch(new URL('auth/csrf', base), { credentials: 'same-origin' });
            const csrf = await csrfResponse.json();
            if (!csrfResponse.ok || !csrf.success) throw new Error('Không thể xác minh phiên làm việc.');
            headers.set(csrf.data.headerName, csrf.data.token);
        }
        const response = await fetch(new URL(path, base), { ...options, headers, credentials: 'same-origin' });
        let result;
        try { result = await response.json(); }
        catch { throw new Error('Server trả phản hồi không hợp lệ.'); }
        if (!response.ok || !result.success) {
            const error = new Error(result.message || 'Không thể hoàn tất thao tác.');
            error.status = response.status;
            error.fieldErrors = result.data?.fieldErrors || {};
            error.retryAfterSeconds = Number(response.headers.get('Retry-After') || result.data?.retryAfterSeconds || 0);
            throw error;
        }
        return result.data;
    }
    function fieldErrors(form, errors = {}, fields = {}) {
        form.querySelectorAll('[data-field-error]').forEach(node => node.remove());
        form.querySelectorAll('[aria-invalid="true"]').forEach(node => {
            node.removeAttribute('aria-invalid');
            const described=(node.getAttribute('aria-describedby')||'').split(' ').filter(id=>!id.endsWith('_error'));
            if(described.length)node.setAttribute('aria-describedby',described.join(' '));else node.removeAttribute('aria-describedby');
        });
        let first;
        for(const [key,message] of Object.entries(errors)) {
            const input=document.getElementById(fields[key] || key);
            if(!input || !form.contains(input))continue;
            const text=document.createElement('p');text.id=input.id+'_error';text.dataset.fieldError='';
            text.className='text-red-700 text-sm';text.textContent=message;
            input.after(text);input.setAttribute('aria-invalid','true');
            input.setAttribute('aria-describedby',((input.getAttribute('aria-describedby')||'')+' '+text.id).trim());
            first ||= input;
        }
        first?.focus();
    }
    function randomId() {
        const bytes = new Uint8Array(16); crypto.getRandomValues(bytes);
        bytes[6] = (bytes[6] & 15) | 64; bytes[8] = (bytes[8] & 63) | 128;
        const hex = [...bytes].map(b => b.toString(16).padStart(2, '0')).join('');
        return `${hex.slice(0,8)}-${hex.slice(8,12)}-${hex.slice(12,16)}-${hex.slice(16,20)}-${hex.slice(20)}`;
    }
    function home(role) {
        return ({ VT01: 'Man_hinh_chinh_KH.html', VT02: 'Man_hinh_chinh_NVKH.html',
            VT03: 'Man_hinh_chinh_NVKT.html', VT04: 'Man_hinh_chinh.html' })[role] || 'Dang_nhap.html';
    }
    // Only carry booking filters, never accept a redirect URL supplied by the browser.
    function bookingIntent(params = new URLSearchParams(location.search)) {
        const result = new URLSearchParams();
        const rules = {date:/^\d{4}-\d{2}-\d{2}$/,start:/^\d{2}:\d{2}(?::\d{2})?$/,end:/^\d{2}:\d{2}(?::\d{2})?$/,pitch:/^[\w-]{1,20}$/,type:/^[\w-]{1,20}$/};
        for(const [key,rule] of Object.entries(rules)){const value=params.get(key);if(value&&rule.test(value))result.set(key,value);}
        return result;
    }
    function loginDestination(role) {
        const intent=bookingIntent();
        return role==='VT01' && intent.has('date') && intent.has('start') && intent.has('end')
            ? 'Man_hinh_chinh_Dat_san_KH.html?'+intent : home(role);
    }
    async function logout(event) {
        event.preventDefault();
        try { await request('auth/logout', { method: 'POST' }); window.location.href = 'Dang_nhap.html'; }
        catch (error) { alert(error.message); }
    }
    document.addEventListener('DOMContentLoaded', async () => {
        const style = document.createElement('style');
        style.textContent = '[hidden]{display:none!important} @media(max-width:767px){body>aside{position:fixed;inset:0 auto 0 0;width:min(18rem,85vw);z-index:70!important;display:flex}body>nav .md\\:flex{position:absolute;top:5rem;left:0;right:0;background:white;max-height:70vh;overflow-y:auto;z-index:70}main{min-width:0}header{gap:.5rem}header h2{font-size:1rem}header>div{min-width:0}}';
        document.head.append(style);
        if (/\/(Dang_nhap|Dang_ky)\.html$/.test(location.pathname)) {
            const intent=bookingIntent();
            if(intent.toString())document.querySelectorAll('a[href="Dang_nhap.html"],a[href="Dang_ky.html"]').forEach(a=>a.search=intent.toString());
            return;
        }
        if (document.body.dataset.publicPage === 'true') return;
        try {
            const account = await request('auth/me');
            window.SanBongNavigation?.render(account);
        const sidebar=document.querySelector('aside');
        if(sidebar && !document.querySelector('[data-mobile-menu]')) {
            const trigger=document.createElement('button');trigger.type='button';trigger.dataset.mobileMenu='';trigger.className='md:hidden border rounded-lg px-3 py-2 text-sm';trigger.textContent='☰ Menu';trigger.setAttribute('aria-label','Mở menu');
            document.querySelector('header')?.prepend(trigger);
        }
        const backdrop=document.createElement('button');backdrop.type='button';backdrop.hidden=true;backdrop.setAttribute('aria-label','Đóng menu');backdrop.className='fixed inset-0 bg-black/40 md:hidden';backdrop.style.zIndex='60';document.body.append(backdrop);
        let activeMenu;
        function closeMenu(){if(activeMenu){activeMenu.classList.add('hidden');activeMenu=null;}backdrop.hidden=true;document.querySelectorAll('[data-mobile-menu]').forEach(b=>b.setAttribute('aria-expanded','false'));}
        backdrop.addEventListener('click',closeMenu);document.addEventListener('keydown',event=>{if(event.key==='Escape')closeMenu();});
        document.querySelectorAll('[data-mobile-menu]').forEach(button => button.addEventListener('click', () => {
            const menu = sidebar || document.querySelector('nav .md\\:flex');
            if(menu){const opening=menu.classList.contains('hidden');closeMenu();if(opening){activeMenu=menu;menu.classList.remove('hidden');button.setAttribute('aria-expanded','true');backdrop.hidden=!sidebar;}}
        }));

            document.querySelectorAll('[data-account-name]').forEach(el => el.textContent = account.hoTen);
            document.querySelectorAll('a').forEach(link => {
                if (link.textContent.includes('Đăng xuất')) link.addEventListener('click', logout);
            });
            // Unfinished business flows must not claim that demo data was persisted.
            const pending = ['toggleMaintenance', 'setPitchReady', 'deletePitch', 'checkinPitch',
                'confirmBooking', 'lookupCustomer', 'showActionToast', 'applyFilters', 'copyCode',
                'openPitchTypeModal'];
            document.querySelectorAll('button[onclick]').forEach(button => {
                if (document.body.dataset.pitchApi === 'true' || document.body.dataset.bookingApi === 'true') return;
                if (pending.some(action => button.getAttribute('onclick').startsWith(action + '('))) {
                    button.disabled = true;
                    button.title = 'Chức năng này chưa kết nối API; sẽ hoàn thiện ở phase tiếp theo.';
                }
            });
            ['bookingForm', 'counterBookingForm', 'cancelForm', 'ratingForm', 'pitchForm'].forEach(id => {
                const form = document.getElementById(id);
                if (form && form.dataset.apiReady !== 'true') {
                    form.addEventListener('submit', event => {
                        event.preventDefault(); event.stopImmediatePropagation();
                        alert('Chức năng này chưa kết nối API; chưa ghi dữ liệu vào hệ thống.');
                    }, true);
                    form.querySelectorAll('[type="submit"]').forEach(button => {
                        button.disabled = true; button.title = 'Chưa kết nối API.';
                    });
                }
            });
            document.dispatchEvent(new CustomEvent('sanbong:authenticated', { detail: account }));
        } catch (error) {
            if (error.status === 401) location.href = 'Dang_nhap.html?' + bookingIntent();
            else alert(error.message);
        }
    });
    return { request, home, randomId, bookingIntent, loginDestination, fieldErrors };
})();
