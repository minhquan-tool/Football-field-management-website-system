package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record ServiceCatalogRequest(@NotNull @DecimalMin("0.01") @Digits(integer=16,fraction=2) BigDecimal donGia,
 @NotNull Boolean trangThai,@NotNull Boolean hoTroLoc) { }
