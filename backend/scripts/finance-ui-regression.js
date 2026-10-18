// Run with playwright-cli run-code --filename=backend/scripts/finance-ui-regression.js
async page => {
    const base = 'http://127.0.0.1:8093/';
    const check = (condition, message) => { if (!condition) throw new Error(message); };
    async function openA() {
        await page.goto(base);
        await page.locator('#financeTransactions tr').first().click();
        await page.locator('#financeSummary').filter({hasText:'HDDSA'}).waitFor();
    }
    await openA();
    await page.locator('#financeTransactionDate').fill('2026-10-12');await page.locator('#financeTransactionDate').dispatchEvent('change');
    check(await page.locator('#financeTransactions tr').count()===1 && (await page.locator('#financeTransactions').textContent()).includes('DSB'),'Ledger date filter must select matching transactions');
    await page.locator('#financeTransactionDate').fill('2026-10-14');await page.locator('#financeTransactionDate').dispatchEvent('change');
    check((await page.locator('#financeTransactions').textContent()).includes('Không có giao dịch trong ngày'),'Ledger date filter must explain empty results');
    await page.locator('#financeTransactionDate').fill('');await page.locator('#financeTransactionDate').dispatchEvent('change');
    check(await page.locator('#financeTransactions tr').count()===2,'Clearing ledger filter must restore both transactions');
    await page.evaluate(() => audit.failReload = true);
    await page.locator('#financeInvoiceForm button').click();
    await page.waitForFunction(() => audit.posts === 1 && document.getElementById('financeStatus').textContent !== 'Đang tải...');
    const failedReload = await page.locator('#financeStatus').textContent();
    check(failedReload.includes('SIMULATED_RELOAD_503') && failedReload.includes('Đã lưu'), 'R04: committed POST must retain reload failure warning');
    check(await page.evaluate(() => audit.posts) === 1, 'Reload failure must not retry POST');
    await page.evaluate(() => audit.failReload = false);
    await page.locator('#financeTransactions tr').first().click();
    await page.locator('#financeSummary').filter({hasText:'HDDSA'}).waitFor();

    await openA();
    await page.evaluate(() => audit.delayPost = true);
    await page.locator('#financeInvoiceForm button').click();
    await page.waitForFunction(() => Boolean(audit.releasePost));
    await page.locator('#financeTransactions tr').nth(1).click();
    check(!(await page.evaluate(() => audit.requests)).some(r => r.path === 'finance/bookings/DSB'), 'R05: selection must not change while a mutation is pending');
    await page.evaluate(() => audit.releasePost());
    await page.waitForFunction(() => document.getElementById('financeStatus').textContent.includes('Đã lưu hóa đơn'));
    check((await page.locator('#financeSummary').textContent()).includes('HDDSA'), 'Mutation must keep booking A selected');
    await page.locator('#financeTransactions tr').nth(1).click();
    await page.locator('#financeSummary').filter({hasText:'HDDSB'}).waitFor();

    await openA();
    await page.evaluate(() => audit.failPost = true);
    await page.locator('#financeReceipt').check();
    await page.locator('#financePaymentForm button').click();
    await page.waitForFunction(() => document.getElementById('financeStatus').textContent.includes('SIMULATED_POST_RESPONSE_LOST'));
    await page.locator('#financePaymentForm button').click();
    await page.waitForFunction(() => audit.posts === 2);
    const attempts = await page.evaluate(() => audit.requests.filter(r => r.method === 'POST').map(r => JSON.parse(r.body)));
    check(attempts[0].idempotencyKey === attempts[1].idempotencyKey, 'Unknown POST outcome must keep the same payment idempotency key');
    check(!(await page.locator('#financeStatus').textContent()).includes('Đã ghi nhận thực thu'), 'Failed POST must not claim receipt success');
    await page.locator('#financeTransactions tr').nth(1).click();
    await page.locator('#financeSummary').filter({hasText:'HDDSB'}).waitFor();
    await page.locator('#financeReceipt').check();
    await page.locator('#financePaymentForm button').click();
    await page.waitForFunction(() => audit.posts === 3);
    await page.locator('#financeTransactions tr').first().click();
    await page.locator('#financeSummary').filter({hasText:'HDDSA'}).waitFor();
    await page.locator('#financeReceipt').check();
    await page.locator('#financePaymentForm button').click();
    await page.waitForFunction(() => audit.posts === 4);
    const keysByBooking = await page.evaluate(() => audit.requests.filter(r => r.method === 'POST').map(r => JSON.parse(r.body).idempotencyKey));
    check(keysByBooking[0] !== keysByBooking[2] && keysByBooking[0] === keysByBooking[3], 'Retry keys must remain scoped to each booking after switching away and back');
    return 'FINANCE_UI_PASS: reload failure/recovery, delayed mutation selection, successful switch, lost-response retry and per-booking keys';
}
