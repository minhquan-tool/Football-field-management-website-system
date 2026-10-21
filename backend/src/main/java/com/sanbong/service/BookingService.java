package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import org.slf4j.*;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

@Service
public class BookingService {
    private static final ZoneId ZONE=ZoneId.of("Asia/Ho_Chi_Minh");
    private static final String WAITING="Chờ xác nhận",CONFIRMED="Đã xác nhận",USED="Đã sử dụng",CANCELLED="Đã hủy";
    private static final List<String> STATES=List.of(WAITING,CONFIRMED,USED,CANCELLED);
    private static final Logger log=LoggerFactory.getLogger(BookingService.class);
    private final SanRepository pitches;
    private final LoaiSanRepository types;
    private final KhungGioRepository slots;
    private final BangGiaRepository prices;
    private final DatSanRepository bookings;
    private final KhachHangRepository customers;
    private final TaiKhoanRepository accounts;
    private final BookingWorkflowRepository workflow;
    private final SecurityRepository security;
    private final Set<LocalDate> holidays;
    private final TimePriceRepository timePrices;
    private final OperationsService operations;
    private final FinanceService finance;
    private final CancellationRequestRepository cancellationRequests;
    public BookingService(SanRepository pitches,LoaiSanRepository types,KhungGioRepository slots,
            BangGiaRepository prices,DatSanRepository bookings,KhachHangRepository customers,
            TaiKhoanRepository accounts,BookingWorkflowRepository workflow,SecurityRepository security,
            @org.springframework.beans.factory.annotation.Value("${app.booking.holidays:}") String holidayDates,
            TimePriceRepository timePrices,OperationsService operations,FinanceService finance,CancellationRequestRepository cancellationRequests) {
        this.cancellationRequests=cancellationRequests;
        this.finance=finance;
        this.operations=operations;
        this.timePrices=timePrices;
        this.pitches=pitches;this.types=types;this.slots=slots;this.prices=prices;this.bookings=bookings;
        this.customers=customers;this.accounts=accounts;this.workflow=workflow;this.security=security;
        try {
            this.holidays=Arrays.stream(holidayDates.split(",")).map(String::trim).filter(s -> !s.isEmpty())
                    .map(LocalDate::parse).collect(java.util.stream.Collectors.toUnmodifiableSet());
        } catch(java.time.format.DateTimeParseException e) {
            throw new IllegalArgumentException("APP_BOOKING_HOLIDAYS phải là các ngày yyyy-MM-dd, phân cách bằng dấu phẩy.");
        }
    }
    @Transactional(readOnly=true)
    public Map<String,Object> options(AccountPrincipal actor) {
        var result=new LinkedHashMap<String,Object>();
        result.put("pitches",pitches.findAll(Sort.by("maSan")).stream().map(PitchView::from).toList());
        result.put("types",types.findAll(Sort.by("maLoaiSan")).stream().map(t -> Map.of(
                "maLoaiSan",t.getMaLoaiSan(),"tenLoaiSan",t.getTenLoaiSan())).toList());
        result.put("slots",slots.findAll(Sort.by("gioBatDau")));
        result.put("states",STATES);result.putAll(BookingTimeDefaults.at(LocalDateTime.now(ZONE)));
        if(isCustomer(actor)) {
            var c=ownCustomer(actor);result.put("customer",Map.of("maKH",c.getMaKH(),"hoTen",c.getHoTen(),"soDienThoai",c.getSoDienThoai()));
        }
        return result;
    }
    @Transactional(readOnly=true)
    public List<Map<String,String>> customers(String phone) {
        if(phone==null || !phone.matches("(?=.{7,15}$)\\+?[0-9]+"))
            throw new IllegalArgumentException("Nhập số điện thoại khách hàng hợp lệ (7–15 ký tự).");
        return customers.findBySoDienThoai(phone).stream().map(c -> Map.of("maKH",c.getMaKH(),
                "hoTen",c.getHoTen(),"soDienThoai",c.getSoDienThoai())).toList();
    }
    @Transactional(readOnly=true)
    public List<AvailableSlot> availability(LocalDate date,String type,String slotId,String status) {
        return availability(date,type,slotId,status,null,null);
    }
    @Transactional(readOnly=true)
    public List<BookingView> list(LocalDate date,String pitch,String slotId,String state,AccountPrincipal actor) {
        if(date==null) throw new IllegalArgumentException("Cần ngày chơi để xem lịch.");
        if(pitch!=null && !pitch.isBlank() && !pitches.existsById(pitch)) throw new BookingNotFoundException("Sân không tồn tại.");
        if(slotId!=null && !slotId.isBlank()) slot(slotId);
        if(state!=null && !state.isBlank() && !STATES.contains(state)) throw new IllegalArgumentException("Trạng thái booking không hợp lệ.");
        String owner=isCustomer(actor)?ownCustomer(actor).getMaKH():null;
        Specification<DatSan> spec=(root,q,cb) -> {
            var p=new ArrayList<jakarta.persistence.criteria.Predicate>();p.add(cb.equal(root.get("ngayChoi"),date));
            if(owner!=null) p.add(cb.equal(root.get("khachHang").get("maKH"),owner));
            if(pitch!=null && !pitch.isBlank()) p.add(cb.equal(root.get("san").get("maSan"),pitch));
            if(slotId!=null && !slotId.isBlank()) p.add(cb.equal(root.get("khungGio").get("maKhungGio"),slotId));
            if(state!=null && !state.isBlank()) p.add(cb.equal(root.get("trangThai"),state));
            return cb.and(p.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
        return bookings.findAll(spec,Sort.by("gioBatDau","san.maSan","maDatSan")).stream().map(BookingView::from).toList();
    }
    @Transactional(readOnly=true)
    public BookingView detail(String id,AccountPrincipal actor) {
        var d=find(id);checkOwner(d,actor);return BookingView.from(d);
    }
    @Transactional(readOnly=true)
    public java.util.List<java.util.Map<String,Object>> serviceLines(String id,AccountPrincipal actor) {
        var d=find(id);checkOwner(d,actor);return operations.serviceLines(id);
    }
    /** Shared pitch lock serializes creation with Phase 3 maintenance and booking transitions. */
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public BookingView create(BookingRequest request,AccountPrincipal actor) {
        validateDate(request.ngayChoi());
        var san=pitches.lockById(request.maSan()).orElseThrow(() -> new BookingNotFoundException("Sân không tồn tại."));
        activePitch(san);
        KhungGio kg=null;
        var start=request.gioBatDau();var end=request.gioKetThuc();
        if(start==null && end==null && request.maKhungGio()!=null && !request.maKhungGio().isBlank()) {
            kg=slot(request.maKhungGio());start=kg.getGioBatDau();end=kg.getGioKetThuc();
        } else if(request.maKhungGio()!=null && !request.maKhungGio().isBlank()) {
            throw new IllegalArgumentException("Chọn giờ tự do hoặc mã khung giờ, không gửi cả hai.");
        }
        validateTimes(request.ngayChoi(),start,end);
        var customer=isCustomer(actor)?ownCustomer(actor):customers.findById(Objects.toString(request.maKH(),""))
                .orElseThrow(() -> new IllegalArgumentException("Chọn khách hàng hợp lệ đã có trong hệ thống."));
        if(isCustomer(actor) && request.maKH()!=null && !request.maKH().equals(customer.getMaKH()))
            throw new AccessDeniedException("Không được đặt thay khách hàng khác.");
        final var begin=start;final var finish=end;
        if(bookings.occupied(request.ngayChoi(),CANCELLED).stream().anyMatch(d -> d.getSan().getMaSan().equals(san.getMaSan()) && overlaps(d.getGioBatDau(),d.getGioKetThuc(),begin,finish)))
            throw new IllegalStateException("Sân đã được đặt trong ngày/khung giờ này. Vui lòng tra cứu lại.");
        var hourly=hourly(start);
        long minutes=java.time.Duration.between(start,end).toMinutes();
        var duration=BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP);
        var pitchMoney=hourly.multiply(BigDecimal.valueOf(minutes)).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP);
        var d=new DatSan();d.setMaDatSan("DS"+UUID.randomUUID().toString().replace("-","").substring(0,8));
        d.setKhachHang(customer);d.setSan(san);d.setKhungGio(kg);d.setNgayChoi(request.ngayChoi());
        d.setGioBatDau(start);d.setGioKetThuc(end);d.setCheDoGia("GIA_GIO");
        d.setHinhThucDat(isCustomer(actor)?"TRUC_TUYEN":"TAI_QUAY");
        d.setThoiLuong(duration);d.setDonGia(hourly);d.setTienSan(pitchMoney);
        d.setTienDichVu(BigDecimal.ZERO);d.setTienGiam(BigDecimal.ZERO);d.setTongTien(pitchMoney);
        d.setTrangThai(WAITING);d.setNgayDat(LocalDateTime.now(ZONE));d.setGhiChu(request.ghiChu());
        if(!isCustomer(actor)) d.setNhanVien(accounts.findById(actor.accountId()).orElseThrow().getNhanVien());
        d=bookings.saveAndFlush(d);operations.prebook(d,request.dichVu(),actor);audit(actor,"Thêm",d,"Tạo booking giờ tự do; giá/giờ "+hourly+"; tổng "+d.getTongTien());
        return BookingView.from(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public BookingView confirm(String id,AccountPrincipal actor) {
        if(isCustomer(actor)) throw new AccessDeniedException("Khách hàng không được xác nhận booking.");
        var d=locked(id,actor);if(!WAITING.equals(d.getTrangThai())) throw new IllegalStateException("Chỉ xác nhận booking đang chờ xác nhận.");
        activePitch(d.getSan());if(!d.getNgayChoi().atTime(d.getGioKetThuc()).isAfter(LocalDateTime.now(ZONE))) throw new IllegalStateException("Booking đã hết giờ đặt; không thể xác nhận.");
        d.setTrangThai(CONFIRMED);bookings.flush();audit(actor,"Sửa",d,"Xác nhận booking");return BookingView.from(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public BookingView cancel(String id,String reason,AccountPrincipal actor) {
        if(isCustomer(actor))throw new AccessDeniedException("Vui lòng gửi yêu cầu hủy để kế toán/chủ sân duyệt; không hủy trực tiếp.");
        if(reason==null || reason.isBlank() || reason.length()>255) throw new IllegalArgumentException("Lý do hủy bắt buộc, tối đa 255 ký tự.");
        var d=locked(id,actor);
        cancellationRequests.requireNoPending(id);
        if(workflow.hasCheckIn(id)) throw new IllegalStateException("Booking đã nhận sân; không được hủy theo luồng đặt sân chưa sử dụng.");
        if(!List.of(WAITING,CONFIRMED).contains(d.getTrangThai())) throw new IllegalStateException("Chỉ hủy booking chờ/đã xác nhận.");
        if(!d.getNgayChoi().atTime(d.getGioBatDau()).isAfter(LocalDateTime.now(ZONE))) throw new IllegalStateException("Booking đã đến giờ chơi; cần nhân viên xử lý theo quy trình vận hành.");
        finance.cancelLocked(d,reason.trim(),actor);d.setTrangThai(CANCELLED);bookings.flush();
        audit(actor,"Sửa",d,"Hủy booking: "+reason.trim());return BookingView.from(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public BookingView reschedule(String id,RescheduleRequest r,AccountPrincipal actor) {
        if(!Set.of("VT02","VT04").contains(actor.roleId())) throw new AccessDeniedException("Chỉ nhân viên sân/quản trị xử lý đổi lịch.");
        var d=locked(id,actor);
        cancellationRequests.requireNoPending(id);
        if(!List.of(WAITING,CONFIRMED).contains(d.getTrangThai()) || workflow.hasCheckIn(id)) throw new IllegalStateException("Chỉ đổi lịch lượt đặt chưa nhận sân.");
        if(!"GIA_GIO".equals(d.getCheDoGia())) throw new IllegalStateException("Giữ nguyên booking legacy; không chuyển sang giá theo giờ.");
        if(workflow.hasFinancialHistory(id)) throw new IllegalStateException("Đã có hóa đơn/giao dịch: cần xử lý hủy/hoàn theo chính sách và tạo lượt đặt mới; không sửa snapshot.");
        if(!d.getNgayChoi().atTime(d.getGioBatDau()).isAfter(LocalDateTime.now(ZONE))) throw new IllegalStateException("Lượt đặt đã đến giờ, không đổi lịch.");
        activePitch(d.getSan());validateTimes(r.ngayChoi(),r.gioBatDau(),r.gioKetThuc());
        if(bookings.occupied(r.ngayChoi(),CANCELLED).stream().anyMatch(other->!id.equals(other.getMaDatSan())&&other.getSan().getMaSan().equals(d.getSan().getMaSan())&&overlaps(other.getGioBatDau(),other.getGioKetThuc(),r.gioBatDau(),r.gioKetThuc()))) throw new IllegalStateException("Lịch mới trùng lượt đặt khác.");
        String before=d.getNgayChoi()+" "+d.getGioBatDau()+"–"+d.getGioKetThuc()+"; tiền sân "+d.getTienSan();
        long minutes=Duration.between(r.gioBatDau(),r.gioKetThuc()).toMinutes();var price=hourly(r.gioBatDau());
        d.setNgayChoi(r.ngayChoi());d.setGioBatDau(r.gioBatDau());d.setGioKetThuc(r.gioKetThuc());d.setKhungGio(null);
        d.setDonGia(price);d.setThoiLuong(BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP));
        d.setTienSan(price.multiply(BigDecimal.valueOf(minutes)).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP));
        d.setTongTien(d.getTienSan().add(d.getTienDichVu()).subtract(d.getTienGiam()));d.setTrangThai(WAITING);bookings.flush();
        audit(actor,"Sửa",d,"Đổi lịch từ "+before+" sang "+r.ngayChoi()+" "+r.gioBatDau()+"–"+r.gioKetThuc()+"; tiền sân "+d.getTienSan()+"; lý do "+r.lyDo().trim());return BookingView.from(d);
    }
    private DatSan locked(String id,AccountPrincipal actor) {
        var current=find(id);checkOwner(current,actor);String pitchId=current.getSan().getMaSan();
        // Always pitch before booking. Refresh to avoid a stale state after waiting for another transaction.
        var lockedPitch=pitches.lockById(pitchId).orElseThrow(PitchNotFoundException::new);
        entityManager.refresh(lockedPitch);
        var d=bookings.lockById(id).orElseThrow(() -> new BookingNotFoundException("Booking không tồn tại."));
        entityManager.refresh(d);checkOwner(d,actor);return d;
    }
    @jakarta.persistence.PersistenceContext private jakarta.persistence.EntityManager entityManager;
    private DatSan find(String id) { return bookings.findById(id).orElseThrow(() -> new BookingNotFoundException("Booking không tồn tại.")); }
    private KhungGio slot(String id) { return slots.findById(id).orElseThrow(() -> new BookingNotFoundException("Khung giờ không tồn tại.")); }
    private boolean isCustomer(AccountPrincipal actor) { return "VT01".equals(actor.roleId()); }
    private KhachHang ownCustomer(AccountPrincipal actor) {
        var account=accounts.findById(actor.accountId()).orElseThrow();
        if(account.getKhachHang()==null) throw new AccessDeniedException("Tài khoản chưa liên kết khách hàng.");
        return account.getKhachHang();
    }
    private void checkOwner(DatSan d,AccountPrincipal actor) {
        if(isCustomer(actor) && !d.getKhachHang().getMaKH().equals(ownCustomer(actor).getMaKH()))
            throw new AccessDeniedException("Không được truy cập booking của khách hàng khác.");
    }
    private void activePitch(San san) {
        if("Bảo trì".equals(san.getTrangThai())) throw new IllegalStateException("Sân đang bảo trì.");
        if(!bookablePitch(san)) throw new IllegalStateException("Sân không hoạt động; chưa thể đặt/xác nhận.");
    }
    // Current use belongs to operations; reservability is determined by the requested date/interval below.
    private boolean bookablePitch(San san) {
        return Set.of("Trống","Đang sử dụng").contains(san.getTrangThai());
    }
    private void validateDate(LocalDate date) {
        if(date==null || date.isBefore(LocalDate.now(ZONE)) || date.getYear()>9999)
            throw new IllegalArgumentException("Ngày chơi phải từ hôm nay trở đi và trong phạm vi SQL Server.");
    }
    private boolean future(LocalDate date,KhungGio kg) {
        return date.atTime(kg.getGioBatDau()).isAfter(LocalDateTime.now(ZONE));
    }
    private boolean overlaps(KhungGio a,KhungGio b) {
        return a.getGioBatDau().isBefore(b.getGioKetThuc()) && b.getGioBatDau().isBefore(a.getGioKetThuc());
    }
    private boolean overlaps(LocalTime aStart,LocalTime aEnd,LocalTime bStart,LocalTime bEnd) {
        return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
    }
    private void validateTimes(LocalDate date,LocalTime start,LocalTime end) {
        validateDate(date);
        if(start==null || end==null || start.isBefore(LocalTime.of(7,0)) || !start.isBefore(LocalTime.of(22,0))
                || end.isAfter(LocalTime.of(22,0)) || !end.isAfter(start)
                || start.getSecond()!=0 || end.getSecond()!=0 || start.getNano()!=0 || end.getNano()!=0)
            throw new IllegalArgumentException("Giờ chơi theo phút, trong 07:00–22:00; kết thúc phải sau bắt đầu.");
        if(!date.atTime(start).isAfter(LocalDateTime.now(ZONE)))
            throw new IllegalArgumentException("Giờ bắt đầu phải trong tương lai.");
    }
    @Transactional(readOnly=true)
    public List<AvailableSlot> availability(LocalDate date,String type,String slotId,String status,LocalTime start,LocalTime end) {
        if(start==null && end==null) {
            if(slotId!=null && !slotId.isBlank()) {
                var kg=slot(slotId);return availability(date,type,slotId,status,kg.getGioBatDau(),kg.getGioKetThuc());
            }
            var result=new ArrayList<AvailableSlot>();
            for(var kg:slots.findAll(Sort.by("gioBatDau"))) {
                if(kg.getGioBatDau().isBefore(LocalTime.of(7,0)) || !future(date,kg)) continue;
                result.addAll(availability(date,type,kg.getMaKhungGio(),status,kg.getGioBatDau(),kg.getGioKetThuc()));
            }
            return result;
        }
        validateTimes(date,start,end);
        if(type!=null && !type.isBlank() && !types.existsById(type)) throw new BookingNotFoundException("Loại sân không tồn tại.");
        if(status!=null && !status.isBlank() && !Set.of("Trống","Đang sử dụng","Bảo trì").contains(status))
            throw new IllegalArgumentException("Trạng thái sân không hợp lệ.");
        var hourly=hourly(start);long minutes=java.time.Duration.between(start,end).toMinutes();
        var duration=BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP);
        var total=hourly.multiply(BigDecimal.valueOf(minutes)).divide(BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP);
        var occupied=bookings.occupied(date,CANCELLED);var result=new ArrayList<AvailableSlot>();
        for(var p:pitches.findAll(Sort.by("maSan"))) {
            if(!bookablePitch(p) || type!=null && !type.isBlank() && !type.equals(p.getLoaiSan().getMaLoaiSan())
                    || status!=null && !status.isBlank() && !status.equals(p.getTrangThai())) continue;
            if(occupied.stream().anyMatch(d -> d.getSan().getMaSan().equals(p.getMaSan()) && overlaps(d.getGioBatDau(),d.getGioKetThuc(),start,end))) continue;
            result.add(new AvailableSlot(p.getMaSan(),p.getTenSan(),p.getLoaiSan().getMaLoaiSan(),p.getLoaiSan().getTenLoaiSan(),
                    p.getTrangThai(),date,slotId,start,end,duration,"GIA_GIO",null,hourly,total));
        }
        return result;
    }
    private BigDecimal hourly(LocalTime start) {
        var price=timePrices.price(start);
        if(price==null || price.signum()<=0) throw new IllegalStateException("Chưa có đúng một giá theo ca cho giờ bắt đầu.");
        return price;
    }
    private BangGia price(List<BangGia> all,San san,KhungGio kg,LocalDate date) {
        String day=holidays.contains(date)?"Ngày lễ":date.getDayOfWeek()==DayOfWeek.SATURDAY || date.getDayOfWeek()==DayOfWeek.SUNDAY?"Cuối tuần":"Ngày thường";
        var matches=all.stream().filter(p -> p.getLoaiSan().getMaLoaiSan().equals(san.getLoaiSan().getMaLoaiSan())
                && p.getKhungGio().getMaKhungGio().equals(kg.getMaKhungGio()) && p.getLoaiNgay().equals(day)
                && !date.isBefore(p.getNgayHieuLuc()) && (p.getNgayHetHieuLuc()==null || !date.isAfter(p.getNgayHetHieuLuc()))).toList();
        if(matches.size()>1) throw new IllegalStateException("Bảng giá chồng hiệu lực; cần quản lý kiểm tra trước khi đặt sân.");
        if(matches.isEmpty() || matches.getFirst().getDonGia().signum()<=0) return null;
        return matches.getFirst(); // DonGia is the price for the stored slot duration, matching existing DatSan snapshots.
    }
    private void audit(AccountPrincipal actor,String action,DatSan d,String detail) {
        security.audit(actor.accountId(),action,"Đặt sân",d.getMaDatSan(),detail);
        log.info("Booking action={} bookingId={} pitchId={} accountId={}",action,d.getMaDatSan(),d.getSan().getMaSan(),actor.accountId());
    }
}
