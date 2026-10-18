package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.ConfigurationService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/configuration")
public class ConfigurationController {
    private final ConfigurationService service;
    public ConfigurationController(ConfigurationService service){this.service=service;}
    @GetMapping @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN02_XEM')")
    public ApiResponse<?> list(){return ApiResponse.ok("Cấu hình sân",service.list());}
    @PutMapping("/{kind}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN02_SUA')")
    public ApiResponse<?> save(@PathVariable String kind,@Valid @RequestBody ConfigurationRequest r,@AuthenticationPrincipal AccountPrincipal a){service.save(kind,r,a.accountId());return ApiResponse.ok("Đã lưu cấu hình, không thay đổi snapshot lịch sử",null);}
}
