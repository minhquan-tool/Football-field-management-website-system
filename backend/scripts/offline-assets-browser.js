async page=>{
 const base='http://127.0.0.1:8084/api/',external=[],errors=[];
 const check=(v,m)=>{if(!v)throw Error(m)};
 page.on('pageerror',error=>errors.push(error.message));
 await page.route('**/*',route=>{
  const url=route.request().url();
  if(url.startsWith('http')&&!url.startsWith('http://127.0.0.1:8084/')){external.push({url,type:route.request().resourceType()});return route.abort();}
  return route.continue();
 });
 for(const path of ['Dang_nhap.html','Dang_ky.html']){
  await page.goto(base+path);await page.locator('input.fc-input').first().waitFor();
  await page.evaluate(()=>document.fonts.ready);
  check(await page.evaluate(()=>document.fonts.check('16px Montserrat')),'Local Montserrat unavailable');
  check(await page.locator('img').evaluateAll(images=>images.every(img=>img.complete&&img.naturalWidth>0)),'Local logo missing');
  check(await page.locator('.input-icon').first().evaluate(el=>getComputedStyle(el).fontFamily.includes('Font Awesome')),'Icon font unavailable');
  for(const width of [1440,768,390]){await page.setViewportSize({width,height:1000});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Offline overflow '+path+width);}
  await page.screenshot({path:'exports/medium-offline-'+path.replace('.html','')+'.png',fullPage:true});
 }
 check(!external.length,'UI requested external resources: '+JSON.stringify(external));
 check(!errors.length,errors.join('\n'));
 return {status:'PASS',externalUiRequests:external.length,localFontsIconsLogo:true,widths:[1440,768,390],internetBlocked:true};
}
