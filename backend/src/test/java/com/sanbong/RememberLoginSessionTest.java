package com.sanbong;

import com.sanbong.security.RememberLoginSession;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import static org.junit.jupiter.api.Assertions.*;

class RememberLoginSessionTest {
    @Test void remembersOnlyAnOpaqueSessionCookie() {
        var request = new MockHttpServletRequest(); request.setContextPath("/api");
        request.setParameter("remember-me", "true");
        var response = new MockHttpServletResponse();
        RememberLoginSession.apply(request, response, 604800, true);
        assertEquals(604800, request.getSession().getMaxInactiveInterval());
        String cookie = response.getHeader("Set-Cookie");
        assertTrue(cookie.contains("Max-Age=604800")); assertTrue(cookie.contains("Path=/api"));
        assertTrue(cookie.contains("HttpOnly")); assertTrue(cookie.contains("Secure")); assertTrue(cookie.contains("SameSite=Lax"));
        assertTrue(cookie.contains(request.getSession().getId()));
    }
    @Test void uncheckedKeepsNormalSessionTimeoutAndNoPersistentCookie() {
        var request = new MockHttpServletRequest(); request.getSession().setMaxInactiveInterval(1800);
        request.getServletContext().setSessionTimeout(30);
        var response = new MockHttpServletResponse();
        RememberLoginSession.apply(request, response, 604800, false);
        assertEquals(1800, request.getSession().getMaxInactiveInterval());
        assertFalse(response.getHeader("Set-Cookie").contains("Max-Age"));
    }
    @Test void boundsRememberDuration() {
        var request = new MockHttpServletRequest(); request.setParameter("remember-me", "true");
        RememberLoginSession.apply(request,new MockHttpServletResponse(),Integer.MAX_VALUE,false);
        assertEquals(2592000,request.getSession().getMaxInactiveInterval());
    }
}
