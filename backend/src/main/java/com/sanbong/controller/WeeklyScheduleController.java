package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.ApiResponse;
import com.sanbong.service.WeeklyScheduleService;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import java.time.LocalDate;

@RestController
public class WeeklyScheduleController {
    private final WeeklyScheduleService service;
    public WeeklyScheduleController(WeeklyScheduleService service){this.service=service;}
    @GetMapping("/staff/weekly-schedule")
    @PreAuthorize("hasAnyRole('PITCH_STAFF','ADMIN') and hasAuthority('CN02_XEM')")
    public ApiResponse<?> week(@RequestParam LocalDate date,@RequestParam(required=false) String pitch,@RequestParam(required=false) String status,@AuthenticationPrincipal AccountPrincipal actor){return ApiResponse.ok("Lịch đá bóng trong tuần",service.week(date,pitch,status,actor));}
}
