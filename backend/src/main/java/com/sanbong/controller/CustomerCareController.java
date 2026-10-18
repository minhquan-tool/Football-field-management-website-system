package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.CustomerCareService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController
public class CustomerCareController {
    private final CustomerCareService service;
    private final com.sanbong.service.AuthService authentication;
    public CustomerCareController(CustomerCareService service,com.sanbong.service.AuthService authentication){this.service=service;this.authentication=authentication;}
    @PostMapping("/customer/password") @PreAuthorize("hasRole('CUSTOMER')")
    public ApiResponse<?> password(@AuthenticationPrincipal AccountPrincipal a,@Valid @RequestBody CustomerPasswordRequest r){
        authentication.changeCustomerPassword(a,r);
        return ApiResponse.ok("Đã đổi mật khẩu. Vui lòng đăng nhập lại.",null);
    }
    @GetMapping("/customer/profile") @PreAuthorize("hasRole('CUSTOMER')")
    public ApiResponse<?> profile(@AuthenticationPrincipal AccountPrincipal a){return ApiResponse.ok("Hồ sơ của bạn",service.profile(a));}
    @GetMapping("/customer/promotions") @PreAuthorize("hasRole('CUSTOMER')")
    public ApiResponse<?> promotions(){return ApiResponse.ok("Khuyến mãi hiện có",service.promotions());}
    @PutMapping("/customer/profile") @PreAuthorize("hasRole('CUSTOMER')")
    public ApiResponse<?> profile(@AuthenticationPrincipal AccountPrincipal a,@Valid @RequestBody CustomerProfileRequest r){return ApiResponse.ok("Đã lưu hồ sơ",service.profile(a,r));}
    @GetMapping("/customer/history") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN02_XEM')")
    public ApiResponse<?> history(@AuthenticationPrincipal AccountPrincipal a,
            @RequestParam(required=false) Integer page,@RequestParam(defaultValue="20") int size,
            @RequestParam(defaultValue="") String q,@RequestParam(defaultValue="") String state,@RequestParam(defaultValue="desc") String order){
        return ApiResponse.ok("Lịch sử của bạn",page==null&&size==20&&q.isEmpty()&&state.isEmpty()&&order.equals("desc")
                ?service.history(a):service.history(a,page==null?1:page,size,q,state,order));
    }
    @PostMapping("/customer/bookings/{id}/review") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN05_THEM')")
    public ApiResponse<?> review(@PathVariable String id,@Valid @RequestBody ReviewRequest r,@AuthenticationPrincipal AccountPrincipal a){service.review(id,r,a);return ApiResponse.ok("Đã lưu đánh giá",null);}
    @GetMapping("/feedback") @PreAuthorize("hasAnyRole('CUSTOMER','PITCH_STAFF','ADMIN') and hasAuthority('CN05_XEM')")
    public ApiResponse<?> feedback(@AuthenticationPrincipal AccountPrincipal a){return ApiResponse.ok("Phản hồi",service.feedback(a));}
    @PostMapping("/feedback") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN05_THEM')")
    public ApiResponse<?> feedback(@Valid @RequestBody FeedbackRequest r,@AuthenticationPrincipal AccountPrincipal a){service.feedback(r,a);return ApiResponse.ok("Đã tiếp nhận phản hồi",null);}
    @PutMapping("/feedback/{id}") @PreAuthorize("hasAnyRole('PITCH_STAFF','ADMIN') and hasAuthority('CN05_SUA')")
    public ApiResponse<?> resolve(@PathVariable String id,@Valid @RequestBody FeedbackResolutionRequest r,@AuthenticationPrincipal AccountPrincipal a){service.resolve(id,r,a);return ApiResponse.ok("Đã lưu kết quả xử lý",null);}
}
