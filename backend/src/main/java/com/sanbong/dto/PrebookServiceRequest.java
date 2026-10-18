package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record PrebookServiceRequest(@NotBlank @Size(max=10) String maDV,
 @Min(1) int soLuong,@NotBlank @Pattern(regexp="DON_VI|LOC_6") String quyCach) { }
