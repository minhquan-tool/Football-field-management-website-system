package com.sanbong;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Anonymous CSS/fonts must load before login; no fixture/business writes. */
class LocalAssetsHttpTest extends RoleAuditSupport {
    @Test void loginReferencesOnlyLocalStyles() throws Exception {
        String html=mvc.perform(get("/dang-nhap")).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertTrue(html.contains("css/tailwind.css"));assertTrue(html.contains("vendor/montserrat/montserrat.css"));
        assertFalse(html.contains("cdn.tailwindcss.com"));assertFalse(html.contains("fonts.googleapis.com"));
    }
    @Test void vendorCssIsAnonymousStylesheetInsteadOfJsonAuthenticationResponse() throws Exception {
        for(String path:new String[]{"/vendor/fontawesome/css/all.min.css","/vendor/montserrat/montserrat.css","/css/tailwind.css"})
            mvc.perform(get(path)).andExpect(status().isOk()).andExpect(content().contentTypeCompatibleWith("text/css"));
    }
    @Test void anonymousFontsAndLogoAreAvailable() throws Exception {
        for(String path:new String[]{"/vendor/fontawesome/webfonts/fa-solid-900.woff2","/vendor/montserrat/Montserrat-Variable.ttf","/assets/hcmute-logo.png"})
            assertTrue(mvc.perform(get(path)).andExpect(status().isOk()).andReturn().getResponse().getContentAsByteArray().length>1000);
    }
    @Test void staticReadPermissionDoesNotAllowUnauthenticatedWrites() throws Exception {
        mvc.perform(post("/vendor/fontawesome/css/all.min.css")).andExpect(status().isForbidden());
    }
}
