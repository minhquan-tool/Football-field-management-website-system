async page=>{
 const base='http://127.0.0.1:8082/api/';const check=(v,m)=>{if(!v)throw Error(m);};const errors=[],failedGets=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith(base)&&r.request().method()==='GET'&&r.status()>=400&&!/favicon/.test(r.url()))failedGets.push(r.status()+' '+r.url());});
 await page.goto('about:blank');await page.context().clearCookies();await page.setViewportSize({width:1440,height:1000});
 const token=(await(await page.request.get(base+'auth/csrf')).json()).data;
 check((await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:'khachhang',password:'123456'}})).ok(),'Customer login failed');
 await page.goto(base+'Man_hinh_chinh_KH.html',{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT01"]').waitFor();
 const links=await page.locator('[data-role-menu] a').evaluateAll(nodes=>nodes.filter(n=>n.textContent!=='Đăng xuất').map(n=>({name:n.textContent,href:n.getAttribute('href')})));
 for(const link of links){
  await page.setViewportSize({width:1440,height:1000});await page.locator('[data-role-menu]').getByRole('link',{name:link.name,exact:true}).click();await page.locator('[data-role-menu="VT01"]').waitFor();
  check(decodeURIComponent(new URL(page.url()).pathname)===decodeURIComponent(new URL(link.href,base).pathname),'Wrong customer destination '+link.href);
  check(!await page.locator('body>aside').count(),'Customer became sidebar '+link.href);
  if(await page.locator('#careStatus').count())await page.waitForFunction(()=>document.body.dataset.careReady==='true');
  await page.setViewportSize({width:390,height:844});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Mobile overflow '+link.href);
  await page.locator('[data-mobile-menu]').click();check(await page.locator('[data-role-menu]').isVisible(),'Mobile menu failed '+link.href);await page.keyboard.press('Escape');
 }
 const profile=(await(await page.request.get(base+'customer/profile')).json()).data;
 const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;
 const invalid=await page.request.put(base+'customer/profile',{headers:{[csrf.headerName]:csrf.token},data:{hoTen:profile.hoTen,soDienThoai:'+++++++',email:profile.email,diaChi:profile.diaChi}});
 check(invalid.status()===400,'Malformed customer phone still accepted');
 const after=(await(await page.request.get(base+'customer/profile')).json()).data;check(after.soDienThoai===profile.soDienThoai,'Rejected profile request changed saved phone');
 await page.setViewportSize({width:1440,height:1000});await page.goto(base+encodeURI('Man_hinh_LS&ĐG_KH.html'),{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.careReady==='true');await page.screenshot({path:'exports/customer-audit-history.png',fullPage:true});
 check(!errors.length,errors.join('\n'));check(!failedGets.length,failedGets.join('\n'));
 return {status:'PASS',customerMenuPages:links.length,widths:[1440,390],horizontalNavigation:true,invalidPhoneRejected:true,savedProfileUnchanged:true,pageErrors:errors,failedGets,businessWrites:0};
}
