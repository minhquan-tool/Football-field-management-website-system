package com.sanbong;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import com.sanbong.service.CustomerCareService;
import org.junit.jupiter.api.*;
import org.springframework.security.access.AccessDeniedException;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class CustomerCareTest {
    TaiKhoanRepository accounts=mock(TaiKhoanRepository.class);KhachHangRepository customers=mock(KhachHangRepository.class);
    DatSanRepository bookings=mock(DatSanRepository.class);CustomerCareRepository care=mock(CustomerCareRepository.class);SecurityRepository audit=mock(SecurityRepository.class);
    CustomerCareService service=new CustomerCareService(accounts,customers,bookings,care,audit);AccountPrincipal actor=mock(AccountPrincipal.class);KhachHang customer=new KhachHang();DatSan booking=new DatSan();
    @BeforeEach void setup(){customer.setMaKH("KH1");var a=new TaiKhoan();a.setKhachHang(customer);when(actor.accountId()).thenReturn("TK1");when(actor.roleId()).thenReturn("VT01");when(accounts.findById("TK1")).thenReturn(Optional.of(a));booking.setKhachHang(customer);booking.setTrangThai("Đã sử dụng");var pitch=new San();pitch.setMaSan("S1");booking.setSan(pitch);when(bookings.lockById("DS1")).thenReturn(Optional.of(booking));when(care.criteria()).thenReturn(List.of(Map.of("maTieuChi","TC1")));}
    @Test void otherCustomerCannotReview(){var other=new KhachHang();other.setMaKH("KH2");booking.setKhachHang(other);assertThrows(AccessDeniedException.class,()->service.review("DS1",new ReviewRequest(Map.of("TC1",5),""),actor));verify(care,never()).review(any(),any(),any(),any(),any(),any());}
    @Test void unfinishedBookingCannotReview(){booking.setTrangThai("Đã xác nhận");assertThrows(IllegalStateException.class,()->service.review("DS1",new ReviewRequest(Map.of("TC1",5),""),actor));verify(care,never()).review(any(),any(),any(),any(),any(),any());}
    @Test void missingOrUnknownCriteriaCannotBeWritten(){assertThrows(IllegalArgumentException.class,()->service.review("DS1",new ReviewRequest(Map.of("OTHER",5),""),actor));verify(care,never()).review(any(),any(),any(),any(),any(),any());}
    @Test void completedOwnBookingCanReview(){service.review("DS1",new ReviewRequest(Map.of("TC1",4),"Tốt"),actor);verify(care).review(anyString(),eq("DS1"),eq("KH1"),eq("S1"),eq("Tốt"),eq(Map.of("TC1",4)));verify(audit).audit(eq("TK1"),eq("Thêm"),anyString());}
    @Test void feedbackCannotReferenceAnotherCustomerBooking(){var other=new KhachHang();other.setMaKH("KH2");booking.setKhachHang(other);when(bookings.findById("DS1")).thenReturn(Optional.of(booking));assertThrows(AccessDeniedException.class,()->service.feedback(new FeedbackRequest("DS1","Góp ý","Test"),actor));verify(care,never()).feedback(any(),any(),any(),any(),any());}
    @Test void profileSerializesAViewInsteadOfAnEntityProxy()throws Exception{
        customer.setGhiChu("Internal note");var result=service.profile(actor);var json=new com.fasterxml.jackson.databind.ObjectMapper().valueToTree(result);
        assertEquals(CustomerProfileView.class,result.getClass());assertEquals("KH1",json.path("maKH").asText());assertFalse(json.has("ghiChu"));assertFalse(json.has("hibernateLazyInitializer"));
    }
}
