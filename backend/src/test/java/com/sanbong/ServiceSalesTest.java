package com.sanbong;
import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest @AutoConfigureMockMvc @Transactional
class ServiceSalesTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc; @Autowired EntityManager em;
 String pitch; MockHttpSession admin;
 @BeforeEach void fixture() throws Exception {
  pitch="SB"+UUID.randomUUID().toString().replace("-","").substring(0,8);
  jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Service rollback","LS01","Trống","Phase5.1B test"); admin=login("admin");
 }
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login(String user)throws Exception{
  var r=mvc.perform(get("/auth/csrf")).andReturn();var s=(MockHttpSession)r.getRequest().getSession(false);var c=data(r);
  r=mvc.perform(post("/auth/login").session(s).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",user)
   .param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn();return (MockHttpSession)r.getRequest().getSession(false);
 }
 ResultActions write(MockHttpSession s,org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder req,Object body)throws Exception{
  var c=data(mvc.perform(get("/auth/csrf").session(s)).andReturn());return mvc.perform(req.session(s).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));
 }
 Map<String,Object> line(String sku,String pack,int qty){return Map.of("maDV",sku,"quyCach",pack,"soLuong",qty);}
 ResultActions create(MockHttpSession s,List<Map<String,Object>> lines)throws Exception{
  return write(s,post("/bookings"),Map.of("maSan",pitch,"maKH","KH01","ngayChoi",LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(25).toString(),"gioBatDau","08:00","gioKetThuc","09:00","dichVu",lines,"ghiChu","Phase5.1B test"));
 }
 String create(List<Map<String,Object>> lines)throws Exception{return data(create(admin,lines).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
 void open(String id){
  jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã xác nhận",id);
  jdbc.update("INSERT XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan) VALUES(?,?,?,GETDATE())",pitch,id,"NV01");em.clear();
 }
 String path(String id){return "/operations/bookings/"+id;}
 @Test void activeCatalogAccessibleToCustomerButOperationsDenied()throws Exception{
  var s=login("khachhang");mvc.perform(get("/booking-services").session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(13));
  mvc.perform(get("/service-catalog").session(s)).andExpect(status().isForbidden());mvc.perform(get("/services").session(s)).andExpect(status().isForbidden());
 }
 @ParameterizedTest @CsvSource({"SV02,DON_VI,5000","SV03,DON_VI,10000","SV03,LOC_6,58200","SV07,LOC_6,69840"})
 void snapshotsOfficialPrices(String sku,String pack,int price)throws Exception{
  var row=data(create(admin,List.of(line(sku,pack,2))).andExpect(status().isOk()).andReturn());assertEquals(price*2,row.path("tienDichVu").asInt());
  var l=jdbc.queryForMap("SELECT * FROM ChiTietDichVu WHERE MaDatSan=?",row.path("maDatSan").asText());
  assertEquals("DAT_TRUOC",l.get("Nguon"));assertEquals(pack,l.get("QuyCach"));assertEquals(0,new java.math.BigDecimal(price).compareTo((java.math.BigDecimal)l.get("DonGia")));
 }
 @ParameterizedTest @CsvSource({"SV01,LOC_6,1,400","SV03,DON_VI,0,400","SV03,DON_VI,-1,400","MISSING,DON_VI,1,404","SV03,BAD,1,400"})
 void rejectsInvalidSales(String sku,String pack,int qty,int code)throws Exception{create(admin,List.of(line(sku,pack,qty))).andExpect(status().is(code));}
 @Test void stoppedSkuRejected()throws Exception{jdbc.update("UPDATE DichVu SET TrangThai=0 WHERE MaDV='SV03'");create(admin,List.of(line("SV03","DON_VI",1))).andExpect(status().isConflict());}
 @Test void sourcePackAndPriceCreateIndependentLinesAndLegacyRouteRejectsAmbiguity()throws Exception{
  var id=create(List.of(line("SV03","DON_VI",1),line("SV03","LOC_6",1)));open(id);
  write(admin,post(path(id)+"/services/SV03"),Map.of("soLuong",1,"quyCach","DON_VI")).andExpect(status().isOk());
  write(admin,put("/service-catalog/SV03"),Map.of("donGia",11000,"trangThai",true,"hoTroLoc",true)).andExpect(status().isOk());
  write(admin,post(path(id)+"/services/SV03"),Map.of("soLuong",1,"quyCach","DON_VI")).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(89200));
  assertEquals(4,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaDatSan=?",Integer.class,id));
  write(admin,put(path(id)+"/services/SV03"),Map.of("soLuong",2)).andExpect(status().isConflict());write(admin,delete(path(id)+"/services/SV03"),Map.of()).andExpect(status().isConflict());
  long line=jdbc.queryForObject("SELECT MIN(MaChiTiet) FROM ChiTietDichVu WHERE MaDatSan=?",Long.class,id);
  write(admin,put(path(id)+"/service-lines/"+line),Map.of("soLuong",2)).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(99200));
  write(admin,delete(path(id)+"/service-lines/"+line),Map.of()).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(79200));
 }
 @Test void snapshotOldAndNewBookingAndCatalogRights()throws Exception{
  var id=create(List.of(line("SV03","DON_VI",1)));
  write(login("nvsan"),put("/service-catalog/SV03"),Map.of("donGia",11000,"trangThai",true,"hoTroLoc",true)).andExpect(status().isForbidden());
  write(admin,put("/service-catalog/SV03"),Map.of("donGia",11000,"trangThai",true,"hoTroLoc",true)).andExpect(status().isOk());
  assertEquals(0,new java.math.BigDecimal("10000").compareTo(jdbc.queryForObject("SELECT DonGia FROM ChiTietDichVu WHERE MaDatSan=?",java.math.BigDecimal.class,id)));
  jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã hủy",id);em.clear();
  var newer=create(List.of(line("SV03","DON_VI",1)));assertEquals(0,new java.math.BigDecimal("11000").compareTo(jdbc.queryForObject("SELECT DonGia FROM ChiTietDichVu WHERE MaDatSan=?",java.math.BigDecimal.class,newer)));
 }
 @Test void customerOwnershipCheckedAndStaffOperationsNeverOpened()throws Exception{
  var customer=login("khachhang");var id=data(create(customer,List.of(line("SV02","DON_VI",1))).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
  mvc.perform(get("/bookings/"+id+"/services").session(customer)).andExpect(status().isOk());
  write(customer,post(path(id)+"/services/SV02"),Map.of("soLuong",1)).andExpect(status().isForbidden());
  write(customer,put(path(id)+"/service-lines/1"),Map.of("soLuong",2)).andExpect(status().isForbidden());
  jdbc.update("UPDATE DatSan SET MaKH='KH02' WHERE MaDatSan=?",id);em.clear();mvc.perform(get("/bookings/"+id+"/services").session(customer)).andExpect(status().isForbidden());
 }
 @Test void closedServicesCannotBeEdited()throws Exception{
  var id=create(List.of(line("SV03","DON_VI",1)));open(id);jdbc.update("UPDATE XacNhanSan SET ThoiGianKetThuc=GETDATE() WHERE MaDatSan=?",id);em.clear();
  long l=jdbc.queryForObject("SELECT MaChiTiet FROM ChiTietDichVu WHERE MaDatSan=?",Long.class,id);
  write(admin,put(path(id)+"/service-lines/"+l),Map.of("soLuong",2)).andExpect(status().isConflict());
  write(admin,delete(path(id)+"/service-lines/"+l),Map.of()).andExpect(status().isConflict());
 }
 @Test void legacyRawLineKeepsRecordedMoneyAfterCatalogEdit()throws Exception{
  var id=create(List.of());jdbc.update("INSERT ChiTietDichVu(MaDatSan,MaDV,SoLuong,DonGiaLegacySnapshot) VALUES(?,'DV01',2,10000)",id);
  write(admin,put("/service-catalog/DV01"),Map.of("donGia",12000,"trangThai",true,"hoTroLoc",true)).andExpect(status().isOk());open(id);
  write(admin,put(path(id)+"/services/DV01"),Map.of("soLuong",3)).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(30000));
  assertEquals("LEGACY",jdbc.queryForObject("SELECT Nguon FROM ChiTietDichVu WHERE MaDatSan=?",String.class,id));
 }
 @Test void unsupportedPackCatalogAndInvalidPricesRejected()throws Exception{
  write(admin,put("/service-catalog/SV01"),Map.of("donGia",50000,"trangThai",true,"hoTroLoc",true)).andExpect(status().isBadRequest());
  write(admin,put("/service-catalog/SV03"),Map.of("donGia",0,"trangThai",true,"hoTroLoc",true)).andExpect(status().isBadRequest());
 }
}
