package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.time.*;
public record RescheduleRequest(@NotNull LocalDate ngayChoi,@NotNull LocalTime gioBatDau,
        @NotNull LocalTime gioKetThuc,@NotBlank @Size(max=255) String lyDo) {}
