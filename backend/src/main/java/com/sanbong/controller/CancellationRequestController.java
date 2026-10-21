package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.CancellationRequestService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
public class CancellationRequestController {
 private final CancellationRequestService service;
 public CancellationRequestController(CancellationRequestService service){this.service=service;}
 public record Decision(@NotNull Boolean approve,@NotBlank @Size(max=255) String ghiChu){}
 @GetMapping("/finance/cancellation-requests")
 @PreAuthorize("(hasRole('CUSTOMER') and hasAuthority('CN02_XEM')) or (hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN04_XEM'))")
 public ApiResponse<?> list(@RequestParam(defaultValue="PENDING") String status,@RequestParam(defaultValue="1") int page,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Yêu cầu hủy đặt sân",service.list(actor,status,page));}
 @PostMapping("/bookings/{id}/cancellation-requests")
 @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN02_SUA')")
 public ApiResponse<?> submit(@PathVariable String id,@Valid @RequestBody BookingCancelRequest request,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã gửi yêu cầu hủy; sân vẫn được giữ trong lúc chờ duyệt.",service.submit(id,request.lyDo(),actor));}
 @PostMapping("/finance/cancellation-requests/{id}/decision")
 @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN04_SUA')")
 public ApiResponse<?> decide(@PathVariable String id,@Valid @RequestBody Decision request,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok(request.approve()?"Đã duyệt hủy; khoản hoàn nếu có cần xác nhận chi thực tế riêng.":"Đã từ chối yêu cầu; lượt đặt vẫn được giữ.",service.decide(id,request.approve(),request.ghiChu(),actor));}
}
