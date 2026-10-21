package com.sanbong;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpSession;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** All fixtures and financial writes are transaction-local and roll back. No bank calls. */
class CustomerPromotionTest extends RoleAuditSupport {
 String promo(String type,int amount,String condition){String id=code("CP").toUpperCase(Locale.ROOT);jdbc.update("INSERT KhuyenMai(MaKM,TenKM,LoaiGiam,MucGiam,NgayBatDau,NgayKetThuc,DieuKien,TrangThai) VALUES(?,?,?,?,?,?,?,1)",id,marker+" ("+id+"X)",type,amount,LocalDate.now().minusDays(2),day().plusDays(90),condition);return id;}
 String path(String id){return "/api/finance/bookings/"+id;}
 org.springframework.test.web.servlet.ResultActions apply(MockHttpSession s,String id,String code)throws Exception{return write(s,"POST",path(id)+"/promotion",Map.of("maKM",code,"tienGiam",99999999,"tongTien",1));}
 com.fasterxml.jackson.databind.JsonNode detail(MockHttpSession s,String id)throws Exception{return data(mvc.perform(get(path(id)).session(s)).andExpect(status().isOk()).andReturn());}
 void open(String id){jdbc.update("UPDATE DatSan SET TrangThai=N'Đã xác nhận' WHERE MaDatSan=?",id);jdbc.update("INSERT XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan) VALUES(?,?,?,?)",code("CX"),id,"NV02",LocalDateTime.now().minusMinutes(10));em.clear();}
 @Test void aliasAndPrimaryCodeReducePitchOnlyAndRepeatNeverStacks()throws Exception{
  var staff=login("nvsan");var customer=login("khachhang");String id=data(write(staff,"POST","/api/bookings",Map.of("maSan",pitch(),"maKH",customer(),"ngayChoi",day().toString(),"gioBatDau","08:00","gioKetThuc","09:00","dichVu",List.of(Map.of("maDV","SV02","quyCach","DON_VI","soLuong",2)))).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
  String code=promo("Phần trăm",10,"");var before=detail(customer,id).path("booking");BigDecimal expected=before.path("tienSan").decimalValue().multiply(new BigDecimal("0.10")).setScale(2);
  for(String entered:List.of((code+"X").toLowerCase(Locale.ROOT),code)){var result=data(apply(customer,id,entered).andExpect(status().isOk()).andReturn());assertEquals(code,result.path("promotionCode").asText());assertEquals(0,expected.compareTo(result.path("invoice").path("tienGiam").decimalValue()));assertEquals(10000,result.path("invoice").path("tienDichVu").asInt());assertEquals(0,before.path("tongTien").decimalValue().subtract(expected).compareTo(result.path("invoice").path("tongTien").decimalValue()));}
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void fixedDiscountCapsAtPitchAndReplacementDoesNotAddToOldDiscount()throws Exception{
  var customer=login("khachhang");String id=book(login("nvsan"));String a=promo("Số tiền",10000,""),b=promo("Số tiền",999999,"");apply(customer,id,a).andExpect(status().isOk());var result=data(apply(customer,id,b).andExpect(status().isOk()).andReturn());assertEquals(0,result.path("booking").path("tienSan").decimalValue().compareTo(result.path("invoice").path("tienGiam").decimalValue()));assertEquals(0,result.path("invoice").path("tongTien").decimalValue().signum());
 }
 @Test void rejectsInvalidExpiredDisabledOrAmbiguousCodeWithoutCreatingInvoice()throws Exception{
  var customer=login("khachhang");String id=book(login("nvsan"));apply(customer,id,"NO_SUCH_CODE").andExpect(status().isNotFound());apply(customer,id," ").andExpect(status().isBadRequest());
  String disabled=promo("Số tiền",1000,"");jdbc.update("UPDATE KhuyenMai SET TrangThai=0 WHERE MaKM=?",disabled);apply(customer,id,disabled).andExpect(status().isBadRequest());String expired=promo("Số tiền",1000,"");jdbc.update("UPDATE KhuyenMai SET NgayBatDau=?,NgayKetThuc=? WHERE MaKM=?",LocalDate.now().minusDays(5),LocalDate.now().minusDays(1),expired);apply(customer,id,expired).andExpect(status().isBadRequest());
  String duplicate=promo("Số tiền",1000,"");jdbc.update("UPDATE KhuyenMai SET TenKM=? WHERE MaKM=?","Another ("+duplicate+")",disabled);apply(customer,id,duplicate).andExpect(status().isConflict());assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
 }
 @Test void studentAndUnknownConditionsRequireStaffButStaffCanRecordFixedDiscount()throws Exception{
  var customer=login("khachhang");String id=book(login("nvsan")),code=promo("Số tiền",20000,"Dành cho sinh viên có thẻ SV");apply(customer,id,code).andExpect(status().isBadRequest());var accountant=login("ketoan");write(accountant,"POST",path(id)+"/invoice",Map.of("maKM",code)).andExpect(status().isBadRequest());var result=data(write(accountant,"POST",path(id)+"/invoice",Map.of("maKM",code,"daXacMinhDieuKien",true)).andExpect(status().isOk()).andReturn());assertEquals(20000,result.path("invoice").path("tienGiam").asInt());
 }
 @Test void weekdayConditionRejectsWeekendAndAcceptsWeekday()throws Exception{
  String id=book(login("nvsan")),code=promo("Phần trăm",10,"Áp dụng ngày trong tuần");var customer=login("khachhang");LocalDate weekend=day().with(java.time.temporal.TemporalAdjusters.nextOrSame(DayOfWeek.SATURDAY));jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",weekend,id);em.clear();apply(customer,id,code).andExpect(status().isBadRequest());jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",weekend.plusDays(2),id);em.clear();apply(customer,id,code).andExpect(status().isOk());
 }
 @org.junit.jupiter.params.ParameterizedTest
 @org.junit.jupiter.params.provider.ValueSource(ints={1,2,3,4,5,6,7})
 void wednesdayPromotionChecksPlayDateAndStaffCannotOverride(int isoDay)throws Exception{
  var staff=login("nvsan");var customer=login("khachhang");String id=book(staff),code=promo("Phần trăm",10,"Chỉ áp dụng thứ Tư");
  LocalDate play=day().with(java.time.temporal.TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY)).plusDays(isoDay-1);
  jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",play,id);em.clear();
  if(isoDay==3){
   var result=data(apply(customer,id,code+"X").andExpect(status().isOk()).andReturn());
   assertEquals(0,result.path("booking").path("tienSan").decimalValue().multiply(new BigDecimal("0.10")).setScale(2).compareTo(result.path("invoice").path("tienGiam").decimalValue()));
  }else{
   apply(customer,id,code).andExpect(status().isBadRequest());
   write(login("ketoan"),"POST",path(id)+"/invoice",Map.of("maKM",code,"daXacMinhDieuKien",true)).andExpect(status().isBadRequest());
   assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
  }
 }
 @Test void firstBookingConditionChecksCustomerHistoryAndOwnership()throws Exception{
  var staff=login("nvsan");String old=book(staff),code=promo("Số tiền",1000,"Dành cho khách hàng mới");apply(login("khachhang"),old,code).andExpect(status().isBadRequest());
  String username=code("pc"),password="Coupon-"+UUID.randomUUID();write(login("khachhang"),"POST","/api/auth/register",Map.of("hoTen",marker,"soDienThoai",phone(),"email",username+"@example.invalid","tenDangNhap",username,"matKhau",password)).andExpect(status().isOk());var fresh=login(username,password);String customerId=jdbc.queryForObject("SELECT MaKH FROM TaiKhoan WHERE TenDangNhap=?",String.class,username);
  apply(fresh,old,code).andExpect(status().isForbidden());String first=data(write(staff,"POST","/api/bookings",Map.of("maSan",pitch(),"maKH",customerId,"ngayChoi",day().toString(),"gioBatDau","09:00","gioKetThuc","10:00")).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();apply(fresh,first,code).andExpect(status().isOk());apply(staff,first,code).andExpect(status().isForbidden());
 }
 @Test void pendingOrConfirmedPaymentsAndCancelledOrSealedInvoiceBlockCoupon()throws Exception{
  var staff=login("nvsan");var customer=login("khachhang");String a=book(staff),b=book(staff,"09:00","10:00"),c=book(staff,"10:00","11:00"),d=book(staff,"11:00","12:00"),promo=promo("Phần trăm",10,"");
  write(customer,"POST",path(a)+"/payment-requests",payment(1000,UUID.randomUUID().toString())).andExpect(status().isOk());apply(customer,a,promo).andExpect(status().isConflict());
  write(login("ketoan"),"POST",path(b)+"/payments",payment(1000,UUID.randomUUID().toString())).andExpect(status().isOk());apply(customer,b,promo).andExpect(status().isConflict());
  write(customer,"POST","/api/bookings/"+c+"/cancel",Map.of("lyDo",marker)).andExpect(status().isOk());apply(customer,c,promo).andExpect(status().isConflict());open(d);write(staff,"POST","/api/operations/bookings/"+d+"/check-out",Map.of()).andExpect(status().isOk());apply(customer,d,promo).andExpect(status().isConflict());
 }
 @Test void prepaidPitchCanAddServicesAfterCheckInAndOnlyNewBalanceRemainsDue()throws Exception{
  var staff=login("nvsan");var customer=login("khachhang");String id=book(staff),code=promo("Phần trăm",10,"");var applied=data(apply(customer,id,code).andExpect(status().isOk()).andReturn());var total=applied.path("invoice").path("tongTien").decimalValue();var discount=applied.path("invoice").path("tienGiam").decimalValue();
  write(login("ketoan"),"POST",path(id)+"/payments",Map.of("soTien",total,"phuongThuc","Tiền mặt","daNhanTien",true,"idempotencyKey",UUID.randomUUID().toString())).andExpect(status().isOk());
  write(staff,"POST","/api/operations/bookings/"+id+"/api/services/SV02",Map.of("soLuong",2)).andExpect(status().isConflict());open(id);
  write(customer,"POST","/api/operations/bookings/"+id+"/api/services/SV02",Map.of("soLuong",2)).andExpect(status().isForbidden());write(staff,"POST","/api/operations/bookings/"+id+"/api/services/SV02",Map.of("soLuong",2)).andExpect(status().isOk());var result=detail(customer,id).path("invoice");assertEquals(10000,result.path("conLai").asInt());assertEquals(0,total.compareTo(result.path("daThanhToan").decimalValue()));assertEquals(0,discount.compareTo(result.path("tienGiam").decimalValue()));
  write(staff,"POST","/api/operations/bookings/"+id+"/check-out",Map.of()).andExpect(status().isOk());assertTrue(detail(customer,id).path("invoice").path("daChot").asBoolean());write(staff,"POST","/api/operations/bookings/"+id+"/api/services/SV03",Map.of("soLuong",1)).andExpect(status().isConflict());
 }
}
