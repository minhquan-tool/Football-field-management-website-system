package com.sanbong;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import com.sanbong.service.*;
import org.junit.jupiter.api.*;
import org.mockito.MockedStatic;
import java.time.*;
import java.util.Optional;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class LateBookingConfirmationTest {
    final DatSanRepository bookings=mock(DatSanRepository.class);
    final SanRepository pitches=mock(SanRepository.class);
    final AccountPrincipal actor=mock(AccountPrincipal.class);
    final DatSan booking=new DatSan();
    final San pitch=new San();
    final BookingService service=new BookingService(pitches,mock(LoaiSanRepository.class),mock(KhungGioRepository.class),mock(BangGiaRepository.class),bookings,mock(KhachHangRepository.class),mock(TaiKhoanRepository.class),mock(BookingWorkflowRepository.class),mock(SecurityRepository.class),"",mock(TimePriceRepository.class),mock(OperationsService.class),mock(FinanceService.class),mock(CancellationRequestRepository.class));
    final LocalDate day=LocalDate.of(2026,10,21);
    final ZoneId zone=ZoneId.of("Asia/Ho_Chi_Minh");
    @BeforeEach void setup(){
        org.springframework.test.util.ReflectionTestUtils.setField(service,"entityManager",mock(jakarta.persistence.EntityManager.class));
        when(actor.roleId()).thenReturn("VT02");
        pitch.setMaSan("S1");pitch.setTrangThai("Trống");
        var type=new LoaiSan();type.setTenLoaiSan("5 người");pitch.setLoaiSan(type);
        var customer=new KhachHang();customer.setMaKH("KH1");booking.setKhachHang(customer);
        booking.setMaDatSan("DS1");booking.setSan(pitch);booking.setNgayChoi(day);
        booking.setGioBatDau(LocalTime.of(7,0));booking.setGioKetThuc(LocalTime.of(8,0));booking.setTrangThai("Chờ xác nhận");
        when(bookings.findById("DS1")).thenReturn(Optional.of(booking));
        when(bookings.lockById("DS1")).thenReturn(Optional.of(booking));
        when(pitches.lockById("S1")).thenReturn(Optional.of(pitch));
    }
    void at(LocalDateTime now,Runnable assertion){
        try(MockedStatic<LocalDateTime> time=mockStatic(LocalDateTime.class,CALLS_REAL_METHODS)){
            time.when(()->LocalDateTime.now(zone)).thenReturn(now);assertion.run();
        }
    }
    @Test void earlyOnTimeAndLateConfirmationKeepSchedule(){
        for(var time:new LocalTime[]{LocalTime.of(6,50),LocalTime.of(7,0),LocalTime.of(7,1),LocalTime.of(7,10),LocalTime.of(7,59)}){
            booking.setTrangThai("Chờ xác nhận");
            at(day.atTime(time),()->assertEquals("Đã xác nhận",service.confirm("DS1",actor).trangThai()));
            assertEquals(LocalTime.of(8,0),booking.getGioKetThuc());
        }
    }
    @Test void atEndAndAfterEndAreRejected(){
        for(var time:new LocalTime[]{LocalTime.of(8,0),LocalTime.of(8,1)})
            at(day.atTime(time),()->assertThrows(IllegalStateException.class,()->service.confirm("DS1",actor)));
        verify(bookings,never()).flush();
    }
    @Test void cancelledAndMaintenanceRemainRejected(){
        at(day.atTime(7,1),()->{
            booking.setTrangThai("Đã hủy");assertThrows(IllegalStateException.class,()->service.confirm("DS1",actor));
            booking.setTrangThai("Chờ xác nhận");pitch.setTrangThai("Bảo trì");assertThrows(IllegalStateException.class,()->service.confirm("DS1",actor));
        });
    }
}
