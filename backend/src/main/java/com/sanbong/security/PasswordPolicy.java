package com.sanbong.security;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.springframework.security.crypto.password.PasswordEncoder;

/** Shared write-time policy and the matching internal startup checks. Never includes secrets in errors. */
public final class PasswordPolicy {
    public static final int MIN_LENGTH = 10;
    public static final int MAX_BYTES = 72;
    private static final List<String> DENIED = List.of("123456", "12345678", "admin", "password", "demo123");
    private PasswordPolicy() { }

    public static void validate(String password) {
        if (password == null || password.isBlank())
            throw new IllegalArgumentException("Vui lòng nhập mật khẩu.");
        if (DENIED.contains(password))
            throw new IllegalArgumentException("Không sử dụng mật khẩu phổ biến hoặc mật khẩu demo.");
        if (password.length() < MIN_LENGTH)
            throw new IllegalArgumentException("Mật khẩu phải có ít nhất 10 ký tự.");
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_BYTES)
            throw new IllegalArgumentException("Mật khẩu tối đa 72 byte UTF-8; ký tự có dấu có thể dùng nhiều byte.");
    }

    public static boolean isBcryptHash(String hash) {
        return hash != null && hash.matches("\\$2[aby]\\$\\d{2}\\$[./A-Za-z0-9]{53}");
    }

    public static void validateStoredHash(String hash, PasswordEncoder encoder) {
        if (!isBcryptHash(hash))
            throw new IllegalStateException("Internal startup requires BCrypt passwords.");
        for (String sample : DENIED)
            if (encoder.matches(sample, hash))
                throw new IllegalStateException("Replace active demo passwords before internal startup; no passwords were changed automatically.");
    }
}
