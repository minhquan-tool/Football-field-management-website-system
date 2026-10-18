package com.sanbong.service;
import java.time.*;
import java.util.Map;
/** Shared initial search interval; actual booking validation remains in BookingService. */
public final class BookingTimeDefaults {
    private BookingTimeDefaults() {}
    public static Map<String,Object> at(LocalDateTime now){
        var start=now.withSecond(0).withNano(0).plusMinutes(1);
        if(start.toLocalTime().isBefore(LocalTime.of(7,0)))start=start.toLocalDate().atTime(7,0);
        if(!start.toLocalTime().isBefore(LocalTime.of(22,0)))start=start.toLocalDate().plusDays(1).atTime(7,0);
        var end=start.toLocalTime().plusHours(1);if(end.isAfter(LocalTime.of(22,0)))end=LocalTime.of(22,0);
        return Map.of("today",now.toLocalDate(),"defaultDate",start.toLocalDate(),"defaultStart",start.toLocalTime(),"defaultEnd",end);
    }
}
