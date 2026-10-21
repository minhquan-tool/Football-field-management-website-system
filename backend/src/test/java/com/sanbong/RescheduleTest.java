package com.sanbong;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.RescheduleRequest;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import com.sanbong.service.*;
import org.junit.jupiter.api.*;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
class RescheduleTest {
    SanRepository pitches=mock(SanRepository.class);DatSanRepository bookings=mock(DatSanRepository.class);BookingWorkflowRepository workflow=mock(BookingWorkflowRepository.class);TimePriceRepository prices=mock(TimePriceRepository.class);SecurityRepository audit=mock(SecurityRepository.class);
    BookingService service=new BookingService(pitches,mock(LoaiSanRepository.class),mock(KhungGioRepository.class),mock(BangGiaRepository.class),bookings,mock(KhachHangRepository.class),mock(TaiKhoanRepository.class),workflow,audit,"",prices,mock(OperationsService.class),mock(FinanceService.class),mock(CancellationRequestRepository.class));
    AccountPrincipal actor=mock(AccountPrincipal.class);DatSan d=new DatSan();San san=new San();
    LocalDate day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(7);
    RescheduleRequest request=new RescheduleRequest(day,LocalTime.of(8,0),LocalTime.of(9,30),"Khách xin đổi giờ");
    @BeforeEach void setup(){org.springframework.test.util.ReflectionTestUtils.setField(service,"entityManager",mock(jakarta.persistence.EntityManager.class));
        when(actor.roleId()).thenReturn("VT02");when(actor.accountId()).thenReturn("NV1");san.setMaSan("S1");san.setTrangThai("Trống");var type=new LoaiSan();type.setMaLoaiSan("LS1");type.setTenLoaiSan("5 người");san.setLoaiSan(type);san.setTenSan("Sân 1");
        d.setSan(san);var customer=new KhachHang();customer.setMaKH("KH1");customer.setHoTen("Khách");customer.setSoDienThoai("0900000000");d.setKhachHang(customer);d.setMaDatSan("DS1");d.setNgayChoi(day.plusDays(1));d.setGioBatDau(LocalTime.of(10,0));d.setGioKetThuc(LocalTime.of(11,0));d.setTrangThai("Đã xác nhận");d.setCheDoGia("GIA_GIO");d.setTienSan(new BigDecimal("90000"));d.setTienDichVu(new BigDecimal("10000"));d.setTienGiam(BigDecimal.ZERO);d.setTongTien(new BigDecimal("100000"));
        when(bookings.findById("DS1")).thenReturn(Optional.of(d));when(bookings.lockById("DS1")).thenReturn(Optional.of(d));when(pitches.lockById("S1")).thenReturn(Optional.of(san));when(bookings.occupied(day,"Đã hủy")).thenReturn(List.of());when(prices.price(LocalTime.of(8,0))).thenReturn(new BigDecimal("90000"));
    }
    @Test void customerCannotReschedule(){when(actor.roleId()).thenReturn("VT01");assertThrows(org.springframework.security.access.AccessDeniedException.class,()->service.reschedule("DS1",request,actor));verify(bookings,never()).flush();}
    @Test void legacyPriceCannotBeConverted(){d.setCheDoGia("GIA_KHUNG");assertThrows(IllegalStateException.class,()->service.reschedule("DS1",request,actor));verify(bookings,never()).flush();}
    @Test void invoiceOrPaymentProtectsSnapshots(){when(workflow.hasFinancialHistory("DS1")).thenReturn(true);assertThrows(IllegalStateException.class,()->service.reschedule("DS1",request,actor));assertEquals(new BigDecimal("90000"),d.getTienSan());verify(bookings,never()).flush();}
    @Test void conflictCannotChangeBooking(){var other=new DatSan();other.setMaDatSan("DS2");other.setSan(san);other.setGioBatDau(LocalTime.of(9,0));other.setGioKetThuc(LocalTime.of(10,0));when(bookings.occupied(day,"Đã hủy")).thenReturn(List.of(other));assertThrows(IllegalStateException.class,()->service.reschedule("DS1",request,actor));verify(bookings,never()).flush();}
    @Test void unpaidFreeTimeRepricesAndRequiresConfirmation(){service.reschedule("DS1",request,actor);assertEquals(day,d.getNgayChoi());assertEquals(new BigDecimal("135000.00"),d.getTienSan());assertEquals(new BigDecimal("145000.00"),d.getTongTien());assertEquals("Chờ xác nhận",d.getTrangThai());verify(pitches).lockById("S1");verify(bookings).lockById("DS1");verify(audit).audit(eq("NV1"),eq("Sửa"),anyString(),eq("DS1"),contains("Đổi lịch từ"));}
}
