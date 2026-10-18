package com.sanbong;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.mock.web.MockHttpSession;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Read-only timetable endpoints; setup writes are DEV-only transaction fixtures. */
class WeeklyScheduleTest extends RoleAuditSupport {
 final String endpoint="/staff/weekly-schedule";
 @Autowired PasswordEncoder encoder;
 String staffName,staffPassword;
 @BeforeEach void temporaryStaff(){String employee=code("WN");staffName=code("wk");staffPassword="Weekly-"+UUID.randomUUID();jdbc.update("INSERT NhanVien(MaNV,HoTen,SoDienThoai,Email,ChucVu,BoPhan,NgayVaoLam,TrangThai) VALUES(?,?,?,?,?,?,?,1)",employee,marker,phone(),staffName+"@example.invalid","Ca kiểm thử","Nhân viên sân bóng",LocalDate.now());jdbc.update("INSERT TaiKhoan(MaTK,TenDangNhap,MatKhau,MaVaiTro,MaNV,TrangThai) VALUES(?,?,?,'VT02',?,N'Hoạt động')",code("WT"),staffName,encoder.encode(staffPassword),employee);}
 MockHttpSession staff()throws Exception{return login(staffName,staffPassword);}
 String bookOn(MockHttpSession staff,LocalDate date,String start)throws Exception{return data(write(staff,"POST","/bookings",Map.of("maSan",pitch(),"maKH",customer(),"ngayChoi",date.toString(),"gioBatDau",start,"gioKetThuc",LocalTime.parse(start).plusHours(1).toString(),"ghiChu",marker)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
 @Test void onlyPitchStaffAndOwnerCanReadPageAndEndpoint()throws Exception{
  for(String user:List.of(staffName,"admin")){var session=user.equals(staffName)?staff():login(user);mvc.perform(get("/Lich_da_bong.html").session(session)).andExpect(status().isOk());mvc.perform(get(endpoint).session(session).param("date",day().toString())).andExpect(status().isOk());}
  for(String user:List.of("khachhang","ketoan")){var session=login(user);mvc.perform(get("/Lich_da_bong.html").servletPath("/Lich_da_bong.html").session(session)).andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/"+(user.equals("khachhang")?"Man_hinh_chinh_KH.html":"Man_hinh_chinh_NVKT.html")+"?accessDenied=1"));mvc.perform(get(endpoint).session(session).param("date",day().toString())).andExpect(status().isForbidden());}
  mvc.perform(get(endpoint).param("date",day().toString())).andExpect(status().isUnauthorized());
 }
 @Test void weekRunsMondayThroughSundayAndDoesNotIncludeAdjacentWeeks()throws Exception{
  var staff=staff();LocalDate monday=day().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));String first=bookOn(staff,monday,"08:00"),last=bookOn(staff,monday.plusDays(6),"09:00");bookOn(staff,monday.minusDays(1),"08:00");bookOn(staff,monday.plusDays(7),"08:00");
  var result=data(mvc.perform(get(endpoint).session(staff).param("date",monday.plusDays(3).toString()).param("pitch",pitch())).andExpect(status().isOk()).andReturn());assertEquals(monday.toString(),result.path("weekStart").asText());assertEquals(monday.plusDays(6).toString(),result.path("weekEnd").asText());assertEquals(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).toString(),result.path("today").asText());assertEquals(2,result.path("bookings").size());assertEquals(first,result.path("bookings").get(0).path("maDatSan").asText());assertEquals(last,result.path("bookings").get(1).path("maDatSan").asText());
 }
 @Test void cancellationAndPitchFiltersAreAppliedOnServer()throws Exception{
  var staff=staff();String active=bookOn(staff,day(),"08:00"),cancelled=bookOn(staff,day(),"09:00");write(staff,"POST","/bookings/"+cancelled+"/cancel",Map.of("lyDo",marker)).andExpect(status().isOk());
  var ordinary=data(mvc.perform(get(endpoint).session(staff).param("date",day().toString()).param("pitch",pitch())).andExpect(status().isOk()).andReturn());assertEquals(1,ordinary.path("bookings").size());assertEquals(active,ordinary.path("bookings").get(0).path("maDatSan").asText());
  var all=data(mvc.perform(get(endpoint).session(staff).param("date",day().toString()).param("pitch",pitch()).param("status","ALL")).andExpect(status().isOk()).andReturn());assertEquals(2,all.path("bookings").size());
  var onlyCancelled=data(mvc.perform(get(endpoint).session(staff).param("date",day().toString()).param("pitch",pitch()).param("status","Đã hủy")).andExpect(status().isOk()).andReturn());assertEquals(cancelled,onlyCancelled.path("bookings").get(0).path("maDatSan").asText());
 }
 @Test void supportsYearBoundaryAndReadingDoesNotCreateInvoicesOrVisits()throws Exception{
  var staff=staff();LocalDate start=LocalDate.of(LocalDate.now().getYear()+1,12,28).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));String id=bookOn(staff,start.plusDays(6),"08:00");
  var result=data(mvc.perform(get(endpoint).session(staff).param("date",start.plusDays(6).toString()).param("pitch",pitch())).andExpect(status().isOk()).andReturn());assertEquals(start.toString(),result.path("weekStart").asText());assertEquals(1,result.path("bookings").size());assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void invalidDatesPitchesAndStatesReturnActionableErrors()throws Exception{
  var staff=staff();mvc.perform(get(endpoint).session(staff)).andExpect(status().isBadRequest());mvc.perform(get(endpoint).session(staff).param("date","invalid")).andExpect(status().isBadRequest());mvc.perform(get(endpoint).session(staff).param("date","0000-01-01")).andExpect(status().isBadRequest());mvc.perform(get(endpoint).session(staff).param("date",day().toString()).param("pitch","NO_SUCH_PITCH")).andExpect(status().isNotFound());mvc.perform(get(endpoint).session(staff).param("date",day().toString()).param("status","INVALID")).andExpect(status().isBadRequest());
 }
}
