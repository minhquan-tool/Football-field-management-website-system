package com.sanbong.config;
import java.time.*;
import org.springframework.context.annotation.*;
@Configuration
public class FinanceClockConfig {
 @Bean public Clock financeClock() { return Clock.system(ZoneId.of("Asia/Ho_Chi_Minh")); }
}
