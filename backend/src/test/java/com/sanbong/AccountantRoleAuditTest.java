package com.sanbong;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpSession;
import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AccountantRoleAuditTest extends RoleAuditSupport {
 String path(String id){return "/finance/bookings/"+id;}
 JsonNode pay(MockHttpSession accountant,String id,int amount)throws Exception{return data(write(accountant,"POST",path(id)+"/payments",payment(amount,UUID.randomUUID().toString())).andExpect(status().isOk()).andReturn());}
 LocalDate today(){return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));}
 JsonNode report(MockHttpSession accountant)throws Exception{return data(mvc.perform(get("/reports/finance").param("from",today().toString()).param("to",today().toString()).param("pitch",pitch()).session(accountant)).andExpect(status().isOk()).andReturn());}
 @Test void accountantCannotOperatePitchesManageAccountsOrImpersonateCustomer()throws Exception{
  var s=login("ketoan");for(String url:List.of("/booking-options","/customer/profile","/admin/options","/security/accounts","/service-catalog"))mvc.perform(get(url).session(s)).andExpect(status().isForbidden());
  write(s,"POST","/bookings",Map.of("maSan",pitch(),"ngayChoi",day().toString(),"maKH",customer(),"gioBatDau","08:00","gioKetThuc","09:00")).andExpect(status().isForbidden());
  write(s,"POST","/admin/employees",employee(true)).andExpect(status().isForbidden());
 }
 @Test void invoiceIsUniqueAndIgnoresClientSuppliedTotals()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");BigDecimal expected=jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",BigDecimal.class,id);
  for(int n=0;n<2;n++){var d=data(write(s,"POST",path(id)+"/invoice",Map.of("tongTien",1,"tienSan",1)).andExpect(status().isOk()).andReturn());assertEquals(0,expected.compareTo(d.path("invoice").path("tongTien").decimalValue()));}
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void partialAndFinalPaymentsUpdateBalanceWithoutCompletingPitchVisit()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");pay(s,id,1000);var partial=pay(s,id,2000);
  assertEquals(3000,partial.path("invoice").path("daThanhToan").asInt());int balance=partial.path("invoice").path("conLai").asInt();assertTrue(balance>0);
  var paid=pay(s,id,balance);assertEquals(0,paid.path("invoice").path("conLai").asInt());assertEquals("Chờ xác nhận",paid.path("booking").path("trangThai").asText());assertFalse(paid.path("invoice").path("hoanTatTaiChinh").asBoolean());
  write(s,"POST",path(id)+"/payments",payment(1,UUID.randomUUID().toString())).andExpect(status().isConflict());
 }
 @Test void receiptRetryCreatesOneAndChangedPayloadOrBookingIsRejected()throws Exception{
  var staff=login("nvsan");String first=book(staff),second=book(staff,"09:00","10:00");var s=login("ketoan");String key=UUID.randomUUID().toString();
  for(int n=0;n<2;n++)write(s,"POST",path(first)+"/payments",payment(1000,key)).andExpect(status().isOk());
  write(s,"POST",path(first)+"/payments",payment(1001,key)).andExpect(status().isConflict());write(s,"POST",path(second)+"/payments",payment(1000,key)).andExpect(status().isConflict());
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaGiaoDich=?",Integer.class,key));
 }
 @Test void cashReceiptRequiresExplicitConfirmationAndPositiveAmount()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");var body=new LinkedHashMap<String,Object>(payment(1000,UUID.randomUUID().toString()));body.put("daNhanTien",false);
  write(s,"POST",path(id)+"/payments",body).andExpect(status().isBadRequest());body.put("daNhanTien",true);body.put("soTien",0);write(s,"POST",path(id)+"/payments",body).andExpect(status().isBadRequest());
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void pendingRequestCanBeConfirmedOnceAndRejectionNeverCountsAsCash()throws Exception{
  var staff=login("nvsan");String a=book(staff),b=book(staff,"09:00","10:00");var customer=login("khachhang");var accountant=login("ketoan");
  for(String id:List.of(a,b))write(customer,"POST",path(id)+"/payment-requests",payment(1000,UUID.randomUUID().toString())).andExpect(status().isOk());
  String pa=jdbc.queryForObject("SELECT MaTT FROM ThanhToan WHERE MaDatSan=?",String.class,a),pb=jdbc.queryForObject("SELECT MaTT FROM ThanhToan WHERE MaDatSan=?",String.class,b);
  write(accountant,"POST","/finance/payments/"+pa+"/confirm",Map.of("daNhanTien",false)).andExpect(status().isBadRequest());
  for(int n=0;n<2;n++)write(accountant,"POST","/finance/payments/"+pa+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isOk());
  write(accountant,"POST","/finance/payments/"+pb+"/reject",Map.of()).andExpect(status().isOk());
  assertEquals("Thất bại",jdbc.queryForObject("SELECT TrangThai FROM ThanhToan WHERE MaTT=?",String.class,pb));
  mvc.perform(get(path(b)).session(accountant)).andExpect(jsonPath("$.data.thucThu").value(0));assertEquals(1000,report(accountant).path("totals").path("tienThu").asInt());
 }
 @Test void refundConfirmationIsIdempotentRequiresWitnessAndKeepsActor()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");pay(s,id,1000);write(login("khachhang"),"POST","/bookings/"+id+"/cancel",Map.of("lyDo",marker)).andExpect(status().isOk());
  String refund=jdbc.queryForObject("SELECT h.MaHT FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",String.class,id);
  var pending=report(s).path("totals");assertEquals(1000,pending.path("thucNhan").asInt());assertEquals(0,pending.path("tienHoan").asInt());
  write(s,"POST","/finance/refunds/"+refund+"/confirm",Map.of("phuongThuc","Chuyển khoản","daHoanTien",false,"lyDo",marker)).andExpect(status().isBadRequest());
  for(int n=0;n<2;n++)write(s,"POST","/finance/refunds/"+refund+"/confirm",Map.of("phuongThuc","Chuyển khoản","daHoanTien",true,"lyDo",marker)).andExpect(status().isOk());
  var totals=report(s).path("totals");assertEquals(1000,totals.path("tienHoan").asInt());assertEquals(0,totals.path("thucNhan").asInt());
  assertEquals(jdbc.queryForObject("SELECT MaNV FROM TaiKhoan WHERE TenDangNhap='ketoan'",String.class),jdbc.queryForObject("SELECT MaNV FROM HoanTien WHERE MaHT=?",String.class,refund));
  write(s,"POST",path(id)+"/payments",payment(1,UUID.randomUUID().toString())).andExpect(status().isConflict());
 }
 @Test void prepaidFutureBookingIsCashButNotRevenue()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");pay(s,id,1000);var totals=report(s).path("totals");assertEquals(1000,totals.path("tienThu").asInt());assertEquals(0,totals.path("doanhThu").asInt());
 }
 @Test void returnedInvoiceIsSealedAndPriceCatalogCannotRewriteSnapshot()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");pay(s,id,1000);
  var now=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));jdbc.update("INSERT XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan,ThoiGianKetThuc) VALUES(?,?,?,?,?)",code("AX"),id,"NV02",now.minusHours(1),now);
  jdbc.update("UPDATE DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=?",id);em.clear();
  var before=data(write(s,"POST",path(id)+"/invoice",Map.of()).andExpect(status().isOk()).andReturn()).path("invoice");assertTrue(before.path("daChot").asBoolean());
  jdbc.update("UPDATE GiaTheoCa SET DonGia=DonGia+100 WHERE GioBatDau<='08:00' AND GioKetThuc>'08:00'");
  var after=data(write(s,"POST",path(id)+"/invoice",Map.of()).andExpect(status().isOk()).andReturn()).path("invoice");assertEquals(before.path("tongTien"),after.path("tongTien"));
  write(s,"POST",path(id)+"/invoice",Map.of("maKM","NO_PROMO")).andExpect(status().isConflict());
  assertEquals(0,before.path("tongTien").decimalValue().compareTo(report(s).path("totals").path("doanhThu").decimalValue()));
 }
 @Test void reconciliationDetectsMismatchAndReportRejectsInvalidRange()throws Exception{
  String id=book(login("nvsan"));var s=login("ketoan");pay(s,id,1000);
  var query=get("/reports/reconciliation").param("from",day().toString()).param("to",day().toString()).param("pitch",pitch());
  mvc.perform(query.session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.rows[0].ketQua").value("Khớp sổ nội bộ"));
  jdbc.update("UPDATE HoaDon SET DaThanhToan=999 WHERE MaDatSan=?",id);
  mvc.perform(get("/reports/reconciliation").param("from",day().toString()).param("to",day().toString()).param("pitch",pitch()).session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.rows[0].ketQua").value("Cần kiểm tra"));
  mvc.perform(get("/reports/finance").param("from",day().toString()).param("to",day().minusDays(1).toString()).session(s)).andExpect(status().isBadRequest());
  mvc.perform(get("/reports/refunds").param("from",day().toString()).param("to",day().toString()).param("size","0").session(s)).andExpect(status().isBadRequest());
 }
}
