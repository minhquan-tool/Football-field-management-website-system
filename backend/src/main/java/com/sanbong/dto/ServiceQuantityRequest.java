package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record ServiceQuantityRequest(@NotNull @Min(1) Integer soLuong) { }
