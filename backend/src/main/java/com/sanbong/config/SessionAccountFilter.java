package com.sanbong.config;

import com.sanbong.service.AuthService;
import com.sanbong.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

/** Reload status and permissions so locked accounts and revoked rights take effect immediately. */
public class SessionAccountFilter extends OncePerRequestFilter {
    private final AuthService service;
    private final ObjectMapper json;
    public SessionAccountFilter(AuthService service,ObjectMapper json) { this.service=service; this.json=json; }
    @Override
    protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain)
            throws ServletException,IOException {
        var auth=SecurityContextHolder.getContext().getAuthentication();
        if(auth!=null && auth.getPrincipal() instanceof AccountPrincipal old) {
            try {
                var current=service.reload(old.accountId());
                if(!current.isEnabled()) throw new UsernameNotFoundException("Locked account");
                var session=request.getSession(false);
                String fingerprint=AuthService.fingerprint(current.getPassword());
                if(session!=null) {
                    Object saved=session.getAttribute("credentialFingerprint");
                    if(saved!=null && !fingerprint.equals(saved)) throw new UsernameNotFoundException("Credentials changed");
                    session.setAttribute("credentialFingerprint",fingerprint);
                }
                current.eraseCredentials();
                var refreshed=UsernamePasswordAuthenticationToken.authenticated(current,null,current.getAuthorities());
                refreshed.setDetails(auth.getDetails());
                SecurityContextHolder.getContext().setAuthentication(refreshed);
            } catch(UsernameNotFoundException e) {
                SecurityContextHolder.clearContext();
                var session=request.getSession(false); if(session!=null) session.invalidate();
            } catch(org.springframework.dao.DataAccessException e) {
                response.setStatus(503); response.setContentType("application/json;charset=UTF-8");
                json.writeValue(response.getOutputStream(),ApiResponse.error("Database tạm thời không khả dụng."));
                return;
            }
        }
        chain.doFilter(request,response);
    }
}
