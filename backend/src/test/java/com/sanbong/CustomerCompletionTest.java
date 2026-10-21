package com.sanbong;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Registered fixtures and password changes roll back; never touches demo passwords. */
class CustomerCompletionTest extends RoleAuditSupport {
    @Autowired PasswordEncoder encoder;
    final String oldPassword="Customer-"+UUID.randomUUID();
    final String newPassword="Changed-"+UUID.randomUUID();
    String username;
    MockHttpSession customerSession() throws Exception {
        username="cc_"+UUID.randomUUID().toString().replace("-","").substring(0,12);
        var r=mvc.perform(get("/api/auth/csrf")).andReturn();var csrf=data(r);
        mvc.perform(post("/api/auth/register").session((MockHttpSession)r.getRequest().getSession())
                .header(csrf.path("headerName").asText(),csrf.path("token").asText()).contentType("application/json")
                .content(json.writeValueAsString(Map.of("hoTen",marker,"soDienThoai",phone(),"email",username+"@example.invalid","tenDangNhap",username,"matKhau",oldPassword))))
                .andExpect(status().isOk());
        return login(username,oldPassword);
    }
    Map<String,String> body(String old,String next,String confirmation){return Map.of("matKhauHienTai",old,"matKhauMoi",next,"xacNhanMatKhau",confirmation);}
    String hash(){return jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=?",String.class,username);}
    @Test void passwordChangeHashesOnlyOwnAccountRevokesAllOldSessionsAndAuditsWithoutSecrets() throws Exception {
        var first=customerSession();String user=username;var second=login(user,oldPassword);
        var other=customerSession();String otherHash=hash();username=user;
        String account=jdbc.queryForObject("SELECT MaTK FROM TaiKhoan WHERE TenDangNhap=?",String.class,user);
        var payload=new LinkedHashMap<String,Object>(body(oldPassword,newPassword,newPassword));payload.put("maTK","TK01");
        var result=write(first,"POST","/api/customer/password",payload).andExpect(status().isOk()).andReturn();
        assertTrue(encoder.matches(newPassword,hash()));assertFalse(encoder.matches(oldPassword,hash()));
        assertFalse(result.getResponse().getContentAsString().contains(newPassword));
        for(var session:List.of(first,second))mvc.perform(get("/api/auth/me").session(session)).andExpect(status().isUnauthorized());
        var token=mvc.perform(get("/api/auth/csrf")).andReturn();var csrf=data(token);
        mvc.perform(post("/api/auth/login").session((MockHttpSession)token.getRequest().getSession()).header(csrf.path("headerName").asText(),csrf.path("token").asText()).param("identifier",user).param("password",oldPassword)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/auth/me").session(login(user,newPassword))).andExpect(status().isOk());
        mvc.perform(get("/api/auth/me").session(other)).andExpect(status().isOk());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE MaTK=? AND NoiDungThayDoi=N'Khách hàng tự đổi mật khẩu; phiên cũ hết hiệu lực'",Integer.class,account));
        String logs=jdbc.queryForList("SELECT NoiDungThayDoi FROM NhatKyHeThong WHERE MaTK=?",account).toString();
        assertFalse(logs.contains(oldPassword));assertFalse(logs.contains(newPassword));assertFalse(logs.contains(hash()));
        assertNotEquals(otherHash,hash());
    }
    @Test void wrongCurrentPasswordCannotChangeHashOrRevokeSession() throws Exception {
        var session=customerSession();String before=hash();
        write(session,"POST","/api/customer/password",body("Wrong-"+UUID.randomUUID(),newPassword,newPassword)).andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value("Mật khẩu hiện tại không đúng."));
        assertEquals(before,hash());mvc.perform(get("/api/auth/me").session(session)).andExpect(status().isOk());
    }
    @Test void confirmationMismatchDoesNotWrite() throws Exception {
        var session=customerSession();String before=hash();write(session,"POST","/api/customer/password",body(oldPassword,newPassword,"Mismatch2026!")).andExpect(status().isBadRequest());assertEquals(before,hash());
    }
    @ParameterizedTest @ValueSource(strings={"123456","short","ĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐĐ"})
    void weakOrOversizedPasswordRejected(String value) throws Exception {
        var session=customerSession();String before=hash();write(session,"POST","/api/customer/password",body(oldPassword,value,value)).andExpect(status().isBadRequest());assertEquals(before,hash());
    }
    @Test void reusingCurrentPasswordRejected() throws Exception {
        var session=customerSession();String before=hash();write(session,"POST","/api/customer/password",body(oldPassword,oldPassword,oldPassword)).andExpect(status().isBadRequest());assertEquals(before,hash());
    }
    @Test void blankInputsReportFieldsWithoutLeakingPassword() throws Exception {
        var session=customerSession();String before=hash();
        var result=write(session,"POST","/api/customer/password",body(oldPassword,"","")).andExpect(status().isBadRequest()).andExpect(jsonPath("$.data.fieldErrors.matKhauMoi").exists()).andReturn();
        assertFalse(result.getResponse().getContentAsString().contains(oldPassword));assertEquals(before,hash());
        assertFalse(new com.sanbong.dto.CustomerPasswordRequest(oldPassword,newPassword,newPassword).toString().contains(newPassword));
    }
    @Test void csrfIsRequiredAndAnonymousCannotChangePassword() throws Exception {
        var session=customerSession();String before=hash();
        mvc.perform(post("/api/customer/password").session(session).contentType("application/json").content(json.writeValueAsString(body(oldPassword,newPassword,newPassword)))).andExpect(status().isForbidden());
        mvc.perform(get("/api/customer/profile")).andExpect(status().isUnauthorized());assertEquals(before,hash());
    }
    @ParameterizedTest @ValueSource(strings={"nvsan","ketoan","admin"})
    void otherRolesCannotUseCustomerPasswordEndpoint(String user) throws Exception {
        write(login(user),"POST","/api/customer/password",body("irrelevant",newPassword,newPassword)).andExpect(status().isForbidden());
    }
    @Test void validationIdentifiesCustomerProfileAndRegistrationFieldsWithoutEchoingInput() throws Exception {
        var session=customerSession();
        write(session,"PUT","/api/customer/profile",Map.of("hoTen","","soDienThoai","+++++++","email","wrong","diaChi",""))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.data.fieldErrors.hoTen").exists()).andExpect(jsonPath("$.data.fieldErrors.soDienThoai").exists()).andExpect(jsonPath("$.data.fieldErrors.email").exists());
        write(session,"POST","/api/auth/register",Map.of("hoTen",marker,"soDienThoai",phone(),"tenDangNhap","Tên có dấu","matKhau",oldPassword))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.data.fieldErrors.tenDangNhap").value(org.hamcrest.Matchers.containsString("không dấu")));
    }
}


