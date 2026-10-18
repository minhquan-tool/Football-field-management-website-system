package com.sanbong.controller;

import com.sanbong.dto.ApiResponse;
import com.sanbong.service.PublicPitchService;
import org.springframework.web.bind.annotation.*;
import java.time.*;

@RestController
@RequestMapping("/public")
public class PublicPitchController {
    private final PublicPitchService service;
    public PublicPitchController(PublicPitchService service) { this.service = service; }
    @GetMapping("/options")
    public ApiResponse<?> options() { return ApiResponse.ok("Thông tin tra cứu sân công khai", service.options()); }
    @GetMapping("/pitches")
    public ApiResponse<?> pitches(@RequestParam(defaultValue = "") String q, @RequestParam(defaultValue = "") String type) {
        return ApiResponse.ok("Danh mục sân bóng", service.catalog(q, type));
    }
    @GetMapping("/availability")
    public ApiResponse<?> availability(@RequestParam LocalDate date, @RequestParam LocalTime start,
            @RequestParam LocalTime end, @RequestParam(defaultValue = "") String type,
            @RequestParam(defaultValue = "") String q) {
        return ApiResponse.ok("Sân còn trống theo khoảng giờ", service.availability(date, type, start, end, q));
    }
}
