package com.sanbong;
import com.sanbong.service.*;
import com.sanbong.repository.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class AccountingReadModelTest {
 @Test void invalidPagesAndStatesNeverReachDatabase(){var repo=mock(FinanceRepository.class);var service=new FinanceService(repo,null,null,null,null,Clock.systemUTC());assertThrows(IllegalArgumentException.class,()->service.invoicePage("","",0,20));assertThrows(IllegalArgumentException.class,()->service.invoicePage("","SQL",1,20));assertThrows(IllegalArgumentException.class,()->service.refundPage("x".repeat(101),"",1,20));assertThrows(IllegalArgumentException.class,()->service.refundPage("","",1,101));verifyNoInteractions(repo);}
 @Test void invoiceAndRefundFiltersAreBoundedAndTrimmed(){var repo=mock(FinanceRepository.class);var service=new FinanceService(repo,null,null,null,null,Clock.systemUTC());when(repo.invoicePage("KH","DUE",2,20)).thenReturn(Map.of("rows",List.of()));service.invoicePage(" KH ","DUE",2,20);verify(repo).invoicePage("KH","DUE",2,20);service.refundPage(" HT ","Chờ duyệt",1,20);verify(repo).refundPage("HT","Chờ duyệt",1,20);}
 @Test void financialReportKeepsEarnedRevenueSeparateFromCash(){var repo=mock(ReportRepository.class);var service=new ReportService(repo,Clock.systemUTC());var date=LocalDate.of(2026,10,21);Map<String,Object> row=new HashMap<>();for(String key:List.of("tienSan","tienDichVu","tienGiam","doanhThu","tienThu","tienHoan","thucNhan"))row.put(key,BigDecimal.ZERO);row.put("doanhThu",new BigDecimal("400000"));row.put("tienThu",new BigDecimal("100000"));row.put("tienHoan",new BigDecimal("20000"));row.put("thucNhan",new BigDecimal("80000"));when(repo.finance(date,date,"")).thenReturn(List.of(row));when(repo.methods(date,date,"")).thenReturn(List.of());var totals=(Map<?,?>)service.finance(date,date,"").get("totals");assertEquals(new BigDecimal("400000"),totals.get("doanhThu"));assertEquals(new BigDecimal("80000"),totals.get("thucNhan"));assertNotEquals(totals.get("doanhThu"),totals.get("tienThu"));}
 @Test void reportRejectsReversedAndExcessiveDates(){assertThrows(IllegalArgumentException.class,()->ReportService.range(LocalDate.of(2026,2,1),LocalDate.of(2026,1,1)));assertThrows(IllegalArgumentException.class,()->ReportService.range(LocalDate.of(2025,1,1),LocalDate.of(2026,10,1)));}
}
