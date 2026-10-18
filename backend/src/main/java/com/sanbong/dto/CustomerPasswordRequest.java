package com.sanbong.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CustomerPasswordRequest(
        @NotBlank(message="Vui lòng nhập mật khẩu hiện tại.") @Size(max=200) String matKhauHienTai,
        @NotBlank(message="Vui lòng nhập mật khẩu mới.") @Size(max=200) String matKhauMoi,
        @NotBlank(message="Vui lòng xác nhận mật khẩu mới.") @Size(max=200) String xacNhanMatKhau) {
    @Override public String toString(){return "CustomerPasswordRequest[passwords redacted]";}
}
