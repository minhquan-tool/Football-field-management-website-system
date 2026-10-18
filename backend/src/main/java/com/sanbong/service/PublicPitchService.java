package com.sanbong.service;

import com.sanbong.dto.AvailableSlot;
import com.sanbong.dto.PitchView;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.text.Normalizer;
import java.util.*;

/** Guest read model: only pitch/catalog/pricing, never customer or booking details. */
@Service
public class PublicPitchService {
    private final PitchService pitches;
    private final BookingService bookings;
    private final Clock clock;
    public PublicPitchService(PitchService pitches, BookingService bookings, Clock clock) {
        this.pitches = pitches; this.bookings = bookings; this.clock = clock;
    }
    private String query(String q) {
        if (q != null && q.length() > 100) throw new IllegalArgumentException("Từ khóa tối đa 100 ký tự.");
        return normalized(Objects.toString(q, "").trim());
    }
    private static String normalized(String text) {
        return Normalizer.normalize(text.toLowerCase(Locale.ROOT), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").replace('đ', 'd');
    }
    private boolean matches(String key, String id, String name, String type) {
        return key.isEmpty() || normalized(id + " " + name + " " + type).contains(key);
    }
    @Transactional(readOnly = true)
    public List<PitchView> catalog(String q, String type) {
        String key = query(q);
        return pitches.list("", type, "").stream()
                .filter(p -> matches(key, p.maSan(), p.tenSan(), p.tenLoaiSan())).toList();
    }
    @Transactional(readOnly = true)
    public Map<String,Object> options() {
        var now = LocalDateTime.now(clock.withZone(ZoneId.of("Asia/Ho_Chi_Minh")));
        var types = pitches.types();
        var result=new LinkedHashMap<String,Object>(BookingTimeDefaults.at(now));
        result.put("types",types);result.put("pitchCount",pitches.list("","","").size());result.put("typeCount",types.size());return result;
    }
    @Transactional(readOnly = true)
    public List<AvailableSlot> availability(LocalDate date, String type, LocalTime start, LocalTime end, String q) {
        String key = query(q);
        // Shared validation, price-by-start and overlap logic; no parallel pricing implementation.
        return bookings.availability(date, type, null, null, start, end).stream()
                .filter(p -> matches(key, p.maSan(), p.tenSan(), p.tenLoaiSan())).toList();
    }
}
