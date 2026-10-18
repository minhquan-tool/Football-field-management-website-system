package com.sanbong;
import com.sanbong.controller.*;
import com.sanbong.service.PublicPitchService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PublicHomeRoutingTest {
    @Test void rootShowsGuestLandingBeforeLogin() throws Exception {
        MockMvcBuilders.standaloneSetup(new HomeController()).build().perform(get("/"))
                .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/Trang_chu.html"));
    }
    @Test void guestControllerHasReadEndpointsOnly() throws Exception {
        var service=mock(PublicPitchService.class);
        when(service.catalog("", "")).thenReturn(List.of());
        var mvc=MockMvcBuilders.standaloneSetup(new PublicPitchController(service)).build();
        mvc.perform(get("/public/pitches")).andExpect(status().isOk()).andExpect(jsonPath("$.success").value(true));
        mvc.perform(post("/public/pitches")).andExpect(status().isMethodNotAllowed());
    }
}
