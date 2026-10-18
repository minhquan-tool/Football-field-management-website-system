async page=>{
 const base='http://127.0.0.1:8084/api/',check=(value,message)=>{if(!value)throw Error(message);},errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.goto('about:blank');await page.context().clearCookies();
 const token=(await(await page.request.get(base+'auth/csrf')).json()).data;
 check((await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:'khachhang',password:'123456'}})).ok(),'Login failed');
 await page.goto(base+encodeURI('Man_hinh_LS&ĐG_KH.html'),{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.historyReady==='true');
 const real=(await(await page.request.get(base+'customer/history?page=1&size=10&q=&state=&order=desc')).json()).data;
 check(await page.locator('#historyRows article').count()===real.bookings.length,'Real page row count');check((await page.locator('[data-history-summary]').textContent()).includes('/'+real.total+' '),'Real total');
 await page.getByRole('combobox',{name:'Sắp xếp lịch sử'}).selectOption('asc');await page.waitForFunction(()=>document.body.dataset.historyReady==='true');
 for(const width of [1440,1024,768,390]){await page.setViewportSize({width,height:900});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Overflow '+width);check(!await page.locator('body>aside').count(),'Customer sidebar');}
 // UI-only paging fixtures; backend ownership/pagination are covered by rollback integration tests.
 const rows=Array.from({length:23},(_,i)=>({maDatSan:'HP'+String(i+1).padStart(8,'0'),maSan:'TEST',tenSan:'Sân phân trang '+String(i+1).padStart(2,'0'),ngayChoi:'2027-01-'+String(i+1).padStart(2,'0'),gioBatDau:'08:00',gioKetThuc:'09:00',trangThai:i%2?'Đã hủy':'Chờ xác nhận'}));
 let fail=false,slowSeen=false;
 await page.route('**/customer/history?*',async route=>{
  const p=new URL(route.request().url()).searchParams,q=p.get('q')||'',state=p.get('state')||'',size=Number(p.get('size')||10),n=Number(p.get('page')||1);
  if(fail){await route.fulfill({status:503,json:{success:false,message:'Lỗi kiểm thử tải lịch sử',data:null}});return;}
  if(q==='slow'){slowSeen=true;await new Promise(resolve=>setTimeout(resolve,1000));}
  const selected=rows.filter(b=>(!state||b.trangThai===state)&&(`${b.maDatSan} ${b.tenSan}`.toLocaleLowerCase('vi').includes(q.toLocaleLowerCase('vi'))));
  if(p.get('order')!=='asc')selected.reverse();
  await route.fulfill({json:{success:true,message:'UI fixture',data:{bookings:selected.slice((n-1)*size,n*size),total:selected.length,totalPages:Math.ceil(selected.length/size),page:n,size,criteria:[],reviews:[]}}});
 });
 await page.reload({waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.body.dataset.historyReady==='true');
 const next=page.getByRole('button',{name:'Trang sau',exact:true}),previous=page.getByRole('button',{name:'Trang trước',exact:true});
 check(await previous.isDisabled(),'First page has previous');check(await page.locator('#historyRows article').count()===10,'First page size');
 await next.click();await page.waitForFunction(()=>document.body.dataset.historyReady==='true');check((await page.locator('[data-history-summary]').textContent()).includes('10/23'),'Page 2 count');
 await next.click();await page.waitForFunction(()=>document.body.dataset.historyReady==='true');check(await page.locator('#historyRows article').count()===3,'Last page size');check(await next.isDisabled(),'Last page has next');
 const search=page.getByRole('searchbox',{name:'Tìm lượt đặt'});
 await search.fill('HP00000001');await page.waitForFunction(()=>document.querySelector('[data-history-summary]').textContent.includes('1/1 '));check((await page.locator('#historyRows article h3').textContent()).startsWith('HP00000001'),'Search misses row from other page');
 await search.fill('slow');for(let i=0;i<30&&!slowSeen;i++)await page.waitForTimeout(50);check(slowSeen,'Slow response was not exercised');
 await search.fill('HP00000005');await page.waitForFunction(()=>document.querySelector('#historyRows article h3')?.textContent.startsWith('HP00000005'));await page.waitForTimeout(1100);
 check((await page.locator('#historyRows article h3').textContent()).startsWith('HP00000005'),'Stale response overwrote current search');
 await search.fill('');await page.getByRole('combobox',{name:'Lọc trạng thái lượt đặt'}).selectOption('Đã hủy');await page.waitForFunction(()=>document.querySelector('[data-history-summary]').textContent.includes('/11 '));
 await page.getByRole('combobox',{name:'Số lượt mỗi trang'}).selectOption('20');await page.waitForFunction(()=>document.querySelectorAll('#historyRows article').length===11);check(await next.isDisabled(),'Filtered results still paged incorrectly');
 await page.getByRole('combobox',{name:'Sắp xếp lịch sử'}).selectOption('asc');await page.waitForFunction(()=>document.querySelector('#historyRows article h3')?.textContent.startsWith('HP00000002'));
 fail=true;await page.getByRole('combobox',{name:'Sắp xếp lịch sử'}).selectOption('desc');await page.getByRole('button',{name:'Tải lại lịch sử',exact:true}).waitFor();
 check(await page.locator('#historyRows article').count()===0,'Failure left stale details');check(await next.isDisabled()&&await previous.isDisabled(),'Failure left pager enabled');
 fail=false;await page.getByRole('button',{name:'Tải lại lịch sử',exact:true}).click();await page.waitForFunction(()=>document.querySelectorAll('#historyRows article').length===11);
 await page.unroute('**/customer/history?*');check(!errors.length,errors.join('\n'));
 return {status:'PASS',realBackendRead:true,mockPagingRows:23,searchAcrossPages:true,staleResponseIgnored:true,filterSizeSort:true,errorClearsRowsAndRetry:true,widths:[1440,1024,768,390],businessWrites:0,pageErrors:errors};
}
