package com.sanbong.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.ResponseCookie;

/** Persist only the opaque server session identifier, never credentials. */
public final class RememberLoginSession {
    private RememberLoginSession() { }
    public static void apply(HttpServletRequest request, HttpServletResponse response,
                             int rememberSeconds, boolean secureCookie) {
        boolean remember = "true".equals(request.getParameter("remember-me"));
        var session = request.getSession();
        if (remember) session.setMaxInactiveInterval(Math.max(1800, Math.min(rememberSeconds, 2592000)));
        else session.setMaxInactiveInterval(Math.max(1, request.getServletContext().getSessionTimeout()) * 60);
        String path = request.getContextPath().isEmpty() ? "/" : request.getContextPath();
        response.addHeader("Set-Cookie", ResponseCookie.from("JSESSIONID", session.getId())
                .path(path).httpOnly(true).secure(secureCookie || request.isSecure()).sameSite("Lax")
                .maxAge(remember ? session.getMaxInactiveInterval() : -1).build().toString());
    }
}
