package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record FeedbackResolutionRequest(@NotBlank @Pattern(regexp="Đang xử lý|Đã xử lý") String trangThai,
                                        @NotBlank @Size(max=500) String ketQua) {}
