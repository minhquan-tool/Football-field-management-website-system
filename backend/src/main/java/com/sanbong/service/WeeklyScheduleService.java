package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.BookingView;
import com.sanbong.model.DatSan;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

/** Bounded, read-only week view. Booking changes still use the existing workflows. */
@Service
public class WeeklyScheduleService {
    private final DatSanRepository bookings;private final SanRepository pitches;private final Clock clock;
    public WeeklyScheduleService(DatSanRepository bookings,SanRepository pitches,Clock clock){this.bookings=bookings;this.pitches=pitches;this.clock=clock;}
    @Transactional(readOnly=true)
    public Map<String,Object> week(LocalDate date,String pitch,String state,AccountPrincipal actor){
        if(!Set.of("VT02","VT04").contains(actor.roleId()))throw new AccessDeniedException("Lịch đá bóng chỉ dành cho nhân viên sân và chủ sân.");
        if(date==null||date.getYear()<1||date.getYear()>9999)throw new IllegalArgumentException("Chọn ngày trong tuần hợp lệ.");
        var start=date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        if(start.getYear()<1||start.plusDays(6).getYear()>9999)throw new IllegalArgumentException("Tuần nằm ngoài khoảng ngày hỗ trợ.");
        if(pitch!=null&&!pitch.isBlank()&&!pitches.existsById(pitch))throw new BookingNotFoundException("Sân không tồn tại.");
        if(state!=null&&!state.isBlank()&&!Set.of("ALL","Chờ xác nhận","Đã xác nhận","Đã sử dụng","Đã hủy").contains(state))throw new IllegalArgumentException("Trạng thái lịch không hợp lệ.");
        Specification<DatSan> spec=(root,q,cb)->{
            var predicates=new ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(cb.between(root.get("ngayChoi"),start,start.plusDays(6)));
            if(pitch!=null&&!pitch.isBlank())predicates.add(cb.equal(root.get("san").get("maSan"),pitch));
            if(state==null||state.isBlank())predicates.add(cb.notEqual(root.get("trangThai"),"Đã hủy"));
            else if(!"ALL".equals(state))predicates.add(cb.equal(root.get("trangThai"),state));
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
        var rows=bookings.findAll(spec,Sort.by("ngayChoi","gioBatDau","san.maSan","maDatSan")).stream().map(BookingView::from).toList();
        return Map.of("weekStart",start,"weekEnd",start.plusDays(6),"today",LocalDate.now(clock.withZone(ZoneId.of("Asia/Ho_Chi_Minh"))),"bookings",rows);
    }
}
