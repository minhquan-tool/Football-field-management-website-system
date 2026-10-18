package com.sanbong;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;

/** All fixtures roll back and may run only on the opted-in disposable database. */
@AuditCleanupFixture
class LegacyViewsIntegrationTest extends RoleAuditSupport {
 int available(String pitch,LocalDate date){return jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_KhungGioTrongTheoNgay(?) WHERE MaSan=?",Integer.class,date,pitch);}
 @Test void selectedDateExcludesEveryOverlappingSlotButAllowsTouchingBoundary()throws Exception{
  String p=pitch();int original=available(p,day());assertTrue(original>0);
  String id=book(login("nvsan"),"16:10","17:40");
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_KhungGioTrongTheoNgay(?) WHERE MaSan=? AND GioBatDau<'17:40' AND GioKetThuc>'16:10'",Integer.class,day(),p));
  assertTrue(available(p,day())<original);assertEquals(original,available(p,day().plusDays(1)));
  var slot=jdbc.queryForMap("SELECT TOP(1) GioBatDau,GioKetThuc FROM dbo.KhungGio WHERE GioBatDau>='07:00' AND GioKetThuc<='22:00' ORDER BY GioBatDau");
  jdbc.update("UPDATE DatSan SET GioBatDau=?,GioKetThuc=? WHERE MaDatSan=?",slot.get("GioKetThuc"),java.sql.Time.valueOf(((java.sql.Time)slot.get("GioKetThuc")).toLocalTime().plusMinutes(1)),id);
  assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_KhungGioTrongTheoNgay(?) WHERE MaSan=? AND GioBatDau=CONVERT(time,?) AND GioKetThuc=CONVERT(time,?)",Integer.class,day(),p,slot.get("GioBatDau").toString(),slot.get("GioKetThuc").toString()));
 }
 @Test void cancelledBookingNoLongerBlocksAndMaintenanceIsNeverOffered()throws Exception{
  String p=pitch();int original=available(p,day());String id=book(login("nvsan"));
  jdbc.update("UPDATE DatSan SET TrangThai=N'Đã hủy' WHERE MaDatSan=?",id);assertEquals(original,available(p,day()));
  jdbc.update("UPDATE San SET TrangThai=N'Bảo trì' WHERE MaSan=?",p);assertEquals(0,available(p,day()));
 }
 @Test void nullDateAndOutOfHoursAreNotAvailability(){
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_KhungGioTrongTheoNgay(NULL)",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_KhungGioTrongTheoNgay(?) WHERE GioBatDau<'07:00' OR GioKetThuc>'22:00'",Integer.class,day()));
 }
 @Test void legacyAvailabilityExplicitlyUsesTodayInVietnam(){
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.V_KhungGioTrong WHERE NgayChoi<>CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time')",Integer.class));
 }
 @Test void utilizationUsesMinutesNotBookingCount()throws Exception{
  String p=pitch();LocalDate isolated=day().plusYears(5);
  jdbc.update("INSERT DatSan(MaDatSan,MaKH,MaSan,NgayChoi,DonGia,GioBatDau,GioKetThuc,CheDoGia,TrangThai) VALUES(?,?,?, ?,100000,'08:00','08:37','GIA_GIO',N'Đã xác nhận')",code("LV"),customer(),p,isolated);
  var row=jdbc.queryForMap("SELECT * FROM dbo.V_TyLeLapDay WHERE NgayChoi=?",isolated);
  assertEquals(37,((Number)row.get("PhutDat")).intValue());
  long capacity=jdbc.queryForObject("SELECT COUNT_BIG(*)*900 FROM San",Long.class);
  assertEquals(capacity,((Number)row.get("PhutCongSuat")).longValue());
  assertEquals(0,BigDecimal.valueOf(3700).divide(BigDecimal.valueOf(capacity),2,java.math.RoundingMode.HALF_UP).compareTo((BigDecimal)row.get("TyLeLapDay")));
 }
 @Test void cashCompatibilityAndAccruedRevenueKeepDifferentSources(){
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM (SELECT * FROM dbo.V_DoanhThuTheoNgay EXCEPT SELECT * FROM dbo.V_ThuTienTheoNgay)x",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM (SELECT * FROM dbo.V_ThuTienTheoNgay EXCEPT SELECT CAST(NgayThanhToan AS date),PhuongThuc,COUNT(*),SUM(SoTien) FROM ThanhToan WHERE TrangThai=N'Thành công' GROUP BY CAST(NgayThanhToan AS date),PhuongThuc)x",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM (SELECT Ngay,SUM(DoanhThu) amount FROM V_Phase6_Revenue GROUP BY Ngay EXCEPT SELECT Ngay,DoanhThu FROM V_DoanhThuPhatSinhTheoNgay)x",Integer.class));
  assertEquals(3,jdbc.queryForObject("SELECT COUNT(*) FROM sys.extended_properties WHERE name='SanBongContract'",Integer.class));
 }
}
