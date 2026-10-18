package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.*;
public record ConfigurationRequest(@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{1,10}") String id,
        @Size(max=100) String ten,@Min(1) @Max(100) Integer soNguoi,@Size(max=255) String moTa,
        LocalTime batDau,LocalTime ketThuc,@DecimalMin("0.01") @Digits(integer=16,fraction=2) BigDecimal donGia,
        LocalDate tuNgay,LocalDate denNgay,Boolean hoatDong,
        @Size(max=10) String loaiSan,@Size(max=10) String khungGio,@Size(max=20) String loaiNgay) {}
