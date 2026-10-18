package com.sanbong;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.controller.FinanceController;
import com.sanbong.dto.PaymentRequest;
import com.sanbong.service.FinanceService;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class StaffTransferRequestTest {
 @Test void staffTransferIsAlwaysPending() {
  var service=mock(FinanceService.class);var actor=mock(AccountPrincipal.class);when(actor.roleId()).thenReturn("VT02");
  var request=new PaymentRequest(new BigDecimal("90000"),"Chuyển khoản","test-transfer-01",true);
  new FinanceController(service,mock(com.sanbong.service.BankTransferService.class)).request("DS01",request,actor);
  verify(service).pay("DS01",request,actor,false);
 }
 @Test void cashCannotUseStaffTransferRequest() {
  var service=mock(FinanceService.class);var actor=mock(AccountPrincipal.class);when(actor.roleId()).thenReturn("VT02");
  assertThrows(org.springframework.security.access.AccessDeniedException.class,()->new FinanceController(service,mock(com.sanbong.service.BankTransferService.class)).request("DS01",new PaymentRequest(BigDecimal.TEN,"Tiền mặt","test-transfer-02",true),actor));
  verifyNoInteractions(service);
 }
}
