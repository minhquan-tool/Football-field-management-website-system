package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record PaymentRequest(@NotNull @DecimalMin("0.01") @Digits(integer=16,fraction=2) BigDecimal soTien,
 @NotBlank @Pattern(regexp="Tiền mặt|Chuyển khoản") String phuongThuc,
 @NotBlank @Pattern(regexp="[a-zA-Z0-9_-]{8,50}") String idempotencyKey, Boolean daNhanTien,
 @Pattern(regexp="DEPOSIT_40|FULL") String paymentPlan) {
 public PaymentRequest(BigDecimal soTien,String phuongThuc,String idempotencyKey,Boolean daNhanTien){this(soTien,phuongThuc,idempotencyKey,daNhanTien,null);}
}
