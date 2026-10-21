package com.sanbong;
import com.fasterxml.jackson.databind.*;
import com.sanbong.repository.SecurityRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest @AutoConfigureMockMvc
@AuditCleanupFixture
class FinanceIntegrationTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 @MockBean Clock clock; @SpyBean SecurityRepository security;
 String pitch,promo; LocalDate day; LocalDateTime time; MockHttpSession admin;
 @BeforeEach void fixture() throws Exception {
  pitch="FC"+UUID.randomUUID().toString().replace("-","").substring(0,8);promo=pitch;day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(20);time=day.atTime(8,0);
  when(clock.instant()).thenReturn(time.atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
  jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Finance test","LS01","Trống","Phase5.1C automated fixture");
  jdbc.update("INSERT KhuyenMai(MaKM,TenKM,LoaiGiam,MucGiam,NgayBatDau,NgayKetThuc,TrangThai) VALUES(?,?,?,10,?,?,1)",promo,"Finance percent test","Phần trăm",day.minusDays(1),day.plusDays(1));admin=login("admin");
 }
 @AfterEach void cleanup() {
  reset(security);reset(clock);
  assertEquals("Phase5.1C automated fixture",jdbc.queryForObject("SELECT MoTa FROM San WHERE MaSan=?",String.class,pitch));
  var ids=jdbc.queryForList("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch);
  for(String id:ids){
   jdbc.update("DELETE h FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",id);
   jdbc.update("DELETE ThanhToan WHERE MaDatSan=?",id);jdbc.update("DELETE HuyDatSan WHERE MaDatSan=?",id);
   jdbc.update("DELETE ChiTietDichVu WHERE MaDatSan=?",id);jdbc.update("DELETE HoaDon WHERE MaDatSan=?",id);jdbc.update("DELETE XacNhanSan WHERE MaDatSan=?",id);
   jdbc.update("DELETE NhatKyHeThong WHERE DoiTuong=? AND ChucNang IN (?,?,?)",id,"Tài chính","Đặt sân","Nhận sân / Dịch vụ");jdbc.update("DELETE DatSan WHERE MaDatSan=?",id);
  }
  jdbc.update("DELETE San WHERE MaSan=?",pitch);jdbc.update("DELETE KhuyenMai WHERE MaKM=?",promo);
 }
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login(String user)throws Exception{
  var r=mvc.perform(get("/api/auth/csrf")).andReturn();var s=(MockHttpSession)r.getRequest().getSession(false);var c=data(r);
  r=mvc.perform(post("/api/auth/login").session(s).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",user)
   .param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn();return (MockHttpSession)r.getRequest().getSession(false);
 }
 ResultActions write(MockHttpSession s,String path,Object body)throws Exception{
  var c=data(mvc.perform(get("/api/auth/csrf").session(s)).andReturn());return mvc.perform(post(path).session(s).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));
 }
 String create(boolean service)throws Exception{
  var body=new HashMap<String,Object>(Map.of("maSan",pitch,"maKH","KH01","ngayChoi",day.toString(),"gioBatDau","13:00","gioKetThuc","15:00","ghiChu","Phase5.1C automated fixture"));
  if(service)body.put("dichVu",List.of(Map.of("maDV","SV03","quyCach","LOC_6","soLuong",1)));
  return data(write(admin,"/api/bookings",body).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
 }
 String path(String id){return "/api/finance/bookings/"+id;}
 Map<String,Object> payment(int amount,String method){return Map.of("soTien",amount,"phuongThuc",method,"idempotencyKey",UUID.randomUUID().toString(),"daNhanTien",true);}
 JsonNode pay(String id,int amount,String method)throws Exception{return data(write(admin,path(id)+"/payments",payment(amount,method)).andExpect(status().isOk()).andReturn());}
 void open(String id){jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã xác nhận",id);jdbc.update("INSERT XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan) VALUES(?,?,?,?)",pitch,id,"NV01",LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusMinutes(2));}
 @Test void invoicePromoSnapshotsIgnoreFakeTotalAndOneInvoiceOnRetry()throws Exception{
  var id=create(true);var body=Map.of("maKM",promo,"tongTien",1,"tienSan",1,"tienDichVu",1);
  for(int i=0;i<2;i++)write(admin,path(id)+"/invoice",body).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.tienSan").value(260000))
   .andExpect(jsonPath("$.data.invoice.tienDichVu").value(58200)).andExpect(jsonPath("$.data.invoice.tienGiam").value(26000)).andExpect(jsonPath("$.data.invoice.tongTien").value(292200));
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
  jdbc.update("UPDATE DichVu SET DonGia=DonGia WHERE MaDV='SV03'");mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.tongTien").value(292200));
 }
 @ParameterizedTest @CsvSource({"Tiền mặt","Chuyển khoản"})
 void fullPrepaymentWithoutClaimingBookingCompleted(String method)throws Exception{
  var id=create(false);pay(id,260000,method);mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.conLai").value(0)).andExpect(jsonPath("$.data.invoice.hoanTatTaiChinh").value(false));
  write(admin,path(id)+"/payments",payment(1,method)).andExpect(status().isConflict());
 }
 @Test void partialPrepayServiceSupplementCheckoutAndBalance()throws Exception{
  var id=create(false);pay(id,200000,"Tiền mặt");open(id);
  write(admin,"/api/operations/bookings/"+id+"/api/services/SV03",Map.of("soLuong",1,"quyCach","LOC_6")).andExpect(status().isOk());
  mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.conLai").value(118200));
  write(admin,"/api/operations/bookings/"+id+"/check-out",Map.of()).andExpect(status().isOk());
  mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.hoanTatTaiChinh").value(false));
  var row=pay(id,118200,"Chuyển khoản");assertTrue(row.path("invoice").path("hoanTatTaiChinh").asBoolean());
  write(admin,"/api/operations/bookings/"+id+"/api/services/SV02",Map.of("soLuong",1)).andExpect(status().isConflict());
 }
 @Test void noPrepayCanPayAfterReturnAndConfirmedBookingMayBeUnpaid()throws Exception{
  var id=create(false);open(id);write(admin,path(id)+"/invoice",Map.of()).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.daThanhToan").value(0));
  write(admin,"/api/operations/bookings/"+id+"/check-out",Map.of()).andExpect(status().isOk());
  assertTrue(pay(id,260000,"Tiền mặt").path("invoice").path("hoanTatTaiChinh").asBoolean());
 }
 @Test void customerCannotSetSuccessAndOwnerAndRoleChecks()throws Exception{
  var id=create(false);var customer=login("khachhang");var body=payment(100000,"Chuyển khoản");
  write(customer,path(id)+"/payments",body).andExpect(status().isForbidden());
  write(customer,path(id)+"/payment-requests",body).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.daThanhToan").value(0));
  String payment=jdbc.queryForObject("SELECT MaTT FROM ThanhToan WHERE MaDatSan=?",String.class,id);
  write(customer,"/api/finance/payments/"+payment+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isForbidden());
  write(login("ketoan"),"/api/finance/payments/"+payment+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.daThanhToan").value(100000));
  jdbc.update("UPDATE DatSan SET MaKH='KH02' WHERE MaDatSan=?",id);mvc.perform(get(path(id)).session(customer)).andExpect(status().isForbidden());
  write(customer,path(id)+"/payment-requests",payment(10000,"Tiền mặt")).andExpect(status().isForbidden());
 }
 @Test void idempotencyReturnsOneReceiptAndRejectsChangedAmount()throws Exception{
  var id=create(false);var body=payment(100000,"Tiền mặt");for(int i=0;i<2;i++)write(admin,path(id)+"/payments",body).andExpect(status().isOk());
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
  var changed=new HashMap<>(body);changed.put("soTien",100001);write(admin,path(id)+"/payments",changed).andExpect(status().isConflict());
 }
 @Test void paymentRaceNeverExceedsBalance()throws Exception{
  var id=create(false);pay(id,160000,"Tiền mặt");var a=login("admin");var b=login("ketoan");
  assertEquals(List.of(200,409),race(() -> write(a,path(id)+"/payments",payment(100000,"Tiền mặt")).andReturn().getResponse().getStatus(),() -> write(b,path(id)+"/payments",payment(100000,"Chuyển khoản")).andReturn().getResponse().getStatus()));
  money("SELECT SUM(SoTien) FROM ThanhToan WHERE MaDatSan=? AND TrangThai=N'Thành công'",id,260000);
 }
 @ParameterizedTest @CsvSource({"10,1,100,200000","10,0,100,200000","9,59,50,100000","2,0,50,100000","1,59,0,0"})
 void cancellationExactDatetimeBoundariesOnActualPaid(int hours,int minutes,int rate,int refund)throws Exception{
  var cancelTime=day.atTime(13,0).minusHours(hours).minusMinutes(minutes);
  when(clock.instant()).thenReturn(cancelTime.minusHours(1).atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
  var id=create(true);write(admin,path(id)+"/invoice",Map.of("maKM",promo)).andExpect(status().isOk());pay(id,200000,"Tiền mặt");
  when(clock.instant()).thenReturn(cancelTime.atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
  write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Finance boundary test")).andExpect(status().isOk());
  money("SELECT TiLeHoan FROM HuyDatSan WHERE MaDatSan=?",id,rate);money("SELECT SoTienHoan FROM HuyDatSan WHERE MaDatSan=?",id,refund);
  assertEquals(refund==0?0:1,jdbc.queryForObject("SELECT COUNT(*) FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",Integer.class,id));
 }
 @Test void unpaidCancellationRefundsZeroAndClosesDebt()throws Exception{
  var id=create(false);write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Unpaid cancellation")).andExpect(status().isOk());
  money("SELECT SoTienHoan FROM HuyDatSan WHERE MaDatSan=?",id,0);mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.conLai").value(0));
 }
 @Test void refundRaceAndRetryHaveOneActualRefundAndAudit()throws Exception{
  when(clock.instant()).thenReturn(day.atTime(2,0).atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
  var id=create(false);pay(id,200000,"Tiền mặt");
  write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Refund test")).andExpect(status().isOk());
  String refund=jdbc.queryForObject("SELECT h.MaHT FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",String.class,id);
  var body=Map.of("phuongThuc","Chuyển khoản","daHoanTien",true,"lyDo","Đã hoàn thực tế");
  write(login("nvsan"),"/api/finance/refunds/"+refund+"/confirm",body).andExpect(status().isForbidden());
  write(login("khachhang"),"/api/finance/refunds/"+refund+"/confirm",body).andExpect(status().isForbidden());
  var accountant=login("ketoan");assertEquals(List.of(200,200),race(() -> write(admin,"/api/finance/refunds/"+refund+"/confirm",body).andReturn().getResponse().getStatus(),() -> write(accountant,"/api/finance/refunds/"+refund+"/confirm",body).andReturn().getResponse().getStatus()));
  write(admin,"/api/finance/refunds/"+refund+"/confirm",body).andExpect(status().isOk());
  money("SELECT SUM(h.SoTienHoan) FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=? AND h.TrangThai=N'Đã hoàn'",id,200000);
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE DoiTuong=? AND ChucNang=? AND NoiDungThayDoi LIKE ?",Integer.class,id,"Tài chính","Nhân viên xác nhận đã hoàn thực tế%"));
 }
 @Test void paymentAuditFailureRollsBackReceiptAndInvoice()throws Exception{
  var id=create(false);doThrow(new RuntimeException("Injected finance failure")).when(security).audit(anyString(),eq("Thêm"),eq("Tài chính"),eq(id),startsWith("Ghi nhận thực thu"));
  write(admin,path(id)+"/payments",payment(100000,"Tiền mặt")).andExpect(status().isInternalServerError());
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void cancelAuditFailureRollsBackStatusAndRefundRequest()throws Exception{
  var id=create(false);pay(id,200000,"Tiền mặt");doThrow(new RuntimeException("Injected cancel failure")).when(security).audit(anyString(),eq("Thêm"),eq("Tài chính"),eq(id),startsWith("Hủy;"));
  write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Rollback cancellation")).andExpect(status().isInternalServerError());
  assertEquals("Chờ xác nhận",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void completedBookingCannotCancelAndLegacyMoneyUntouched()throws Exception{
  var id=create(false);open(id);write(admin,"/api/operations/bookings/"+id+"/check-out",Map.of()).andExpect(status().isOk());
  write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Not allowed")).andExpect(status().isConflict());
  money("SELECT TongTien FROM DatSan WHERE MaDatSan=?","DS01",230000);money("SELECT TongTien FROM DatSan WHERE MaDatSan=?","DS02",300000);money("SELECT TongTien FROM DatSan WHERE MaDatSan=?","DS3b97491a",200000);
 }

 @Test void fullPrepaymentThenSupplementHasOnlyAdditionalBalance()throws Exception{
  var id=create(false);pay(id,260000,"Tiền mặt");open(id);
  write(admin,"/api/operations/bookings/"+id+"/api/services/SV02",Map.of("soLuong",1)).andExpect(status().isOk());
  mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.conLai").value(5000));
  write(admin,"/api/operations/bookings/"+id+"/check-out",Map.of()).andExpect(status().isOk());assertTrue(pay(id,5000,"Chuyển khoản").path("invoice").path("hoanTatTaiChinh").asBoolean());
 }
 @Test void overpaymentAndUnwitnessedReceiptRejected()throws Exception{
  var id=create(false);write(admin,path(id)+"/payments",payment(260001,"Tiền mặt")).andExpect(status().isConflict());
  var body=new HashMap<>(payment(10000,"Tiền mặt"));body.put("daNhanTien",false);write(admin,path(id)+"/payments",body).andExpect(status().isBadRequest());
 }
 @Test void refundAuditFailureRollsBackThenRetryWorks()throws Exception{
  var id=create(false);pay(id,200000,"Tiền mặt");write(admin,"/api/bookings/"+id+"/cancel",Map.of("lyDo","Rollback refund")).andExpect(status().isOk());
  String refund=jdbc.queryForObject("SELECT h.MaHT FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",String.class,id);
  var body=Map.of("phuongThuc","Tiền mặt","daHoanTien",true,"lyDo","Đã trả tiền thực tế");
  doThrow(new RuntimeException("Injected refund failure")).when(security).audit(anyString(),eq("Sửa"),eq("Tài chính"),eq(id),startsWith("Nhân viên xác nhận"));
  write(admin,"/api/finance/refunds/"+refund+"/confirm",body).andExpect(status().isInternalServerError());
  assertEquals("Chờ duyệt",jdbc.queryForObject("SELECT TrangThai FROM HoanTien WHERE MaHT=?",String.class,refund));reset(security);
  write(admin,"/api/finance/refunds/"+refund+"/confirm",body).andExpect(status().isOk());
 }
 @Test void legacyDiscountCannotBeRepriced()throws Exception{
  write(admin,"/api/finance/bookings/DS01/invoice",Map.of("maKM",promo)).andExpect(status().isConflict());money("SELECT TongTien FROM DatSan WHERE MaDatSan=?","DS01",230000);
 }
 void money(String sql,String id,int expected){assertEquals(0,BigDecimal.valueOf(expected).compareTo(jdbc.queryForObject(sql,BigDecimal.class,id)));}
 List<Integer> race(Callable<Integer> a,Callable<Integer> b)throws Exception{
  var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
  try{var f=pool.submit(() -> {start.await();return a.call();});var g=pool.submit(() -> {start.await();return b.call();});start.countDown();var r=new ArrayList<>(List.of(f.get(30,TimeUnit.SECONDS),g.get(30,TimeUnit.SECONDS)));Collections.sort(r);return r;}
  finally{start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
 }
}
