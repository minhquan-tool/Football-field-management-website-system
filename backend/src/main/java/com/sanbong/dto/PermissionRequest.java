package com.sanbong.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record PermissionRequest(@NotBlank @Pattern(regexp = "CN0[1-8]") String maChucNang,
                                boolean xem, boolean them, boolean sua, boolean xoa) { }
