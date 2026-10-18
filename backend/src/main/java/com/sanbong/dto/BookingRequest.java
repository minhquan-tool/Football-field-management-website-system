package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalTime;
public record BookingRequest(@NotBlank @Size(max=10) String maSan,
        @NotNull LocalDate ngayChoi,@Size(max=10) String maKhungGio,
        @Size(max=10) String maKH,@Size(max=255) String ghiChu,
        LocalTime gioBatDau,LocalTime gioKetThuc,
        @Size(max=50) java.util.List<@jakarta.validation.Valid @NotNull PrebookServiceRequest> dichVu) { }
