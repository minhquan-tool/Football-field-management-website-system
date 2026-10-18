package com.sanbong.dto;
import jakarta.validation.constraints.*;
import com.sanbong.security.PasswordPolicy;
public record StaffAccountRequest(@NotBlank @Size(max=10) String maNV,
 @NotBlank @Pattern(regexp="[a-zA-Z0-9_.-]{3,50}") String tenDangNhap,
 @NotBlank @Size(min=PasswordPolicy.MIN_LENGTH,max=PasswordPolicy.MAX_BYTES) String matKhau,@Pattern(regexp="VT02|VT03|VT04") @NotNull String maVaiTro) {
    @Override public String toString() { return "StaffAccountRequest[password redacted]"; }
}
