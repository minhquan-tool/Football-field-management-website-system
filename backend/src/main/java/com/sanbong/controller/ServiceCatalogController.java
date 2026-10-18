package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.OperationsService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController
public class ServiceCatalogController {
 private final OperationsService service;
 public ServiceCatalogController(OperationsService service) { this.service=service; }
 @GetMapping("/booking-services") @PreAuthorize("hasAuthority('CN02_THEM')")
 public ApiResponse<?> options() { return ApiResponse.ok("Dịch vụ đặt trước",service.services()); }
 @GetMapping("/service-catalog") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN03_XEM')")
 public ApiResponse<?> catalog() { return ApiResponse.ok("Danh mục dịch vụ",service.catalog()); }
 @PostMapping("/service-catalog") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN03_THEM')")
 public ApiResponse<?> create(@Valid @RequestBody NewServiceRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
  return ApiResponse.ok("Đã thêm dịch vụ mới.",service.createCatalog(request,actor));
 }
 @PutMapping("/service-catalog/{id}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN03_SUA')")
 public ApiResponse<?> update(@PathVariable String id,@Valid @RequestBody ServiceCatalogRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
  return ApiResponse.ok("Đã cập nhật catalog; giữ giá lịch sử.",service.updateCatalog(id,request,actor));
 }
}
