package com.sanbong;

import com.fasterxml.jackson.databind.*;
import com.sanbong.repository.*;
import com.sanbong.service.FinanceService;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
@AuditCleanupFixture
class CheckoutSnapshotTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 @Autowired FinanceService finance; @Autowired com.sanbong.repository.DatSanRepository bookings;
 @Autowired PlatformTransactionManager tx;
 @MockBean Clock clock; @SpyBean SecurityRepository security; @SpyBean FinanceRepository repository;
 String pitch,promo; LocalDate day; MockHttpSession admin;
 static final String MARKER="Fix02 checkout snapshot fixture";
 @BeforeEach void setup()throws Exception{
  pitch="F2"+UUID.randomUUID().toString().replace("-","").substring(0,8);promo=pitch;day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(20);
  when(clock.instant()).thenReturn(day.atTime(8,0).atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
  jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,MARKER,"LS01","Trống",MARKER);
  jdbc.update("INSERT KhuyenMai(MaKM,TenKM,LoaiGiam,MucGiam,NgayBatDau,NgayKetThuc,TrangThai) VALUES(?,?,?,10,?,?,1)",promo,MARKER,"Phần trăm",day.minusDays(1),day.plusDays(1));admin=login("admin");
 }
 @AfterEach void cleanup(){
  reset(security,repository,clock);assertEquals(MARKER,jdbc.queryForObject("SELECT MoTa FROM San WHERE MaSan=?",String.class,pitch));
  for(String id:jdbc.queryForList("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch)){
   assertEquals(MARKER,jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));
   jdbc.update("DELETE h FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=?",id);
   for(String table:List.of("ThanhToan","HuyDatSan","ChiTietDichVu","HoaDon","XacNhanSan"))jdbc.update("DELETE FROM "+table+" WHERE MaDatSan=?",id);
   jdbc.update("DELETE NhatKyHeThong WHERE DoiTuong=?",id);jdbc.update("DELETE DatSan WHERE MaDatSan=?",id);
  }jdbc.update("DELETE San WHERE MaSan=?",pitch);jdbc.update("DELETE KhuyenMai WHERE MaKM=?",promo);
 }
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login(String name)throws Exception{
  var r=mvc.perform(get("/auth/csrf")).andReturn();var c=data(r);return (MockHttpSession)mvc.perform(post("/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",name).param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn().getRequest().getSession();
 }
 ResultActions write(MockHttpSession s,String path,Object body)throws Exception{var c=data(mvc.perform(get("/auth/csrf").session(s)).andReturn());return mvc.perform(post(path).session(s).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));}
 String create(boolean services)throws Exception{
  var b=new HashMap<String,Object>(Map.of("maSan",pitch,"maKH","KH01","ngayChoi",day.toString(),"gioBatDau","13:00","gioKetThuc","15:00","ghiChu",MARKER));if(services)b.put("dichVu",List.of(Map.of("maDV","SV03","soLuong",1,"quyCach","LOC_6")));
  return data(write(admin,"/bookings",b).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
 }
 // Controlled DEV fixture visit, like existing FinanceIntegrationTest; no production clock/data changes.
 void open(String id)throws Exception{write(admin,"/bookings/"+id+"/confirm",Map.of()).andExpect(status().isOk());jdbc.update("INSERT XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan) VALUES(?,?,?,?)",pitch,id,"NV01",LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")));jdbc.update("UPDATE San SET TrangThai=N'Đang sử dụng' WHERE MaSan=?",pitch);}
 String path(String id){return "/finance/bookings/"+id;}
 String checkout(String id){return "/operations/bookings/"+id+"/check-out";}
 Map<String,Object> snapshot(String id){return jdbc.queryForMap("SELECT DonGia,TienSan,TienDichVu,TienGiam,TongTien FROM DatSan WHERE MaDatSan=?",id);}
 BigDecimal revenue(){return jdbc.queryForObject("SELECT ISNULL(SUM(DoanhThu),0) FROM V_Phase6_Revenue WHERE MaSan=?",BigDecimal.class,pitch);}
 Map<String,Object> payment(int n,String method){return Map.of("soTien",n,"phuongThuc",method,"idempotencyKey",UUID.randomUUID().toString(),"daNhanTien",true);}
 void assertSealed(String id)throws Exception{mvc.perform(get(path(id)).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.daChot").value(true));assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));}
 @Test void checkoutWithoutInvoiceCreatesUnpaidFinalSnapshot()throws Exception{
  String id=create(true);open(id);var before=snapshot(id);assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));write(admin,checkout(id),Map.of()).andExpect(status().isOk());assertSealed(id);assertEquals(before,snapshot(id));mvc.perform(get(path(id)).session(admin)).andExpect(jsonPath("$.data.invoice.daThanhToan").value(0)).andExpect(jsonPath("$.data.invoice.conLai").value(318200)).andExpect(jsonPath("$.data.invoice.hoanTatTaiChinh").value(false));
 }
 @Test void promotionAfterCheckoutIs409AndCannotChangeRevenue()throws Exception{
  String id=create(false);open(id);write(admin,checkout(id),Map.of()).andExpect(status().isOk());var before=snapshot(id);var rev=revenue();for(int i=0;i<2;i++)write(admin,path(id)+"/invoice",Map.of("maKM",promo)).andExpect(status().isConflict());assertEquals(before,snapshot(id));assertEquals(rev,revenue());
 }
 @Test void repeatInvoiceSyncAndPostpaymentKeepFinalAmounts()throws Exception{
  String id=create(true);open(id);write(admin,checkout(id),Map.of()).andExpect(status().isOk());var before=snapshot(id);var rev=revenue();
  for(int i=0;i<2;i++)write(admin,path(id)+"/invoice",Map.of("tongTien",1)).andExpect(status().isOk());new TransactionTemplate(tx).executeWithoutResult(s->finance.sync(bookings.findById(id).orElseThrow()));
  var accountant=login("ketoan");var pay=payment(318200,"Chuyển khoản");for(int i=0;i<2;i++)write(accountant,path(id)+"/payments",pay).andExpect(status().isOk());assertSealed(id);assertEquals(before,snapshot(id));assertEquals(rev,revenue());assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));mvc.perform(get(path(id)).session(admin)).andExpect(jsonPath("$.data.invoice.hoanTatTaiChinh").value(true));
 }
 @Test void partialPrepayThenCheckoutAndBalanceDoNotChangeRevenue()throws Exception{
  String id=create(false);write(admin,path(id)+"/payments",payment(100000,"Tiền mặt")).andExpect(status().isOk());open(id);write(admin,checkout(id),Map.of()).andExpect(status().isOk());var before=snapshot(id);var rev=revenue();write(login("ketoan"),path(id)+"/payments",payment(160000,"Chuyển khoản")).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.conLai").value(0));assertEquals(before,snapshot(id));assertEquals(rev,revenue());assertSealed(id);
 }
 @Test void servicesAndDoubleCheckoutAreRejectedAfterReturn()throws Exception{
  String id=create(true);open(id);write(admin,checkout(id),Map.of()).andExpect(status().isOk());var before=snapshot(id);var lines=jdbc.queryForList("SELECT * FROM ChiTietDichVu WHERE MaDatSan=?",id);write(admin,checkout(id),Map.of()).andExpect(status().isConflict());write(admin,"/operations/bookings/"+id+"/services/SV02",Map.of("soLuong",1)).andExpect(status().isConflict());var c=data(mvc.perform(get("/auth/csrf").session(admin)).andReturn());
  mvc.perform(put("/operations/bookings/"+id+"/services/SV03").session(admin).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content("{\"soLuong\":2}")).andExpect(status().isConflict());
  mvc.perform(delete("/operations/bookings/"+id+"/services/SV03").session(admin).header(c.path("headerName").asText(),c.path("token").asText())).andExpect(status().isConflict());assertEquals(before,snapshot(id));assertEquals(lines,jdbc.queryForList("SELECT * FROM ChiTietDichVu WHERE MaDatSan=?",id));assertSealed(id);
 }
 @ParameterizedTest @ValueSource(strings={"invoice","promotion","service","payment","checkout"})
 void concurrentCheckoutSerializesAllFinancialMutations(String action)throws Exception{
  String id=create(false);open(id);var other=login("admin");var executor=Executors.newFixedThreadPool(2);var start=new CountDownLatch(1);
  try{var a=executor.submit(()->{start.await();return write(admin,checkout(id),Map.of()).andReturn().getResponse().getStatus();});var b=executor.submit(()->{start.await();return switch(action){case "invoice"->write(other,path(id)+"/invoice",Map.of()).andReturn().getResponse().getStatus();case "promotion"->write(other,path(id)+"/invoice",Map.of("maKM",promo)).andReturn().getResponse().getStatus();case "service"->write(other,"/operations/bookings/"+id+"/services/SV02",Map.of("soLuong",1)).andReturn().getResponse().getStatus();case "payment"->write(other,path(id)+"/payments",payment(70000,"Tiền mặt")).andReturn().getResponse().getStatus();default->write(other,checkout(id),Map.of()).andReturn().getResponse().getStatus();};});start.countDown();int x=a.get(30,TimeUnit.SECONDS),y=b.get(30,TimeUnit.SECONDS);if(action.equals("checkout"))assertEquals(Set.of(200,409),Set.of(x,y));else{assertEquals(200,x);assertTrue(y==200||y==409);if(action.equals("invoice")||action.equals("payment"))assertEquals(200,y);}
  }finally{executor.shutdownNow();}
  assertSealed(id);var before=snapshot(id);var rev=revenue();write(admin,path(id)+"/invoice",Map.of("maKM",promo)).andExpect(status().isConflict());assertEquals(before,snapshot(id));assertEquals(rev,revenue());assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=? AND ThoiGianKetThuc IS NOT NULL",Integer.class,id));
 }
 @ParameterizedTest @ValueSource(strings={"invoice","audit"})
 void checkoutFailureRollsBackVisitPitchBookingAndInvoice(String failure)throws Exception{
  String id=create(false);open(id);var before=snapshot(id);
  if(failure.equals("invoice"))doThrow(new org.springframework.dao.DataAccessResourceFailureException("test failure")).when(repository).invoiceCreate(eq(id),anyString(),any(),any(),any(),any());
  else doThrow(new org.springframework.dao.DataAccessResourceFailureException("test failure")).when(security).audit(anyString(),eq("Sửa"),eq("Nhận sân / Dịch vụ"),eq(id),anyString());
  write(admin,checkout(id),Map.of()).andExpect(status().isServiceUnavailable());reset(security,repository);assertEquals(before,snapshot(id));assertEquals("Đã xác nhận",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,id));assertEquals("Đang sử dụng",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,pitch));assertNull(jdbc.queryForObject("SELECT ThoiGianKetThuc FROM XacNhanSan WHERE MaDatSan=?",Object.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));write(admin,checkout(id),Map.of()).andExpect(status().isOk());assertSealed(id);
 }
 @Test void pendingConfirmationAfterCheckoutDoesNotChangePriceOrRevenue()throws Exception{
  String id=create(false);open(id);write(admin,checkout(id),Map.of()).andExpect(status().isOk());var before=snapshot(id);var rev=revenue();
  var request=data(write(login("khachhang"),path(id)+"/payment-requests",payment(130000,"Chuyển khoản")).andExpect(status().isOk()).andReturn());assertEquals(0,request.path("invoice").path("daThanhToan").decimalValue().signum());String tt=request.path("payments").get(0).path("maTT").asText();
  var accountant=login("ketoan");for(int i=0;i<2;i++)write(accountant,"/finance/payments/"+tt+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isOk());assertEquals(before,snapshot(id));assertEquals(rev,revenue());assertSealed(id);
 }
 @Test void validRefundUsesActualPaidAndCannotChangeCompletedRevenue()throws Exception{
  String completed=create(false);open(completed);write(admin,checkout(completed),Map.of()).andExpect(status().isOk());var rev=revenue();
  String other=data(write(admin,"/bookings",Map.of("maSan",pitch,"maKH","KH01","ngayChoi",day.toString(),"gioBatDau","15:00","gioKetThuc","17:00","ghiChu",MARKER)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
  write(admin,path(other)+"/payments",payment(70000,"Tiền mặt")).andExpect(status().isOk());var before=snapshot(other);write(admin,"/bookings/"+other+"/cancel",Map.of("lyDo",MARKER)).andExpect(status().isOk());var detail=data(mvc.perform(get(path(other)).session(admin)).andReturn());assertEquals(0,new BigDecimal("35000").compareTo(detail.path("refunds").get(0).path("soTienHoan").decimalValue()));String ht=detail.path("refunds").get(0).path("maHT").asText();
  var accountant=login("ketoan");for(int i=0;i<2;i++)write(accountant,"/finance/refunds/"+ht+"/confirm",Map.of("phuongThuc","Tiền mặt","lyDo",MARKER,"daHoanTien",true)).andExpect(status().isOk());assertEquals(before,snapshot(other));assertEquals(rev,revenue());assertEquals(0,new BigDecimal("35000").compareTo(repository.refunded(other)));
 }
 @Test void historicalReturnedBookingWithoutInvoiceCannotReceivePromotion()throws Exception{
  String id=create(false);open(id);
  // Dedicated fixture represents a pre-fix checkout without invoice; never mutates existing history.
  jdbc.update("UPDATE XacNhanSan SET ThoiGianKetThuc=? WHERE MaDatSan=?",LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")),id);jdbc.update("UPDATE DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=?",id);jdbc.update("UPDATE San SET TrangThai=N'Trống' WHERE MaSan=?",pitch);
  var before=snapshot(id);var rev=revenue();write(admin,path(id)+"/invoice",Map.of("maKM",promo)).andExpect(status().isConflict());assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));write(admin,path(id)+"/invoice",Map.of()).andExpect(status().isOk());assertSealed(id);assertEquals(before,snapshot(id));assertEquals(rev,revenue());
 }
}
