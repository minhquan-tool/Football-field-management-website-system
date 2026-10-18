// Playwright CLI run-code; public GETs only. No accounts/bookings/fixtures are created.
async page => {
    const base = 'http://127.0.0.1:8083/api/';
    const check = (value, message) => { if (!value) throw new Error(message); };
    const errors = []; page.on('pageerror', error => errors.push(error.message));
    await page.setViewportSize({width:1440,height:1000});
    await page.goto(base, {waitUntil:'domcontentloaded'});
    check(page.url().endsWith('/Trang_chu.html'), 'Root must land on public home before login');
    await page.locator('.pitch-card').first().waitFor();
    check(await page.locator('#publicSearchButton').isEnabled(), 'Guest search must be enabled');
    const catalogResponse = await page.request.get(base + 'public/pitches');
    check(catalogResponse.status() === 200, 'Anonymous catalog must be accessible');
    const catalog = (await catalogResponse.json()).data;
    check(catalog.length === Number(await page.locator('#pitchCount').textContent()), 'Stats must match real catalog');
    check(catalog.every(p => !('maKH' in p) && !('matKhau' in p) && !('maDatSan' in p)), 'Guest catalog must not expose customer/booking/password fields');
    for (const path of ['bookings','booking-customers?phone=0999999999','finance/transactions','admin/options']) {
        const response = await page.request.get(base + path);
        check([401,403].includes(response.status()), 'Private endpoint leaked: '+path);
    }
    const csrf = (await (await page.request.get(base+'auth/csrf')).json()).data;
    for (const path of ['public/pitches','bookings']) {
        const response = await page.request.post(base+path, {headers:{[csrf.headerName]:csrf.token},data:{}});
        check([401,403,405].includes(response.status()), 'Anonymous writes must stay blocked: '+path);
    }
    const options = (await (await page.request.get(base+'public/options')).json()).data;
    const tomorrow = new Date(options.today+'T00:00:00Z'); tomorrow.setUTCDate(tomorrow.getUTCDate()+1);
    await page.locator('#publicDate').fill(tomorrow.toISOString().slice(0,10));
    await page.locator('#publicStart').fill('08:00'); await page.locator('#publicEnd').fill('09:00');
    await page.locator('#publicSearchButton').click();
    await page.waitForFunction(() => document.getElementById('publicStatus').textContent.startsWith('Có '));
    const available = await page.locator('.pitch-card').count();
    if (available) {
        check((await page.locator('.pitch-price').first().textContent()).includes('đ'), 'Actual price must be displayed');
        check(await page.locator('.pitch-card a').first().getAttribute('href') === 'Dang_nhap.html', 'Booking still goes through login');
    }
    await page.route('**/public/availability?**', route => route.fulfill({status:503,contentType:'application/json',body:JSON.stringify({success:false,message:'AUDIT_PUBLIC_SEARCH_FAILURE'})}));
    await page.locator('#publicSearchButton').click();
    await page.waitForFunction(() => document.getElementById('publicStatus').textContent.includes('AUDIT_PUBLIC_SEARCH_FAILURE'));
    check(await page.locator('.pitch-card').count() === 0, 'API failure must clear stale results');
    await page.unroute('**/public/availability?**');
    await page.locator('#showAllPitches').click(); await page.locator('.pitch-card').first().waitFor();
    await page.locator('#directionsOrigin').fill('Thủ Đức & Quận 1');
    await page.locator('#directionsForm button').click();
    let route = new URL(await page.locator('#locatedDirections').getAttribute('href'));
    check(route.searchParams.get('destination') === '10.8505572,106.7729939', 'Wrong venue destination');
    check(route.searchParams.get('origin') === 'Thủ Đức & Quận 1', 'Origin encoding failed');
    await page.evaluate(() => Object.defineProperty(navigator,'geolocation',{configurable:true,value:{getCurrentPosition:(ok,fail)=>fail({code:1})}}));
    await page.locator('#locateCustomer').click();
    check((await page.locator('#mapStatus').textContent()).includes('Không lấy được vị trí'), 'Denied location must have a usable fallback');
    check(await page.locator('#locateCustomer').isEnabled(), 'Denied location must unlock button');
    await page.evaluate(() => Object.defineProperty(navigator,'geolocation',{configurable:true,value:{getCurrentPosition:ok=>ok({coords:{latitude:10.8,longitude:106.7}})}}));
    await page.locator('#locateCustomer').click();
    route = new URL(await page.locator('#locatedDirections').getAttribute('href'));
    check(route.searchParams.get('origin') === '10.8,106.7', 'Explicit geolocation route failed');
    await page.evaluate(() => window.scrollTo(0,0));
    await page.screenshot({path:'exports/guest-home-desktop.png',fullPage:true});
    await page.setViewportSize({width:390,height:844}); await page.evaluate(() => window.scrollTo(0,0));
    check(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'Mobile horizontal overflow');
    await page.locator('#navToggle').click(); check(await page.locator('#mainNav').isVisible(), 'Mobile menu must open');
    await page.locator('#mainNav a[href="#tim-san"]').click(); check(!await page.locator('#mainNav').isVisible(), 'Mobile menu must close after navigation');
    await page.evaluate(() => window.scrollTo(0,0)); await page.screenshot({path:'exports/guest-home-mobile.png',fullPage:true});
    check(errors.length === 0, 'Browser JS errors: '+errors.join(', '));
    return {status:'PUBLIC_HOME_BROWSER_PASS',catalogCount:catalog.length,available,anonymousPrivateReads:'blocked',anonymousWrites:'blocked',location:'typed/denied/granted',mobileWidth:390,pageErrors:errors.length,databaseFixtureWrites:0};
}
