package com.sanbong.dto;
import jakarta.validation.constraints.*;

public record PitchRequest(
        @NotBlank @Pattern(regexp="[A-Za-z0-9_-]{1,10}") String maSan,
        @NotBlank @Size(max=50) String tenSan,
        @NotBlank @Size(max=10) String maLoaiSan,
        @NotBlank @Pattern(regexp="Trống|Đang sử dụng|Bảo trì") String trangThai,
        @Size(max=255) String moTa) { }
