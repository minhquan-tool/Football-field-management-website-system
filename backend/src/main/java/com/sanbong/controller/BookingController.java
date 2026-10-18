package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.BookingService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;

@RestController
public class BookingController {
    private final BookingService service;
    private final com.sanbong.service.WalkInCustomerService walkInCustomers;
    public BookingController(BookingService service,com.sanbong.service.WalkInCustomerService walkInCustomers) { this.service=service;this.walkInCustomers=walkInCustomers; }
    @GetMapping("/booking-options") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> options(@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Thông tin đặt sân",service.options(actor));
    }
    @GetMapping("/booking-customers")
    @PreAuthorize("hasAnyRole('ADMIN','PITCH_STAFF') and hasAuthority('CN02_THEM')")
    public ApiResponse<?> customers(@RequestParam String phone) {
        return ApiResponse.ok("Khách hàng theo số điện thoại",service.customers(phone));
    }
    @PostMapping("/booking-customers")
    @PreAuthorize("hasAnyRole('ADMIN','PITCH_STAFF') and hasAuthority('CN02_THEM')")
    public ApiResponse<?> createCustomer(@Valid @RequestBody WalkInCustomerRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã tạo hồ sơ khách tại quầy.",walkInCustomers.create(request,actor));
    }
    @GetMapping("/availability") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> availability(@RequestParam LocalDate date,@RequestParam(required=false) String type,
            @RequestParam(required=false) String slot,@RequestParam(required=false) String status,
            @RequestParam(required=false) java.time.LocalTime start,@RequestParam(required=false) java.time.LocalTime end) {
        return ApiResponse.ok("Sân và giờ có thể đặt",service.availability(date,type,slot,status,start,end));
    }
    @GetMapping("/bookings") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> list(@RequestParam LocalDate date,@RequestParam(required=false) String pitch,
            @RequestParam(required=false) String slot,@RequestParam(required=false) String status,
            @AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Lịch đặt sân",service.list(date,pitch,slot,status,actor));
    }
    @GetMapping("/bookings/{id}") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> detail(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Chi tiết booking",service.detail(id,actor));
    }
    @PostMapping("/bookings") @PreAuthorize("hasAuthority('CN02_THEM')")
    public ApiResponse<?> create(@Valid @RequestBody BookingRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã tạo booking chờ xác nhận. Chưa ghi nhận thanh toán.",service.create(request,actor));
    }
    @GetMapping("/bookings/{id}/services") @PreAuthorize("hasAuthority('CN02_XEM')")
    public ApiResponse<?> serviceLines(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Dịch vụ đã lưu",service.serviceLines(id,actor));
    }
    @PostMapping("/bookings/{id}/confirm")
    @PreAuthorize("hasAnyRole('ADMIN','PITCH_STAFF') and hasAuthority('CN02_SUA')")
    public ApiResponse<?> confirm(@PathVariable String id,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã xác nhận booking.",service.confirm(id,actor));
    }
    @PostMapping("/bookings/{id}/cancel") @PreAuthorize("hasAuthority('CN02_SUA')")
    public ApiResponse<?> cancel(@PathVariable String id,@Valid @RequestBody BookingCancelRequest request,
            @AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã hủy booking; xem hóa đơn và yêu cầu hoàn nếu có.",service.cancel(id,request.lyDo(),actor));
    }
    @PostMapping("/bookings/{id}/reschedule")
    @PreAuthorize("hasAnyRole('ADMIN','PITCH_STAFF') and hasAuthority('CN02_SUA')")
    public ApiResponse<?> reschedule(@PathVariable String id,@Valid @RequestBody RescheduleRequest request,@AuthenticationPrincipal AccountPrincipal actor) {
        return ApiResponse.ok("Đã đổi lịch trên cùng sân; cần xác nhận lại.",service.reschedule(id,request,actor));
    }
}
