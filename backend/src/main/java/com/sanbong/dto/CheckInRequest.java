package com.sanbong.dto;
import jakarta.validation.constraints.Size;
public record CheckInRequest(@Size(max=255) String tinhTrangSan,@Size(max=255) String ghiChu) { }
