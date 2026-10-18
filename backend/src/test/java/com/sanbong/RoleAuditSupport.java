package com.sanbong;
import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Only transaction-local fixtures. No cleanup/delete and no password reset of existing users. */
@SpringBootTest @AutoConfigureMockMvc @Transactional
abstract class RoleAuditSupport {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc; @Autowired EntityManager em;
 final String marker="Role audit "+UUID.randomUUID();private String pitch;
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login(String username)throws Exception{return login(username,System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"));}
 MockHttpSession login(String username,String password)throws Exception{
  var r=mvc.perform(get("/auth/csrf")).andReturn();var c=data(r);
  return (MockHttpSession)mvc.perform(post("/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",username).param("password",password)).andExpect(status().isOk()).andReturn().getRequest().getSession();
 }
 ResultActions write(MockHttpSession session,String method,String path,Object body)throws Exception{
  var r=mvc.perform(get("/auth/csrf").session(session)).andReturn();var c=data(r);
  return mvc.perform(request(org.springframework.http.HttpMethod.valueOf(method),path).session(session).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));
 }
 String code(String prefix){return prefix+UUID.randomUUID().toString().replace("-","").substring(0,8);}
 String phone(){return "09"+String.format("%08d",new java.security.SecureRandom().nextInt(100000000));}
 LocalDate day(){return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(30);}
 String pitch(){if(pitch==null){pitch=code("RA");jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,N'Trống',?)",pitch,marker,"LS01",marker);}return pitch;}
 String customer(){return jdbc.queryForObject("SELECT MaKH FROM TaiKhoan WHERE TenDangNhap='khachhang'",String.class);}
 String book(MockHttpSession staff)throws Exception{return book(staff,"08:00","09:00");}
 String book(MockHttpSession staff,String start,String end)throws Exception{return data(write(staff,"POST","/bookings",Map.of("maSan",pitch(),"maKH",customer(),"ngayChoi",day().toString(),"gioBatDau",start,"gioKetThuc",end,"ghiChu",marker)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
 Map<String,Object> payment(int amount,String key){return Map.of("soTien",amount,"phuongThuc","Chuyển khoản","idempotencyKey",key,"daNhanTien",true);}
 Map<String,Object> employee(boolean active){return Map.of("hoTen",marker,"soDienThoai",phone(),"email","audit-"+UUID.randomUUID()+"@example.invalid","chucVu","Ca kiểm thử","boPhan","Nhân viên sân bóng","ngayVaoLam",LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).toString(),"trangThai",active);}
}
