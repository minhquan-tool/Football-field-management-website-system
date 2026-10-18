// Playwright CLI run-code. Existing demo logins only; GETs and rejected invalid writes.
// No fixture, registration, booking, payment, refund, password reset or cleanup.
async page => {
    const base='http://127.0.0.1:8084/api/';
    const check=(ok,message)=>{if(!ok)throw new Error(message);};
    const errors=[];page.on('pageerror',e=>errors.push(e.message));
    const apiFailures=[];page.on('response',response=>{const url=response.url();if(url.startsWith(base)&&response.request().method()==='GET'&&response.status()>=400&&!/favicon/.test(url))apiFailures.push(response.status()+' '+url);});
    const results=[];
    async function csrf(){const response=await page.request.get(base+'auth/csrf');check(response.ok(),'CSRF unavailable');return (await response.json()).data;}
    async function post(path,body,method='POST'){const token=await csrf();return page.request.fetch(base+path,{method,headers:{[token.headerName]:token.token},data:body});}
    for(const [user,role,home] of [['khachhang','VT01','Man_hinh_chinh_KH.html'],['nvsan','VT02','Man_hinh_chinh_NVKH.html'],['ketoan','VT03','Man_hinh_chinh_NVKT.html'],['admin','VT04','Man_hinh_chinh.html']]){
        await page.goto('about:blank');await page.context().clearCookies();
        const token=await csrf();const login=await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:user,password:'123456'}});
        check(login.status()===200,'Demo login unavailable for '+role+' HTTP '+login.status());
        await page.setViewportSize({width:1440,height:1000});await page.goto(base+home,{waitUntil:'domcontentloaded'});
        await page.locator('[data-role-menu="'+role+'"]').waitFor();
        const links=await page.locator('[data-role-menu] a').evaluateAll(nodes=>nodes.filter(n=>n.textContent!=='Đăng xuất').map(n=>({text:n.textContent,href:n.getAttribute('href')})));
        check(links.length>=2,'Empty role menu '+role);
        for(const link of links){
            const url=new URL(link.href,base);const response=await page.request.get(url.href);
            check(response.status()===200,role+' broken menu '+link.text);
            check(decodeURIComponent(new URL(response.url()).pathname)===decodeURIComponent(url.pathname),role+' menu redirected to another workspace: '+link.text);
            await page.goto(url.href,{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="'+role+'"]').waitFor();
            if(await page.locator('#careStatus').count())await page.waitForFunction(()=>document.body.dataset.careReady==='true');
            if(await page.locator('#configurationRows').count())await page.locator('#configurationRows section').first().waitFor();
            if(await page.locator('#reportStatus').count()){
                await page.waitForFunction(()=>document.getElementById('reportStatus').textContent==='Đã tải báo cáo.');
                check(await page.getByRole('button',{name:'Xuất CSV',exact:true}).isEnabled(),'CSV disabled after successful report load');
                const [download]=await Promise.all([page.waitForEvent('download'),page.getByRole('button',{name:'Xuất CSV',exact:true}).click()]);await download.saveAs('exports/role-'+role+'-report.csv');
                await page.emulateMedia({media:'print'});check(await page.locator('aside').isHidden(),'Report print includes workspace menu');
                check(await page.locator('main').evaluate(node=>getComputedStyle(node).overflowY)==='visible','Report print would clip long tables');await page.emulateMedia({media:null});
                if(['VT03','VT04'].includes(role)){
                    await page.locator('#reportType').selectOption('reconciliation');await page.waitForFunction(()=>document.getElementById('reportStatus').textContent==='Đã tải báo cáo.');
                    check((await page.locator('#reportHead').textContent()).includes('Lệch thu hóa đơn'),'Reconciliation report not displayed');
                    await page.locator('#reportType').selectOption('refunds');await page.waitForFunction(()=>document.getElementById('reportStatus').textContent==='Đã tải báo cáo.');
                    check(await page.getByRole('button',{name:'Xuất CSV trang đang xem',exact:true}).isEnabled(),'Refund export must state its page scope');
                }
            }
        }
        if(role==='VT01'){
            const history=await page.request.get(base+'customer/history');check(history.status()===200,'Customer history unavailable');
            const profile=await page.request.get(base+'customer/profile');check(profile.status()===200,'Customer profile unavailable');
            check((await post('customer/profile',{hoTen:'Test',soDienThoai:'bad',email:'',diaChi:''},'PUT')).status()===400,'Invalid profile must not persist');
            check((await post('customer/bookings/NO_SUCH_ID/review',{diem:{TC1:6},noiDung:'invalid'})).status()===400,'Out-of-range rating must be rejected');
            check((await post('feedback',{loaiPhanHoi:'Góp ý',noiDung:''})).status()===400,'Empty feedback must be rejected');
            await page.goto(base+encodeURI('Man_hinh_LS&ĐG_KH.html'),{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT01"]').waitFor();
            await page.waitForFunction(()=>document.body.dataset.careReady==='true');
            await page.screenshot({path:'exports/role-customer-history.png',fullPage:true});
        }
        if(role==='VT02'){
            check(!links.some(l=>/NVKT|TK&PQ|Cau_hinh/.test(l.href)),'Staff menu exposes another workspace');
            check((await post('pitches',{maSan:'NO_WRITE',tenSan:'Test',maLoaiSan:'LS01',trangThai:'Trống'})).status()===403,'Staff must not create catalog pitches');
            await page.goto(base+'Quan_ly_lich_dat_san.html',{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT02"]').waitFor();await page.waitForFunction(()=>/^\d+$/.test(document.getElementById('bookingCount').textContent));await page.screenshot({path:'exports/role-staff-calendar.png',fullPage:true});
        }
        if(role==='VT03'){
            check(links.every(l=>['Man_hinh_chinh_NVKT.html','Bao_cao.html'].includes(l.href)),'Accountant menu crosses roles');
            check((await page.request.get(base+'customer/profile')).status()===403,'Accountant must not read customer self-service');
            await page.goto(base+home,{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT03"]').waitFor();await page.locator('#financeTransactions tr').first().waitFor();await page.screenshot({path:'exports/role-accountant.png',fullPage:true});
            check(await page.locator('#financeTransactionDate').isEnabled(),'Ledger date filter disabled');
            check((await page.locator('main').textContent()).includes('Tổng tiền đã thu (toàn bộ)'),'Ledger labels confuse receipts with revenue');
        }
        if(role==='VT04'){
            const configuration=await page.request.get(base+'configuration');check(configuration.status()===200,'Configuration read unavailable');
            check((await post('configuration/hourly',{id:'SANG',donGia:-1},'PUT')).status()===400,'Negative price must be rejected before writes');
            await page.goto(base+'Cau_hinh_san.html',{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT04"]').waitFor();await page.locator('#configurationRows section').first().waitFor();
            await page.locator('#configurationRows button').first().click();check((await page.locator('#configurationFields input[name=id]').inputValue()).length>0,'Edit configuration did not fill selected record');await page.screenshot({path:'exports/role-admin-configuration.png',fullPage:true});
        }
        const forbidden=role==='VT03'?'Quan_ly_lich_dat_san.html':role==='VT01'?'Man_hinh_chinh_NVKT.html':role==='VT02'?'Man_hinh_chinh_NVKT.html':'Man_hinh_chinh_KH.html';
        await page.goto(base+forbidden,{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="'+role+'"]').waitFor();
        check(page.url().includes(home+'?accessDenied=1'),'Denied HTML must return to own workspace '+role);
        check(await page.getByRole('alert').count()===1,'Missing access-denied explanation '+role);
        await page.setViewportSize({width:390,height:844});
        check(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth+1),'Horizontal overflow on mobile '+role);
        if(await page.locator('[data-mobile-menu]').count()){
            await page.locator('[data-mobile-menu]').first().click();
            check(await page.locator('[data-role-menu]').isVisible(),'Mobile menu did not open '+role);
            check(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth+1),'Open mobile menu overflows '+role);
            await page.screenshot({path:'exports/role-'+role+'-mobile.png',fullPage:true});
            await page.locator('[data-role-menu] a').first().click();await page.locator('[data-role-menu="'+role+'"]').waitFor({state:'attached'});
            check(new URL(page.url()).pathname.endsWith(home),'Mobile menu link did not navigate to own home '+role);
        }
        results.push({role,menuLinks:links.length,invalidWritesRejected:true});
        await page.goto('about:blank');await post('auth/logout',{});
    }
    check(errors.length===0,'Browser errors: '+errors.join('; '));
    check(apiFailures.length===0,'Failed page API loads: '+apiFailures.join('; '));
    return JSON.stringify({status:'PASS',roles:results,pageErrors:errors,apiFailures,fixtures:0,businessWrites:0,writeCoverage:'Successful writes covered by rollback integration tests.'});
}
