package com.sanbong.controller;

import com.sanbong.dto.ApiResponse;
import com.sanbong.service.CustomerCareService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Public catalog only; applying a promotion still uses the authenticated booking workflow. */
@RestController
public class PublicPromotionController {
    private final CustomerCareService service;

    public PublicPromotionController(CustomerCareService service) {
        this.service = service;
    }

    @GetMapping("/public/promotions")
    public ApiResponse<?> promotions() {
        // Reuse the read-only service and its active/date/discount validity filters.
        return ApiResponse.ok("Chương trình ưu đãi đang áp dụng", service.promotions());
    }
}
