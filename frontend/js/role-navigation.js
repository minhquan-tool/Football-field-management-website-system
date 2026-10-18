/* One navigation policy for the four workspaces. Backend remains authoritative. */
window.SanBongNavigation = (() => {
    const routes = {
        VT01: [
            ['Trang chủ', 'Man_hinh_chinh_KH.html'],
            ['Đặt sân', 'Man_hinh_chinh_Dat_san_KH.html', 'CN02_XEM'],
            ['Lịch đặt / Hóa đơn', 'Quan_ly_lich_dat_san.html', 'CN02_XEM'],
            ['Lịch sử / Đánh giá', 'Man_hinh_LS&ĐG_KH.html', 'CN02_XEM'],
            ['Khuyến mãi', 'Man_hinh_Khuyen_mai_KH.html'],
            ['Thông tin / Phản hồi', 'Tai_khoan_KH.html']
        ],
        VT02: [
            ['Bảng điều khiển sân', 'Man_hinh_chinh_NVKH.html', 'CN02_XEM'],
            ['Lịch đá bóng', 'Lich_da_bong.html', 'CN02_XEM'],
            ['Lịch / Nhận trả sân / Dịch vụ', 'Quan_ly_lich_dat_san.html', 'CN02_XEM'],
            ['Đặt sân tại quầy', 'Dat_san_tai_quay.html', 'CN02_THEM'],
            ['Trạng thái sân', 'Quan_ly_san.html', 'CN02_XEM'],
            ['Tiếp nhận phản hồi', 'Phan_hoi.html', 'CN05_XEM'],
            ['Báo cáo sử dụng sân', 'Bao_cao.html', 'CN06_XEM']
        ],
        VT03: [
            ['Giao dịch / Hóa đơn / Hoàn tiền', 'Man_hinh_chinh_NVKT.html', 'CN04_XEM'],
            ['Doanh thu / Đối soát / Báo cáo', 'Bao_cao.html', 'CN06_XEM']
        ],
        VT04: [
            ['Tổng quan', 'Man_hinh_chinh.html', 'CN06_XEM'],
            ['Lịch đá bóng', 'Lich_da_bong.html', 'CN02_XEM'],
            ['Lịch / Nhận trả sân / Dịch vụ', 'Quan_ly_lich_dat_san.html', 'CN02_XEM'],
            ['Đặt sân tại quầy', 'Dat_san_tai_quay.html', 'CN02_THEM'],
            ['Quản lý sân', 'Quan_ly_san.html', 'CN02_XEM'],
            ['Giao dịch / Hoàn tiền', 'Man_hinh_chinh_NVKT.html', 'CN04_XEM'],
            ['Nhân viên / Tài khoản / Phân quyền', 'Man_hinh_chinh_TK&PQ_HT.html', 'CN07_XEM'],
            ['Danh mục / Giá / Khuyến mãi', 'Cau_hinh_san.html', 'CN02_XEM'],
            ['Phản hồi', 'Phan_hoi.html', 'CN05_XEM'],
            ['Báo cáo', 'Bao_cao.html', 'CN06_XEM'],
            ['Nhật ký', 'Man_hinh_chinh_TK&PQ_HT.html#logs', 'CN08_XEM'],
            ['Sao lưu / Phục hồi', 'Sao_luu.html', 'CN08_XEM']
        ]
    };
    function items(account) {
        return (routes[account.maVaiTro] || []).filter(([, , permission]) => !permission || account.permissions.includes(permission));
    }
    function updateSelection(menu) {
        const links=[...menu.querySelectorAll('a')],path=decodeURIComponent(location.pathname.split('/').pop());
        const matchesHash=links.some(a=>a.getAttribute('href')===path+location.hash&&location.hash);
        for(const link of links){
            const href=link.getAttribute('href');if(href==='Dang_nhap.html')continue;
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
        const brand=document.createElement('a');brand.href=({VT01:'Man_hinh_chinh_KH.html',VT02:'Man_hinh_chinh_NVKH.html',VT03:'Man_hinh_chinh_NVKT.html',VT04:'Man_hinh_chinh.html'})[account.maVaiTro];brand.textContent='FC-UTE';brand.className='fc-brand';
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
            const title=document.createElement('span');title.className='fc-page-title';title.textContent=main.querySelector('h1')?.textContent||document.title.split(' - ')[0];header.append(trigger,title,name);frame.append(header);
        }
        frame.append(main);document.body.append(frame);return {host,sidebar:!customer};
    }
    function render(account) {
        const layout=shell(account);if(!layout)return;
        const {host,sidebar}=layout;
        const menu = document.createElement('div');
        menu.dataset.roleMenu = account.maVaiTro;
        menu.className = sidebar ? 'space-y-2' : 'max-w-7xl mx-auto px-4 py-3 flex flex-wrap items-center gap-2';
        for (const [label, href] of items(account)) {
            const link = document.createElement('a');
            link.href = href; link.textContent = label;
            const icons={'Man_hinh_chinh_KH.html':'house','Man_hinh_chinh.html':'chart-pie','Man_hinh_chinh_NVKH.html':'table-columns','Man_hinh_chinh_NVKT.html':'receipt','Lich_da_bong.html':'calendar-days','Quan_ly_lich_dat_san.html':'calendar-check','Dat_san_tai_quay.html':'calendar-plus','Quan_ly_san.html':'futbol','Bao_cao.html':'chart-line','Phan_hoi.html':'comments','Man_hinh_chinh_TK&PQ_HT.html':'users-gear','Cau_hinh_san.html':'sliders','Sao_luu.html':'database'};
            const icon=document.createElement('i');icon.className='fa-solid fa-'+(icons[href.split('#')[0]]||'circle-dot')+' fc-menu-icon';icon.setAttribute('aria-hidden','true');link.prepend(icon);
            const selected = decodeURIComponent(location.pathname.split('/').pop()) === href.split('#')[0];
            link.className = (sidebar ? 'block px-4 py-3 rounded-xl ' : 'inline-block px-3 py-2 rounded-lg ') +
                (selected ? 'bg-brand-50 text-brand-700 font-bold' : 'text-gray-600 hover:bg-gray-50');
            if (selected) link.setAttribute('aria-current', 'page');
            menu.append(link);
        }
        {
            const logout = document.createElement('a'); logout.href = 'Dang_nhap.html'; logout.textContent = 'Đăng xuất';
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
