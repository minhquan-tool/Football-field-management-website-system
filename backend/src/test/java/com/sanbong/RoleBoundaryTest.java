package com.sanbong;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sanbong.config.*;
import com.sanbong.controller.*;
import com.sanbong.model.*;
import com.sanbong.service.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@WebMvcTest(controllers={AuthController.class,CustomerCareController.class,ConfigurationController.class,PitchController.class,ReportController.class},
        excludeAutoConfiguration=org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration.class)
@Import(SecurityConfig.class)
// MVC slice has only mocked services and no datasource or fixture writes.
@org.springframework.test.context.TestExecutionListeners(listeners={
        org.springframework.test.context.web.ServletTestExecutionListener.class,
        org.springframework.test.context.support.DependencyInjectionTestExecutionListener.class,
        org.springframework.boot.test.mock.mockito.MockitoTestExecutionListener.class,
        org.springframework.boot.test.mock.mockito.ResetMocksTestExecutionListener.class
},mergeMode=org.springframework.test.context.TestExecutionListeners.MergeMode.REPLACE_DEFAULTS)
class RoleBoundaryTest {
    @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired PasswordEncoder encoder;
    @MockBean AuthService auth;@MockBean CustomerCareService care;@MockBean ConfigurationService configuration;
    @MockBean PitchService pitches;@MockBean ReportService reports;
    private String hash;
    @BeforeEach void setup(){hash=encoder.encode("RoleTestOnly-123");when(auth.credentialFingerprint(anyString())).thenReturn(AuthService.fingerprint(hash));}
    private AccountPrincipal principal(String role){var account=new TaiKhoan();account.setMaTK(role);account.setTenDangNhap(role);account.setMatKhau(hash);account.setTrangThai("Hoạt động");var type=new VaiTro();type.setMaVaiTro(role);account.setVaiTro(type);
        String name=Map.of("VT01","CUSTOMER","VT02","PITCH_STAFF","VT03","ACCOUNTANT","VT04","ADMIN").get(role);
        var granted=new ArrayList<SimpleGrantedAuthority>();granted.add(new SimpleGrantedAuthority("ROLE_"+name));
        for(int n=1;n<=8;n++)for(String action:List.of("XEM","THEM","SUA","XOA"))granted.add(new SimpleGrantedAuthority("CN0"+n+"_"+action));
        return new AccountPrincipal(account,granted);
    }
    private MockHttpSession login(String role)throws Exception{
        when(auth.loadUserByUsername(role)).thenAnswer(i->principal(role));when(auth.reload(role)).thenAnswer(i->principal(role));
        var c=mvc.perform(get("/auth/csrf")).andReturn();var token=json.readTree(c.getResponse().getContentAsString()).path("data");
        return (MockHttpSession)mvc.perform(post("/auth/login").session((MockHttpSession)c.getRequest().getSession()).header(token.path("headerName").asText(),token.path("token").asText()).param("identifier",role).param("password","RoleTestOnly-123")).andExpect(status().isOk()).andReturn().getRequest().getSession();
    }
    @Test void customerCannotEnterStaffFinanceOrAdminEvenWithBroadPermissions()throws Exception{
        var s=login("VT01");mvc.perform(get("/configuration").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/reports/finance").param("from","2026-10-01").param("to","2026-10-15").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/Man_hinh_chinh_NVKT.html").servletPath("/Man_hinh_chinh_NVKT.html").session(s)).andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/Man_hinh_chinh_KH.html?accessDenied=1"));
        mvc.perform(get("/customer/history").session(s)).andExpect(status().isOk());verify(care).history(any());
    }
    @Test void pitchStaffCannotEditCatalogOrAccessAccountingWorkspace()throws Exception{
        var s=login("VT02");mvc.perform(get("/configuration").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/Man_hinh_chinh_NVKT.html").servletPath("/Man_hinh_chinh_NVKT.html").session(s)).andExpect(redirectedUrl("/Man_hinh_chinh_NVKH.html?accessDenied=1"));
        var c=mvc.perform(get("/auth/csrf").session(s)).andReturn();var t=json.readTree(c.getResponse().getContentAsString()).path("data");
        mvc.perform(post("/pitches").session(s).header(t.path("headerName").asText(),t.path("token").asText()).contentType("application/json").content("{\"maSan\":\"X1\",\"tenSan\":\"Test\",\"maLoaiSan\":\"LS01\",\"trangThai\":\"Trống\"}")).andExpect(status().isForbidden());verify(pitches,never()).create(any(),anyString());
    }
    @Test void accountantCannotEnterOperationsOrCustomerProfile()throws Exception{
        var s=login("VT03");mvc.perform(get("/customer/profile").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/Quan_ly_lich_dat_san.html").servletPath("/Quan_ly_lich_dat_san.html").session(s)).andExpect(redirectedUrl("/Man_hinh_chinh_NVKT.html?accessDenied=1"));
        mvc.perform(get("/feedback").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/reports/finance").param("from","2026-10-01").param("to","2026-10-15").session(s)).andExpect(status().isOk());
    }
    @Test void adminCanConfigureButCannotImpersonateCustomer()throws Exception{
        var s=login("VT04");mvc.perform(get("/configuration").session(s)).andExpect(status().isOk());
        mvc.perform(get("/customer/history").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/Man_hinh_chinh_KH.html").servletPath("/Man_hinh_chinh_KH.html").session(s)).andExpect(redirectedUrl("/Man_hinh_chinh.html?accessDenied=1"));
    }
}
