async page=>{
 await page.goto('http://127.0.0.1:8093/');
 await page.evaluate(()=>{const original=SanBong.request;SanBong.request=async(path,options)=>{
  const data=await original(path,options);
  if(path.startsWith('finance/bookings/')&&!path.endsWith('cancel-preview')){
   data.invoice.conLai=70000;
   data.payments=[{maTT:'PAID',soTien:20000,trangThai:'Thành công'},{maTT:'PENDING',soTien:10000,trangThai:'Chờ xử lý'}];
   data.refunds=[{maHT:'PENDING_REFUND',soTienHoan:5000,trangThai:'Chờ duyệt'},{maHT:'DONE_REFUND',soTienHoan:3000,trangThai:'Đã hoàn'}];
  }return data;
 };});
 await page.locator('#financeTransactions tr').first().click();await page.locator('#financeAmounts:not([hidden])').waitFor();
 const values=await page.locator('#financeAmounts strong').allTextContents();
 if(values.join('|')!=='20.000đ|70.000đ|5.000đ')throw Error('Pending receipts/refunds conflated: '+values);
 await page.evaluate(()=>{audit.failReload=true;audit.posts=1;});
 await page.locator('#financeTransactions tr').last().click();await page.locator('#financeStatus').filter({hasText:'SIMULATED_RELOAD_503'}).waitFor();
 if(!await page.locator('#financeAmounts').isHidden())throw Error('Stale finance metrics after load error');
 return {status:'PASS',confirmedReceiptOnly:true,pendingRefundOnly:true,invoiceBalance:true,staleValuesCleared:true,syntheticOnly:true};
}
