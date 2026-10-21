package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.model.DatSan;
import com.sanbong.repository.*;
import jakarta.persistence.*;
import org.slf4j.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

@Service
public class OperationsService {
    private static final ZoneId ZONE=ZoneId.of("Asia/Ho_Chi_Minh");
    private static final BigDecimal MAX_MONEY=new BigDecimal("9999999999999999.99");
    private static final Logger log=LoggerFactory.getLogger(OperationsService.class);
    private final OperationsRepository operations;
    private final DatSanRepository bookings;
    private final SanRepository pitches;
    private final TaiKhoanRepository accounts;
    private final SecurityRepository security;
    private final FinanceService finance;
    private final CancellationRequestRepository cancellationRequests;
    @PersistenceContext private EntityManager em;
    public OperationsService(OperationsRepository operations,DatSanRepository bookings,SanRepository pitches,
            TaiKhoanRepository accounts,SecurityRepository security,FinanceService finance,CancellationRequestRepository cancellationRequests) {
        this.cancellationRequests=cancellationRequests;
        this.finance=finance;
        this.operations=operations;this.bookings=bookings;this.pitches=pitches;this.accounts=accounts;this.security=security;
    }
    @Transactional(readOnly=true)
    public List<Map<String,Object>> services() { return prices(operations.services()); }
    @Transactional(readOnly=true)
    public Map<String,Object> detail(String id) { return view(find(id)); }
    @Transactional(readOnly=true)
    public List<Map<String,Object>> serviceLines(String id) { return operations.lines(id); }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> checkIn(String id,CheckInRequest request,AccountPrincipal actor) {
        var d=lock(id);var now=LocalDateTime.now(ZONE);
        cancellationRequests.requireNoPending(id);
        if(!"Đã xác nhận".equals(d.getTrangThai())) throw new IllegalStateException("Chỉ nhận sân cho booking đã xác nhận, chưa hủy/chưa hoàn thành.");
        if(operations.visit(id).isPresent()) throw new IllegalStateException("Booking đã nhận sân; không nhận lần thứ hai.");
        if(!d.getNgayChoi().equals(now.toLocalDate()) || now.isBefore(d.getNgayChoi().atTime(d.getGioBatDau()).minusMinutes(30))
                || !now.isBefore(d.getNgayChoi().atTime(d.getGioKetThuc())))
            throw new IllegalStateException("Chỉ nhận sân trong ngày chơi, từ 30 phút trước giờ bắt đầu đến trước giờ kết thúc.");
        if(!"Trống".equals(d.getSan().getTrangThai()) || operations.hasOpenPitch(d.getSan().getMaSan()))
            throw new IllegalStateException("Sân đang bảo trì/đang sử dụng hoặc còn lượt nhận sân chưa trả.");
        operations.checkIn(id,employee(actor),now,request.tinhTrangSan(),request.ghiChu());
        d.getSan().setTrangThai("Đang sử dụng");em.flush();audit(actor,"Thêm",id,"Nhận sân");return view(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> checkOut(String id,AccountPrincipal actor) {
        employee(actor);var d=lock(id);requireOpen(d);
        operations.checkOut(id,LocalDateTime.now(ZONE));d.setTrangThai("Đã sử dụng");d.getSan().setTrangThai("Trống");
        em.flush();finance.sealAtCheckout(d,actor);audit(actor,"Sửa",id,"Trả sân; chốt snapshot hóa đơn, chưa tự thu tiền");return view(d);
    }
    public static BigDecimal packPrice(BigDecimal unit,String pack) {
        return "LOC_6".equals(pack)?unit.multiply(new BigDecimal("5.82")).setScale(2,java.math.RoundingMode.HALF_UP):unit;
    }
    @Transactional(readOnly=true)
    public List<Map<String,Object>> catalog() { return prices(operations.catalog(true)); }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public List<Map<String,Object>> createCatalog(NewServiceRequest request,AccountPrincipal actor) {
        if(!"VT04".equals(actor.roleId())) throw new org.springframework.security.access.AccessDeniedException("Chỉ quản trị được thêm dịch vụ.");
        if(request.hoTroLoc() && !Set.of("Chai","Lon").contains(request.donViTinh())) throw new IllegalArgumentException("Chỉ chai/lon được hỗ trợ lốc 6.");
        if(operations.service(request.maDV()).isPresent()) throw new IllegalStateException("Mã dịch vụ đã tồn tại; không ghi đè SKU.");
        operations.catalogCreate(request.maDV(),request.tenDV().trim(),request.donViTinh().trim(),request.donGia(),request.hoTroLoc());
        security.audit(actor.accountId(),"Thêm","Danh mục dịch vụ",request.maDV(),"Tạo SKU mới; giữ nguyên dịch vụ legacy");return catalog();
    }
    private List<Map<String,Object>> prices(List<Map<String,Object>> rows) {
        for(var row:rows) row.put("giaLoc",Boolean.TRUE.equals(row.get("hoTroLoc"))?packPrice((BigDecimal)row.get("donGia"),"LOC_6"):null);
        return rows;
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public List<Map<String,Object>> updateCatalog(String id,ServiceCatalogRequest request,AccountPrincipal actor) {
        if(!"VT04".equals(actor.roleId())) throw new org.springframework.security.access.AccessDeniedException("Chỉ quản lý được sửa catalog.");
        var old=operations.service(id).orElseThrow(() -> new BookingNotFoundException("Dịch vụ không tồn tại."));
        if(request.hoTroLoc() && !Set.of("Chai","Lon").contains(old.get("donViTinh")))
            throw new IllegalArgumentException("Chỉ sản phẩm chai/lon được hỗ trợ lốc 6.");
        operations.catalogUpdate(id,request.donGia(),request.trangThai(),request.hoTroLoc());
        security.audit(actor.accountId(),"Sửa","Danh mục dịch vụ",id,"Giá "+old.get("donGia")+" -> "+request.donGia()+"; kinh doanh "+request.trangThai()+"; lốc "+request.hoTroLoc());
        return catalog();
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public void prebook(DatSan d,List<PrebookServiceRequest> lines,AccountPrincipal actor) {
        if(lines==null) return;
        // Consistent SKU order also serializes catalog edits without lock-order inversions.
        for(var line:lines.stream().sorted(Comparator.comparing(PrebookServiceRequest::maDV)).toList()) {
            sale(d,line.maDV(),line.soLuong(),line.quyCach(),"DAT_TRUOC",null);
            em.refresh(d);
        }
        if(!lines.isEmpty()) audit(actor,"Thêm",d.getMaDatSan(),"Dịch vụ đặt trước; "+lines.size()+" dòng");
    }
    private void sale(DatSan d,String service,int quantity,String pack,String source,String employee) {
        validateQuantity(quantity);if(pack==null)pack="DON_VI";
        if(!Set.of("DON_VI","LOC_6").contains(pack)) throw new IllegalArgumentException("Quy cách không hợp lệ.");
        var catalog=operations.service(service).orElseThrow(() -> new BookingNotFoundException("Dịch vụ không tồn tại."));
        if(!Boolean.TRUE.equals(catalog.get("trangThai"))) throw new IllegalStateException("Dịch vụ không hoạt động.");
        if("LOC_6".equals(pack) && !Boolean.TRUE.equals(catalog.get("hoTroLoc"))) throw new IllegalArgumentException("Dịch vụ không hỗ trợ lốc 6.");
        var unit=(BigDecimal)catalog.get("donGia");var price=packPrice(unit,pack);
        final var packaging=pack;
        if(operations.lines(d.getMaDatSan()).stream().anyMatch(l -> service.equals(l.get("maDV")) && source.equals(l.get("nguon"))
                && packaging.equals(l.get("quyCach")) && price.compareTo((BigDecimal)l.get("donGia"))==0))
            throw new IllegalStateException("Đã có dòng cùng nguồn/quy cách/giá; hãy sửa số lượng bằng MaChiTiet.");
        validateMoney(d,BigDecimal.ZERO,price.multiply(BigDecimal.valueOf(quantity)));
        operations.add(d.getMaDatSan(),service,quantity,employee,source,pack,unit);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> add(String id,String service,int quantity,AccountPrincipal actor) { return add(id,service,quantity,"DON_VI",actor); }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> add(String id,String service,int quantity,String pack,AccountPrincipal actor) {
        var employee=employee(actor);var d=lock(id);requireEditable(d);
        sale(d,service,quantity,pack,"PHAT_SINH",employee);em.refresh(d);finance.sync(d);
        audit(actor,"Thêm",id,"Dịch vụ phát sinh "+service+"; số lượng "+quantity+"; quy cách "+pack);return view(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> quantity(String id,String service,int quantity,AccountPrincipal actor) {
        employee(actor);var d=lock(id);requireEditable(d);
        var line=operations.line(id,service).orElseThrow(() -> new BookingNotFoundException("Dòng dịch vụ không tồn tại."));
        return quantityLocked(d,line,quantity,actor);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> quantityLine(String id,long lineId,int quantity,AccountPrincipal actor) {
        employee(actor);var d=lock(id);requireEditable(d);
        return quantityLocked(d,operations.lineById(id,lineId).orElseThrow(() -> new BookingNotFoundException("Dòng dịch vụ không tồn tại.")),quantity,actor);
    }
    private Map<String,Object> quantityLocked(DatSan d,Map<String,Object> line,int quantity,AccountPrincipal actor) {
        validateQuantity(quantity);var price=(BigDecimal)line.get("donGia");
        validateMoney(d,(BigDecimal)line.get("thanhTien"),price.multiply(BigDecimal.valueOf(quantity)));
        operations.quantity(d.getMaDatSan(),((Number)line.get("maChiTiet")).longValue(),quantity);em.refresh(d);finance.sync(d);
        audit(actor,"Sửa",d.getMaDatSan(),"Sửa dòng "+line.get("maChiTiet")+"; SL "+quantity+"; giữ giá "+price);return view(d);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> remove(String id,String service,AccountPrincipal actor) {
        employee(actor);var d=lock(id);requireEditable(d);
        return removeLocked(d,operations.line(id,service).orElseThrow(() -> new BookingNotFoundException("Dòng dịch vụ không tồn tại.")),actor);
    }
    @Transactional(isolation=Isolation.READ_COMMITTED)
    public Map<String,Object> removeLine(String id,long line,AccountPrincipal actor) {
        employee(actor);var d=lock(id);requireEditable(d);
        return removeLocked(d,operations.lineById(id,line).orElseThrow(() -> new BookingNotFoundException("Dòng dịch vụ không tồn tại.")),actor);
    }
    private Map<String,Object> removeLocked(DatSan d,Map<String,Object> line,AccountPrincipal actor) {
        operations.remove(d.getMaDatSan(),((Number)line.get("maChiTiet")).longValue());em.refresh(d);finance.sync(d);
        audit(actor,"Xóa",d.getMaDatSan(),"Xóa dòng chưa chốt "+line.get("maChiTiet"));return view(d);
    }
    private void requireOpen(DatSan d) {
        var visit=operations.visit(d.getMaDatSan()).orElseThrow(() -> new IllegalStateException("Booking chưa nhận sân."));
        if(!"Đã xác nhận".equals(d.getTrangThai()) || visit.get("thoiGianKetThuc")!=null)
            throw new IllegalStateException("Booking đã trả sân/hủy/hoàn thành; không được thực hiện thao tác này.");
    }
    private void requireEditable(DatSan d) {
        requireOpen(d);
        if(finance.sealed(d.getMaDatSan())) throw new IllegalStateException("Hóa đơn đã chốt; không sửa dịch vụ bình thường.");
        if(operations.hasPayment(d.getMaDatSan()) && !finance.invoiceExists(d.getMaDatSan())) throw new IllegalStateException("Booking có thanh toán; không sửa dịch vụ hoặc số tiền đã ghi nhận.");
    }
    private void validateQuantity(int quantity) { if(quantity<=0) throw new IllegalArgumentException("Số lượng phải lớn hơn 0."); }
    private void validateMoney(DatSan d,BigDecimal old,BigDecimal value) {
        var services=d.getTienDichVu().subtract(old).add(value);
        var total=d.getTienSan().add(services).subtract(d.getTienGiam());
        if(value.signum()<=0 || services.compareTo(MAX_MONEY)>0 || total.compareTo(MAX_MONEY)>0 || total.signum()<0)
            throw new IllegalArgumentException("Số lượng/giá vượt giới hạn tiền của SQL Server hoặc làm tổng tiền không hợp lệ.");
    }
    private DatSan find(String id) { return bookings.findById(id).orElseThrow(() -> new BookingNotFoundException("Booking không tồn tại.")); }
    private DatSan lock(String id) {
        var current=find(id);
        var pitch=pitches.lockById(current.getSan().getMaSan()).orElseThrow(PitchNotFoundException::new);em.refresh(pitch);
        var d=bookings.lockById(id).orElseThrow(() -> new BookingNotFoundException("Booking không tồn tại."));em.refresh(d);return d;
    }
    private String employee(AccountPrincipal actor) {
        var account=accounts.findById(actor.accountId()).orElseThrow();
        if(account.getNhanVien()==null || !Boolean.TRUE.equals(account.getNhanVien().getTrangThai()))
            throw new org.springframework.security.access.AccessDeniedException("Cần nhân viên đang làm việc để nhận sân/ghi dịch vụ.");
        return account.getNhanVien().getMaNV();
    }
    private Map<String,Object> view(DatSan d) {
        var result=new LinkedHashMap<String,Object>();result.put("booking",BookingView.from(d));
        result.put("visit",operations.visit(d.getMaDatSan()).orElse(null));result.put("services",operations.lines(d.getMaDatSan()));
        return result;
    }
    private void audit(AccountPrincipal actor,String action,String id,String message) {
        security.audit(actor.accountId(),action,"Nhận sân / Dịch vụ",id,message);
        log.info("Operations action={} bookingId={} accountId={}",action,id,actor.accountId());
    }
}
