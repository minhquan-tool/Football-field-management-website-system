async page => {
 const base='http://127.0.0.1:8084/api/';const check=(v,m)=>{if(!v)throw Error(m);};const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.context().clearCookies();await page.goto(base,{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>!document.getElementById('publicSearchButton').disabled);
 const date=await page.locator('#publicDate').inputValue();
 // Search a future date, independent of today's remaining opening hours.
 const future=new Date(date+'T12:00:00');future.setDate(future.getDate()+7);const day=future.toISOString().slice(0,10);
 await page.locator('#publicDate').fill(day);await page.locator('#publicStart').fill('08:00');await page.locator('#publicEnd').fill('09:00');await page.locator('#publicSearchButton').click();
 const entry=page.getByRole('link',{name:'Đăng nhập để đặt sân'}).first();await entry.waitFor();const intent=new URL(await entry.getAttribute('href'),base).searchParams;check(intent.has('pitch'),'Selected pitch missing');
 await entry.click();await page.waitForFunction(()=>Array.from(document.links).some(a=>a.pathname.endsWith('/Dang_ky.html')&&a.search.includes('pitch=')));const signup=page.getByRole('link',{name:'Đăng ký ngay'});check((await signup.getAttribute('href')).includes('pitch='),'Registration drops selection');
 await signup.click();await page.waitForFunction(()=>Array.from(document.links).some(a=>a.pathname.endsWith('/Dang_nhap.html')&&a.search.includes('pitch=')));check((await page.getByRole('link',{name:'Đăng nhập',exact:true}).getAttribute('href')).includes('pitch='),'Registration return drops selection');await page.getByRole('link',{name:'Đăng nhập',exact:true}).click();
 await page.locator('#identifier').fill('khachhang');await page.locator('#password').fill('123456');await page.locator('#loginForm button[type="submit"]').click();
 await page.waitForURL(/Man_hinh_chinh_Dat_san_KH/);await page.waitForFunction(pitch=>document.getElementById('receiptPitch').textContent.includes('('+pitch+')'),intent.get('pitch'));
 check(await page.locator('#playDate').inputValue()===day,'Date lost');check(await page.locator('#startTime').inputValue()==='08:00','Start lost');check((await page.locator('#receiptPitch').textContent()).includes(intent.get('pitch')),'Wrong selected pitch');
 await page.goto(base+encodeURI('Man_hinh_LS&ĐG_KH.html'));await page.waitForFunction(()=>document.body.dataset.careReady==='true');
 const data=(await(await page.request.get(base+'customer/history')).json()).data;
 let printed=false;
 if(data.bookings.length){
  await page.getByRole('searchbox',{name:'Tìm lượt đặt'}).fill(data.bookings[0].maDatSan);
  check(await page.locator('#historyRows article:visible').count()>=1,'History filter lost matching booking');
  await page.getByRole('searchbox',{name:'Tìm lượt đặt'}).fill('NO_SUCH_BOOKING_999');check(await page.locator('#historyRows article:visible').count()===0,'History filter ignored search');
  const b=data.bookings[0];await page.goto(base+'Quan_ly_lich_dat_san.html?'+new URLSearchParams({date:b.ngayChoi,pitch:b.maSan,booking:b.maDatSan}));
  await page.waitForFunction(()=>!document.getElementById('detailModal').classList.contains('hidden'));
  await page.evaluate(()=>{window.print=()=>{window.__printed=true;};});await page.locator('#printBookingSlip').click();await page.waitForFunction(()=>window.__printed===true);
  check((await page.locator('#bookingPrintSheet').textContent()).includes(b.maDatSan),'Wrong print booking');
  await page.emulateMedia({media:'print'});check(await page.locator('#detailModal').isHidden(),'Print includes workflow controls');check(await page.locator('#bookingPrintSheet').isVisible(),'Print slip hidden');await page.emulateMedia({media:null});
  await page.evaluate(()=>window.dispatchEvent(new Event('afterprint')));check(await page.locator('#bookingPrintSheet').count()===0,'Stale slip left after print');
  await page.emulateMedia({media:'print'});check(await page.locator('#detailModal').isVisible(),'Normal print hidden without booking slip');await page.emulateMedia({media:null});printed=true;
 }
 await page.goto('about:blank');await page.context().clearCookies();await page.goto(base+'Dang_nhap.html?'+intent);
 await page.locator('#identifier').fill('nvsan');await page.locator('#password').fill('123456');await page.locator('#loginForm button[type="submit"]').click();await page.waitForURL(/Man_hinh_chinh_NVKH/);await page.locator('#staffWorkQueue').waitFor();check(!page.url().includes('Dat_san_KH'),'Staff redirected into customer booking');
 await page.setViewportSize({width:390,height:844});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Staff queue overflows mobile');await page.screenshot({path:'exports/experience-staff-mobile.png',fullPage:true});
 check(!errors.length,errors.join('\n'));return {status:'PASS',guestIntent:true,registrationPreservesIntent:true,roleIsolation:true,customerHistoryBookings:data.bookings.length,printVerified:printed,staffQueue:true,pageErrors:errors,businessWrites:0};
}


