package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record CustomerProfileRequest(@NotBlank @Size(max=100) String hoTen,
        @NotBlank @Pattern(regexp="(?=.{7,15}$)\\+?[0-9]+",message="Số điện thoại gồm 7–15 ký tự, chỉ có thể có một dấu + ở đầu.") String soDienThoai,
        @Email @Size(max=100) String email,@Size(max=255) String diaChi) {}
