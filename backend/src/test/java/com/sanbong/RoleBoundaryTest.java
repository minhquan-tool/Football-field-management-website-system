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
@WebMvcTest(controllers={AuthController.class,CustomerCareController.class,ConfigurationController.class,PitchController.class,ReportController.class,CancellationRequestController.class,PageController.class,HomeController.class},
        excludeAutoConfiguration=org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration.class)
@Import({SecurityConfig.class,ApiRoutesConfig.class})
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
    @MockBean CancellationRequestService cancellations;
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
        var c=mvc.perform(get("/api/auth/csrf")).andReturn();var token=json.readTree(c.getResponse().getContentAsString()).path("data");
        return (MockHttpSession)mvc.perform(post("/api/auth/login").session((MockHttpSession)c.getRequest().getSession()).header(token.path("headerName").asText(),token.path("token").asText()).param("identifier",role).param("password","RoleTestOnly-123")).andExpect(status().isOk()).andReturn().getRequest().getSession();
    }
    @Test void customerCannotEnterStaffFinanceOrAdminEvenWithBroadPermissions()throws Exception{
        var s=login("VT01");mvc.perform(get("/api/configuration").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/api/reports/finance").param("from","2026-10-01").param("to","2026-10-15").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/hoa-don").servletPath("/hoa-don").session(s)).andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/khach-hang?accessDenied=1"));
        mvc.perform(get("/api/customer/history").session(s)).andExpect(status().isOk());verify(care).history(any());
    }
    @Test void pitchStaffCannotEditCatalogOrAccessAccountingWorkspace()throws Exception{
        var s=login("VT02");mvc.perform(get("/api/configuration").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/hoa-don").servletPath("/hoa-don").session(s)).andExpect(redirectedUrl("/nhan-vien?accessDenied=1"));
        var c=mvc.perform(get("/api/auth/csrf").session(s)).andReturn();var t=json.readTree(c.getResponse().getContentAsString()).path("data");
        mvc.perform(post("/api/pitches").session(s).header(t.path("headerName").asText(),t.path("token").asText()).contentType("application/json").content("{\"maSan\":\"X1\",\"tenSan\":\"Test\",\"maLoaiSan\":\"LS01\",\"trangThai\":\"Trống\"}")).andExpect(status().isForbidden());verify(pitches,never()).create(any(),anyString());
    }
    @Test void accountantCannotEnterOperationsOrCustomerProfile()throws Exception{
        var s=login("VT03");mvc.perform(get("/api/customer/profile").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/dieu-phoi-san").servletPath("/dieu-phoi-san").session(s)).andExpect(redirectedUrl("/hoa-don?accessDenied=1"));
        mvc.perform(get("/api/feedback").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/api/reports/finance").param("from","2026-10-01").param("to","2026-10-15").session(s)).andExpect(status().isOk());
    }
    @Test void adminCanConfigureButCannotImpersonateCustomer()throws Exception{
        var s=login("VT04");mvc.perform(get("/api/configuration").session(s)).andExpect(status().isOk());
        mvc.perform(get("/api/customer/history").session(s)).andExpect(status().isForbidden());
        mvc.perform(get("/khach-hang").servletPath("/khach-hang").session(s)).andExpect(redirectedUrl("/quan-tri?accessDenied=1"));
    }
    @Test void cancellationQueueSeparatesCustomerAndReviewerAndRequiresCsrf()throws Exception{
        var customer=login("VT01");var staff=login("VT02");var accountant=login("VT03");
        mvc.perform(get("/api/finance/cancellation-requests").session(customer)).andExpect(status().isOk());
        mvc.perform(get("/api/finance/cancellation-requests").session(staff)).andExpect(status().isForbidden());
        mvc.perform(post("/api/finance/cancellation-requests/YC1/decision").session(accountant).contentType("application/json").content("{\"approve\":true,\"ghiChu\":\"Duyệt\"}")).andExpect(status().isForbidden());
        var c=mvc.perform(get("/api/auth/csrf").session(customer)).andReturn();var token=json.readTree(c.getResponse().getContentAsString()).path("data");
        mvc.perform(post("/api/finance/cancellation-requests/YC1/decision").session(customer).header(token.path("headerName").asText(),token.path("token").asText()).contentType("application/json").content("{\"approve\":true,\"ghiChu\":\"Duyệt\"}")).andExpect(status().isForbidden());
        var a=mvc.perform(get("/api/auth/csrf").session(accountant)).andReturn();var at=json.readTree(a.getResponse().getContentAsString()).path("data");
        mvc.perform(post("/api/finance/cancellation-requests/YC1/decision").session(accountant).header(at.path("headerName").asText(),at.path("token").asText()).contentType("application/json").content("{\"approve\":true,\"ghiChu\":\"Duyệt\"}")).andExpect(status().isOk());verify(cancellations).decide(eq("YC1"),eq(true),eq("Duyệt"),any());
        mvc.perform(post("/api/bookings/DS1/cancellation-requests").session(customer).header(token.path("headerName").asText(),token.path("token").asText()).contentType("application/json").content("{\"lyDo\":\"Khách bận\"}")).andExpect(status().isOk());verify(cancellations).submit(eq("DS1"),eq("Khách bận"),any());
        mvc.perform(post("/api/bookings/DS1/cancellation-requests").session(customer).contentType("application/json").content("{\"lyDo\":\"Khách bận\"}")).andExpect(status().isForbidden());

    }

    @Test void cleanPagesAndLegacyRedirectsPreserveQueries()throws Exception{
        mvc.perform(get("/trang-chu").servletPath("/trang-chu")).andExpect(status().isOk()).andExpect(content().contentTypeCompatibleWith("text/html"));
        mvc.perform(get("/api/Trang_chu.html").servletPath("/api/Trang_chu.html").queryParam("date","2026-10-22")).andExpect(redirectedUrl("/trang-chu?date=2026-10-22"));
        mvc.perform(get("/api/")).andExpect(redirectedUrl("/trang-chu"));
        mvc.perform(get("/dieu-phoi-san").servletPath("/dieu-phoi-san")).andExpect(redirectedUrl("/dang-nhap"));
        mvc.perform(get("/api/auth/csrf")).andExpect(status().isOk());
        mvc.perform(get("/auth/csrf")).andExpect(status().isUnauthorized());
        var s=login("VT01");
        mvc.perform(get("/api/Quan_ly_lich_dat_san.html").servletPath("/api/Quan_ly_lich_dat_san.html").session(s).queryParam("booking","DS1").queryParam("payment","1")).andExpect(redirectedUrl("/lich-dat-cua-toi?booking=DS1&payment=1"));
        mvc.perform(get("/dieu-phoi-san").servletPath("/dieu-phoi-san").session(s)).andExpect(redirectedUrl("/khach-hang?accessDenied=1"));
        mvc.perform(get("/lich-dat-cua-toi").servletPath("/lich-dat-cua-toi").session(s)).andExpect(status().isOk());
    }

    @Test void allCanonicalScreensAreMappedAndAuthorizedForTheirRoles()throws Exception{
        var screens=Map.of("VT01",List.of("khach-hang","dat-san","lich-dat-cua-toi","lich-su-dat-san","khuyen-mai","tai-khoan","phan-hoi"),"VT02",List.of("nhan-vien","lich-san","dieu-phoi-san","dat-san-tai-quay","quan-ly-san","phan-hoi","bao-cao"),"VT03",List.of("hoa-don","hoan-tien","thanh-toan","bao-cao"),"VT04",List.of("quan-tri","cau-hinh","nhan-su-phan-quyen","doanh-thu","sao-luu","dieu-phoi-san","hoa-don","hoan-tien","thanh-toan","bao-cao"));
        for(var entry:screens.entrySet()){var session=login(entry.getKey());for(String route:entry.getValue())mvc.perform(get("/"+route).servletPath("/"+route).session(session)).andExpect(status().isOk()).andExpect(content().contentTypeCompatibleWith("text/html"));}
        for(String route:List.of("trang-chu","dang-nhap","dang-ky"))mvc.perform(get("/"+route).servletPath("/"+route)).andExpect(status().isOk());
    }

}
