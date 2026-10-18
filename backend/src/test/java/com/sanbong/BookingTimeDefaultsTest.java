package com.sanbong;
import com.sanbong.service.BookingTimeDefaults;
import org.junit.jupiter.api.Test;
import java.time.*;
import static org.junit.jupiter.api.Assertions.*;
class BookingTimeDefaultsTest {
    @Test void afternoonSearchDoesNotDefaultToPastMorning(){var result=BookingTimeDefaults.at(LocalDateTime.of(2026,10,15,18,41,30));assertEquals(LocalTime.of(18,42),result.get("defaultStart"));assertEquals(LocalTime.of(19,42),result.get("defaultEnd"));}
    @Test void beforeOpeningStartsAtSeven(){var result=BookingTimeDefaults.at(LocalDateTime.of(2026,10,15,6,30));assertEquals(LocalTime.of(7,0),result.get("defaultStart"));}
    @Test void closingSearchStaysWithinTwentyTwo(){var result=BookingTimeDefaults.at(LocalDateTime.of(2026,10,15,21,30));assertEquals(LocalTime.of(21,31),result.get("defaultStart"));assertEquals(LocalTime.of(22,0),result.get("defaultEnd"));}
    @Test void closedVenueMovesToNextDay(){var result=BookingTimeDefaults.at(LocalDateTime.of(2026,10,15,22,0));assertEquals(LocalDate.of(2026,10,16),result.get("defaultDate"));assertEquals(LocalTime.of(7,0),result.get("defaultStart"));}
}
