async page=>{
 const base='http://127.0.0.1:8084/api/';const check=(ok,message)=>{if(!ok)throw Error(message);};const errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('about:blank');await page.context().clearCookies();
 const csrf=(await(await page.request.get(base+'auth/csrf')).json()).data;
 check((await page.request.post(base+'auth/login',{headers:{[csrf.headerName]:csrf.token},form:{identifier:'khachhang',password:'123456'}})).ok(),'Customer login');
 await page.route(base+'customer/profile',route=>route.fulfill({status:503,json:{success:false,message:'Database tạm thời không khả dụng.',data:null}}));
 await page.goto(base+'Tai_khoan_KH.html',{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.careReady==='true');
 check(await page.locator('#profileForm button').isDisabled(),'Profile enabled before loading data');check(await page.locator('#passwordForm button').isDisabled(),'Password form enabled when initialization failed');
 check((await page.locator('#careStatus').textContent()).includes('không khả dụng'),'Failed loading hidden');await page.unroute(base+'customer/profile');
 await page.reload({waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.careReady==='true');
 for(const width of [1440,1024,768,390]){await page.setViewportSize({width,height:900});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Profile overflow '+width);check(!await page.locator('body>aside').count(),'Customer sidebar');}
 const newPassword='BrowserFixtureOnly2026!';
 await page.locator('#password_current').fill('DefinitelyIncorrect-DoNotChange2026!');await page.locator('#password_new').fill(newPassword);await page.locator('#password_confirm').fill('MismatchOnly2026!');
 let writes=0;const count=r=>{if(r.url()===base+'customer/password'&&r.method()==='POST')writes++;};page.on('request',count);
 await page.locator('#passwordForm button').click();check(writes===0,'Mismatch sent request');check(await page.locator('#password_confirm').getAttribute('aria-invalid')==='true','Missing confirmation error');
 await page.locator('#password_confirm').fill(newPassword);await page.locator('#passwordForm button').click();await page.waitForFunction(()=>document.querySelector('#passwordStatus').textContent.includes('hiện tại không đúng'));
 check(writes===1,'Wrong current request count');check(await page.locator('#passwordForm button').isEnabled(),'Failed change disabled form');check(!await page.locator('#passwordRelogin').isVisible(),'Failed change claimed success');
 // Exercise API field validation via the actual profile form without allowing a valid write.
 await page.locator('#profileForm').evaluate(form=>form.noValidate=true);await page.locator('#profile_soDienThoai').fill('+++++++');
 await page.locator('#profileForm button').click();await page.waitForFunction(()=>document.querySelector('#profile_soDienThoai').getAttribute('aria-invalid')==='true');
 check((await page.locator('#profile_soDienThoai_error').textContent()).includes('Số điện thoại'),'Profile field error absent');
 // Transport failure and success rendering use intercepted responses, never change the demo password.
 await page.route(base+'customer/password',route=>route.abort('failed'));
 await page.locator('#passwordForm button').click();await page.waitForFunction(()=>document.querySelector('#passwordStatus').textContent.includes('phản hồi bị gián đoạn'));
 check(await page.locator('#passwordForm button').isEnabled(),'Transport failure cannot retry');await page.unroute(base+'customer/password');
 await page.route(base+'customer/password',async route=>{await new Promise(resolve=>setTimeout(resolve,250));await route.fulfill({json:{success:true,message:'Đã đổi mật khẩu.',data:null}});});
 await page.locator('#passwordForm button').click();await page.waitForFunction(()=>!document.querySelector('#passwordRelogin').hidden);
 check(await page.locator('#password_current').inputValue()==='','Password not cleared');check(await page.locator('#passwordForm button').isDisabled(),'Successful change still submits');check(await page.locator('#profileForm button').isDisabled(),'Profile still writes after credential change');
 await page.unroute(base+'customer/password');page.off('request',count);
 await page.goto(base+encodeURI('Man_hinh_LS&ĐG_KH.html'),{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.careReady==='true');
 const history=(await(await page.request.get(base+'customer/history?page=1&size=10&order=desc')).json()).data;check(await page.locator('#historyRows article').count()===history.bookings.length,'Missing history rows');
 await page.getByRole('searchbox',{name:'Tìm lượt đặt'}).fill('NO-MATCH-'+Date.now());
 await page.waitForFunction(()=>document.querySelector('[data-history-summary]').textContent.startsWith('Hiển thị 0/'));
 check(await page.locator('#historyRows article:visible').count()===0,'History no-match filter');check(await page.getByText('Không có lượt đặt phù hợp.',{exact:false}).isVisible()||!history.bookings.length,'No-match explanation');
 await page.getByRole('searchbox',{name:'Tìm lượt đặt'}).fill('');
 await page.getByRole('combobox',{name:'Sắp xếp lịch sử'}).selectOption('asc');
 await page.waitForFunction(()=>document.body.dataset.historyReady==='true');
 const ids=await page.locator('#historyRows article h3').allTextContents();
 const expected=(await(await page.request.get(base+'customer/history?page=1&size=10&order=asc')).json()).data.bookings;
 check(expected.every((b,i)=>ids[i].startsWith(b.maDatSan+' ·')),'History sorting');
 for(const width of [1440,1024,768,390]){await page.setViewportSize({width,height:900});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'History overflow '+width);}
 await page.goto(base+'Dang_ky.html',{waitUntil:'domcontentloaded'});
 await page.locator('#fullName').fill('Khách kiểm thử UI bị từ chối');await page.locator('#phoneNumber').fill('0900000000');await page.locator('#username').fill('Tên có dấu');
 await page.locator('#password').fill(newPassword);await page.locator('#confirmPassword').fill(newPassword);await page.locator('#agreeTerms').check();
 await page.locator('#registerForm button[type=submit]').click();await page.waitForFunction(()=>document.querySelector('#username').getAttribute('aria-invalid')==='true');
 check((await page.locator('#username_error').textContent()).includes('không dấu'),'Registration generic error');
 check(!errors.length,errors.join('\n'));
 return {status:'PASS',widths:[1440,1024,768,390],wrongPasswordRejected:true,profileFieldError:true,registrationFieldError:true,historySortAndNoMatch:true,passwordSuccessAndNetworkFailure:'intercepted UI only',realPasswordChanges:0,pageErrors:errors};
}
