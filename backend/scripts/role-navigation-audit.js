async page=>{
 const base='http://127.0.0.1:8084/api/';const check=(v,m)=>{if(!v)throw Error(m);};const errors=[],failures=[],results=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith(base)&&r.request().method()==='GET'&&r.status()>=400&&!/favicon/.test(r.url()))failures.push(r.status()+' '+r.url());});
 for(const [user,role,home]of [['khachhang','VT01','Man_hinh_chinh_KH.html'],['nvsan','VT02','Man_hinh_chinh_NVKH.html'],['ketoan','VT03','Man_hinh_chinh_NVKT.html'],['admin','VT04','Man_hinh_chinh.html']]){
  await page.goto('about:blank');await page.context().clearCookies();
  const token=(await(await page.request.get(base+'auth/csrf')).json()).data;
  const login=await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:user,password:'123456'}});check(login.ok(),'Login '+role);
  await page.setViewportSize({width:1440,height:1000});await page.goto(base+home);await page.locator('[data-role-menu]').waitFor();
  const links=await page.locator('[data-role-menu] a').evaluateAll(nodes=>nodes.filter(n=>n.textContent!=='Đăng xuất').map(n=>({label:n.textContent,href:n.getAttribute('href')})));
  for(const link of links){
   await page.locator('[data-role-menu]').getByRole('link',{name:link.label,exact:true}).click();
   await page.locator('[data-role-menu="'+role+'"]').waitFor();
   check(decodeURIComponent(new URL(page.url()).pathname)===decodeURIComponent(new URL(link.href,base).pathname),'Wrong workspace '+role+' '+link.href);
   check(await page.locator('[data-role-menu] [aria-current="page"]').count()===1,'Wrong active menu '+role+' '+link.href);
   await page.waitForFunction(href=>document.querySelector('[data-role-menu] [aria-current="page"]')?.getAttribute('href')===href,link.href);
   if(await page.locator('#pitchFeedback').count()){
    check(await page.locator('#addPitchButton').count()===1,'Pitch header action lost');
    await page.waitForFunction(()=>/^\d+$/.test(document.getElementById('statTotalPitch').textContent));
    if(role==='VT04'){check(await page.locator('#addPitchButton').isEnabled(),'Admin cannot open create pitch');await page.locator('#addPitchButton').click();await page.locator('#pitchModal').waitFor();await page.locator('#pitchModal button').filter({hasText:'Hủy'}).click();}
    else check(await page.locator('#addPitchButton').isHidden(),'Staff create-pitch action exposed');
   }
   for(const width of [1440,1024,768,390]){
    await page.setViewportSize({width,height:920});
    check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Overflow '+role+' '+link.href+' '+width);
    check(await page.locator('main').count()===1,'Content lost '+link.href);
    if(width>=768){
     const layout=await page.locator('[data-role-menu]').evaluate(el=>({sidebar:Boolean(el.closest('aside')),ys:[...el.querySelectorAll('a')].map(a=>Math.round(a.getBoundingClientRect().y))}));
     check(layout.sidebar===(role!=='VT01'),'Orientation changed '+role+' '+link.href);
     if(role==='VT01')check(new Set(layout.ys).size===1,'Customer menu wraps/turns vertical '+link.href+' '+width);
    }else{
     const trigger=page.locator('[data-mobile-menu]');check(await trigger.count()===1,'Missing/duplicate trigger '+link.href);
     await trigger.click();check(await page.locator('[data-role-menu]').isVisible(),'Mobile menu did not open '+link.href);
     await page.keyboard.press('Escape');check(await trigger.getAttribute('aria-expanded')==='false','Mobile menu did not close '+link.href);
    }
   }
   await page.setViewportSize({width:1440,height:1000});results.push({role,href:link.href});
  }
  await page.goto(base+home);await page.locator('[data-role-menu]').waitFor();await page.screenshot({path:'exports/navigation-'+role+'-desktop.png',fullPage:true});
  await page.setViewportSize({width:390,height:844});await page.locator('[data-mobile-menu]').click();await page.screenshot({path:'exports/navigation-'+role+'-mobile.png',fullPage:true});
  await page.getByRole('link',{name:'Đăng xuất',exact:true}).click();await page.waitForURL(/Dang_nhap\.html/);
 }
 check(!errors.length,errors.join('\n'));check(!failures.length,failures.join('\n'));
 return {status:'PASS',pages:results.length,widths:[1440,1024,768,390],customerHorizontal:true,employeeSidebars:true,uniqueActiveMenu:true,mobileOpenEscapeLogout:true,pageErrors:errors,apiFailures:failures};
}
