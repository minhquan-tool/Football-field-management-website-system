package com.sanbong;

import com.fasterxml.jackson.databind.*;
import com.sanbong.config.*;
import com.sanbong.controller.AuthController;
import com.sanbong.model.*;
import com.sanbong.service.AuthService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Actual Spring Security filter chain, mocked users; no database or real account changes. */
@WebMvcTest(controllers=AuthController.class,properties={"app.security.login-limit.per-identifier=2","app.security.login-limit.per-ip=4","app.security.login-limit.window-seconds=60"},
        excludeAutoConfiguration=org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration.class)
@Import(SecurityConfig.class)
@org.springframework.test.context.TestExecutionListeners(listeners={
        org.springframework.test.context.web.ServletTestExecutionListener.class,
        org.springframework.test.context.support.DependencyInjectionTestExecutionListener.class,
        org.springframework.boot.test.mock.mockito.MockitoTestExecutionListener.class,
        org.springframework.boot.test.mock.mockito.ResetMocksTestExecutionListener.class
},mergeMode=org.springframework.test.context.TestExecutionListeners.MergeMode.REPLACE_DEFAULTS)
class LoginRateLimitHttpTest {
    @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired PasswordEncoder encoder;@MockBean AuthService auth;
    static final AtomicInteger peers=new AtomicInteger();String peer,hash;
    record Token(MockHttpSession session,String header,String value){}
    @BeforeEach void setup(){
        peer="198.51.100."+peers.incrementAndGet();hash=encoder.encode("RateLimitFixture2026!");
        when(auth.loadUserByUsername(anyString())).thenAnswer(call->{if(!"valid".equals(call.getArgument(0)))throw new org.springframework.security.core.userdetails.UsernameNotFoundException("Invalid credentials");return principal();});
        when(auth.credentialFingerprint(anyString())).thenReturn(AuthService.fingerprint(hash));when(auth.reload(anyString())).thenAnswer(call->principal());
    }
    AccountPrincipal principal(){var account=new TaiKhoan();account.setMaTK("MOCK");account.setTenDangNhap("valid");account.setMatKhau(hash);account.setTrangThai("Hoạt động");var role=new VaiTro();role.setMaVaiTro("VT01");account.setVaiTro(role);return new AccountPrincipal(account,List.of(new SimpleGrantedAuthority("ROLE_CUSTOMER")));}
    Token token()throws Exception{var result=mvc.perform(get("/api/auth/csrf")).andReturn();var data=json.readTree(result.getResponse().getContentAsString()).path("data");return new Token((MockHttpSession)result.getRequest().getSession(),data.path("headerName").asText(),data.path("token").asText());}
    ResultActions login(String address,String id,String password,String... headers)throws Exception{
        var t=token();var request=post("/api/auth/login").session(t.session()).header(t.header(),t.value()).param("identifier",id).param("password",password).with(r->{r.setRemoteAddr(address);return r;});
        for(int i=0;i<headers.length;i+=2)request.header(headers[i],headers[i+1]);return mvc.perform(request);
    }
    @Test void rejectsThirdWrongAttemptWithRetryAfterAndWithoutCallingAuthenticationAgain()throws Exception{
        login(peer,"missing","bad").andExpect(status().isUnauthorized());login(peer,"missing","bad").andExpect(status().isUnauthorized());
        login(peer,"missing","bad").andExpect(status().isTooManyRequests()).andExpect(header().exists("Retry-After")).andExpect(jsonPath("$.data.retryAfterSeconds").value(org.hamcrest.Matchers.greaterThan(0)));
        verify(auth,times(2)).loadUserByUsername("missing");mvc.perform(get("/api/auth/csrf")).andExpect(status().isOk());
    }
    @Test void forwardedHeadersCannotBypassPeerLimitAndOtherPeerCanStillTry()throws Exception{
        login(peer,"missing","bad").andExpect(status().isUnauthorized());login(peer,"missing","bad").andExpect(status().isUnauthorized());
        login(peer," MISSING ","bad","X-Forwarded-For","203.0.113.8","CF-Connecting-IP","203.0.113.9").andExpect(status().isTooManyRequests());
        login("203.0.113.10","missing","bad").andExpect(status().isUnauthorized());
    }
    @Test void ipLimitStillAppliesWhenIdentifiersAreRotated()throws Exception{
        for(int i=0;i<4;i++)login(peer,"missing"+i,"bad").andExpect(status().isUnauthorized());
        login(peer,"valid","RateLimitFixture2026!").andExpect(status().isTooManyRequests());
    }
    @Test void missingCsrfDoesNotConsumeLoginBudget()throws Exception{
        for(int i=0;i<4;i++)mvc.perform(post("/api/auth/login").param("identifier","valid").param("password","bad").with(r->{r.setRemoteAddr(peer);return r;})).andExpect(status().isForbidden());
        login(peer,"valid","RateLimitFixture2026!").andExpect(status().isOk());
    }
    @Test void successBeforeThresholdResetsPairAndDoesNotLeakPassword()throws Exception{
        login(peer,"valid","bad").andExpect(status().isUnauthorized());
        var success=login(peer,"valid","RateLimitFixture2026!").andExpect(status().isOk()).andReturn();
        Assertions.assertFalse(success.getResponse().getContentAsString().contains("RateLimitFixture2026!"));
        login(peer,"valid","bad").andExpect(status().isUnauthorized());login(peer,"valid","RateLimitFixture2026!").andExpect(status().isOk());
    }
    @Test void authenticationInfrastructureErrorsDoNotConsumeFailureBudget()throws Exception{
        doThrow(new org.springframework.security.authentication.InternalAuthenticationServiceException("Fixture outage")).when(auth).loadUserByUsername("outage");
        for(int i=0;i<4;i++)login(peer,"outage","bad").andExpect(status().isUnauthorized());
        login(peer,"valid","RateLimitFixture2026!").andExpect(status().isOk());
    }
    @Test void contextPathAndDecodedServletPathStillUseLimiter()throws Exception{
        for(int i=0;i<3;i++){var t=token();mvc.perform(post("/api/auth/login").contextPath("/api").servletPath("/api/auth/login").session(t.session()).header(t.header(),t.value()).param("identifier","missing").param("password","bad").with(r->{r.setRemoteAddr(peer);return r;})).andExpect(status().is(i<2?401:429));}
    }
}
