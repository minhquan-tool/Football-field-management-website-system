package com.sanbong.dto;
import jakarta.validation.constraints.*;
import com.sanbong.security.PasswordPolicy;
public record PasswordResetRequest(@NotBlank @Size(min=PasswordPolicy.MIN_LENGTH,max=PasswordPolicy.MAX_BYTES) String matKhau) {
    @Override public String toString() { return "PasswordResetRequest[password redacted]"; }
}
