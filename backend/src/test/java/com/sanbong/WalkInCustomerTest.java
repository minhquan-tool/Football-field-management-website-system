package com.sanbong;
import com.fasterxml.jackson.databind.*;
import com.sanbong.repository.SecurityRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
@AuditCleanupFixture
class WalkInCustomerTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 @SpyBean SecurityRepository security;
 static final String MARKER="Fix04 walk-in fixture";
 String phone,pitch; MockHttpSession staff;
 @BeforeEach void setup()throws Exception{phone="094"+ThreadLocalRandom.current().nextLong(100000000000L,1000000000000L);pitch="F4"+UUID.randomUUID().toString().replace("-","").substring(0,8);staff=login("nvsan");}
 @AfterEach void cleanup(){
  reset(security);
  for(String id:jdbc.queryForList("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch)){
   assertEquals(MARKER,jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));jdbc.update("DELETE NhatKyHeThong WHERE DoiTuong=?",id);jdbc.update("DELETE DatSan WHERE MaDatSan=?",id);
  }
  if(jdbc.queryForObject("SELECT COUNT(*) FROM San WHERE MaSan=?",Integer.class,pitch)>0){assertEquals(MARKER,jdbc.queryForObject("SELECT MoTa FROM San WHERE MaSan=?",String.class,pitch));jdbc.update("DELETE San WHERE MaSan=?",pitch);}
  for(String id:jdbc.queryForList("SELECT MaKH FROM KhachHang WHERE SoDienThoai=?",String.class,phone)){
   assertEquals(MARKER,jdbc.queryForObject("SELECT HoTen FROM KhachHang WHERE MaKH=?",String.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan WHERE MaKH=?",Integer.class,id));jdbc.update("DELETE NhatKyHeThong WHERE DoiTuong=?",id);jdbc.update("DELETE KhachHang WHERE MaKH=?",id);
  }
 }
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login(String name)throws Exception{var r=mvc.perform(get("/api/auth/csrf")).andReturn();var c=data(r);return (MockHttpSession)mvc.perform(post("/api/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",name).param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn().getRequest().getSession();}
 ResultActions write(MockHttpSession s,String path,Object body)throws Exception{var req=get("/api/auth/csrf");if(s!=null)req.session(s);var r=mvc.perform(req).andReturn();var c=data(r);return mvc.perform(post(path).session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));}
 Map<String,String> customer(){return Map.of("hoTen",MARKER,"soDienThoai",phone);}
 String create()throws Exception{return data(write(staff,"/api/booking-customers",customer()).andExpect(status().isOk()).andReturn()).path("maKH").asText();}
 @Test void staffCreatesThenFindsCustomerWithoutWebsiteAccount()throws Exception{
  var rows=data(mvc.perform(get("/api/booking-customers").session(staff).param("phone",phone)).andExpect(status().isOk()).andReturn());assertTrue(rows.isEmpty());
  int accounts=jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class);
  var c=data(write(staff,"/api/booking-customers",Map.of("hoTen","  "+MARKER+"  ","soDienThoai","  "+phone+"  ")).andExpect(status().isOk()).andReturn());String id=c.path("maKH").asText();assertTrue(id.startsWith("KH"));assertEquals(Set.of("maKH","hoTen","soDienThoai"),json.convertValue(c,Map.class).keySet());assertEquals(MARKER,c.path("hoTen").asText());
  assertEquals(accounts,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class));assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE MaKH=? AND SoDienThoai=?",Integer.class,id,phone));
  var found=data(mvc.perform(get("/api/booking-customers").session(staff).param("phone",phone)).andExpect(status().isOk()).andReturn());assertEquals(id,found.get(0).path("maKH").asText());
 }
 @Test void adminCanCreate()throws Exception{write(login("admin"),"/api/booking-customers",customer()).andExpect(status().isOk());}
 @Test void repeatedPhoneIsConflictAndKeepsOriginalCustomer()throws Exception{String id=create();write(staff,"/api/booking-customers",Map.of("hoTen","Different name","soDienThoai",phone)).andExpect(status().isConflict());assertEquals(id,jdbc.queryForObject("SELECT MaKH FROM KhachHang WHERE SoDienThoai=?",String.class,phone));assertEquals(MARKER,jdbc.queryForObject("SELECT HoTen FROM KhachHang WHERE MaKH=?",String.class,id));}
 @Test void concurrentStaffCreatesOnlyOneCustomer()throws Exception{
  var other=login("nvsan");var ready=new CountDownLatch(2);var go=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
  try{var a=pool.submit(()->{ready.countDown();assertTrue(go.await(10,TimeUnit.SECONDS));return write(staff,"/api/booking-customers",customer()).andReturn().getResponse().getStatus();});var b=pool.submit(()->{ready.countDown();assertTrue(go.await(10,TimeUnit.SECONDS));return write(other,"/api/booking-customers",customer()).andReturn().getResponse().getStatus();});assertTrue(ready.await(10,TimeUnit.SECONDS));go.countDown();var statuses=new ArrayList<>(List.of(a.get(30,TimeUnit.SECONDS),b.get(30,TimeUnit.SECONDS)));Collections.sort(statuses);assertEquals(List.of(200,409),statuses);assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE SoDienThoai=?",Integer.class,phone));}finally{go.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
 }
 @ParameterizedTest @CsvSource({"khachhang","ketoan"}) void otherRolesAreForbidden(String role)throws Exception{write(login(role),"/api/booking-customers",customer()).andExpect(status().isForbidden());assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE SoDienThoai=?",Integer.class,phone));}
 @Test void anonymousIsUnauthorized()throws Exception{write(null,"/api/booking-customers",customer()).andExpect(status().isUnauthorized());}
 @ParameterizedTest @CsvSource(value={"'',123456789","'   ',123456789","Name,''","Name,123456","Name,abcdefghi","Name,1234567890123456"},emptyValue="")
 void invalidInputIs400(String name,String value)throws Exception{write(staff,"/api/booking-customers",Map.of("hoTen",name,"soDienThoai",value)).andExpect(status().isBadRequest());}
 @Test void missingFieldsAndLongNameAre400()throws Exception{write(staff,"/api/booking-customers",Map.of()).andExpect(status().isBadRequest());write(staff,"/api/booking-customers",Map.of("hoTen","x".repeat(101),"soDienThoai",phone)).andExpect(status().isBadRequest());}
 @Test void newCustomerCanBookWithFutureOverlapAndMaintenanceGuards()throws Exception{
  String id=create();jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,MARKER,"LS01","Đang sử dụng",MARKER);
  var day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(30);var body=Map.of("maSan",pitch,"maKH",id,"ngayChoi",day.toString(),"gioBatDau","08:00","gioKetThuc","09:00","ghiChu",MARKER);
  String booking=data(write(staff,"/api/bookings",body).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();assertEquals(id,jdbc.queryForObject("SELECT MaKH FROM DatSan WHERE MaDatSan=?",String.class,booking));write(staff,"/api/bookings",body).andExpect(status().isConflict());
  jdbc.update("UPDATE San SET TrangThai=N'Bảo trì' WHERE MaSan=?",pitch);var next=new HashMap<String,Object>(body);next.put("ngayChoi",day.plusDays(1).toString());write(staff,"/api/bookings",next).andExpect(status().isConflict());assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE SoDienThoai=?",Integer.class,phone));
 }
 @Test void auditFailureRollsBackCustomerCreate()throws Exception{doThrow(new org.springframework.dao.DataAccessResourceFailureException("test failure")).when(security).audit(anyString(),eq("Thêm"),eq("Đặt sân"),anyString(),eq("Tạo hồ sơ khách tại quầy"));write(staff,"/api/booking-customers",customer()).andExpect(status().isServiceUnavailable());assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE SoDienThoai=?",Integer.class,phone));}
}
