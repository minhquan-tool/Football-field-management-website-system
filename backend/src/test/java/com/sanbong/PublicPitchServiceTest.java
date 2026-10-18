package com.sanbong;
import com.sanbong.service.*;
import com.sanbong.dto.*;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PublicPitchServiceTest {
    private final PitchService pitches = mock(PitchService.class);
    private final BookingService bookings = mock(BookingService.class);
    private PublicPitchService service(String local) {
        var instant = LocalDateTime.parse(local).atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant();
        return new PublicPitchService(pitches, bookings, Clock.fixed(instant, ZoneOffset.UTC));
    }
    @Test void catalogSupportsVietnameseWithoutAccentsAndRejectsOversizedInput() {
        when(pitches.list("", "LS01", "")).thenReturn(List.of(new PitchView("S01","Sân số 1","LS01","Sân 5 người",5,"Trống","")));
        assertEquals(1, service("2026-10-14T12:00:00").catalog("san so 1", "LS01").size());
        assertTrue(service("2026-10-14T12:00:00").catalog("S02", "LS01").isEmpty());
        assertThrows(IllegalArgumentException.class, () -> service("2026-10-14T12:00:00").catalog("a".repeat(101), ""));
    }
    @Test void defaultsStayInsideOperatingHoursAndRollToTomorrowAfterClosing() {
        when(pitches.types()).thenReturn(List.of()); when(pitches.list("", "", "")).thenReturn(List.of());
        var beforeOpen = service("2026-10-14T06:30:00").options();
        assertEquals(LocalTime.of(7,0), beforeOpen.get("defaultStart"));
        var late = service("2026-10-14T21:30:00").options();
        assertEquals(LocalTime.of(21,31), late.get("defaultStart")); assertEquals(LocalTime.of(22,0), late.get("defaultEnd"));
        var closed = service("2026-10-14T21:59:10").options();
        assertEquals(LocalDate.of(2026,10,15), closed.get("defaultDate")); assertEquals(LocalTime.of(7,0), closed.get("defaultStart"));
    }
    @Test void availabilityUsesExistingBookingValidationPricesAndIntervals() {
        var date=LocalDate.of(2026,10,15); var start=LocalTime.of(8,0); var end=LocalTime.of(9,0);
        var slot=new AvailableSlot("S01","Sân số 1","LS01","Sân 5 người","Trống",date,null,start,end,BigDecimal.ONE,"GIA_GIO",null,new BigDecimal("90000"),new BigDecimal("90000"));
        when(bookings.availability(date,"LS01",null,null,start,end)).thenReturn(List.of(slot));
        assertEquals(List.of(slot), service("2026-10-14T12:00:00").availability(date,"LS01",start,end,"san so 1"));
        verify(bookings).availability(date,"LS01",null,null,start,end);
    }
}
