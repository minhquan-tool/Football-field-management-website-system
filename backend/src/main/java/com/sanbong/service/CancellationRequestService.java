package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.model.DatSan;
import com.sanbong.repository.*;
import jakarta.persistence.*;
import org.springframework.stereotype.Service;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.*;
import java.math.*;
import java.time.*;
import java.util.*;

@Service
public class CancellationRequestService {
 private final CancellationRequestRepository requests;
 private final DatSanRepository bookings;
 private final SanRepository pitches;
 private final TaiKhoanRepository accounts;
 private final BookingWorkflowRepository workflow;
 private final FinanceRepository ledger;
 private final FinanceService finance;
 private final SecurityRepository audit;
 private final Clock clock;
 @PersistenceContext private EntityManager em;
 public CancellationRequestService(CancellationRequestRepository requests,DatSanRepository bookings,SanRepository pitches,TaiKhoanRepository accounts,BookingWorkflowRepository workflow,FinanceRepository ledger,FinanceService finance,SecurityRepository audit,Clock clock){this.requests=requests;this.bookings=bookings;this.pitches=pitches;this.accounts=accounts;this.workflow=workflow;this.ledger=ledger;this.finance=finance;this.audit=audit;this.clock=clock;}
 private LocalDateTime now(){return LocalDateTime.ofInstant(clock.instant(),ZoneId.of("Asia/Ho_Chi_Minh"));}
 private void ready(){if(!requests.ready())throw new IllegalStateException("Chức năng yêu cầu hủy chưa được kích hoạt. Vui lòng liên hệ nhân viên.");}
 private void customer(AccountPrincipal actor){if(!"VT01".equals(actor.roleId()))throw new AccessDeniedException("Chỉ khách hàng gửi yêu cầu hủy của mình.");}
 private void reviewer(AccountPrincipal actor){if(!Set.of("VT03","VT04").contains(actor.roleId()))throw new AccessDeniedException("Chỉ kế toán/chủ sân duyệt yêu cầu hủy.");var employee=accounts.findById(actor.accountId()).orElseThrow().getNhanVien();if(employee==null||!Boolean.TRUE.equals(employee.getTrangThai()))throw new AccessDeniedException("Cần nhân viên đang làm việc xử lý yêu cầu.");}
 private void reason(String value){if(value==null||value.isBlank()||value.length()>255)throw new IllegalArgumentException("Lý do bắt buộc, tối đa 255 ký tự.");}
 private DatSan find(String id){return bookings.findById(id).orElseThrow(()->new BookingNotFoundException("Lượt đặt không tồn tại."));}
 private void owner(DatSan d,AccountPrincipal actor){var c=accounts.findById(actor.accountId()).orElseThrow().getKhachHang();if(c==null||!c.getMaKH().equals(d.getKhachHang().getMaKH()))throw new AccessDeniedException("Không được gửi yêu cầu cho lượt đặt của người khác.");}
 private DatSan lock(String id){var original=find(id);var pitch=pitches.lockById(original.getSan().getMaSan()).orElseThrow(PitchNotFoundException::new);em.refresh(pitch);var d=bookings.lockById(id).orElseThrow();em.refresh(d);return d;}
 private void cancellable(DatSan d,boolean sending){if(!Set.of("Chờ xác nhận","Đã xác nhận").contains(d.getTrangThai())||workflow.hasCheckIn(d.getMaDatSan()))throw new IllegalStateException("Lượt đặt đã nhận sân, hoàn thành hoặc đã hủy; không thể xử lý yêu cầu hủy.");if(sending&&!d.getNgayChoi().atTime(d.getGioBatDau()).isAfter(now()))throw new IllegalStateException("Lượt đặt đã đến giờ chơi; vui lòng liên hệ nhân viên.");}
 public static BigDecimal estimate(BigDecimal net,BigDecimal rate){if(net.signum()<0||rate.signum()<0||rate.compareTo(BigDecimal.valueOf(100))>0)throw new IllegalStateException("Thực thu hoặc tỷ lệ hoàn không hợp lệ.");return net.multiply(rate).divide(BigDecimal.valueOf(100),2,RoundingMode.HALF_UP).min(net);}
 @Transactional(readOnly=true)
 public Map<String,Object> list(AccountPrincipal actor,String state,int page){if(!Set.of("VT01","VT03","VT04").contains(actor.roleId()))throw new AccessDeniedException("Không có quyền xem yêu cầu hủy.");if(!Set.of("","PENDING","APPROVED","REJECTED").contains(state)||page<1||page>100000)throw new IllegalArgumentException("Bộ lọc không hợp lệ.");if(!requests.ready())return Map.of("enabled",false,"rows",List.of(),"total",0,"pending",0,"page",page);String account="VT01".equals(actor.roleId())?actor.accountId():"";return Map.of("enabled",true,"rows",requests.list(account,state,page),"total",requests.count(account,state),"pending",requests.count(account,"PENDING"),"page",page);}
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> submit(String id,String reason,AccountPrincipal actor){customer(actor);reason(reason);ready();owner(find(id),actor);var d=lock(id);owner(d,actor);var pending=requests.pending(id);if(pending.isPresent())return pending.get();cancellable(d,true);if(ledger.invoice(id).isEmpty()&&!ledger.payments(id).isEmpty())throw new IllegalStateException("Thanh toán legacy cần đối soát trước khi yêu cầu hủy.");var at=now();var rate=ledger.rate(d.getNgayChoi().atTime(d.getGioBatDau()),at);var net=ledger.paid(id).subtract(ledger.refunded(id));var key=requests.create(id,actor.accountId(),reason.trim(),rate,net,estimate(net,rate),at);audit.audit(actor.accountId(),"Thêm","Yêu cầu hủy",key,"Khách gửi yêu cầu; sân vẫn giữ; tỷ lệ hoàn "+rate);return requests.find(key).orElseThrow();}
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,Object> decide(String id,boolean approve,String note,AccountPrincipal actor){reviewer(actor);reason(note);ready();var original=requests.find(id).orElseThrow(()->new BookingNotFoundException("Yêu cầu hủy không tồn tại."));String booking=(String)original.get("maDatSan");var d=lock(booking);var r=requests.find(id).orElseThrow();String target=approve?"APPROVED":"REJECTED";if(target.equals(r.get("trangThai")))return r;if(!"PENDING".equals(r.get("trangThai")))throw new IllegalStateException("Yêu cầu đã được xử lý khác với thao tác này.");String cancellation=null;if(approve){cancellable(d,false);finance.cancelRequestedLocked(d,(String)r.get("lyDo"),(BigDecimal)r.get("tiLeHoan"),actor);d.setTrangThai("Đã hủy");bookings.flush();cancellation=(String)ledger.cancellation(booking).orElseThrow().get("maHuy");}requests.resolve(id,target,actor.accountId(),note.trim(),cancellation,now());audit.audit(actor.accountId(),"Sửa","Yêu cầu hủy",id,target+"; "+note.trim()+"; chưa xác nhận chuyển tiền hoàn");return requests.find(id).orElseThrow();}
}
