package com.sanbong;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.fasterxml.jackson.databind.node.ArrayNode;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AdminRoleAuditTest extends RoleAuditSupport {
 @Autowired PasswordEncoder encoder;
 record Fixture(String employee,String account,String username,String password){}
 Fixture fixture(MockHttpSession admin)throws Exception{
  String employee=data(write(admin,"POST","/admin/employees",employee(true)).andExpect(status().isOk()).andReturn()).path("MaNV").asText();assertFalse(employee.isBlank());
  String username="ra_"+UUID.randomUUID().toString().replace("-","").substring(0,12),password=UUID.randomUUID().toString();
  String account=data(write(admin,"POST","/admin/accounts",Map.of("maNV",employee,"tenDangNhap",username,"matKhau",password,"maVaiTro","VT02")).andExpect(status().isOk()).andReturn()).path("MaTK").asText();
  assertFalse(account.isBlank());return new Fixture(employee,account,username,password);
 }
 void rejectedLogin(Fixture f)throws Exception{
  var r=mvc.perform(get("/auth/csrf")).andReturn();var c=data(r);mvc.perform(post("/auth/login").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",f.username()).param("password",f.password())).andExpect(status().isUnauthorized());
 }
 ArrayNode matrix(MockHttpSession admin,String role)throws Exception{
  var rows=data(mvc.perform(get("/security/permissions").param("role",role).session(admin)).andExpect(status().isOk()).andReturn()).path("permissions");var result=json.createArrayNode();
  for(var row:rows){var p=result.addObject();p.put("maChucNang",row.path("MaChucNang").asText());for(String k:List.of("Xem","Them","Sua","Xoa"))p.put(k.toLowerCase(),row.path(k).asBoolean());}return result;
 }
 @Test void employeeAccountRoundTripPreservesUnicodeAndHashesPrivatePassword()throws Exception{
  var admin=login("admin");var f=fixture(admin);var employee=new LinkedHashMap<String,Object>(employee(true));employee.put("hoTen","Nguyễn Thị Ánh");
  write(admin,"PUT","/admin/employees/"+f.employee(),employee).andExpect(status().isOk()).andExpect(jsonPath("$.data.HoTen").value("Nguyễn Thị Ánh"));
  mvc.perform(get("/admin/employees").param("q",f.employee()).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(1));
  String hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE MaTK=?",String.class,f.account());assertTrue(encoder.matches(f.password(),hash));
  String body=mvc.perform(get("/security/accounts").session(admin)).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();assertFalse(body.contains(hash));assertFalse(body.contains(f.password()));
  mvc.perform(get("/auth/me").session(login(f.username(),f.password()))).andExpect(status().isOk()).andExpect(jsonPath("$.data.maVaiTro").value("VT02"));
 }
 @ParameterizedTest @ValueSource(strings={"++++++++","090+1234567","++8490123456"})
 void malformedEmployeePhoneDoesNotCreateRows(String phone)throws Exception{
  var admin=login("admin");var body=new LinkedHashMap<String,Object>(employee(true));body.put("soDienThoai",phone);int before=jdbc.queryForObject("SELECT COUNT(*) FROM NhanVien",Integer.class);
  write(admin,"POST","/admin/employees",body).andExpect(status().isBadRequest());assertEquals(before,jdbc.queryForObject("SELECT COUNT(*) FROM NhanVien",Integer.class));
 }
 @ParameterizedTest @ValueSource(strings={"local","international","spaced"})
 void validEmployeePhoneFormatsArePreserved(String format)throws Exception{
  var admin=login("admin");var body=new LinkedHashMap<String,Object>(employee(true));String digits=phone();
  String value=switch(format){case "international"->"+84"+digits.substring(1);case "spaced"->digits.substring(0,3)+" "+digits.substring(3,6)+" "+digits.substring(6);default->digits;};
  body.put("soDienThoai",value);String id=data(write(admin,"POST","/admin/employees",body).andExpect(status().isOk()).andReturn()).path("MaNV").asText();
  assertEquals(value,jdbc.queryForObject("SELECT SoDienThoai FROM NhanVien WHERE MaNV=?",String.class,id));
 }
 @Test void invalidDepartmentAndFutureHireDateDoNotPersist()throws Exception{
  var admin=login("admin");var body=new LinkedHashMap<String,Object>(employee(true));body.put("boPhan","Không hợp lệ");write(admin,"POST","/admin/employees",body).andExpect(status().isBadRequest());
  body=new LinkedHashMap<>(employee(true));body.put("ngayVaoLam",LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(1).toString());write(admin,"POST","/admin/employees",body).andExpect(status().isBadRequest());
 }
 @Test void duplicateLinkedAccountAndCrossOwnerRoleAreRejected()throws Exception{
  var admin=login("admin");var f=fixture(admin);
  write(admin,"POST","/admin/accounts",Map.of("maNV",f.employee(),"tenDangNhap",f.username()+"x","matKhau",UUID.randomUUID().toString(),"maVaiTro","VT02")).andExpect(status().isConflict());
  write(admin,"PUT","/admin/accounts/"+f.account(),Map.of("hoatDong",true,"maVaiTro","VT01")).andExpect(status().isBadRequest());
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan WHERE MaNV=?",Integer.class,f.employee()));
 }
 @Test void lockingAccountRevokesActiveSessionAndUnlockRequiresNewLogin()throws Exception{
  var admin=login("admin");var f=fixture(admin);var s=login(f.username(),f.password());
  write(admin,"PUT","/admin/accounts/"+f.account(),Map.of("hoatDong",false,"maVaiTro","VT02")).andExpect(status().isOk());em.clear();mvc.perform(get("/auth/me").session(s)).andExpect(status().isUnauthorized());rejectedLogin(f);
  write(admin,"PUT","/admin/accounts/"+f.account(),Map.of("hoatDong",true,"maVaiTro","VT02")).andExpect(status().isOk());em.clear();login(f.username(),f.password());
 }
 @Test void employeeStopLocksAccountAndCannotUnlockWhileStopped()throws Exception{
  var admin=login("admin");var f=fixture(admin);var s=login(f.username(),f.password());
  write(admin,"PUT","/admin/employees/"+f.employee(),employee(false)).andExpect(status().isOk());em.clear();mvc.perform(get("/auth/me").session(s)).andExpect(status().isUnauthorized());
  write(admin,"PUT","/admin/accounts/"+f.account(),Map.of("hoatDong",true,"maVaiTro","VT02")).andExpect(status().isConflict());assertEquals("Khóa",jdbc.queryForObject("SELECT TrangThai FROM TaiKhoan WHERE MaTK=?",String.class,f.account()));
 }
 @Test void resetOnlyFixtureAccountInvalidatesSessionAndDoesNotLeakToLogs()throws Exception{
  var admin=login("admin");var f=fixture(admin);var old=login(f.username(),f.password());String next=UUID.randomUUID().toString();
  write(admin,"POST","/admin/accounts/"+f.account()+"/reset-password",Map.of("matKhau",next)).andExpect(status().isOk());em.clear();mvc.perform(get("/auth/me").session(old)).andExpect(status().isUnauthorized());login(f.username(),next);
  String hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE MaTK=?",String.class,f.account());assertTrue(encoder.matches(next,hash));
  var logs=jdbc.queryForList("SELECT NoiDungThayDoi FROM NhatKyHeThong WHERE DoiTuong=?",String.class,f.account());assertTrue(logs.stream().noneMatch(text->text.contains(next)||text.contains(f.password())||text.contains(hash)));
 }
 @Test void roleChangeIsReloadedForExistingFixtureSession()throws Exception{
  var admin=login("admin");var f=fixture(admin);var s=login(f.username(),f.password());
  write(admin,"PUT","/admin/accounts/"+f.account(),Map.of("hoatDong",true,"maVaiTro","VT03")).andExpect(status().isOk());em.clear();mvc.perform(get("/auth/me").session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.maVaiTro").value("VT03"));
  mvc.perform(get("/reports/finance").param("from",day().toString()).param("to",day().toString()).session(s)).andExpect(status().isOk());mvc.perform(get("/booking-options").session(s)).andExpect(status().isForbidden());
 }
 @Test void selfLockDowngradeAndStoppingOwnAdminEmployeeAreBlocked()throws Exception{
  var admin=login("admin");String id=jdbc.queryForObject("SELECT MaTK FROM TaiKhoan WHERE TenDangNhap='admin'",String.class),employee=jdbc.queryForObject("SELECT MaNV FROM TaiKhoan WHERE MaTK=?",String.class,id);
  write(admin,"PUT","/admin/accounts/"+id,Map.of("hoatDong",false,"maVaiTro","VT04")).andExpect(status().isConflict());write(admin,"PUT","/admin/accounts/"+id,Map.of("hoatDong",true,"maVaiTro","VT02")).andExpect(status().isConflict());
  write(admin,"PUT","/admin/employees/"+employee,employee(false)).andExpect(status().isConflict());
 }
 @Test void permissionRevokeAndGrantAffectSessionWithoutAllowingRoleEscalation()throws Exception{
  var admin=login("admin");var f=fixture(admin);var staff=login(f.username(),f.password());var body=matrix(admin,"VT02");
  for(boolean allow:List.of(false,true,false)){
   for(var p:body){if("CN06".equals(p.path("maChucNang").asText()))((com.fasterxml.jackson.databind.node.ObjectNode)p).put("xem",allow);if("CN07".equals(p.path("maChucNang").asText()))((com.fasterxml.jackson.databind.node.ObjectNode)p).put("xem",true);}
   write(admin,"PUT","/security/permissions/VT02",body).andExpect(status().isOk());em.clear();
   mvc.perform(get("/reports/usage").param("from",day().toString()).param("to",day().toString()).param("pitch",pitch()).session(staff)).andExpect(status().is(allow?200:403));
   mvc.perform(get("/security/accounts").session(staff)).andExpect(status().isForbidden());
  }
 }
 @Test void adminCannotRemoveRecoveryPermissionsOrWriteInvalidMatrix()throws Exception{
  var admin=login("admin");var body=matrix(admin,"VT04");for(var p:body)if("CN08".equals(p.path("maChucNang").asText()))((com.fasterxml.jackson.databind.node.ObjectNode)p).put("sua",false);
  write(admin,"PUT","/security/permissions/VT04",body).andExpect(status().isBadRequest());write(admin,"PUT","/security/permissions/VT02",List.of()).andExpect(status().isBadRequest());
  assertEquals(1,jdbc.queryForObject("SELECT CONVERT(int,Sua) FROM PhanQuyen WHERE MaVaiTro='VT04' AND MaChucNang='CN08'",Integer.class));
 }
 @Test void auditLogCanBeFilteredButCannotBeDeleted()throws Exception{
  var admin=login("admin");var f=fixture(admin);String date=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).toString();
  mvc.perform(get("/admin/logs").param("from",date).param("to",date).param("target",f.employee()).session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(1));
  write(admin,"DELETE","/admin/logs",Map.of()).andExpect(status().isMethodNotAllowed());
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE DoiTuong=?",Integer.class,f.employee()));
 }
 @ParameterizedTest @ValueSource(strings={"soDienThoai","email"})
 void duplicateContactCannotBecomeNewLoginAlias(String field)throws Exception{
  var admin=login("admin");String column=field.equals("email")?"Email":"SoDienThoai";
  String existing=jdbc.queryForObject("SELECT "+column+" FROM KhachHang WHERE MaKH=?",String.class,customer());
  var body=new LinkedHashMap<String,Object>(employee(true));body.put(field,existing);
  String employee=data(write(admin,"POST","/admin/employees",body).andExpect(status().isOk()).andReturn()).path("MaNV").asText();
  write(admin,"POST","/admin/accounts",Map.of("maNV",employee,"tenDangNhap","ra_"+UUID.randomUUID().toString().substring(0,8),"matKhau",UUID.randomUUID().toString(),"maVaiTro","VT02")).andExpect(status().isConflict());
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan WHERE MaNV=?",Integer.class,employee));login(existing);
 }
 @ParameterizedTest @ValueSource(strings={"soDienThoai","email"})
 void editingLinkedEmployeeCannotBreakAnotherLoginAlias(String field)throws Exception{
  var admin=login("admin");var f=fixture(admin);String column=field.equals("email")?"Email":"SoDienThoai";
  String before=jdbc.queryForObject("SELECT "+column+" FROM NhanVien WHERE MaNV=?",String.class,f.employee());
  String existing=jdbc.queryForObject("SELECT "+column+" FROM KhachHang WHERE MaKH=?",String.class,customer());
  var body=new LinkedHashMap<String,Object>(employee(true));body.put(field,existing);
  write(admin,"PUT","/admin/employees/"+f.employee(),body).andExpect(status().isConflict());
  assertEquals(before,jdbc.queryForObject("SELECT "+column+" FROM NhanVien WHERE MaNV=?",String.class,f.employee()));login(existing);
 }
 @Test void editingOwnEmailCaseIsAllowedAndDoesNotCreateSelfConflict()throws Exception{
  var admin=login("admin");var f=fixture(admin);var row=jdbc.queryForMap("SELECT SoDienThoai,Email FROM NhanVien WHERE MaNV=?",f.employee());
  var body=new LinkedHashMap<String,Object>(employee(true));body.put("soDienThoai",row.get("SoDienThoai"));String email=row.get("Email").toString().toUpperCase(Locale.ROOT);body.put("email",email);
  write(admin,"PUT","/admin/employees/"+f.employee(),body).andExpect(status().isOk());em.clear();login(email,f.password());
 }
 @Test void legacyDuplicateContactDoesNotPreventStoppingFixtureEmployee()throws Exception{
  var admin=login("admin");var f=fixture(admin);String duplicate=jdbc.queryForObject("SELECT SoDienThoai FROM KhachHang WHERE MaKH=?",String.class,customer());
  jdbc.update("UPDATE NhanVien SET SoDienThoai=? WHERE MaNV=?",duplicate,f.employee());
  var body=new LinkedHashMap<String,Object>(employee(false));body.put("soDienThoai",duplicate);body.put("email",jdbc.queryForObject("SELECT Email FROM NhanVien WHERE MaNV=?",String.class,f.employee()));
  write(admin,"PUT","/admin/employees/"+f.employee(),body).andExpect(status().isOk());assertEquals("Khóa",jdbc.queryForObject("SELECT TrangThai FROM TaiKhoan WHERE MaTK=?",String.class,f.account()));
 }
}
