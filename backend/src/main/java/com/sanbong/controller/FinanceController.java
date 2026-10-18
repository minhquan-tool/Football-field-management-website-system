package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.FinanceService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController
public class FinanceController {
 private final FinanceService service;
 private final com.sanbong.service.BankTransferService transfers;
 public FinanceController(FinanceService service,com.sanbong.service.BankTransferService transfers) { this.service=service;this.transfers=transfers; }
 @GetMapping("/finance/bookings/{id}/transfer-instructions") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN04_XEM')")
 public ApiResponse<?> transfer(@PathVariable String id,@RequestParam java.math.BigDecimal amount,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Thông tin chuyển khoản; chưa xác nhận nhận tiền.",transfers.instructions(id,amount,actor));}
 @GetMapping("/finance/bookings/{id}/bank-qr") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN04_XEM')")
 public org.springframework.http.ResponseEntity<byte[]> bankQr(@PathVariable String id,@RequestParam java.math.BigDecimal amount,@AuthenticationPrincipal AccountPrincipal actor){return transfers.image(id,amount,actor);}
 @PostMapping("/finance/payments/{id}/confirm-cash") @PreAuthorize("hasRole('PITCH_STAFF') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> cash(@PathVariable String id,@Valid @RequestBody ReceiptConfirmation request,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Nhân viên đã xác nhận thực nhận tiền mặt.",service.confirmCashPayment(id,actor));}
 @GetMapping("/finance/bookings/{id}") @PreAuthorize("hasAuthority('CN04_XEM')")
 public ApiResponse<?> detail(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Tài chính booking",service.detail(id,actor)); }
 @GetMapping("/finance/bookings/{id}/cancel-preview") @PreAuthorize("hasAuthority('CN04_XEM')")
 public ApiResponse<?> preview(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Dự kiến hoàn theo thời điểm hiện tại",service.cancelPreview(id,actor)); }
 @GetMapping("/finance/promotions") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> promotions() { return ApiResponse.ok("Khuyến mãi phần trăm",service.promotions()); }
 @GetMapping("/finance/transactions") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_XEM')")
 public ApiResponse<?> transactions() { return ApiResponse.ok("Giao dịch thực tế",service.transactions()); }
 @PostMapping("/finance/bookings/{id}/invoice") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> invoice(@PathVariable String id,@Valid @RequestBody InvoiceRequest request,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Hóa đơn snapshot",service.invoice(id,request,actor)); }
 @PostMapping("/finance/bookings/{id}/promotion") @PreAuthorize("hasRole('CUSTOMER') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> promotion(@PathVariable String id,@Valid @RequestBody PromotionApplyRequest request,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã áp dụng khuyến mãi vào tiền sân.",service.applyCustomerPromotion(id,request,actor));}
 @PostMapping("/finance/bookings/{id}/payments") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> pay(@PathVariable String id,@Valid @RequestBody PaymentRequest request,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Đã ghi nhận thực thu nội bộ.",service.pay(id,request,actor,true)); }
 @PostMapping("/finance/bookings/{id}/payment-requests") @PreAuthorize("hasAnyRole('CUSTOMER','PITCH_STAFF') and hasAuthority('CN04_THEM')")
 public ApiResponse<?> request(@PathVariable String id,@Valid @RequestBody PaymentRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
  if("VT02".equals(actor.roleId()) && !"Chuyển khoản".equals(request.phuongThuc())) throw new org.springframework.security.access.AccessDeniedException("Nhân viên chỉ gửi chuyển khoản chờ kế toán xác minh qua thao tác này.");
  return ApiResponse.ok("Đang chờ nhân viên xác minh; chưa xác nhận thu tiền.",service.pay(id,request,actor,false));
 }
 @PostMapping("/finance/payments/{id}/confirm") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_SUA')")
 public ApiResponse<?> confirm(@PathVariable String id,@Valid @RequestBody ReceiptConfirmation request,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Đã xác nhận thực thu.",service.confirmPayment(id,actor,true)); }
 @PostMapping("/finance/payments/{id}/reject") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN04_SUA')")
 public ApiResponse<?> reject(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Đã từ chối giao dịch chờ.",service.confirmPayment(id,actor,false)); }
 @PostMapping("/finance/refunds/{id}/confirm") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN04_SUA')")
 public ApiResponse<?> refund(@PathVariable String id,@Valid @RequestBody RefundConfirmation request,@AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Nhân viên xác nhận đã hoàn thực tế, ứng dụng không tự chuyển tiền.",service.refund(id,request,actor)); }
}
