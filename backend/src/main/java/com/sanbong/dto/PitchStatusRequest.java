package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record PitchStatusRequest(@NotBlank @Pattern(regexp="Trống|Đang sử dụng|Bảo trì") String trangThai) { }
