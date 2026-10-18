package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record NewServiceRequest(@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{1,10}") String maDV,
        @NotBlank @Size(max=100) String tenDV,@NotBlank @Size(max=20) String donViTinh,
        @NotNull @DecimalMin("0.01") @Digits(integer=16,fraction=2) BigDecimal donGia,
        @NotNull Boolean hoTroLoc) {}
