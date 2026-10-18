package com.sanbong;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class SecurityUpgradeIntegrationTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 private ResultActions login(String username, String password) throws Exception {
  var csrf=mvc.perform(get("/auth/csrf")).andExpect(status().isOk()).andReturn();
  var data=json.readTree(csrf.getResponse().getContentAsString()).path("data");
  return mvc.perform(post("/auth/login").session((MockHttpSession)csrf.getRequest().getSession())
    .header(data.path("headerName").asText(),data.path("token").asText())
    .param("identifier",username).param("password",password));
 }
 @ParameterizedTest @ValueSource(booleans={false,true})
 void loginRejectsLongAsciiAndUnicodeSuffixes(boolean unicode)throws Exception {
  String password=unicode ? "\u20ac".repeat(24) : "A".repeat(72);
  String username="f15_"+UUID.randomUUID().toString().substring(0,8);
  var csrf=mvc.perform(get("/auth/csrf")).andReturn();
  var data=json.readTree(csrf.getResponse().getContentAsString()).path("data");
  mvc.perform(post("/auth/register").session((MockHttpSession)csrf.getRequest().getSession())
    .header(data.path("headerName").asText(),data.path("token").asText()).contentType("application/json")
    .content(json.writeValueAsString(Map.of("hoTen","F15 security fixture","soDienThoai","0997150028","tenDangNhap",username,"matKhau",password))))
    .andExpect(status().isOk());
  String stored=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,username);
  login(username,password+(unicode ? "\u20ac" : "!")).andExpect(status().isUnauthorized());
  login(username,"B"+password.substring(1)).andExpect(status().isUnauthorized());
  var result=login(username,password).andExpect(status().isOk()).andReturn();
  String response=result.getResponse().getContentAsString();
  assertFalse(response.contains(password));assertFalse(response.contains(stored));
  var session=(MockHttpSession)result.getRequest().getSession();
  mvc.perform(get("/auth/me").session(session)).andExpect(status().isOk());
  mvc.perform(get("/admin/options").session(session)).andExpect(status().isForbidden());
  assertEquals(stored,jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,username));
 }
 @ParameterizedTest @CsvSource({"admin,VT04,/admin/options","nvsan,VT02,/pitches","ketoan,VT03,/finance/transactions","khachhang,VT01,/bookings"})
 void existingHashesRolesSessionsAndLogoutRemainCompatible(String username,String role,String endpoint)throws Exception {
  String stored=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,username);
  var result=login(username,System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456")).andExpect(status().isOk()).andReturn();
  assertEquals(role,json.readTree(result.getResponse().getContentAsString()).path("data").path("maVaiTro").asText());
  var session=(MockHttpSession)result.getRequest().getSession();
  mvc.perform(get(endpoint).param("date",java.time.LocalDate.now().toString()).session(session)).andExpect(status().isOk());
  mvc.perform(post("/auth/logout").session(session)).andExpect(status().isForbidden());
  var csrf=mvc.perform(get("/auth/csrf").session(session)).andReturn();
  var data=json.readTree(csrf.getResponse().getContentAsString()).path("data");
  mvc.perform(post("/auth/logout").session(session).header(data.path("headerName").asText(),data.path("token").asText())).andExpect(status().isOk());
  mvc.perform(get("/auth/me")).andExpect(status().isUnauthorized());
  assertEquals(stored,jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,username));
 }
 @Test void loginStillRequiresCsrfAndWrongPasswordFails()throws Exception {
  mvc.perform(post("/auth/login").param("identifier","admin").param("password",UUID.randomUUID().toString())).andExpect(status().isForbidden());
  login("admin",UUID.randomUUID().toString()).andExpect(status().isUnauthorized());
 }
}
