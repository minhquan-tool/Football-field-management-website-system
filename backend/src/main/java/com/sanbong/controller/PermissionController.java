package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.PermissionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotNull;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/security")
public class PermissionController {
    private final PermissionService service;
    public PermissionController(PermissionService service) { this.service=service; }
    @GetMapping("/accounts") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_XEM')")
    public ApiResponse<?> accounts() { return ApiResponse.ok("Danh sách tài khoản",service.accounts()); }
    @GetMapping("/permissions") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN08_XEM')")
    public ApiResponse<?> permissions(@RequestParam(defaultValue="VT02") String role) {
        return ApiResponse.ok("Ma trận quyền",service.matrix(role));
    }
    @PutMapping("/permissions/{role}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN08_SUA')")
    public ApiResponse<?> save(@PathVariable String role,
            @Valid @RequestBody @Size(min=8,max=8) List<@NotNull @Valid PermissionRequest> permissions,
            @AuthenticationPrincipal AccountPrincipal actor) {
        service.save(role,permissions,actor.accountId());
        return ApiResponse.ok("Đã lưu phân quyền.",null);
    }
}
