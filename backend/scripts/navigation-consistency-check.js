async page=>{
 const base='http://127.0.0.1:8082/api/';
 await page.goto('about:blank');await page.context().clearCookies();
 const token=(await(await page.request.get(base+'auth/csrf')).json()).data;
 const login=await page.request.post(base+'auth/login',{headers:{[token.headerName]:token.token},form:{identifier:'khachhang',password:'123456'}});
 if(!login.ok())throw Error('Login unavailable');
 await page.setViewportSize({width:1440,height:1000});await page.goto(base+'Man_hinh_chinh_KH.html');
 await page.locator('[data-role-menu="VT01"]').waitFor();
 await page.getByRole('link',{name:'Lịch đặt / Hóa đơn',exact:true}).click();await page.locator('[data-role-menu="VT01"]').waitFor();
 const layout=await page.locator('[data-role-menu="VT01"]').evaluate(el=>({sidebar:Boolean(el.closest('aside')),rect:el.getBoundingClientRect().toJSON()}));
 if(layout.sidebar)throw Error('NAV_LAYOUT_CHANGED: customer top navigation became a left sidebar on Lịch đặt / Hóa đơn');
 const links=await page.locator('[data-role-menu="VT01"] a').evaluateAll(nodes=>nodes.map(n=>({text:n.textContent,y:Math.round(n.getBoundingClientRect().y)})));
 if(new Set(links.map(n=>n.y)).size!==1)throw Error('Customer desktop navigation no longer stays on one horizontal row: '+JSON.stringify(links));
 return {status:'PASS',customerInvoiceHorizontal:true};
}
