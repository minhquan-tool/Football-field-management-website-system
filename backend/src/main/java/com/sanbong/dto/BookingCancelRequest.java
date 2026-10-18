package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record BookingCancelRequest(@NotBlank @Size(max=255) String lyDo) { }
