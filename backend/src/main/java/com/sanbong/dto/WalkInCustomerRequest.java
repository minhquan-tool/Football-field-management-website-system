package com.sanbong.dto;
import jakarta.validation.constraints.*;
/** Uses the existing counter lookup phone format; preserves + and leading zeros. */
public record WalkInCustomerRequest(
 @NotBlank @Size(max=100) String hoTen,
 @NotBlank @Pattern(regexp="(?=.{7,15}$)\\+?[0-9]+") String soDienThoai) {
 public WalkInCustomerRequest {
  hoTen=hoTen==null?null:hoTen.trim();
  soDienThoai=soDienThoai==null?null:soDienThoai.trim();
 }
}
