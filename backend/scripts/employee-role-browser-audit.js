async page=>{
 const role='VT02',base='http://127.0.0.1:8084/api/';
 const [user,home]=({VT02:['nvsan','Man_hinh_chinh_NVKH.html'],VT03:['ketoan','Man_hinh_chinh_NVKT.html'],VT04:['admin','Man_hinh_chinh.html']})[role];
 const check=(v,m)=>{if(!v)throw Error(m);};const errors=[],failedGets=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith(base)&&r.request().method()==='GET'&&r.status()>=400&&!/favicon/.test(r.url()))failedGets.push(r.status()+' '+r.url());});
 await page.goto('about:blank');await page.context().clearCookies();await page.setViewportSize({width:1440,height:1000});
 const token=(await(await page.request.get(base+'auth/csrf')).json()).data;
 check((await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:user,password:'123456'}})).ok(),'Login '+role);
 await page.goto(base+home,{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu]').waitFor();
 const links=await page.locator('[data-role-menu] a').evaluateAll(nodes=>nodes.filter(n=>n.textContent!=='Đăng xuất').map(n=>({name:n.textContent,href:n.getAttribute('href')})));
 for(const link of links){
  await page.setViewportSize({width:1440,height:1000});await page.locator('[data-role-menu]').getByRole('link',{name:link.name,exact:true}).click();await page.locator('[data-role-menu="'+role+'"]').waitFor();
  check(decodeURIComponent(new URL(page.url()).pathname)===decodeURIComponent(new URL(link.href,base).pathname),'Wrong workspace '+link.href);
  check(await page.locator('aside [data-role-menu]').count()===1,'Sidebar lost '+link.href);
  await page.waitForFunction(href=>document.querySelector('[data-role-menu] [aria-current="page"]')?.getAttribute('href')===href,link.href);
  if(await page.locator('#careStatus').count())await page.waitForFunction(()=>document.body.dataset.careReady==='true');
  if(await page.locator('#pitchFeedback').count())await page.waitForFunction(()=>/^\d+$/.test(document.getElementById('statTotalPitch').textContent));
  if(await page.locator('#reportStatus').count())await page.waitForFunction(()=>document.getElementById('reportStatus').textContent==='Đã tải báo cáo.');
  if(await page.locator('#configurationRows').count())await page.locator('#configurationRows section').first().waitFor();
  if(await page.locator('#financeNet').count())await page.waitForFunction(()=>document.getElementById('financeNet').textContent.includes('Thực nhận'));
  for(const width of [1024,768,390]){await page.setViewportSize({width,height:920});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Overflow '+link.href+' '+width);}
  await page.locator('[data-mobile-menu]').click();check(await page.locator('[data-role-menu]').isVisible(),'Mobile menu failed '+link.href);await page.keyboard.press('Escape');
 }
 await page.goto(base+home,{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu]').waitFor({state:'attached'});await page.screenshot({path:'exports/employee-audit-'+role+'-mobile.png',fullPage:true});
 await page.locator('[data-mobile-menu]').click();await page.getByRole('link',{name:'Đăng xuất',exact:true}).click();await page.waitForURL(/Dang_nhap\.html/);
 check(!errors.length,errors.join('\n'));check(!failedGets.length,failedGets.join('\n'));
 return {status:'PASS',role,menuPages:links.length,widths:[1440,1024,768,390],sidebarConsistent:true,mobileAndLogout:true,pageErrors:errors,failedGets,businessWrites:0};
}
