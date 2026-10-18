package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record EmployeeRequest(@NotBlank @Size(max=100) String hoTen,
 @Pattern(regexp="(?=.{8,15}$)\\+?[0-9]+(?: [0-9]+)*") String soDienThoai,@Email @Size(max=100) String email,
 @Size(max=50) String chucVu,@Pattern(regexp="Nhân viên sân bóng|Kế toán|Quản trị hệ thống") String boPhan,
 @PastOrPresent LocalDate ngayVaoLam,@NotNull Boolean trangThai) {}
