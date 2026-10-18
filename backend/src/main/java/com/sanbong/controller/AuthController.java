package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {
    private final AuthService service;
    public AuthController(AuthService service) { this.service=service; }
    @GetMapping("/csrf")
    public ApiResponse<?> csrf(CsrfToken token) {
        return ApiResponse.ok("CSRF token",Map.of("headerName",token.getHeaderName(),"token",token.getToken()));
    }
    @PostMapping("/register")
    public ApiResponse<?> register(@Valid @RequestBody RegisterRequest request) {
        service.register(request); return ApiResponse.ok("Đăng ký thành công.",null);
    }
    @GetMapping("/me")
    public ApiResponse<?> me(@AuthenticationPrincipal AccountPrincipal account) {
        return ApiResponse.ok("Thông tin phiên đăng nhập",account.profile());
    }
    @GetMapping("/permissions")
    public ApiResponse<?> permissions(@AuthenticationPrincipal AccountPrincipal account) {
        return ApiResponse.ok("Quyền hiện tại",account.getAuthorities().stream().map(a -> a.getAuthority()).toList());
    }
}
