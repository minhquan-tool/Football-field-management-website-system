package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.OperationsService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
public class OperationsController {
    private final OperationsService service;
    public OperationsController(OperationsService service) { this.service=service; }
    @GetMapping("/services") @PreAuthorize("hasAuthority('CN03_XEM')")
    public ApiResponse<?> services() { return ApiResponse.ok("Dịch vụ hoạt động",service.services()); }
    @GetMapping("/operations/bookings/{id}") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> detail(@PathVariable String id) { return ApiResponse.ok("Nhận sân và dịch vụ",service.detail(id)); }
    @PostMapping("/operations/bookings/{id}/check-in") @PreAuthorize("hasAuthority('CN02_SUA')")
    public ApiResponse<?> checkIn(@PathVariable String id,@Valid @RequestBody CheckInRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã nhận sân.",service.checkIn(id,request,actor));
    }
    @PostMapping("/operations/bookings/{id}/check-out") @PreAuthorize("hasAuthority('CN02_SUA')")
    public ApiResponse<?> checkOut(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã trả sân và chốt dịch vụ. Xem trạng thái tài chính tại hóa đơn.",service.checkOut(id,actor));
    }
    @PostMapping("/operations/bookings/{id}/services/{serviceId}") @PreAuthorize("hasAuthority('CN03_THEM')")
    public ApiResponse<?> add(@PathVariable String id,@PathVariable String serviceId,@Valid @RequestBody ServiceSaleRequest request,
            @AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Đã ghi dịch vụ.",service.add(id,serviceId,request.soLuong(),request.quyCach(),actor)); }
    @PutMapping("/operations/bookings/{id}/services/{serviceId}") @PreAuthorize("hasAuthority('CN03_SUA')")
    public ApiResponse<?> quantity(@PathVariable String id,@PathVariable String serviceId,@Valid @RequestBody ServiceQuantityRequest request,
            @AuthenticationPrincipal AccountPrincipal actor) { return ApiResponse.ok("Đã sửa số lượng.",service.quantity(id,serviceId,request.soLuong(),actor)); }
    @DeleteMapping("/operations/bookings/{id}/services/{serviceId}") @PreAuthorize("hasAuthority('CN03_XOA')")
    public ApiResponse<?> remove(@PathVariable String id,@PathVariable String serviceId,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã xóa dòng dịch vụ chưa chốt.",service.remove(id,serviceId,actor));
    }

    @PutMapping("/operations/bookings/{id}/service-lines/{line}") @PreAuthorize("hasAuthority('CN03_SUA')")
    public ApiResponse<?> quantityLine(@PathVariable String id,@PathVariable long line,@Valid @RequestBody ServiceQuantityRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã sửa dòng dịch vụ.",service.quantityLine(id,line,request.soLuong(),actor));
    }
    @DeleteMapping("/operations/bookings/{id}/service-lines/{line}") @PreAuthorize("hasAuthority('CN03_XOA')")
    public ApiResponse<?> removeLine(@PathVariable String id,@PathVariable long line,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã xóa dòng dịch vụ.",service.removeLine(id,line,actor));
    }
}
