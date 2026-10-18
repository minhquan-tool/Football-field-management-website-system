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
    SecurityFilterChain security(HttpSecurity http,AuthService service,ObjectMapper json,com.sanbong.security.LoginAttemptLimiter limiter) throws Exception {
        http.authorizeHttpRequests(a -> a
                .requestMatchers(org.springframework.http.HttpMethod.GET,"/Trang_chu.html","/css/**","/assets/**","/vendor/**",
                        "/public/options","/public/pitches","/public/availability").permitAll()
                .requestMatchers("/","/Dang_nhap.html","/Dang_ky.html","/js/**","/auth/csrf","/auth/register","/health","/error").permitAll()
                .requestMatchers("/Man_hinh_chinh_TK&PQ_HT.html").hasRole("ADMIN")
                .requestMatchers("/Tai_khoan_KH.html","/customer/**").hasRole("CUSTOMER")
                .requestMatchers("/Phan_hoi.html","/feedback","/feedback/**").hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/Cau_hinh_san.html","/Sao_luu.html","/configuration/**").hasRole("ADMIN")
                .requestMatchers("/Man_hinh_chinh.html").hasRole("ADMIN")
                .requestMatchers("/Man_hinh_chinh_NVKT.html").hasAnyRole("ACCOUNTANT","ADMIN")
                .requestMatchers("/Man_hinh_chinh_NVKH.html","/Dat_san_tai_quay.html","/Quan_ly_san.html")
                    .hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/Lich_da_bong.html","/staff/weekly-schedule").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/Quan_ly_lich_dat_san.html","/availability","/booking-options","/booking-customers","/bookings","/bookings/**")
                    .hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/Man_hinh_chinh_KH.html","/Man_hinh_chinh_Dat_san_KH.html",
                        "/Man_hinh_Khuyen_mai_KH.html","/Man_hinh_LS&ĐG_KH.html").hasRole("CUSTOMER")
                .requestMatchers("/pitches","/pitches/**","/pitch-types","/pitch-prices").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/reports/**","/Bao_cao.html").hasAnyRole("ADMIN","ACCOUNTANT","PITCH_STAFF")
                .requestMatchers("/finance/**").hasAnyRole("CUSTOMER","PITCH_STAFF","ACCOUNTANT","ADMIN")
                .requestMatchers("/booking-services").hasAnyRole("CUSTOMER","PITCH_STAFF","ADMIN")
                .requestMatchers("/service-catalog","/service-catalog/**").hasRole("ADMIN")
                .requestMatchers("/services","/operations/**").hasAnyRole("PITCH_STAFF","ADMIN")
                .requestMatchers("/auth/me","/auth/permissions","/security/**").authenticated()
                .anyRequest().denyAll())
            .formLogin(f -> f.loginPage("/Dang_nhap.html").loginProcessingUrl("/auth/login")
                .usernameParameter("identifier").passwordParameter("password").permitAll()
                .successHandler((req,res,auth) -> {
                    var principal=(AccountPrincipal)auth.getPrincipal();
                    try {
                        service.audit(principal.accountId(),"Đăng nhập","Đăng nhập thành công");
                        req.getSession().setAttribute("credentialFingerprint",service.credentialFingerprint(principal.accountId()));
                        req.setAttribute(LoginRateLimitFilter.SUCCESS,true);
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
            .logout(l -> l.logoutUrl("/auth/logout")
                .addLogoutHandler((req,res,auth) -> {
                    if(auth!=null && auth.getPrincipal() instanceof AccountPrincipal p)
                        service.audit(p.accountId(),"Đăng xuất","Đăng xuất khỏi hệ thống");
                })
                .logoutSuccessHandler((req,res,auth) -> write(json,res,200,ApiResponse.ok("Đã đăng xuất.",null))))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req,res,err) -> {
                    if(req.getServletPath().endsWith(".html") || "/".equals(req.getServletPath()))
                        res.sendRedirect(req.getContextPath()+"/Dang_nhap.html");
                    else write(json,res,401,ApiResponse.error("Bạn cần đăng nhập."));
                })
                .accessDeniedHandler((req,res,err) -> {
                    if ("GET".equals(req.getMethod()) && req.getServletPath().endsWith(".html")
                            && req.getUserPrincipal() instanceof org.springframework.security.core.Authentication authentication
                            && authentication.getPrincipal() instanceof AccountPrincipal account) {
                        String page=switch(account.roleId()) {
                            case "VT01" -> "Man_hinh_chinh_KH.html";
                            case "VT02" -> "Man_hinh_chinh_NVKH.html";
                            case "VT03" -> "Man_hinh_chinh_NVKT.html";
                            default -> "Man_hinh_chinh.html";
                        };
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
