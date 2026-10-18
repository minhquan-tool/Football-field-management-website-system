package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.service.AdminService;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import jakarta.validation.Valid;
import java.time.LocalDate;
@RestController @RequestMapping("/admin")
public class AdminController {
 private final AdminService service;public AdminController(AdminService service){this.service=service;}
 @GetMapping("/options") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_XEM')")
 public ApiResponse<?> options(){return ApiResponse.ok("Tùy chọn quản trị",service.options());}
 @GetMapping("/employees") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_XEM')")
 public ApiResponse<?> list(@RequestParam(defaultValue="") String q,@RequestParam(required=false) Boolean active,@RequestParam(defaultValue="1") int page,@RequestParam(defaultValue="20") int size){return ApiResponse.ok("Nhân viên",service.employees(q,active,page,size));}
 @GetMapping("/employees/{id}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_XEM')")
 public ApiResponse<?> detail(@PathVariable String id){return ApiResponse.ok("Nhân viên",service.employee(id));}
 @PostMapping("/employees") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_THEM')")
 public ApiResponse<?> create(@Valid @RequestBody EmployeeRequest r,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã thêm nhân viên",service.createEmployee(r,actor.accountId()));}
 @PutMapping("/employees/{id}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_SUA')")
 public ApiResponse<?> edit(@PathVariable String id,@Valid @RequestBody EmployeeRequest r,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã sửa nhân viên",service.editEmployee(id,r,actor.accountId()));}
 @PostMapping("/accounts") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_THEM')")
 public ApiResponse<?> createAccount(@Valid @RequestBody StaffAccountRequest r,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã tạo tài khoản",service.createAccount(r,actor.accountId()));}
 @PutMapping("/accounts/{id}") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_SUA')")
 public ApiResponse<?> update(@PathVariable String id,@Valid @RequestBody AccountUpdateRequest r,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Đã cập nhật tài khoản",service.updateAccount(id,r,actor.accountId()));}
 @PostMapping("/accounts/{id}/reset-password") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN07_SUA')")
 public ApiResponse<?> reset(@PathVariable String id,@Valid @RequestBody PasswordResetRequest r,@AuthenticationPrincipal AccountPrincipal actor){service.reset(id,r,actor.accountId());return ApiResponse.ok("Đã reset mật khẩu; phiên cũ hết hiệu lực",null);}
 @GetMapping("/logs") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN08_XEM')")
 public ApiResponse<?> logs(@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="") String actor,@RequestParam(defaultValue="") String action,@RequestParam(defaultValue="") String module,@RequestParam(defaultValue="") String target,@RequestParam(defaultValue="1") int page,@RequestParam(defaultValue="20") int size){return ApiResponse.ok("Nhật ký",service.logs(from,to,actor,action,module,target,page,size));}
}
