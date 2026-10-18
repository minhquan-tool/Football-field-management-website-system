package com.sanbong.service;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.sanbong.repository.ReportRepository;
import java.time.*;
import java.math.*;
import java.util.*;
@Service
public class ReportService {
 private final ReportRepository repo;private final Clock clock;public ReportService(ReportRepository repo,Clock clock){this.repo=repo;this.clock=clock;}
 public static void range(LocalDate from,LocalDate to){if(from==null||to==null||to.isBefore(from)||java.time.temporal.ChronoUnit.DAYS.between(from,to)>365||to.getYear()>9998||from.getYear()<1753)throw new IllegalArgumentException("Khoảng ngày không hợp lệ, tối đa366 ngày.");}
 private void pitch(String pitch){if(pitch.length()>10)throw new IllegalArgumentException("Mã sân không hợp lệ.");}
 @Transactional(readOnly=true) public Map<String,Object> usage(LocalDate from,LocalDate to,String pitch){range(from,to);pitch(pitch);var rows=repo.usage(from,to,pitch);var total=new LinkedHashMap<String,Object>();for(String key:List.of("soBooking","soDaSuDung","soDaHuy","phutDat","phutCongSuat"))total.put(key,rows.stream().mapToLong(r->((Number)r.get(key)).longValue()).sum());long minutes=(long)total.get("phutDat"),capacity=(long)total.get("phutCongSuat");total.put("gioDat",BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60),2,RoundingMode.HALF_UP));total.put("tyLeLapDay",capacity==0?BigDecimal.ZERO:BigDecimal.valueOf(minutes*100).divide(BigDecimal.valueOf(capacity),2,RoundingMode.HALF_UP));return Map.of("rows",rows,"totals",total,"from",from,"to",to,"congSuat","15 giờ/ngày/sân thuộc danh mục hiện tại; chưa có lịch sử ngừng/bảo trì");}
 @Transactional(readOnly=true) public Map<String,Object> finance(LocalDate from,LocalDate to,String pitch){range(from,to);pitch(pitch);var rows=repo.finance(from,to,pitch);var total=new LinkedHashMap<String,Object>();for(String key:List.of("tienSan","tienDichVu","tienGiam","doanhThu","tienThu","tienHoan","thucNhan"))total.put(key,rows.stream().map(r->(BigDecimal)r.get(key)).reduce(BigDecimal.ZERO,BigDecimal::add));var methods=repo.methods(from,to,pitch);var gross=(BigDecimal)total.get("tienThu");for(var m:methods)m.put("tyLeTienThu",gross.signum()==0?BigDecimal.ZERO:((BigDecimal)m.get("tienThu")).multiply(BigDecimal.valueOf(100)).divide(gross,2,RoundingMode.HALF_UP));return Map.of("rows",rows,"totals",total,"methods",methods,"from",from,"to",to,"ghiNhan","Doanh thu tại ngày trả sân; thu tại ngày nhận tiền; hoàn tại ngày xác nhận hoàn");}
 @Transactional(readOnly=true) public Map<String,Object> refunds(LocalDate from,LocalDate to,String status,String booking,String method,int page,int size){range(from,to);AdminService.pagination(page,size);if(!List.of("","Chờ duyệt","Đã hoàn","Từ chối").contains(status)||!List.of("","Tiền mặt","Chuyển khoản").contains(method)||booking.length()>10)throw new IllegalArgumentException("Bộ lọc hoàn không hợp lệ.");return repo.refunds(from,to,status,booking,method,page,size);}
 @Transactional(readOnly=true) public Map<String,Object> options(){return Map.of("today",LocalDate.now(clock.withZone(ZoneId.of("Asia/Ho_Chi_Minh"))),"pitches",repo.choices());}
 @Transactional(readOnly=true) public Map<String,Object> reconciliation(LocalDate from,LocalDate to,String pitch){
  range(from,to);pitch(pitch);var rows=repo.reconciliation(from,to,pitch);long review=0;BigDecimal discrepancy=BigDecimal.ZERO;
  for(var row:rows){
   var paid=(BigDecimal)row.get("tienThu");var refunded=(BigDecimal)row.get("tienHoan");var expected=paid.subtract(refunded);
   var receiptDifference=row.get("thuHoaDon")==null?BigDecimal.ZERO:((BigDecimal)row.get("thuHoaDon")).subtract(paid);
   var cashDifference=((BigDecimal)row.get("soThucNhan")).subtract(expected);
   var invoiceDifference=Boolean.TRUE.equals(row.get("daChot"))?((BigDecimal)row.get("tongHoaDon")).subtract((BigDecimal)row.get("tongBooking")):BigDecimal.ZERO;
   var diff=receiptDifference.abs().add(cashDifference.abs()).add(invoiceDifference.abs());
   boolean legacy=row.get("maHoaDon")==null&&paid.signum()>0;boolean invalid=diff.signum()!=0||refunded.compareTo(paid)>0;
   row.put("chenhLechThu",receiptDifference);row.put("chenhLechTien",cashDifference);row.put("chenhLechHoaDon",invoiceDifference);row.put("thucNhanTinhLai",expected);
   row.put("ketQua",legacy?"Legacy cần đối soát":invalid?"Cần kiểm tra":"Khớp sổ nội bộ");
   if(legacy||invalid)review++;discrepancy=discrepancy.add(diff);
  }
  return Map.of("rows",rows,"totals",Map.of("soLuotDat",rows.size(),"canKiemTra",review,"tongSaiLech",discrepancy),"from",from,"to",to,"ghiNhan","Lọc theo ngày chơi; đối chiếu toàn bộ thu/hoàn của từng lượt đặt với số tiền hóa đơn. Nợ chưa trả và hoàn đang chờ không tự coi là sai lệch. Không đối soát sao kê ngân hàng.");
 }
 @Transactional(readOnly=true) public Map<String,Object> dashboard(){var today=LocalDate.now(clock.withZone(ZoneId.of("Asia/Ho_Chi_Minh")));return Map.of("today",today,"usage",usage(today,today,""),"finance",finance(today,today,""),"pitches",repo.pitches(),"topServices",repo.topServices(today),"bookings",repo.todayBookings(today));}
}
