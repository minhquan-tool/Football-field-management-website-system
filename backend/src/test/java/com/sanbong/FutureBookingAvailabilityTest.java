package com.sanbong;

import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
@AuditCleanupFixture
class FutureBookingAvailabilityTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
 static final String MARKER="Fix03 future booking fixture";
 String pitch; LocalDate tomorrow,day; MockHttpSession staff;
 @BeforeEach void setup()throws Exception{
  pitch="F3"+UUID.randomUUID().toString().replace("-","").substring(0,8);
  tomorrow=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(1);day=tomorrow.plusDays(29);
  // Minimal fixture isolates the current operating-status bug; live check-in is covered by the separate HTTP flow.
  jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,MARKER,"LS01","Đang sử dụng",MARKER);staff=login();
 }
 @AfterEach void cleanup(){
  assertEquals(MARKER,jdbc.queryForObject("SELECT MoTa FROM San WHERE MaSan=?",String.class,pitch));
  for(String id:jdbc.queryForList("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch)){
   assertEquals(MARKER,jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));
   assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
   jdbc.update("DELETE NhatKyHeThong WHERE DoiTuong=?",id);jdbc.update("DELETE DatSan WHERE MaDatSan=?",id);
  }jdbc.update("DELETE San WHERE MaSan=?",pitch);
 }
 JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
 MockHttpSession login()throws Exception{
  var r=mvc.perform(get("/api/auth/csrf")).andReturn();var c=data(r);return (MockHttpSession)mvc.perform(post("/api/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier","nvsan").param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn().getRequest().getSession();
 }
 ResultActions write(MockHttpSession s,String path,Object body)throws Exception{
  var c=data(mvc.perform(get("/api/auth/csrf").session(s)).andReturn());return mvc.perform(post(path).session(s).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));
 }
 Map<String,Object> body(LocalDate date,String start,String end){return Map.of("maSan",pitch,"maKH","KH01","ngayChoi",date.toString(),"gioBatDau",start,"gioKetThuc",end,"ghiChu",MARKER);}
 String create(LocalDate date,String start,String end)throws Exception{return data(write(staff,"/api/bookings",body(date,start,end)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
 JsonNode available(LocalDate date,String start,String end,String state)throws Exception{
  var req=get("/api/availability").session(staff).param("date",date.toString()).param("start",start).param("end",end);if(state!=null)req.param("status",state);
  return data(mvc.perform(req).andExpect(status().isOk()).andReturn());
 }
 boolean contains(JsonNode rows){for(var row:rows)if(pitch.equals(row.path("maSan").asText()))return true;return false;}
 void operating(){assertEquals("Đang sử dụng",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,pitch));}
 @Test void currentlyUsedPitchCanBeBookedTomorrow()throws Exception{create(tomorrow,"08:00","09:00");operating();}
 @Test void currentlyUsedPitchAppearsThirtyDaysAhead()throws Exception{assertTrue(contains(available(day,"08:00","09:00",null)));}
 @Test void futureConfirmationDoesNotChangeCurrentOperatingStatus()throws Exception{String id=create(day,"08:00","09:00");write(staff,"/api/bookings/"+id+"/confirm",Map.of()).andExpect(status().isOk());operating();}
 @Test void futureOverlapIsConflictAndUnavailable()throws Exception{
  create(day,"08:00","09:00");assertFalse(contains(available(day,"08:30","09:30",null)));write(staff,"/api/bookings",body(day,"08:30","09:30")).andExpect(status().isConflict());assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,pitch));
 }
 @Test void adjacentFutureBookingAndOtherDateAreAvailable()throws Exception{
  create(day,"08:00","09:00");assertTrue(contains(available(day,"09:00","10:00",null)));create(day,"09:00","10:00");assertTrue(contains(available(day.plusDays(1),"08:00","09:00",null)));operating();
 }
 @Test void maintenanceBlocksAvailabilityCreationAndConfirmation()throws Exception{
  jdbc.update("UPDATE San SET TrangThai=N'Trống' WHERE MaSan=?",pitch);String id=create(day,"08:00","09:00");
  // Dedicated fixture models a maintained pitch with a pending booking, not a production maintenance transition.
  jdbc.update("UPDATE San SET TrangThai=N'Bảo trì' WHERE MaSan=?",pitch);
  assertFalse(contains(available(day.plusDays(1),"08:00","09:00",null)));write(staff,"/api/bookings",body(day.plusDays(1),"08:00","09:00")).andExpect(status().isConflict());write(staff,"/api/bookings/"+id+"/confirm",Map.of()).andExpect(status().isConflict());
 }
 @Test void explicitOperatingStatusFilterStillFilters()throws Exception{
  assertTrue(contains(available(day,"08:00","09:00","Đang sử dụng")));assertFalse(contains(available(day,"08:00","09:00","Trống")));
  mvc.perform(get("/api/availability").session(staff).param("date",day.toString()).param("start","08:00").param("end","09:00").param("status","invalid")).andExpect(status().isBadRequest());
 }
 @Test void freeLaterIntervalTodayIsNotBlockedByCurrentStatus()throws Exception{
  var today=tomorrow.minusDays(1);var now=LocalTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));var start=now.isBefore(LocalTime.of(20,0))?LocalTime.of(20,0):now.plusMinutes(1).withSecond(0).withNano(0);
  // Near closing there is no future interval left today; use tomorrow without weakening time validation.
  if(!start.isBefore(LocalTime.of(21,59))){today=tomorrow;start=LocalTime.of(20,0);}
  create(today,start.toString(),start.plusMinutes(1).toString());operating();
 }
 @ParameterizedTest @CsvSource({"06:59,08:00","21:00,22:01","22:00,22:01","09:00,09:00","10:00,09:00"})
 void timeBoundariesStayRejected(String start,String end)throws Exception{write(staff,"/api/bookings",body(day,start,end)).andExpect(status().isBadRequest());mvc.perform(get("/api/availability").session(staff).param("date",day.toString()).param("start",start).param("end",end)).andExpect(status().isBadRequest());}
 void race(boolean overlap)throws Exception{
  var other=login();var ready=new CountDownLatch(2);var go=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
  try{
   var a=pool.submit(()->{ready.countDown();assertTrue(go.await(10,TimeUnit.SECONDS));return write(staff,"/api/bookings",body(day,"08:00","09:00")).andReturn().getResponse().getStatus();});
   var b=pool.submit(()->{ready.countDown();assertTrue(go.await(10,TimeUnit.SECONDS));return write(other,"/api/bookings",body(day,overlap?"08:00":"09:00",overlap?"09:00":"10:00")).andReturn().getResponse().getStatus();});
   assertTrue(ready.await(10,TimeUnit.SECONDS));go.countDown();var statuses=new ArrayList<>(List.of(a.get(30,TimeUnit.SECONDS),b.get(30,TimeUnit.SECONDS)));Collections.sort(statuses);assertEquals(overlap?List.of(200,409):List.of(200,200),statuses);
   assertEquals(overlap?1:2,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,pitch));operating();
  }finally{go.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
 }
 @Test void concurrentSameFutureIntervalCreatesOnlyOneBooking()throws Exception{race(true);}
 @Test void concurrentDisjointFutureIntervalsBothSucceed()throws Exception{race(false);}
}
