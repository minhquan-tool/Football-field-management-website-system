async page => {
 const base=__QA_BASE_JSON__,password=__QA_PASSWORD_JSON__;
 const check=(condition,message)=>{if(!condition)throw new Error(message)};
 const errors=[],apiErrors=[],checked=[];
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base+'reports/')&&r.status()>=400)apiErrors.push(r.status()+' '+r.url());});
 for(const [user,role,allowed] of [['khachhang','VT01',[]],['nvsan','VT02',['usage']],['ketoan','VT03',['finance','reconciliation','refunds']],['admin','VT04',['usage','finance','reconciliation','refunds']]]){
  await page.context().clearCookies();
  const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;
  const login=await page.request.post(base+'auth/login',{headers:{[csrf.headerName]:csrf.token},form:{identifier:user,password}});
  check(login.ok(),'Login failed for '+role);
  const me=(await(await page.request.get(base+'auth/me')).json()).data;
  check(me.maVaiTro===role,'Unexpected role for '+user);
  if(!allowed.length){
   const response=await page.request.get(base+'reports/finance?from=2026-10-17&to=2026-10-17');
   check(response.status()===403,'Customer read financial report');
   checked.push({role,financialAccess:403});continue;
  }
  await page.setViewportSize({width:1440,height:1000});
  await page.goto(base+'Bao_cao.html');
  await page.locator('#reportType option').first().waitFor({state:'attached'});
  const options=await page.locator('#reportType option').evaluateAll(items=>items.map(x=>x.value));
  check(JSON.stringify(options)===JSON.stringify(allowed),'Report options mismatch for '+role);
  for(const type of allowed){
   await page.selectOption('#reportType',type);
   await page.waitForFunction(()=>document.getElementById('reportStatus').textContent==='Đã tải báo cáo.');
   check(await page.locator('#reportRows tr').count()>0,'No result/empty-state row for '+role+'/'+type);
   checked.push({role,type,loaded:true});
  }
  for(const width of [1440,390]){
   await page.setViewportSize({width,height:1000});
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+2),'Page overflow '+role+'/'+width);
  }
 }
 check(errors.length===0,JSON.stringify(errors));
 // The expected customer 403 is tested with page.request and is not a page response.
 check(apiErrors.length===0,JSON.stringify(apiErrors));
 return {status:'PASS',base,checked,viewports:[1440,390],pageErrors:errors,apiErrors};
}
