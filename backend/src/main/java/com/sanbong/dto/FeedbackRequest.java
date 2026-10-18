package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record FeedbackRequest(@Size(max=10) String maDatSan,@NotBlank @Size(max=50) String loaiPhanHoi,
                              @NotBlank @Size(max=500) String noiDung) {}
