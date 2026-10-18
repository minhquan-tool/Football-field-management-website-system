package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record AccountUpdateRequest(@NotNull Boolean hoatDong,@NotNull @Pattern(regexp="VT01|VT02|VT03|VT04") String maVaiTro) {}
