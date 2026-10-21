package com.sanbong;

import com.sanbong.controller.PublicPromotionController;
import com.sanbong.service.CustomerCareService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.List;
import java.util.Map;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PublicPromotionControllerTest {
    private org.springframework.test.web.servlet.MockMvc mvc(CustomerCareService service) {
        return MockMvcBuilders.standaloneSetup(new PublicPromotionController(service))
                .setCustomHandlerMapping(() -> {
                    var mapping = new org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping();
                    mapping.setPathPrefixes(Map.of("/api", type -> type.isAnnotationPresent(org.springframework.web.bind.annotation.RestController.class)));
                    return mapping;
                }).build();
    }
    @Test void exposesExistingCatalogWithoutWriteRoutes() throws Exception {
        var service = mock(CustomerCareService.class);
        when(service.promotions()).thenReturn(List.of(Map.of("maKM", "SAN20", "mucGiam", 20)));
        var mvc = mvc(service);
        mvc.perform(get("/api/public/promotions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].maKM").value("SAN20"));
        mvc.perform(post("/api/public/promotions")).andExpect(status().isMethodNotAllowed());
        mvc.perform(put("/api/public/promotions")).andExpect(status().isMethodNotAllowed());
        mvc.perform(delete("/api/public/promotions")).andExpect(status().isMethodNotAllowed());
        verify(service, times(1)).promotions();
        verifyNoMoreInteractions(service);
    }

    @Test void emptyCatalogDoesNotInventPromotions() throws Exception {
        var service = mock(CustomerCareService.class);
        when(service.promotions()).thenReturn(List.of());
        mvc(service)
                .perform(get("/api/public/promotions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
    }
}
