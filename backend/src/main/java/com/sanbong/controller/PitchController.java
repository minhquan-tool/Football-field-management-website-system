package com.sanbong.controller;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.PitchService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping
public class PitchController {
    private final PitchService service;
    public PitchController(PitchService service) { this.service=service; }
    @GetMapping("/pitches") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> list(@RequestParam(required=false) String q,@RequestParam(required=false) String type,
                              @RequestParam(required=false) String status) {
        return ApiResponse.ok("Danh sách sân",service.list(q,type,status));
    }
    @GetMapping("/pitches/{id}") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> detail(@PathVariable String id) { return ApiResponse.ok("Chi tiết sân",service.detail(id)); }
    @GetMapping("/pitch-types") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> types() { return ApiResponse.ok("Loại sân",service.types()); }
    @GetMapping("/pitch-prices") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> prices() { return ApiResponse.ok("Bảng giá theo loại sân",service.allPrices()); }
    @GetMapping("/pitches/{id}/prices") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> prices(@PathVariable String id) { return ApiResponse.ok("Bảng giá của loại sân",service.prices(id)); }
    @PostMapping("/pitches") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN02_THEM')")
    public ApiResponse<?> create(@Valid @RequestBody PitchRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã thêm sân.",service.create(request,actor.accountId()));
    }
    @PutMapping("/pitches/{id}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN02_SUA')")
    public ApiResponse<?> update(@PathVariable String id,@Valid @RequestBody PitchRequest request,
                                 @AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã cập nhật sân.",service.update(id,request,actor.accountId()));
    }
    @PatchMapping("/pitches/{id}/status") @PreAuthorize("hasAuthority('CN02_SUA')")
    public ApiResponse<?> status(@PathVariable String id,@Valid @RequestBody PitchStatusRequest request,
                                 @AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã cập nhật trạng thái.",service.status(id,request.trangThai(),actor.accountId()));
    }
}
