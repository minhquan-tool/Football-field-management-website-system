package com.sanbong;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class StaffRoleAuditTest extends RoleAuditSupport {
 @Test void walkInCreatesOnlyCustomerAndDuplicatePhoneCannotCreateAnother()throws Exception{
  var staff=login("nvsan");String phone=phone();int before=jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class);
  var body=Map.of("hoTen","Khách tại quầy có dấu","soDienThoai",phone);
  String id=data(write(staff,"POST","/booking-customers",body).andExpect(status().isOk()).andExpect(jsonPath("$.data.hoTen").value("Khách tại quầy có dấu")).andReturn()).path("maKH").asText();
  mvc.perform(get("/booking-customers").param("phone",phone).session(staff)).andExpect(status().isOk()).andExpect(jsonPath("$.data[0].maKH").value(id));
  write(staff,"POST","/booking-customers",body).andExpect(status().isConflict());
  assertEquals(before,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan",Integer.class));assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE SoDienThoai=?",Integer.class,phone));
 }
 @ParameterizedTest @ValueSource(strings={"+++++++","090+1234567","++8490123456"})
 void malformedWalkInPhoneIsRejectedWithoutPersistence(String phone)throws Exception{
  var staff=login("nvsan");int before=jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang",Integer.class);
  mvc.perform(get("/booking-customers").param("phone",phone).session(staff)).andExpect(status().isBadRequest());
  write(staff,"POST","/booking-customers",Map.of("hoTen",marker,"soDienThoai",phone)).andExpect(status().isBadRequest());assertEquals(before,jdbc.queryForObject("SELECT COUNT(*) FROM KhachHang",Integer.class));
 }
 @Test void staffCanChangePitchStatusButCannotCreateOrRewritePitchCatalog()throws Exception{
  var staff=login("nvsan");String id=pitch();
  write(staff,"PATCH","/pitches/"+id+"/status",Map.of("trangThai","Bảo trì")).andExpect(status().isOk());
  assertEquals("Bảo trì",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,id));
  var body=Map.of("maSan",id,"tenSan",marker,"maLoaiSan","LS01","trangThai","Trống");
  write(staff,"PUT","/pitches/"+id,body).andExpect(status().isForbidden());write(staff,"POST","/pitches",body).andExpect(status().isForbidden());
 }
 @Test void waitingOrFutureBookingCannotCheckInAndStaffCannotRefundOrManageUsers()throws Exception{
  var staff=login("nvsan");String id=book(staff),path="/operations/bookings/"+id;
  write(staff,"POST",path+"/check-in",Map.of()).andExpect(status().isConflict());
  write(staff,"POST","/bookings/"+id+"/confirm",Map.of()).andExpect(status().isOk());
  write(staff,"POST",path+"/check-in",Map.of()).andExpect(status().isConflict());
  write(staff,"POST",path+"/check-out",Map.of()).andExpect(status().isConflict());
  write(staff,"POST","/finance/refunds/NO_SUCH_ID/confirm",Map.of("phuongThuc","Tiền mặt","daHoanTien",true,"lyDo",marker)).andExpect(status().isForbidden());
  write(staff,"POST","/admin/employees",employee(true)).andExpect(status().isForbidden());mvc.perform(get("/security/accounts").session(staff)).andExpect(status().isForbidden());
 }
 @Test void staffUsageReportMatchesItsPitchAndCannotReadFinanceReport()throws Exception{
  var staff=login("nvsan");book(staff);
  mvc.perform(get("/reports/usage").param("from",day().toString()).param("to",day().toString()).param("pitch",pitch()).session(staff)).andExpect(status().isOk()).andExpect(jsonPath("$.data.totals.soBooking").value(1));
  mvc.perform(get("/reports/finance").param("from",day().toString()).param("to",day().toString()).session(staff)).andExpect(status().isForbidden());
 }
}
