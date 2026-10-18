package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record RefundConfirmation(@NotBlank @Pattern(regexp="Tiền mặt|Chuyển khoản") String phuongThuc,
 @NotNull @AssertTrue Boolean daHoanTien,@NotBlank @Size(max=255) String lyDo) { }
