/* One navigation policy for the four workspaces. Backend remains authoritative. */
window.SanBongNavigation = (() => {
    const routes = {
        VT01: [
            ['Trang chủ', 'khach-hang'],
            ['Đặt sân', 'dat-san', 'CN02_XEM'],
            ['Lịch đặt của tôi', 'lich-dat-cua-toi', 'CN02_XEM'],
            ['Lịch sử đặt sân', 'lich-su-dat-san', 'CN02_XEM'],
            ['Khuyến mãi', 'khuyen-mai'],
            ['Thông tin tài khoản', 'tai-khoan']
        ],
        VT02: [
            ['Bảng điều khiển sân', 'nhan-vien', 'CN02_XEM'],
            ['Lịch đá bóng', 'lich-san', 'CN02_XEM'],
            ['Quản lý sân', 'dieu-phoi-san', 'CN02_XEM'],
            ['Đặt sân tại quầy', 'dat-san-tai-quay', 'CN02_THEM'],
            ['Trạng thái sân', 'quan-ly-san', 'CN02_XEM'],
            ['Tiếp nhận phản hồi', 'phan-hoi', 'CN05_XEM']
        ],
        VT03: [
            ['Quản lý hóa đơn', 'hoa-don', 'CN04_XEM'],
            ['Hoàn tiền', 'hoan-tien', 'CN04_XEM'],
            ['Thanh toán VietQR', 'thanh-toan', 'CN04_XEM'],
            ['Đối soát & Báo cáo', 'bao-cao', 'CN06_XEM']
        ],
        VT04: [
            ['Tổng quan', 'quan-tri', 'CN06_XEM'],
            ['Lịch đá bóng', 'lich-san', 'CN02_XEM'],
            ['Quản lý lượt đặt', 'dieu-phoi-san', 'CN02_XEM'],
            ['Đặt sân tại quầy', 'dat-san-tai-quay', 'CN02_THEM'],
            ['Quản lý sân', 'quan-ly-san', 'CN02_XEM'],
            ['Cấu hình kinh doanh', 'cau-hinh', 'CN02_XEM'],
            ['Phản hồi', 'phan-hoi', 'CN05_XEM'],
            ['Quản lý hóa đơn', 'hoa-don', 'CN04_XEM'],
            ['Hoàn tiền', 'hoan-tien', 'CN04_XEM'],
            ['Thanh toán VietQR', 'thanh-toan', 'CN04_XEM'],
            ['Doanh thu', 'doanh-thu', 'CN06_XEM'],
            ['Báo cáo', 'bao-cao', 'CN06_XEM'],
            ['Nhân sự & Phân quyền', 'nhan-su-phan-quyen', 'CN07_XEM'],
            ['Nhật ký', 'nhan-su-phan-quyen#logs', 'CN08_XEM']
        ]
    };
    function items(account) {
        return (routes[account.maVaiTro] || []).filter(([, , permission]) => !permission || account.permissions.includes(permission));
    }
    function updateSelection(menu) {
        const links=[...menu.querySelectorAll('a')],path=decodeURIComponent(location.pathname.split('/').pop());
        const matchesHash=links.some(a=>a.getAttribute('href')===path+location.hash&&location.hash);
        for(const link of links){
            const href=link.getAttribute('href');if(href==='dang-nhap')continue;
            const selected=href.split('#')[0]===path&&(matchesHash?href===path+location.hash:!href.includes('#'));
            for(const cls of ['bg-brand-50','text-brand-700','font-bold'])link.classList.toggle(cls,selected);
            for(const cls of ['text-gray-600','hover:bg-gray-50'])link.classList.toggle(cls,!selected);
            if(selected)link.setAttribute('aria-current','page');else link.removeAttribute('aria-current');
        }
    }
    window.addEventListener('hashchange',()=>{const menu=document.querySelector('[data-role-menu]');if(menu)updateSelection(menu);});
    function shell(account) {
        const customer=account.maVaiTro==='VT01',main=document.querySelector('main');
        if(!main)return null;
        if(account.maVaiTro==='VT02'&&!document.querySelector('link[href="css/staff-dashboard.css"]')){const style=document.createElement('link');style.rel='stylesheet';style.href='css/staff-dashboard.css';document.head.append(style);}
        if(account.maVaiTro==='VT04'&&!document.querySelector('link[href="css/admin-workspace.css"]')){const style=document.createElement('link');style.rel='stylesheet';style.href='css/admin-workspace.css';document.head.append(style);}
        if(account.maVaiTro==='VT04'&&document.body.dataset.staffPage==='bookings'){const title=main.querySelector('.sw-heading h1');if(title)title.textContent='Quản lý lượt đặt';}
        const roleName=({VT01:'Khách hàng',VT02:'Nhân viên sân',VT03:'Kế toán',VT04:'Quản lý hệ thống'})[account.maVaiTro]||'';
        let oldRoot=main;while(oldRoot.parentElement!==document.body)oldRoot=oldRoot.parentElement;
        const actions=document.createElement('div');actions.className='fc-page-actions flex flex-wrap justify-end gap-2 mb-4';
        oldRoot.querySelectorAll('header button[id],header form[id]').forEach(control=>actions.append(control));
        if(actions.childElementCount)main.prepend(actions);
        // Keep the existing business DOM and its handlers, including any nested overlays.
        if(oldRoot!==main)oldRoot.querySelectorAll('[id$="Modal"],dialog,#toast').forEach(node=>{if(!main.contains(node))document.body.append(node);});
        main.remove();if(oldRoot!==main)oldRoot.remove();
        document.querySelectorAll('body>aside,body>nav').forEach(node=>node.remove());
        const footer=document.querySelector('body>footer');if(footer)main.append(footer);
        document.body.dataset.workspace=account.maVaiTro;
        document.body.classList.add('fc-authenticated');
        document.body.classList.toggle('fc-layout-top',customer);
        document.body.classList.toggle('fc-layout-side',!customer);
        const frame=document.createElement('div');frame.className='fc-workspace';
        const header=document.createElement(customer?'nav':'header');header.className=customer?'fc-topbar':'fc-workspace-header';
        header.setAttribute('aria-label',customer?'Điều hướng khách hàng':'Thông tin trang');
        const brand=document.createElement('a');brand.href=({VT01:'khach-hang',VT02:'nhan-vien',VT03:'hoa-don',VT04:'quan-tri'})[account.maVaiTro];brand.textContent='FC-UTE';brand.className='fc-brand';
        if(!customer){const logo=document.createElement('img');logo.src='assets/hcmute-logo.png';logo.alt='';logo.className='fc-brand-logo';brand.prepend(logo);}
        const name=document.createElement('span');name.dataset.accountName='';name.textContent=account.hoTen;name.className='fc-account-name';
        const trigger=document.createElement('button');trigger.type='button';trigger.dataset.mobileMenu='';trigger.className='md:hidden border rounded-lg px-3 py-2';trigger.textContent='☰ Menu';trigger.setAttribute('aria-label','Mở menu');trigger.setAttribute('aria-controls','fcPrimaryNavigation');trigger.setAttribute('aria-expanded','false');
        const host=document.createElement('div');host.id='fcPrimaryNavigation';
        if(customer){
            host.className='hidden md:flex fc-top-menu';header.append(brand,host,name,trigger);document.body.prepend(header);
        }else{
            const sidebar=document.createElement('aside');sidebar.className='hidden md:flex fc-sidebar';
            const identity=document.createElement('div');identity.className='fc-sidebar-identity';
            const role=document.createElement('p');role.textContent=roleName;identity.append(brand,role);
            const nav=document.createElement('nav');nav.setAttribute('aria-label','Chức năng '+roleName);nav.append(host);sidebar.append(identity,nav);document.body.prepend(sidebar);
            const title=document.createElement('span');title.className='fc-page-title';title.textContent=[...main.querySelectorAll('h1')].find(h=>['VT02','VT04'].includes(account.maVaiTro)?!h.closest('.cp-calendar-heading'):!h.closest('.sw-heading,.cp-calendar-heading'))?.textContent||document.title.split(' - ')[0];header.append(trigger,title,name);frame.append(header);
        }
        frame.append(main);document.body.append(frame);return {host,sidebar:!customer};
    }
    function render(account) {
        const layout=shell(account);if(!layout)return;
        const {host,sidebar}=layout;
        const menu = document.createElement('div');
        menu.dataset.roleMenu = account.maVaiTro;
        menu.className = sidebar ? 'space-y-2' : 'max-w-7xl mx-auto px-4 py-3 flex flex-wrap items-center gap-2';
        let previousGroup='';
        for (const [label, href] of items(account)) {
            if(account.maVaiTro==='VT04'){
                const group=href==='quan-tri'?'Tổng quan':href.startsWith('nhan-su-phan-quyen')?'Quản trị':['hoa-don','hoan-tien','thanh-toan','doanh-thu','bao-cao'].includes(href)?'Tài chính':'Vận hành sân';
                if(group!==previousGroup){const heading=document.createElement('p');heading.className='admin-menu-group';heading.textContent=group;menu.append(heading);previousGroup=group;}
            }
            const link = document.createElement('a');
            link.href = href; link.textContent = label;
            const icons={'khach-hang':'house','quan-tri':'chart-pie','nhan-vien':'table-columns','hoan-tien':'rotate-left','thanh-toan':'qrcode','hoa-don':'receipt','lich-san':'calendar-days','dieu-phoi-san':'calendar-check','dat-san-tai-quay':'calendar-plus','quan-ly-san':'futbol','bao-cao':'chart-line','doanh-thu':'chart-column','phan-hoi':'comments','nhan-su-phan-quyen':'users-gear','cau-hinh':'sliders','sao-luu':'database'};
            const icon=document.createElement('i');icon.className='fa-solid fa-'+(icons[href.split('#')[0]]||'circle-dot')+' fc-menu-icon';icon.setAttribute('aria-hidden','true');link.prepend(icon);
            const selected = decodeURIComponent(location.pathname.split('/').pop()) === href.split('#')[0];
            link.className = (sidebar ? 'block px-4 py-3 rounded-xl ' : 'inline-block px-3 py-2 rounded-lg ') +
                (selected ? 'bg-brand-50 text-brand-700 font-bold' : 'text-gray-600 hover:bg-gray-50');
            if (selected) link.setAttribute('aria-current', 'page');
            menu.append(link);
        }
        {
            const logout = document.createElement('a'); logout.href = 'dang-nhap'; logout.textContent = 'Đăng xuất';
            logout.className = 'px-3 py-2 text-red-600'; menu.append(logout);
        }
        host.replaceChildren(menu);
        updateSelection(menu);
        if (new URLSearchParams(location.search).has('accessDenied')) {
            const message = document.createElement('p'); message.role = 'alert'; message.className = 'p-4 text-red-700 bg-red-50';
            message.textContent = 'Trang vừa chọn không thuộc quyền của tài khoản. Chọn chức năng trong menu của bạn.';
            (document.querySelector('main') || host).prepend(message);
        }
    }
    return { items, render };
})();

/* Pending cancellation count is read from the server, never inferred from payments. */
(() => {
 let active=false,loading=false;
 async function update(){if(!active||loading||document.visibilityState!=='visible')return;loading=true;
  const links=[...document.querySelectorAll('[data-role-menu] a[href="hoan-tien"]')];
  try{const data=await SanBong.request('finance/cancellation-requests?status=PENDING&page=1');for(const link of links){link.querySelector('.fc-cancellation-count')?.remove();if(data.enabled&&data.pending>0){const badge=document.createElement('span');badge.className='fc-cancellation-count';badge.textContent=String(data.pending);badge.setAttribute('aria-label',data.pending+' yêu cầu hủy chờ duyệt');link.append(badge);}link.title=data.enabled?data.pending+' yêu cầu hủy chờ duyệt':'Yêu cầu hủy chưa được kích hoạt';}}
  catch{for(const link of links){link.querySelector('.fc-cancellation-count')?.remove();link.title='Chưa tải được số yêu cầu hủy; mở trang để tải lại.';}}
  finally{loading=false;}
 }
 document.addEventListener('sanbong:authenticated',e=>{active=['VT03','VT04'].includes(e.detail.maVaiTro)&&e.detail.permissions.includes('CN04_XEM');update();});
 document.addEventListener('sanbong:cancellation-updated',update);window.addEventListener('focus',update);setInterval(update,60000);
})();
