package com.sanbong;
import com.sanbong.service.*;
import com.sanbong.repository.*;
import com.sanbong.model.*;
import com.sanbong.dto.PaymentRequest;
import com.sanbong.config.AccountPrincipal;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import java.math.BigDecimal;
import java.time.Clock;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
class CustomerPaymentValidationTest {
 @Test void tamperedAndMissingCustomerPlanCannotCreatePayment(){
  var finance=mock(FinanceRepository.class);var bookings=mock(DatSanRepository.class);var pitches=mock(SanRepository.class);var accounts=mock(TaiKhoanRepository.class);var security=mock(SecurityRepository.class);var em=mock(EntityManager.class);
  var service=new FinanceService(finance,bookings,pitches,accounts,security,Clock.systemUTC());ReflectionTestUtils.setField(service,"em",em);
  var actor=mock(AccountPrincipal.class);when(actor.roleId()).thenReturn("VT01");when(actor.accountId()).thenReturn("TK_TEST");
  var customer=new KhachHang();customer.setMaKH("KH_TEST");var account=new TaiKhoan();account.setKhachHang(customer);when(accounts.findById("TK_TEST")).thenReturn(Optional.of(account));
  var pitch=new San();pitch.setMaSan("S_TEST");var booking=new DatSan();booking.setMaDatSan("DS_TEST");booking.setSan(pitch);booking.setKhachHang(customer);booking.setTrangThai("Đã xác nhận");booking.setTienSan(new BigDecimal("90000"));booking.setTienDichVu(BigDecimal.ZERO);booking.setTienGiam(BigDecimal.ZERO);booking.setTongTien(new BigDecimal("90000"));
  when(bookings.findById("DS_TEST")).thenReturn(Optional.of(booking));when(bookings.lockById("DS_TEST")).thenReturn(Optional.of(booking));when(pitches.lockById("S_TEST")).thenReturn(Optional.of(pitch));when(finance.invoice("DS_TEST")).thenReturn(Optional.of(Map.of("tongTien",new BigDecimal("90000"),"conLai",new BigDecimal("90000"),"daChot",true)));when(finance.paid("DS_TEST")).thenReturn(BigDecimal.ZERO);when(finance.byKey(anyString())).thenReturn(Optional.empty());
  for(String plan:new String[]{null,"DEPOSIT_40","FULL"})assertThrows(IllegalArgumentException.class,()->service.pay("DS_TEST",new PaymentRequest(BigDecimal.ONE,"Chuyển khoản","qa-idempotency-key",false,plan),actor,false));
  verify(finance,never()).paymentCreate(anyString(),any(),anyString(),anyString(),any(),anyBoolean(),any());
  var order=inOrder(pitches,bookings);order.verify(pitches).lockById("S_TEST");order.verify(bookings).lockById("DS_TEST");
 }
}
