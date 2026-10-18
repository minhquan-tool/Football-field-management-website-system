async page=>{
 const base=__QA_BASE_JSON__,password=__QA_PASSWORD_JSON__;const check=(v,m)=>{if(!v)throw Error(m);};const errors=[];page.on('pageerror',e=>errors.push(e.message));const results=[];
 async function login(user){await page.goto('about:blank');await page.context().clearCookies();const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;const response=await page.request.post(base+'auth/login',{headers:{[csrf.headerName]:csrf.token},form:{identifier:user,password}});check(response.ok(),'Login '+user);}
 await page.context().clearCookies();
 for(const path of ['', 'Dang_nhap.html','Dang_ky.html']){
  await page.goto(base+path);
  for(const width of [375,390,768,1024,1440]){await page.setViewportSize({width,height:920});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Public/auth overflow '+path+' @'+width);}
  await page.screenshot({path:'exports/redesign-'+(path||'public-home')+'.png',fullPage:true});
 }
 for(const [user,role,home]of [['khachhang','VT01','Man_hinh_chinh_KH.html'],['nvsan','VT02','Man_hinh_chinh_NVKH.html'],['ketoan','VT03','Man_hinh_chinh_NVKT.html'],['admin','VT04','Man_hinh_chinh.html']]){
  await login(user);await page.goto(base+home);await page.locator('[data-role-menu]').waitFor({state:'attached'});
  const links=await page.locator('[data-role-menu] a').evaluateAll(nodes=>nodes.filter(n=>n.textContent!=='Đăng xuất').map(n=>n.getAttribute('href')));
  for(const href of links){await page.goto(new URL(href,base).href);await page.locator('[data-role-menu]').waitFor({state:'attached'});
   check(await page.locator('link[href="css/experience.css"]').count()===1,'Missing experience theme '+href);
   if(await page.locator('#careStatus').count())await page.waitForFunction(()=>document.body.dataset.careReady==='true');
   for(const width of [375,390,768,1024,1440]){await page.setViewportSize({width,height:920});
    check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Horizontal page overflow '+role+' '+href+' @'+width);
   }
   if(role==='VT01'){
    check(await page.locator('body.fc-layout-top').count()===1,'Customer layout changed to sidebar '+href);
    check(await page.locator('[data-role-menu]').evaluate(el=>getComputedStyle(el).flexDirection)==='row','Customer desktop menu became vertical '+href);
    const overlap=await page.locator('.fc-topbar').evaluate(header=>{const links=[...header.querySelectorAll('[data-role-menu] a')].filter(a=>a.getClientRects().length);return links.some((a,i)=>i&&a.getBoundingClientRect().left<links[i-1].getBoundingClientRect().right-1);});
    check(!overlap,'Customer desktop menu overlaps '+href);
   }
   results.push({role,href});
  }
  await page.setViewportSize({width:390,height:844});await page.goto(base+home);await page.locator('[data-role-menu]').waitFor({state:'attached'});
  const trigger=page.locator('[data-mobile-menu]').first();if(await trigger.count()){await trigger.click();check(await page.locator('[data-role-menu]').isVisible(),'Mobile menu hidden '+role);await page.keyboard.press('Escape');}
  await page.screenshot({path:'exports/redesign-'+role+'-mobile.png',fullPage:true});
  await page.setViewportSize({width:1440,height:1000});await page.screenshot({path:'exports/redesign-'+role+'-desktop.png',fullPage:true});
  if(role==='VT01'){
   const history=(await(await page.request.get(base+'customer/history')).json()).data;
   if(history.bookings.length){const b=history.bookings[0];await page.goto(base+'Quan_ly_lich_dat_san.html?'+new URLSearchParams({date:b.ngayChoi,pitch:b.maSan,booking:b.maDatSan}));
    await page.locator('#detailModal').waitFor();await page.locator('#financeAmounts:not([hidden])').waitFor();
    check(await page.locator('#financeAmounts>div').count()===3,'Missing finance metrics');
    await page.setViewportSize({width:390,height:844});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Detail modal overflows');
    const close=page.locator('#detailModal button').filter({hasText:'Đóng'}).first();
    await page.screenshot({path:'exports/redesign-booking-detail-mobile.png',fullPage:true});
    check(await page.locator('#printBookingSlip').isVisible(),'Print action inaccessible');
   }
   await page.goto(base+home);await page.locator('[data-role-menu]').waitFor({state:'attached'});await page.setViewportSize({width:390,height:844});
   await page.locator('[data-mobile-menu]').first().click();await page.getByRole('link',{name:'Đăng xuất',exact:true}).click();await page.waitForURL(/Dang_nhap\.html/);
   check((await page.request.get(base+'auth/me')).status()===401,'Customer mobile logout did not invalidate session');
  }
 }
 check(!errors.length,errors.join('\n'));return {status:'PASS',menuPages:results.length,widths:[375,390,768,1024,1440],pageErrors:errors,businessWrites:0};
}
