package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record ServiceSaleRequest(@Min(1) int soLuong,@Pattern(regexp="DON_VI|LOC_6") String quyCach) { }
