package com.sanbong.config;

import com.sanbong.dto.ApiResponse;
import com.sanbong.service.AuthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import com.sanbong.security.BoundedBcryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.context.SecurityContextHolderFilter;
import jakarta.servlet.http.HttpServletResponse;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {
    private static final org.slf4j.Logger log=org.slf4j.LoggerFactory.getLogger(SecurityConfig.class);
    @Bean
    PasswordEncoder passwordEncoder() { return new BoundedBcryptPasswordEncoder(); }
    @Bean
    com.sanbong.security.LoginAttemptLimiter loginAttemptLimiter(
            @org.springframework.beans.factory.annotation.Value("${app.security.login-limit.per-identifier:5}") int perIdentifier,
            @org.springframework.beans.factory.annotation.Value("${app.security.login-limit.per-ip:30}") int perIp,
            @org.springframework.beans.factory.annotation.Value("${app.security.login-limit.window-seconds:300}") int seconds,
            @org.springframework.beans.factory.annotation.Value("${app.security.login-limit.max-entries:10000}") int maxEntries){
        return new com.sanbong.security.LoginAttemptLimiter(perIdentifier,perIp,seconds,maxEntries);
    }

    @Bean
    SecurityFilterChain security(HttpSecurity http,AuthService service,ObjectMapper json,com.sanbong.security.LoginAttemptLimiter limiter,
            @org.springframework.beans.factory.annotation.Value("${app.security.remember-seconds:604800}") int rememberSeconds,
            @org.springframework.beans.factory.annotation.Value("${server.servlet.session.cookie.secure:false}") boolean secureCookie) throws Exception {
        http.authorizeHttpRequests(a -> a
                .requestMatchers(org.springframework.http.HttpMethod.GET,com.sanbong.controller.PageController.legacyPaths()).permitAll()
                .requestMatchers(org.springframework.http.HttpMethod.GET,"/trang-chu","/css/**","/assets/**","/vendor/**","/api/public/options","/api/public/pitches","/api/public/availability","/api/public/promotions").permitAll()
                .requestMatchers("/","/api","/api/","/dang-nhap","/dang-ky","/js/**","/api/auth/csrf","/api/auth/register","/api/health","/error").permitAll()
                .requestMatchers("/nhan-su-phan-quyen","/cau-hinh","/sao-luu","/quan-tri","/doanh-thu","/api/configuration/**","/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/tai-khoan","/khach-hang","/dat-san","/lich-dat-cua-toi","/lich-su-dat-san","/khuyen-mai","/api/customer/**").hasRole("CUSTOMER")
                .requestMatchers("/phan-hoi","/api/feedback","/api/feedback/**").hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/hoa-don","/hoan-tien","/thanh-toan").hasAnyRole("ACCOUNTANT","ADMIN")
                .requestMatchers("/nhan-vien","/dat-san-tai-quay","/quan-ly-san","/lich-san","/dieu-phoi-san","/api/staff/weekly-schedule").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/api/availability","/api/booking-options","/api/booking-customers","/api/bookings","/api/bookings/**").hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/api/pitches","/api/pitches/**","/api/pitch-types","/api/pitch-prices").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/api/reports/**","/bao-cao").hasAnyRole("ADMIN","ACCOUNTANT","PITCH_STAFF")
                .requestMatchers("/api/finance/**").hasAnyRole("CUSTOMER","PITCH_STAFF","ACCOUNTANT","ADMIN")
                .requestMatchers("/api/booking-services").hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/api/service-catalog","/api/service-catalog/**").hasRole("ADMIN")
                .requestMatchers("/api/services","/api/operations/**").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/api/auth/me","/api/auth/permissions","/api/security/**").authenticated()
                .anyRequest().denyAll())
            .formLogin(f -> f.loginPage("/dang-nhap").loginProcessingUrl("/api/auth/login")
                .usernameParameter("identifier").passwordParameter("password").permitAll()
                .successHandler((req,res,auth) -> {
                    var principal=(AccountPrincipal)auth.getPrincipal();
                    try {
                        service.audit(principal.accountId(),"Đăng nhập","Đăng nhập thành công");
                        req.getSession().setAttribute("credentialFingerprint",service.credentialFingerprint(principal.accountId()));
                        req.setAttribute(LoginRateLimitFilter.SUCCESS,true);
                        com.sanbong.security.RememberLoginSession.apply(req,res,rememberSeconds,secureCookie);
                        write(json,res,200,ApiResponse.ok("Đăng nhập thành công.",principal.profile()));
                    } catch(RuntimeException e) {
                        req.getSession().invalidate();
                        org.springframework.security.core.context.SecurityContextHolder.clearContext();
                        write(json,res,503,ApiResponse.error("Không thể hoàn tất đăng nhập. Vui lòng thử lại."));
                    }
                })
                .failureHandler((req,res,e) -> {
                    req.setAttribute(LoginRateLimitFilter.CREDENTIAL_FAILURE,
                            e instanceof org.springframework.security.authentication.BadCredentialsException
                            || e instanceof org.springframework.security.authentication.AccountStatusException);
                    log.warn("Login rejected type={}",e.getClass().getSimpleName());
                    write(json,res,401,ApiResponse.error("Thông tin đăng nhập không đúng hoặc tài khoản đã bị khóa."));
                }))
            .logout(l -> l.logoutUrl("/api/auth/logout")
                .deleteCookies("JSESSIONID")
                .addLogoutHandler((req,res,auth) -> {
                    if(auth!=null && auth.getPrincipal() instanceof AccountPrincipal p)
                        service.audit(p.accountId(),"Đăng xuất","Đăng xuất khỏi hệ thống");
                })
                .logoutSuccessHandler((req,res,auth) -> write(json,res,200,ApiResponse.ok("Đã đăng xuất.",null))))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req,res,err) -> {
                    if(com.sanbong.controller.PageController.isPage(req.getServletPath()) || "/".equals(req.getServletPath()))
                        res.sendRedirect(req.getContextPath()+"/dang-nhap");
                    else write(json,res,401,ApiResponse.error("Bạn cần đăng nhập."));
                })
                .accessDeniedHandler((req,res,err) -> {
                    if ("GET".equals(req.getMethod()) && com.sanbong.controller.PageController.isPage(req.getServletPath())
                            && req.getUserPrincipal() instanceof org.springframework.security.core.Authentication authentication
                            && authentication.getPrincipal() instanceof AccountPrincipal account) {
                        String page=com.sanbong.controller.PageController.home(account.roleId());
                        res.sendRedirect(req.getContextPath()+"/"+page+"?accessDenied=1");
                    } else write(json,res,403,ApiResponse.error("Bạn không có quyền hoặc CSRF token không hợp lệ."));
                }))
            .addFilterAfter(new SessionAccountFilter(service,json),SecurityContextHolderFilter.class)
            .addFilterBefore(new LoginRateLimitFilter(limiter,json),org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
    private static void write(ObjectMapper json,HttpServletResponse response,int status,Object value)
            throws java.io.IOException {
        response.setStatus(status); response.setContentType("application/json;charset=UTF-8");
        json.writeValue(response.getOutputStream(),value);
    }
}
