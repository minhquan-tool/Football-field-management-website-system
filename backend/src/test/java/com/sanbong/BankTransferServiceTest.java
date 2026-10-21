package com.sanbong;
import com.sanbong.service.*;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.BookingView;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.Clock;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class BankTransferServiceTest {
 final FinanceService finance=mock(FinanceService.class);
 BankTransferService service(boolean enabled){return new BankTransferService(finance,Clock.systemUTC(),enabled,"970422","TEST BANK","0000123456","TEST ONLY","retired-local-file.png");}
 Map<String,Object> booking(AccountPrincipal actor){
  var view=new BookingView("DS123",null,null,null,null,null,null,null,null,null,null,null,null,null,null,new BigDecimal("90000"),"Đã xác nhận",null,null);
  var data=new HashMap<String,Object>(Map.of("booking",view,"payments",List.of()));when(finance.detail("DS123",actor)).thenReturn(data);return data;
 }
 @Test void dynamicQrIncludesAmountMemoAndConfiguredAccount(){booking(null);var quote=service(true).instructions("DS123",new BigDecimal("36000"),null);String url=(String)quote.get("qrUrl");assertTrue(url.startsWith("https://img.vietqr.io/image/970422-0000123456-compact2.svg?amount=36000&"));assertTrue(url.contains("addInfo=FCUTE+DS123"));assertTrue(url.contains("accountName=TEST+ONLY"));assertEquals(true,quote.get("qrAvailable"));}
 @Test void oldImageEndpointRedirectsWithoutCaching(){booking(null);var response=service(true).image("DS123",new BigDecimal("36000"),null);assertEquals(302,response.getStatusCode().value());assertEquals("img.vietqr.io",response.getHeaders().getLocation().getHost());assertEquals("no-store",response.getHeaders().getCacheControl());}
 @Test void customerCannotRequestArbitraryAmount(){var actor=mock(AccountPrincipal.class);when(actor.roleId()).thenReturn("VT01");booking(actor);assertThrows(IllegalArgumentException.class,()->service(true).instructions("DS123",BigDecimal.ONE,actor));assertDoesNotThrow(()->service(true).instructions("DS123",new BigDecimal("36000"),actor));}
 @Test void pendingAndOverpaymentAreRejected(){var data=booking(null);assertThrows(IllegalStateException.class,()->service(true).instructions("DS123",new BigDecimal("90001"),null));data.put("payments",List.of(Map.of("trangThai","Chờ xử lý")));assertThrows(IllegalStateException.class,()->service(true).instructions("DS123",BigDecimal.TEN,null));}
 @Test void disabledAndFractionalAmountsAreRejected(){booking(null);assertThrows(IllegalStateException.class,()->service(false).instructions("DS123",BigDecimal.ONE,null));assertThrows(IllegalArgumentException.class,()->service(true).instructions("DS123",new BigDecimal("36000.5"),null));}
 @Test void ownershipFailureIsNotHidden(){when(finance.detail("DS123",null)).thenThrow(new org.springframework.security.access.AccessDeniedException("owner"));assertThrows(org.springframework.security.access.AccessDeniedException.class,()->service(true).instructions("DS123",BigDecimal.TEN,null));}
}
