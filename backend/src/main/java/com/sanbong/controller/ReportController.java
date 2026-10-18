package com.sanbong.controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import com.sanbong.service.ReportService;
import com.sanbong.dto.ApiResponse;
import java.time.LocalDate;
@RestController @RequestMapping("/reports")
public class ReportController {
 private final ReportService service;public ReportController(ReportService service){this.service=service;}
 @GetMapping("/options") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT','PITCH_STAFF') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> options(){return ApiResponse.ok("Bộ lọc báo cáo",service.options());}
 @GetMapping("/usage") @PreAuthorize("hasAnyRole('ADMIN','PITCH_STAFF') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> usage(@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="") String pitch){return ApiResponse.ok("Sử dụng sân",service.usage(from,to,pitch));}
 @GetMapping("/finance") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> finance(@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="") String pitch){return ApiResponse.ok("Doanh thu/thu/hoàn",service.finance(from,to,pitch));}
 @GetMapping("/refunds") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> refunds(@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="") String status,@RequestParam(defaultValue="") String booking,@RequestParam(defaultValue="") String method,@RequestParam(defaultValue="1") int page,@RequestParam(defaultValue="20") int size){return ApiResponse.ok("Báo cáo hoàn",service.refunds(from,to,status,booking,method,page,size));}
 @GetMapping("/dashboard") @PreAuthorize("hasRole('ADMIN') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> dashboard(){return ApiResponse.ok("Dashboard",service.dashboard());}
 @GetMapping("/reconciliation") @PreAuthorize("hasAnyRole('ADMIN','ACCOUNTANT') and hasAuthority('CN06_XEM')")
 public ApiResponse<?> reconciliation(@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="") String pitch){return ApiResponse.ok("Đối soát sổ nội bộ",service.reconciliation(from,to,pitch));}
}
