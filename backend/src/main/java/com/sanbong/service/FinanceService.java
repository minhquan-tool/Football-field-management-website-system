package com.sanbong.service;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.*;
import com.sanbong.model.DatSan;
import com.sanbong.repository.*;
import jakarta.persistence.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import org.springframework.security.access.AccessDeniedException;
import java.math.*;
import java.time.*;
import java.util.*;
@Service
public class FinanceService {
 private final FinanceRepository finance;
 private final DatSanRepository bookings;
 private final SanRepository pitches;
 private final TaiKhoanRepository accounts;
 private final SecurityRepository security;
 private final Clock clock;
 @PersistenceContext private EntityManager em;
 public FinanceService(FinanceRepository finance,DatSanRepository bookings,SanRepository pitches,TaiKhoanRepository accounts,SecurityRepository security,Clock clock) {
  this.finance=finance;this.bookings=bookings;this.pitches=pitches;this.accounts=accounts;this.security=security;this.clock=clock;
 }
 private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(),ZoneId.of("Asia/Ho_Chi_Minh")).truncatedTo(java.time.temporal.ChronoUnit.MICROS); }
 private DatSan find(String id) { return bookings.findById(id).orElseThrow(() -> new BookingNotFoundException("Booking không tồn tại.")); }
 private void owner(DatSan d,AccountPrincipal actor) {
  if("VT01".equals(actor.roleId())) {
   var customer=accounts.findById(actor.accountId()).orElseThrow().getKhachHang();
   if(customer==null || !customer.getMaKH().equals(d.getKhachHang().getMaKH())) throw new AccessDeniedException("Chỉ xem tài chính booking của mình.");
  }
 }
 private DatSan lock(String id,AccountPrincipal actor) {
  var original=find(id);owner(original,actor);
  var pitch=pitches.lockById(original.getSan().getMaSan()).orElseThrow(PitchNotFoundException::new);em.refresh(pitch);
  var d=bookings.lockById(id).orElseThrow();em.refresh(d);owner(d,actor);return d;
 }
 private String employee(AccountPrincipal actor) {
  var n=accounts.findById(actor.accountId()).orElseThrow().getNhanVien();
  if(n==null || !Boolean.TRUE.equals(n.getTrangThai())) throw new AccessDeniedException("Cần nhân viên đang làm việc xác nhận thực thu/hoàn.");return n.getMaNV();
 }
 private void payable(DatSan d) {
  if("Đã hủy".equals(d.getTrangThai())) throw new IllegalStateException("Booking đã hủy; không ghi nhận thêm thanh toán.");
 }
 private void ensure(DatSan d,AccountPrincipal actor) {
  if(finance.invoice(d.getMaDatSan()).isEmpty()) {
   payable(d);verifyServices(d);finance.invoiceCreate(d.getMaDatSan(),actor.accountId(),d.getTienSan(),d.getTienDichVu(),d.getTienGiam(),now());
   audit(actor,"Thêm",d.getMaDatSan(),"Lập hóa đơn duy nhất từ snapshot booking/dịch vụ");
  }
  sync(d);
 }
 private void verifyServices(DatSan d) {
  if(finance.services(d.getMaDatSan()).compareTo(d.getTienDichVu())!=0) throw new IllegalStateException("Tổng dịch vụ chưa khớp trigger; cần đối soát trước khi lập hóa đơn.");
 }
 /** Caller holds San -> DatSan locks; invoice creation and sealing join the checkout transaction. */
 @Transactional(propagation=Propagation.MANDATORY)
 public void sealAtCheckout(DatSan d,AccountPrincipal actor) {
  verifyServices(d);ensure(d,actor);
 }
 /** Called within the shared San -> DatSan transaction after service writes/checkout. */
 public void sync(DatSan d) {
  var row=finance.invoice(d.getMaDatSan());if(row.isEmpty() || "DA_HUY".equals(row.get().get("trangThai"))) return;
  var paid=finance.paid(d.getMaDatSan());
  var total=Boolean.TRUE.equals(row.get().get("daChot"))?(BigDecimal)row.get().get("tongTien"):d.getTongTien();
  if(paid.compareTo(total)>0) throw new IllegalStateException("Tổng mới thấp hơn thực thu; không sửa tiền đã ghi nhận.");
  finance.sync(d.getMaDatSan(),d.getTienSan(),d.getTienDichVu(),d.getTienGiam(),paid,
   "Đã sử dụng".equals(d.getTrangThai()) || finance.returned(d.getMaDatSan()),false);
 }
 public boolean sealed(String id) {
  return finance.invoice(id).map(r -> Boolean.TRUE.equals(r.get("daChot"))).orElse(false)
   || finance.returned(id) || bookings.findById(id).map(d -> "Đã sử dụng".equals(d.getTrangThai())).orElse(false);
 }
 public boolean invoiceExists(String id) { return finance.invoice(id).isPresent(); }
 @Transactional(readOnly=true)
 public Map<String,Object> detail(String id,AccountPrincipal actor) { var d=find(id);owner(d,actor);return view(d); }
 private Map<String,Object> view(DatSan d) {
  var result=new LinkedHashMap<String,Object>();String id=d.getMaDatSan();
  result.put("booking",BookingView.from(d));result.put("invoice",finance.invoice(id).orElse(null));
  result.put("payments",finance.payments(id));result.put("refunds",finance.refunds(id));result.put("cancellation",finance.cancellation(id).orElse(null));
  result.put("thucThu",finance.paid(id).subtract(finance.refunded(id)));
  result.put("promotionCode",d.getMaKM()==null?"":d.getMaKM());
  result.put("canApplyPromotion","GIA_GIO".equals(d.getCheDoGia())&&!"Đã hủy".equals(d.getTrangThai())&&!sealed(id)&&finance.paid(id).signum()==0&&finance.payments(id).stream().noneMatch(p->"Chờ xử lý".equals(p.get("trangThai"))));return result;
 }
 @Transactional(readOnly=true) public List<Map<String,Object>> promotions() { return finance.promotions(); }
 @Transactional(readOnly=true) public Map<String,Object> transactions() { return Map.of("payments",finance.transactions(),"refunds",finance.refundQueue(),"thucNhan",finance.net()); }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> invoice(String id,InvoiceRequest request,AccountPrincipal actor) {
  employee(actor);var d=lock(id,actor);payable(d);
  if(request.maKM()!=null && !request.maKM().isBlank()) applyPromotion(d,request.maKM(),actor,Boolean.TRUE.equals(request.daXacMinhDieuKien()));
  ensure(d,actor);return view(d);
 }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> applyCustomerPromotion(String id,PromotionApplyRequest request,AccountPrincipal actor) {
  if(!"VT01".equals(actor.roleId()))throw new AccessDeniedException("Chức năng này dành cho khách hàng.");
  var d=lock(id,actor);payable(d);applyPromotion(d,request.maKM(),actor,false);ensure(d,actor);return view(d);
 }
 private void applyPromotion(DatSan d,String code,AccountPrincipal actor,boolean witnessed) {
   String id=d.getMaDatSan();
   if(!"GIA_GIO".equals(d.getCheDoGia())) throw new IllegalStateException("Booking legacy giữ nguyên snapshot giảm giá, không áp cách tính mới.");
   if(sealed(id) || finance.paid(id).signum()>0 || finance.payments(id).stream().anyMatch(p -> "Chờ xử lý".equals(p.get("trangThai"))))
    throw new IllegalStateException("Không đổi khuyến mãi sau chốt hoặc khi có giao dịch thanh toán.");
   code=code.trim().toUpperCase(Locale.ROOT);
   if(!code.matches("[A-Z0-9_-]{1,32}"))throw new IllegalArgumentException("Mã khuyến mãi không hợp lệ.");
   var matches=finance.promotionsByCode(code);
   if(matches.size()>1)throw new IllegalStateException("Mã khuyến mãi bị trùng tên. Vui lòng liên hệ nhân viên.");
   var promo=matches.stream().findFirst().orElseThrow(() -> new BookingNotFoundException("Khuyến mãi không tồn tại."));
   var value=(BigDecimal)promo.get("mucGiam");String type=(String)promo.get("loaiGiam");
   var start=((java.sql.Date)promo.get("ngayBatDau")).toLocalDate();var end=((java.sql.Date)promo.get("ngayKetThuc")).toLocalDate();
   if(!Boolean.TRUE.equals(promo.get("trangThai"))||value.signum()<=0||!("Số tiền".equals(type)||"Phần trăm".equals(type))||"Phần trăm".equals(type)&&value.compareTo(BigDecimal.valueOf(100))>0
     ||now().toLocalDate().isBefore(start)||now().toLocalDate().isAfter(end)||d.getNgayChoi().isBefore(start)||d.getNgayChoi().isAfter(end))
    throw new IllegalArgumentException("Khuyến mãi không hợp lệ hoặc ngoài thời gian áp dụng/ngày sử dụng sân.");
   String condition=Objects.toString(promo.get("dieuKien"),"").trim();
   if(condition.equalsIgnoreCase("Áp dụng ngày trong tuần")) {
    if(Set.of(DayOfWeek.SATURDAY,DayOfWeek.SUNDAY).contains(d.getNgayChoi().getDayOfWeek()))
    throw new IllegalArgumentException("Khuyến mãi này chỉ áp dụng ngày trong tuần.");
   } else if(condition.equalsIgnoreCase("Chỉ áp dụng thứ Tư")) {
    if(d.getNgayChoi().getDayOfWeek()!=DayOfWeek.WEDNESDAY)
     throw new IllegalArgumentException("Khuyến mãi này chỉ áp dụng cho ngày chơi thứ Tư.");
   } else if(condition.equalsIgnoreCase("Dành cho khách hàng mới")) {
    if(finance.hasOtherBooking(d.getKhachHang().getMaKH(),id))throw new IllegalArgumentException("Mã này chỉ áp dụng cho lượt đặt đầu tiên chưa hủy của khách hàng.");
   } else if(!condition.isBlank()) {
    if("VT01".equals(actor.roleId()))throw new IllegalArgumentException("Mã này cần nhân viên xác minh điều kiện tại quầy: "+condition);
    if(!witnessed)throw new IllegalArgumentException("Nhân viên phải xác nhận đã kiểm tra điều kiện khuyến mãi trước khi áp mã: "+condition);
   }
   var discount="Phần trăm".equals(type)?d.getTienSan().multiply(value).divide(BigDecimal.valueOf(100),2,RoundingMode.HALF_UP):value.min(d.getTienSan());
   d.setMaKM((String)promo.get("maKM"));d.setTienGiam(discount);
   d.setTongTien(d.getTienSan().add(d.getTienDichVu()).subtract(d.getTienGiam()));em.flush();
   audit(actor,"Sửa",id,"Khuyến mãi chỉ giảm tiền sân; "+d.getMaKM()+"; giảm "+d.getTienGiam()+(!condition.isBlank()&&!"VT01".equals(actor.roleId())?"; nhân viên chịu trách nhiệm xác minh điều kiện: "+condition:""));
 }
 private BigDecimal remaining(String id) { return (BigDecimal)finance.invoice(id).orElseThrow().get("conLai"); }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> pay(String id,PaymentRequest request,AccountPrincipal actor,boolean received) {
  var d=lock(id,actor);payable(d);String employee=received?employee(actor):null;
  if(received&&"VT02".equals(actor.roleId())&&!"Tiền mặt".equals(request.phuongThuc()))throw new AccessDeniedException("Nhân viên sân chỉ ghi nhận tiền mặt; chuyển khoản cần kế toán hoặc chủ sân xác minh.");
  if(received && !Boolean.TRUE.equals(request.daNhanTien())) throw new IllegalArgumentException("Phải xác nhận đã thực nhận tiền; ứng dụng không tự chuyển tiền ngân hàng.");
  var old=finance.byKey(request.idempotencyKey());
  if(old.isPresent()) {
   var row=old.get();if(!id.equals(row.get("maDatSan")) || request.soTien().compareTo((BigDecimal)row.get("soTien"))!=0 || !request.phuongThuc().equals(row.get("phuongThuc")))
    throw new IllegalStateException("Idempotency key đã dùng cho nội dung khác.");
   if(received && !"Thành công".equals(row.get("trangThai"))) throw new IllegalStateException("Giao dịch đã có; dùng thao tác xác nhận giao dịch đang chờ.");return view(d);
  }
  ensure(d,actor);
  if(request.soTien().compareTo(remaining(id))>0 || remaining(id).signum()==0) throw new IllegalStateException("Số tiền vượt số còn thiếu hoặc hóa đơn đã đủ tiền.");
  if(!received && finance.payments(id).stream().anyMatch(p -> "Chờ xử lý".equals(p.get("trangThai")))) throw new IllegalStateException("Đã có yêu cầu thanh toán chờ xác minh.");
  finance.paymentCreate(id,request.soTien(),request.phuongThuc(),request.idempotencyKey(),employee,received,now());sync(d);
  audit(actor,"Thêm",id,received?"Ghi nhận thực thu "+request.soTien():"Yêu cầu thanh toán; chưa xác nhận thực thu");return view(d);
 }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> confirmPayment(String payment,AccountPrincipal actor,boolean received) {
  return confirmPaymentInternal(payment,actor,received,false);
 }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> confirmCashPayment(String payment,AccountPrincipal actor) {
  if(!"VT02".equals(actor.roleId()))throw new AccessDeniedException("Chỉ nhân viên sân xác nhận tại quầy qua thao tác này.");
  return confirmPaymentInternal(payment,actor,true,true);
 }
 private Map<String,Object> confirmPaymentInternal(String payment,AccountPrincipal actor,boolean received,boolean cashOnly) {
  String employee=employee(actor);var original=finance.payment(payment).orElseThrow(() -> new BookingNotFoundException("Giao dịch không tồn tại."));
  var d=lock((String)original.get("maDatSan"),actor);var row=finance.payment(payment).orElseThrow();payable(d);
  if((cashOnly||"VT02".equals(actor.roleId()))&&!"Tiền mặt".equals(row.get("phuongThuc")))throw new AccessDeniedException("Nhân viên sân chỉ xác nhận tiền mặt; chuyển khoản cần kế toán hoặc chủ sân đối chiếu.");
  if(received && "Thành công".equals(row.get("trangThai"))) return view(d);
  if(!"Chờ xử lý".equals(row.get("trangThai"))) throw new IllegalStateException("Giao dịch không còn chờ xử lý.");
  ensure(d,actor);if(received && ((BigDecimal)row.get("soTien")).compareTo(remaining(d.getMaDatSan()))>0) throw new IllegalStateException("Giao dịch vượt số còn thiếu.");
  finance.paymentStatus(payment,received,employee,now());sync(d);audit(actor,"Sửa",d.getMaDatSan(),received?"Xác nhận thực thu "+payment:"Từ chối giao dịch "+payment);return view(d);
 }
 @Transactional(readOnly=true)
 public Map<String,Object> cancelPreview(String id,AccountPrincipal actor) {
  var d=find(id);owner(d,actor);var now=now();var rate=finance.rate(d.getNgayChoi().atTime(d.getGioBatDau()),now);
  var net=finance.paid(id).subtract(finance.refunded(id));return Map.of("thoiDiem",now,"tiLeHoan",rate,"thucThu",net,"soTienHoan",net.multiply(rate).divide(BigDecimal.valueOf(100),2,RoundingMode.HALF_UP));
 }
 /** BookingService has already locked and validated ownership/state/visit/time. */
 public void cancelLocked(DatSan d,String reason,AccountPrincipal actor) {
  String id=d.getMaDatSan();
  if(!invoiceExists(id) && !finance.payments(id).isEmpty()) throw new IllegalStateException("Thanh toán legacy chưa đối soát; không tự chuyển đổi/hủy.");
  ensure(d,actor);var now=now();var rate=finance.rate(d.getNgayChoi().atTime(d.getGioBatDau()),now);
  var net=finance.paid(id).subtract(finance.refunded(id));if(net.signum()<0) throw new IllegalStateException("Thực thu không hợp lệ; cần đối soát.");
  var target=net.multiply(rate).divide(BigDecimal.valueOf(100),2,RoundingMode.HALF_UP);
  String cancellation=finance.cancel(id,reason,"VT01".equals(actor.roleId()),rate,net,target,now);
  var payments=finance.payments(id).stream().filter(p -> "Thành công".equals(p.get("trangThai"))).toList();var budget=target;
  for(int i=0;i<payments.size();i++) {
   var row=payments.get(i);String payment=(String)row.get("maTT");var available=((BigDecimal)row.get("soTien")).subtract(finance.refundedPayment(payment));
   if(available.signum()<0) throw new IllegalStateException("Khoản hoàn trước vượt thực thu.");
   var amount=budget.min(available);
   amount=amount.min(available);if(amount.signum()>0) finance.refundCreate(payment,cancellation,amount,(String)row.get("phuongThuc"),reason,now);budget=budget.subtract(amount);
  }
  if(budget.signum()!=0) throw new IllegalStateException("Không phân bổ được số tiền hoàn; chưa hủy.");
  finance.sync(id,d.getTienSan(),d.getTienDichVu(),d.getTienGiam(),finance.paid(id),true,true);
  audit(actor,"Thêm",id,"Hủy; tỷ lệ hoàn "+rate+"; thực thu "+net+"; yêu cầu hoàn "+target+"; chưa tự chuyển tiền");
 }
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> refund(String refund,RefundConfirmation request,AccountPrincipal actor) {
  if(!Boolean.TRUE.equals(request.daHoanTien())) throw new IllegalArgumentException("Cần xác nhận đã trả tiền thực tế cho khách.");
  if(!Set.of("VT03","VT04").contains(actor.roleId())) throw new AccessDeniedException("Chỉ kế toán/admin xác nhận hoàn tiền.");
  String employee=employee(actor);var original=finance.refund(refund).orElseThrow(() -> new BookingNotFoundException("Khoản hoàn không tồn tại."));
  var d=lock((String)original.get("maDatSan"),actor);var row=finance.refund(refund).orElseThrow();
  if("Đã hoàn".equals(row.get("trangThai"))) return view(d);
  if(!"Đã hủy".equals(d.getTrangThai()) || !"Chờ duyệt".equals(row.get("trangThai"))) throw new IllegalStateException("Khoản hoàn không còn hợp lệ.");
  var cancellation=finance.cancellation(d.getMaDatSan()).orElseThrow();
  var planned=(BigDecimal)cancellation.get("soTienHoan");var amount=(BigDecimal)row.get("soTienHoan");
  var payment=finance.payment((String)row.get("maTT")).orElseThrow();
  if(!row.get("maHuy").equals(cancellation.get("maHuy")) || !"Thành công".equals(payment.get("trangThai"))
   || finance.refunded(d.getMaDatSan()).add(amount).compareTo(planned)>0
   || finance.refundedPayment((String)row.get("maTT")).add(amount).compareTo((BigDecimal)payment.get("soTien"))>0)
    throw new IllegalStateException("Khoản hoàn vượt chính sách hoặc thực thu.");
  finance.refundConfirm(refund,employee,request.phuongThuc(),request.lyDo(),now());audit(actor,"Sửa",d.getMaDatSan(),"Nhân viên xác nhận đã hoàn thực tế "+refund+"; "+amount+"; "+request.phuongThuc());return view(d);
 }
 private void audit(AccountPrincipal actor,String action,String id,String detail) {
  security.audit(actor.accountId(),action,"Tài chính",id,detail);
  org.slf4j.LoggerFactory.getLogger(FinanceService.class).info("Finance action={} bookingId={} accountId={}",action,id,actor.accountId());
 }
}
