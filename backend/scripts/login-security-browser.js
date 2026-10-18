async page=>{
 const base='http://127.0.0.1:8084/api/',check=(ok,message)=>{if(!ok)throw Error(message);},errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.goto('about:blank');await page.context().clearCookies();
 const id='security_missing_'+Date.now();
 async function attempt(identifier,extraHeaders={}){const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;return page.request.post(base+'auth/login',{headers:{[csrf.headerName]:csrf.token,...extraHeaders},form:{identifier,password:'InvalidFixturePassword2026!'}});}
 for(let i=0;i<5;i++)check((await attempt(id)).status()===401,'Expected bad credentials before limit');
 const blocked=await attempt(id);check(blocked.status()===429,'Sixth attempt not blocked');check(Number(blocked.headers()['retry-after'])>0,'No Retry-After');
 check((await attempt(id.toUpperCase(),{'X-Forwarded-For':'203.0.113.77','CF-Connecting-IP':'203.0.113.88'})).status()===429,'Header or case bypass');
 await page.goto(base+'Dang_nhap.html',{waitUntil:'domcontentloaded'});
 await page.locator('#identifier').fill(id);await page.locator('#password').fill('InvalidFixturePassword2026!');await page.locator('#loginForm button[type=submit]').click();
 await page.waitForFunction(()=>document.querySelector('#loginForm button[type=submit]').textContent.includes('Thử lại sau'));
 check(await page.locator('#loginForm button[type=submit]').isDisabled(),'Cooldown button not disabled');check((await page.locator('#loginStatus').textContent()).includes('quá nhiều lần'),'No persistent feedback');
 for(const width of [1440,1024,768,390]){await page.setViewportSize({width,height:900});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Login overflow '+width);}
 await page.reload({waitUntil:'domcontentloaded'});check((await attempt(id)).status()===429,'Reload bypassed backend limit');
 // Short UI-only cooldown, no waiting five minutes or changing the production policy.
 await page.route(base+'auth/login',route=>route.fulfill({status:429,headers:{'Retry-After':'2'},json:{success:false,message:'Bạn đã thử đăng nhập quá nhiều lần.',data:{retryAfterSeconds:2}}}));
 await page.locator('#identifier').fill('ui-only');await page.locator('#password').fill('InvalidFixturePassword2026!');await page.locator('#loginForm button[type=submit]').click();
 await page.waitForFunction(()=>document.querySelector('#loginForm button[type=submit]').disabled);
 await page.waitForFunction(()=>!document.querySelector('#loginForm button[type=submit]').disabled,{},{timeout:6000});
 check((await page.locator('#loginStatus').textContent()).includes('có thể thử đăng nhập lại'),'Cooldown did not expire');await page.unroute(base+'auth/login');
 const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;
 const valid=await page.request.post(base+'auth/login',{headers:{[csrf.headerName]:csrf.token},form:{identifier:'khachhang',password:'123456'}});check(valid.ok(),'Unrelated valid account blocked by pair limit');
 await page.setViewportSize({width:1440,height:900});await page.goto(base+'Man_hinh_chinh_KH.html',{waitUntil:'domcontentloaded'});await page.locator('[data-role-menu="VT01"]').waitFor();
 check(!errors.length,errors.join('\n'));return {status:'PASS',actualWrongAttempts:5,sixthReturns429:true,retryAfter:true,headerAndReloadBypassRejected:true,shortCooldown:'intercepted UI only',otherAccountLogin:true,widths:[1440,1024,768,390],passwordChanges:0,pageErrors:errors};
}
