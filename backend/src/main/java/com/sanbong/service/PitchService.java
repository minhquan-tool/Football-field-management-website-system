package com.sanbong.service;

import com.sanbong.dto.*;
import com.sanbong.model.San;
import com.sanbong.repository.*;
import org.slf4j.*;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.time.*;
import java.util.*;

@Service
public class PitchService {
    private static final Logger log=LoggerFactory.getLogger(PitchService.class);
    private static final Set<String> STATES=Set.of("Trống","Đang sử dụng","Bảo trì");
    private final SanRepository pitches;
    private final LoaiSanRepository types;
    private final BangGiaRepository prices;
    private final DatSanRepository bookings;
    private final SecurityRepository security;
    private final OperationsRepository operations;
    public PitchService(SanRepository pitches,LoaiSanRepository types,BangGiaRepository prices,
                        DatSanRepository bookings,SecurityRepository security,OperationsRepository operations) {
        this.pitches=pitches;this.types=types;this.prices=prices;this.bookings=bookings;this.security=security;
        this.operations=operations;
    }
    @Transactional(readOnly=true)
    public List<PitchView> list(String q,String type,String status) {
        if(q!=null && q.length()>100) throw new IllegalArgumentException("Từ khóa tối đa 100 ký tự.");
        if(status!=null && !status.isBlank() && !STATES.contains(status))
            throw new IllegalArgumentException("Trạng thái sân không hợp lệ.");
        if(type!=null && !type.isBlank() && !types.existsById(type))
            throw new IllegalArgumentException("Loại sân không tồn tại.");
        Specification<San> spec=(root,query,cb) -> {
            var predicates=new ArrayList<jakarta.persistence.criteria.Predicate>();
            if(q!=null && !q.isBlank()) {
                String escaped=q.trim().toLowerCase(Locale.ROOT).replace("\\","\\\\")
                        .replace("%","\\%").replace("_","\\_").replace("[","\\[");
                predicates.add(cb.or(cb.like(cb.lower(root.get("maSan")),"%"+escaped+"%",'\\'),
                        cb.like(cb.lower(root.get("tenSan")),"%"+escaped+"%",'\\')));
            }
            if(type!=null && !type.isBlank()) predicates.add(cb.equal(root.get("loaiSan").get("maLoaiSan"),type));
            if(status!=null && !status.isBlank()) predicates.add(cb.equal(root.get("trangThai"),status));
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
        return pitches.findAll(spec,Sort.by("maSan")).stream().map(PitchView::from).toList();
    }
    @Transactional(readOnly=true)
    public PitchView detail(String id) { return PitchView.from(find(id)); }
    @Transactional(readOnly=true)
    public List<?> types() {
        return types.findAll(Sort.by("maLoaiSan")).stream().map(t -> Map.of("maLoaiSan",t.getMaLoaiSan(),
                "tenLoaiSan",t.getTenLoaiSan(),"soNguoi",t.getSoNguoi(),"moTa",Objects.toString(t.getMoTa(),""))).toList();
    }
    @Transactional(readOnly=true)
    public List<PriceView> prices(String id) { return typePrices(find(id).getLoaiSan().getMaLoaiSan()); }
    @Transactional(readOnly=true)
    public List<PriceView> allPrices() { return prices.findAll().stream().map(PriceView::from).toList(); }
    private List<PriceView> typePrices(String id) {
        return prices.findByLoaiSanMaLoaiSanOrderByNgayHieuLucDescMaBangGiaAsc(id).stream().map(PriceView::from).toList();
    }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public PitchView create(PitchRequest request,String actor) {
        if(pitches.existsById(request.maSan())) throw new IllegalStateException("Mã sân đã tồn tại.");
        var san=new San();san.setMaSan(request.maSan());apply(san,request);
        pitches.saveAndFlush(san);
        audit(actor,"Thêm",san,"Thêm sân "+san.getTenSan());return PitchView.from(san);
    }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public PitchView update(String id,PitchRequest request,String actor) {
        if(!id.equals(request.maSan())) throw new IllegalArgumentException("Không được thay đổi mã sân.");
        var san=pitches.lockById(id).orElseThrow(PitchNotFoundException::new);
        checkMaintenance(san,request.trangThai());apply(san,request);pitches.flush();
        audit(actor,"Sửa",san,"Cập nhật thông tin sân; trạng thái "+san.getTrangThai());return PitchView.from(san);
    }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public PitchView status(String id,String status,String actor) {
        if(!STATES.contains(status)) throw new IllegalArgumentException("Trạng thái sân không hợp lệ.");
        var san=pitches.lockById(id).orElseThrow(PitchNotFoundException::new);
        checkMaintenance(san,status);String before=san.getTrangThai();san.setTrangThai(status);pitches.flush();
        audit(actor,"Sửa",san,"Trạng thái: "+before+" → "+status);return PitchView.from(san);
    }
    private San find(String id) { return pitches.findById(id).orElseThrow(PitchNotFoundException::new); }
    private void apply(San san,PitchRequest r) {
        san.setTenSan(r.tenSan().trim());san.setMoTa(r.moTa()==null?null:r.moTa().trim());
        san.setLoaiSan(types.findById(r.maLoaiSan()).orElseThrow(() -> new IllegalArgumentException("Loại sân không tồn tại.")));
        san.setTrangThai(r.trangThai());
    }
    private void checkMaintenance(San san,String target) {
        if(!"Đang sử dụng".equals(target) && operations.hasOpenPitch(san.getMaSan()))
            throw new IllegalStateException("Sân còn lượt nhận chưa trả; cần trả sân qua nghiệp vụ trước khi đổi trạng thái.");
        if(!"Bảo trì".equals(target) || target.equals(san.getTrangThai())) return;
        if("Đang sử dụng".equals(san.getTrangThai()))
            throw new IllegalStateException("Sân đang sử dụng; cần kết thúc sử dụng trước khi bảo trì.");
        if(bookings.countUpcomingActive(san.getMaSan(),LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")),
                List.of("Chờ xác nhận","Đã xác nhận"))>0)
            throw new IllegalStateException("Sân có booking chờ/đã xác nhận từ hôm nay trở đi; chưa thể bảo trì. Cần xử lý booking trước.");
    }
    private void audit(String actor,String action,San san,String detail) {
        security.audit(actor,action,"Quản lý sân",san.getMaSan(),detail);
        log.info("Pitch action={} pitchId={} accountId={}",action,san.getMaSan(),actor);
    }
}
