package com.sanbong.service;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.model.KhachHang;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import org.springframework.security.access.AccessDeniedException;
import java.util.*;
@Service
public class CustomerCareService {
    private final TaiKhoanRepository accounts;
    private final KhachHangRepository customers;
    private final DatSanRepository bookings;
    private final CustomerCareRepository care;
    private final SecurityRepository audit;
    public CustomerCareService(TaiKhoanRepository accounts,KhachHangRepository customers,DatSanRepository bookings,CustomerCareRepository care,SecurityRepository audit){this.accounts=accounts;this.customers=customers;this.bookings=bookings;this.care=care;this.audit=audit;}
    private KhachHang customer(AccountPrincipal actor){var c=accounts.findById(actor.accountId()).orElseThrow().getKhachHang();if(!"VT01".equals(actor.roleId())||c==null)throw new AccessDeniedException("Chỉ dành cho khách hàng.");return c;}
    @Transactional(readOnly=true)
    public CustomerProfileView profile(AccountPrincipal actor){return CustomerProfileView.from(customer(actor));}
    @Transactional(readOnly=true) public List<Map<String,Object>> promotions(){return care.promotions();}
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public CustomerProfileView profile(AccountPrincipal actor,CustomerProfileRequest r){
        var c=customer(actor);String phone=r.soDienThoai().trim(),email=r.email()==null||r.email().isBlank()?null:r.email().trim().toLowerCase(Locale.ROOT);
        if(customers.existsByMaKHNotAndSoDienThoai(c.getMaKH(),phone)||email!=null&&customers.existsByMaKHNotAndEmailIgnoreCase(c.getMaKH(),email))throw new IllegalStateException("Số điện thoại hoặc email đã được sử dụng.");
        for(String identifier:Arrays.asList(phone,email)){if(identifier!=null&&accounts.findByIdentifier(identifier).stream().anyMatch(a->!a.getMaTK().equals(actor.accountId())))throw new IllegalStateException("Thông tin liên hệ trùng tài khoản khác.");}
        c.setHoTen(r.hoTen().trim());c.setSoDienThoai(phone);c.setEmail(email);c.setDiaChi(r.diaChi());customers.saveAndFlush(c);
        audit.audit(actor.accountId(),"Sửa","Cập nhật hồ sơ cá nhân");return CustomerProfileView.from(c);
    }
    @Transactional(readOnly=true)
    public Map<String,Object> history(AccountPrincipal actor){return history(actor,1,20,"","","desc");}
    @Transactional(readOnly=true)
    public Map<String,Object> history(AccountPrincipal actor,int page,int size,String query,String state,String order){
        if(page<1||page>100000||size<1||size>50)throw new IllegalArgumentException("Trang phải từ 1–100000, số lượt mỗi trang từ 1–50.");
        if(query==null||query.length()>100)throw new IllegalArgumentException("Từ khóa tối đa 100 ký tự.");
        var states=List.of("Chờ xác nhận","Đã xác nhận","Đã sử dụng","Đã hủy");
        if(!state.isEmpty()&&!states.contains(state))throw new IllegalArgumentException("Trạng thái lượt đặt không hợp lệ.");
        if(!List.of("asc","desc").contains(order))throw new IllegalArgumentException("Thứ tự sắp xếp không hợp lệ.");
        var c=customer(actor);String term=query.trim().toLowerCase(Locale.ROOT);
        String pattern="%"+term.replace("!","!!").replace("%","!%").replace("_","!_").replace("[","![")+"%";
        org.springframework.data.jpa.domain.Specification<com.sanbong.model.DatSan> spec=(root,q,cb)->{
            var predicates=new ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(cb.equal(root.get("khachHang").get("maKH"),c.getMaKH()));
            if(!state.isEmpty())predicates.add(cb.equal(root.get("trangThai"),state));
            if(!term.isEmpty())predicates.add(cb.or(cb.like(cb.lower(root.get("maDatSan")),pattern,'!'),cb.like(cb.lower(root.get("san").get("tenSan")),pattern,'!')));
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
        var direction="asc".equals(order)?org.springframework.data.domain.Sort.Direction.ASC:org.springframework.data.domain.Sort.Direction.DESC;
        var result=bookings.findAll(spec,org.springframework.data.domain.PageRequest.of(page-1,size,
                org.springframework.data.domain.Sort.by(direction,"ngayChoi","gioBatDau","maDatSan")));
        var rows=result.getContent().stream().map(BookingView::from).toList();
        return Map.of("bookings",rows,"criteria",care.criteria(),"reviews",care.reviews(c.getMaKH(),rows.stream().map(BookingView::maDatSan).toList()),
                "page",page,"size",size,"total",result.getTotalElements(),"totalPages",result.getTotalPages(),"states",states);
    }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public void review(String id,ReviewRequest r,AccountPrincipal actor){
        var c=customer(actor);var d=bookings.lockById(id).orElseThrow(()->new IllegalArgumentException("Lượt đặt không tồn tại."));
        if(!c.getMaKH().equals(d.getKhachHang().getMaKH()))throw new AccessDeniedException("Không được đánh giá lượt đặt khác.");
        if(!"Đã sử dụng".equals(d.getTrangThai()))throw new IllegalStateException("Chỉ đánh giá sau khi trả sân.");
        if(care.hasReview(id))throw new IllegalStateException("Lượt đặt đã được đánh giá.");
        var codes=new HashSet<String>();care.criteria().forEach(row->codes.add(row.get("maTieuChi").toString()));
        if(codes.isEmpty()||!codes.equals(r.diem().keySet()))throw new IllegalArgumentException("Cần chấm đủ các tiêu chí hiện có.");
        care.review(id("DG"),id,c.getMaKH(),d.getSan().getMaSan(),r.noiDung(),r.diem());audit.audit(actor.accountId(),"Thêm","Đánh giá lượt đặt "+id);
    }
    @Transactional(readOnly=true)
    public List<Map<String,Object>> feedback(AccountPrincipal actor){return care.feedback("VT01".equals(actor.roleId())?customer(actor).getMaKH():null);}
    @Transactional
    public void feedback(FeedbackRequest r,AccountPrincipal actor){var c=customer(actor);String booking=r.maDatSan()==null||r.maDatSan().isBlank()?null:r.maDatSan();if(booking!=null){var d=bookings.findById(booking).orElseThrow(()->new IllegalArgumentException("Lượt đặt không tồn tại."));if(!c.getMaKH().equals(d.getKhachHang().getMaKH()))throw new AccessDeniedException("Lượt đặt không thuộc tài khoản.");}care.feedback(id("PH"),c.getMaKH(),booking,r.loaiPhanHoi().trim(),r.noiDung().trim());audit.audit(actor.accountId(),"Thêm","Gửi phản hồi");}
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public void resolve(String id,FeedbackResolutionRequest r,AccountPrincipal actor){var employee=accounts.findById(actor.accountId()).orElseThrow().getNhanVien();if(employee==null)throw new IllegalStateException("Tài khoản chưa liên kết nhân viên.");String state=care.lockedFeedbackState(id).orElseThrow(()->new IllegalArgumentException("Phản hồi không tồn tại."));if("Đã xử lý".equals(state))throw new IllegalStateException("Phản hồi đã xử lý, không ghi đè lịch sử.");care.resolve(id,r.trangThai(),r.ketQua().trim(),employee.getMaNV());audit.audit(actor.accountId(),"Sửa","Xử lý phản hồi "+id);}
    private static String id(String prefix){return prefix+UUID.randomUUID().toString().replace("-","").substring(0,8);}
}
