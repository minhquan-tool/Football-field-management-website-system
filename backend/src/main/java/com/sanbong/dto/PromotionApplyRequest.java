package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record PromotionApplyRequest(@NotBlank @Size(max=32) @Pattern(regexp="[A-Za-z0-9_-]+",message="Mã khuyến mãi chỉ gồm chữ không dấu, số, gạch ngang hoặc gạch dưới.") String maKM) { }
