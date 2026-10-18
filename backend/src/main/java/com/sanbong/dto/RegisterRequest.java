package com.sanbong.dto;

import jakarta.validation.constraints.*;
import com.sanbong.security.PasswordPolicy;

public record RegisterRequest(
        @NotBlank @Size(max = 100) String hoTen,
        @NotBlank @Pattern(regexp = "(?=.{9,15}$)\\+?[0-9]+",message="Số điện thoại gồm 9–15 ký tự, chỉ có thể có một dấu + ở đầu.") String soDienThoai,
        @Email @Size(max = 100) String email,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9_.-]{3,50}") String tenDangNhap,
        @NotBlank @Size(min=PasswordPolicy.MIN_LENGTH,max=PasswordPolicy.MAX_BYTES,message="Mật khẩu phải có 10–72 ký tự và tối đa 72 byte UTF-8.") String matKhau) {
    @Override public String toString() { return "RegisterRequest[password redacted]"; }
}
