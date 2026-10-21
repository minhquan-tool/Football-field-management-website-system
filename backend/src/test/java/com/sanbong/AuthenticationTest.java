package com.sanbong;

import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthenticationTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired EntityManager entityManager;
    @Autowired PasswordEncoder encoder;

    private record Csrf(MockHttpSession session,String header,String token) { }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var request=get("/api/auth/csrf"); if(session!=null) request.session(session);
        var result=mvc.perform(request).andExpect(status().isOk()).andReturn();
        var data=json.readTree(result.getResponse().getContentAsString()).path("data");
        return new Csrf((MockHttpSession)result.getRequest().getSession(false),
                data.path("headerName").asText(),data.path("token").asText());
    }
    private MockHttpSession login(String username) throws Exception {
        var csrf=csrf(null);
        var result=mvc.perform(post("/api/auth/login").session(csrf.session()).header(csrf.header(),csrf.token())
                .param("identifier",username).param("password","123456"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.success").value(true)).andReturn();
        assertFalse(result.getResponse().getContentAsString().contains("matKhau"));
        return (MockHttpSession)result.getRequest().getSession(false);
    }

    @Test
    void rejectsAnonymousMissingCsrfAndWrongPassword() throws Exception {
        mvc.perform(get("/api/auth/me")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/login").param("identifier","admin").param("password","123456"))
                .andExpect(status().isForbidden());
        var csrf=csrf(null);
        mvc.perform(post("/api/auth/login").session(csrf.session()).header(csrf.header(),csrf.token())
                .param("identifier","admin").param("password","incorrect"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void authenticatesFourRolesAndProtectsAdministrativeApiAndPages() throws Exception {
        String[][] roles={{"admin","VT04","Man_hinh_chinh.html"},{"nvsan","VT02","Man_hinh_chinh_NVKH.html"},
                {"ketoan","VT03","Man_hinh_chinh_NVKT.html"},{"khachhang","VT01","Man_hinh_chinh_KH.html"}};
        for(var role:roles) {
            var session=login(role[0]);
            mvc.perform(get("/api/auth/me").session(session)).andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.maVaiTro").value(role[1]));
            mvc.perform(get("/"+role[2]).session(session)).andExpect(status().isOk());
            mvc.perform(get("/api/security/accounts").session(session))
                    .andExpect(status().is("VT04".equals(role[1])?200:403));
            if(!"VT04".equals(role[1]))
                mvc.perform(get("/nhan-su-phan-quyen").servletPath("/nhan-su-phan-quyen").session(session))
                        .andExpect(redirectedUrl("/"+role[2]+"?accessDenied=1"));
        }
        login("admin@fcute.vn"); login("0901000002");
        mvc.perform(get("/hoa-don").session(login("admin"))).andExpect(status().isOk());
        mvc.perform(get("/hoa-don").servletPath("/hoa-don").session(login("nvsan")))
                .andExpect(redirectedUrl("/nhan-vien?accessDenied=1"));
    }

    @Test
    void rejectsLockedAccountAndRevokesAnExistingSession() throws Exception {
        var session=login("nvsan");
        jdbc.update("UPDATE TaiKhoan SET TrangThai=N'Khóa' WHERE TenDangNhap='nvsan'"); entityManager.clear();
        mvc.perform(get("/api/auth/me").session(session)).andExpect(status().isUnauthorized());
        var csrf=csrf(null);
        mvc.perform(post("/api/auth/login").session(csrf.session()).header(csrf.header(),csrf.token())
                .param("identifier","nvsan").param("password","123456"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutInvalidatesSessionAndRequiresCsrf() throws Exception {
        var session=login("admin");
        mvc.perform(post("/api/auth/logout").session(session)).andExpect(status().isForbidden());
        var csrf=csrf(session);
        mvc.perform(post("/api/auth/logout").session(session).header(csrf.header(),csrf.token()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.success").value(true));
        assertTrue(session.isInvalid());
        mvc.perform(get("/api/auth/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void registersCustomerWithHashAndRollsBackDuplicateRegistration() throws Exception {
        var csrf=csrf(null);
        String body="""
                {"hoTen":"Test Customer","soDienThoai":"0998887776","email":"phase2-test@example.invalid",
                 "tenDangNhap":"phase2-test","matKhau":"TestPassword2026!"}
                """;
        mvc.perform(post("/api/auth/register").session(csrf.session()).header(csrf.header(),csrf.token())
                .contentType("application/json").content(body)).andExpect(status().isOk());
        String hash=jdbc.queryForObject("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap='phase2-test'",String.class);
        assertNotEquals("TestPassword2026!",hash); assertTrue(encoder.matches("TestPassword2026!",hash));
        assertEquals("VT01",jdbc.queryForObject("SELECT MaVaiTro FROM TaiKhoan WHERE TenDangNhap='phase2-test'",String.class));
        mvc.perform(post("/api/auth/register").session(csrf.session()).header(csrf.header(),csrf.token())
                .contentType("application/json").content(body)).andExpect(status().isConflict());
    }

    @Test
    void validatesRegistrationOnBackend() throws Exception {
        var csrf=csrf(null);
        mvc.perform(post("/api/auth/register").session(csrf.session()).header(csrf.header(),csrf.token())
                .contentType("application/json").content("{\"hoTen\":\"\",\"matKhau\":\"123\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void updatesPermissionsAtomicallyAndRefreshesActiveSessions() throws Exception {
        var session=login("admin"); var csrf=csrf(session);
        var matrix=mvc.perform(get("/api/security/permissions?role=VT02").session(session))
                .andExpect(status().isOk()).andReturn();
        var permissions=json.createArrayNode();
        for(var row:json.readTree(matrix.getResponse().getContentAsString()).path("data").path("permissions")) {
            var p=permissions.addObject(); p.put("maChucNang",row.path("MaChucNang").asText());
            p.put("xem",row.path("Xem").asBoolean()); p.put("them",row.path("Them").asBoolean());
            p.put("sua",row.path("Sua").asBoolean()); p.put("xoa",row.path("Xoa").asBoolean());
            if("CN07".equals(p.path("maChucNang").asText())) p.put("xem",true);
        }
        var staff=login("nvsan");
        mvc.perform(put("/api/security/permissions/VT02").session(staff).header(csrf(staff).header(),csrf(staff).token())
                .contentType("application/json").content(json.writeValueAsString(permissions))).andExpect(status().isForbidden());
        mvc.perform(put("/api/security/permissions/VT02").session(session).header(csrf.header(),csrf.token())
                .contentType("application/json").content(json.writeValueAsString(permissions))).andExpect(status().isOk());
        mvc.perform(get("/api/auth/me").session(staff)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.permissions",org.hamcrest.Matchers.hasItem("CN07_XEM")));
        mvc.perform(get("/api/security/accounts").session(staff)).andExpect(status().isForbidden());
        mvc.perform(put("/api/security/permissions/VT02").session(session).header(csrf.header(),csrf.token())
                .contentType("application/json").content("[]")).andExpect(status().isBadRequest());
        mvc.perform(put("/api/security/permissions/VT02").session(session).header(csrf.header(),csrf.token())
                .contentType("application/json").content("[null,null,null,null,null,null,null,null]"))
                .andExpect(status().isBadRequest());
    }
}
