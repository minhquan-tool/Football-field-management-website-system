package com.sanbong.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sanbong.dto.ApiResponse;
import com.sanbong.security.LoginAttemptLimiter;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.Map;

/** Runs after CSRF and before the form-login authentication filter. */
public final class LoginRateLimitFilter extends OncePerRequestFilter {
    public static final String CREDENTIAL_FAILURE=LoginRateLimitFilter.class.getName()+".credentialFailure";
    public static final String SUCCESS=LoginRateLimitFilter.class.getName()+".success";
    private final LoginAttemptLimiter limiter;
    private final ObjectMapper json;
    public LoginRateLimitFilter(LoginAttemptLimiter limiter,ObjectMapper json){this.limiter=limiter;this.json=json;}
    @Override protected boolean shouldNotFilter(HttpServletRequest request){
        String path=request.getServletPath();
        if(path.isEmpty())path=request.getRequestURI().substring(request.getContextPath().length());
        return !"POST".equals(request.getMethod())||!"/auth/login".equals(path);
    }
    @Override protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain)throws ServletException,IOException {
        // Do not trust user-supplied X-Forwarded-For/CF-Connecting-IP headers.
        var admission=limiter.acquire(request.getRemoteAddr(),request.getParameter("identifier"));
        if(!admission.allowed()){
            response.setStatus(429);response.setContentType("application/json;charset=UTF-8");
            response.setHeader("Retry-After",String.valueOf(admission.retryAfterSeconds()));
            response.setHeader("Cache-Control","no-store");
            json.writeValue(response.getOutputStream(),new ApiResponse<>(false,
                    "Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau "+admission.retryAfterSeconds()+" giây.",Map.of("retryAfterSeconds",admission.retryAfterSeconds())));
            return;
        }
        try{chain.doFilter(request,response);}
        finally{limiter.complete(admission.attempt(),Boolean.TRUE.equals(request.getAttribute(SUCCESS)),Boolean.TRUE.equals(request.getAttribute(CREDENTIAL_FAILURE)));}
    }
}
