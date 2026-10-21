package com.sanbong;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sanbong.config.InternalReadiness;
import com.sanbong.service.RuntimeSafetyService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
@ExtendWith(OutputCaptureExtension.class)
class PasswordPolicyIntegrationTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 @Autowired PasswordEncoder encoder;
 private ResultActions write(MockHttpSession session,String path,Object body)throws Exception{
  var request=get("/api/auth/csrf");if(session!=null)request.session(session);
  var r=mvc.perform(request).andReturn();var c=json.readTree(r.getResponse().getContentAsString()).path("data");
  return mvc.perform(post(path).session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));
 }
 private MockHttpSession admin()throws Exception{
  var r=mvc.perform(get("/api/auth/csrf")).andReturn();var c=json.readTree(r.getResponse().getContentAsString()).path("data");
  return (MockHttpSession)mvc.perform(post("/api/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier","admin").param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn().getRequest().getSession();
 }
 private Map<String,Object> registration(String password){return Map.of("hoTen","Fix01 policy fixture","soDienThoai","0997100283","tenDangNhap","fix01_"+UUID.randomUUID().toString().substring(0,8),"matKhau",password);}
 private void startupAccepts(String hash){
  var safety=mock(RuntimeSafetyService.class);when(safety.databaseEnvironment()).thenReturn("internal");
  var db=mock(JdbcTemplate.class);when(db.queryForMap(anyString())).thenReturn(Map.of("admin",0,"owner",0));when(db.queryForList(anyString(),eq(String.class))).thenReturn(List.of(hash));
  assertDoesNotThrow(()->new InternalReadiness(safety,db,new MockEnvironment().withProperty("spring.jpa.hibernate.ddl-auto","validate"),encoder).afterPropertiesSet());
 }
 @ParameterizedTest @ValueSource(strings={"123456","12345678","admin","password","demo123","NineChars"})
 void registerRejectsInvalidPasswordWithoutCreatingRows(String password)throws Exception{
  int accounts=jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class),customers=jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang",Integer.class);
  write(null,"/api/auth/register",registration(password)).andExpect(status().isBadRequest());
  assertEquals(accounts,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class));assertEquals(customers,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang",Integer.class));
 }
 @Test void validRegisterHashesAndPassesStartupWithoutLeaking(CapturedOutput output)throws Exception{
  String password=UUID.randomUUID().toString();var body=registration(password);
  String response=write(null,"/api/auth/register",body).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
  String hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,body.get("tenDangNhap"));assertTrue(encoder.matches(password,hash));startupAccepts(hash);
  assertFalse(response.contains(password));assertFalse(response.contains(hash));assertFalse(response.toLowerCase().contains("matkhau"));assertFalse(output.getAll().contains(password));assertFalse(output.getAll().contains(hash));
  assertTrue(jdbc.queryForList("SELECT NoiDungThayDoi FROM NhatKyHeThong WHERE MaTK=(SELECT MaTK FROM TaiKhoan WHERE TenDangNhap=?)",String.class,body.get("tenDangNhap")).stream().noneMatch(s->s.contains(password)||s.contains(hash)));
 }
 @Test void createAndResetEnforcePolicyAndKeepHashesPrivate(CapturedOutput output)throws Exception{
  var session=admin();var e=write(session,"/api/admin/employees",Map.of("hoTen","Fix01 policy fixture","trangThai",true,"ngayVaoLam",java.time.LocalDate.now().toString())).andExpect(status().isOk()).andReturn();
  String nv=json.readTree(e.getResponse().getContentAsString()).path("data").path("MaNV").asText(),username="f01_"+UUID.randomUUID().toString().substring(0,8);
  int count=jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class);
  write(session,"/api/admin/accounts",Map.of("maNV",nv,"tenDangNhap",username,"maVaiTro","VT02","matKhau","12345678")).andExpect(status().isBadRequest());assertEquals(count,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class));
  String password=UUID.randomUUID().toString();var result=write(session,"/api/admin/accounts",Map.of("maNV",nv,"tenDangNhap",username,"maVaiTro","VT02","matKhau",password)).andExpect(status().isOk()).andReturn();
  String tk=json.readTree(result.getResponse().getContentAsString()).path("data").path("MaTK").asText(),hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE MaTK=?",String.class,tk);assertTrue(encoder.matches(password,hash));startupAccepts(hash);assertFalse(result.getResponse().getContentAsString().contains(hash));
  write(session,"/api/admin/accounts/"+tk+"/reset-password",Map.of("matKhau","12345678")).andExpect(status().isBadRequest());assertEquals(hash,jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE MaTK=?",String.class,tk));
  String next=UUID.randomUUID().toString();var reset=write(session,"/api/admin/accounts/"+tk+"/reset-password",Map.of("matKhau",next)).andExpect(status().isOk()).andReturn();String nextHash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE MaTK=?",String.class,tk);assertTrue(encoder.matches(next,nextHash));startupAccepts(nextHash);
  String api=mvc.perform(get("/api/security/accounts").session(session)).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();for(String secret:List.of(password,next,hash,nextHash)){assertFalse(api.contains(secret));assertFalse(reset.getResponse().getContentAsString().contains(secret));assertFalse(output.getAll().contains(secret));assertTrue(jdbc.queryForList("SELECT NoiDungThayDoi FROM NhatKyHeThong WHERE DoiTuong=?",String.class,tk).stream().noneMatch(s->s.contains(secret)));}
 }
 @ParameterizedTest @ValueSource(strings={"ắắắắắắắắắắắắắắắắắắắắắắắắắ","aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"})
 void registerRejectsBeyondBcryptByteBoundary(String password)throws Exception{write(null,"/api/auth/register",registration(password)).andExpect(status().isBadRequest());}
 @Test void registerAcceptsExactly72Utf8Bytes()throws Exception{
  String password="ắ".repeat(24);assertEquals(72,password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length);var body=registration(password);write(null,"/api/auth/register",body).andExpect(status().isOk());String hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,body.get("tenDangNhap"));assertTrue(encoder.matches(password,hash));startupAccepts(hash);
 }
}
