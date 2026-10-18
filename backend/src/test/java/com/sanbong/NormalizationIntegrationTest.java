package com.sanbong;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AuditCleanupFixture
class NormalizationIntegrationTest extends RoleAuditSupport {
 @Test void databaseOwnsNineDeterministicDerivedColumns(){
  assertEquals(9,jdbc.queryForObject("SELECT COUNT(*) FROM sys.computed_columns WHERE (object_id=OBJECT_ID('DatSan') AND name IN('ThoiLuong','TienSan','TongTien')) OR (object_id=OBJECT_ID('HoaDon') AND name IN('TongTien','ConLai','HoanTatTaiChinh')) OR (object_id=OBJECT_ID('ChiTietDichVu') AND name IN('SoDonViMoiQuyCach','DonGia','ThanhTien'))",Integer.class));
 }
 @Test void legacyAmountsAndDurationsAreExactSnapshots(){
  assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE CheDoGia='GIA_KHUNG'",Integer.class)>0);
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE CheDoGia='GIA_KHUNG' AND (TienSan<>TienSanLegacySnapshot OR ThoiLuong<>ThoiLuongLegacySnapshot)",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE Nguon='LEGACY' AND DonGia<>DonGiaLegacySnapshot",Integer.class));
 }
 @Test void fractionalHourIsCalculatedFromExactMinutesNotRoundedDuration()throws Exception{
  String id=book(login("nvsan"),"08:00","08:37");em.clear();
  var row=jdbc.queryForMap("SELECT DonGia,TienSan,ThoiLuong,TongTien FROM DatSan WHERE MaDatSan=?",id);
  var rate=(BigDecimal)row.get("DonGia");
  var expected=rate.multiply(BigDecimal.valueOf(37)).divide(BigDecimal.valueOf(60),2,RoundingMode.HALF_UP);
  assertEquals(0,expected.compareTo((BigDecimal)row.get("TienSan")));
  assertEquals(0,new BigDecimal("0.62").compareTo((BigDecimal)row.get("ThoiLuong")));
  assertEquals(0,expected.compareTo(bookingsTotal(id)));
 }
 BigDecimal bookingsTotal(String id){return jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",BigDecimal.class,id);}
 @Test void catalogChangesDoNotRewriteSoldUnitOrLegacySnapshots()throws Exception{
  String id=book(login("nvsan"));var before=bookingsTotal(id);
  jdbc.update("UPDATE GiaTheoCa SET DonGia=DonGia+123");
  assertEquals(0,before.compareTo(bookingsTotal(id)));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE CheDoGia='GIA_KHUNG' AND TienSan<>TienSanLegacySnapshot",Integer.class));
 }
 @Test void unitPackAndTriggerTotalsHaveOneStorageCalculation()throws Exception{
  String id=book(login("nvsan"));var pitchTotal=bookingsTotal(id);
  for(String pack:new String[]{"DON_VI","LOC_6"})jdbc.update("INSERT ChiTietDichVu(MaDatSan,MaDV,SoLuong,Nguon,QuyCach,DonGiaDonViSnapshot) VALUES(?,'SV03',2,'DAT_TRUOC',?,10000)",id,pack);
  assertEquals(0,new BigDecimal("136400").compareTo(jdbc.queryForObject("SELECT TienDichVu FROM DatSan WHERE MaDatSan=?",BigDecimal.class,id)));
  assertEquals(0,pitchTotal.add(new BigDecimal("136400")).compareTo(bookingsTotal(id)));
 }
 @ParameterizedTest @ValueSource(strings={"UPDATE DatSan SET TongTien=1","UPDATE DatSan SET TienSan=1","UPDATE DatSan SET ThoiLuong=1","UPDATE HoaDon SET TongTien=1","UPDATE ChiTietDichVu SET DonGia=1","UPDATE ChiTietDichVu SET SoDonViMoiQuyCach=1"})
 void derivedColumnsRejectIndependentWrites(String sql){
  var error=assertThrows(DataAccessException.class,()->jdbc.update(sql));Throwable cause=error;
  while(cause!=null&&!(cause instanceof SQLException))cause=cause.getCause();
  assertNotNull(cause);assertEquals(271,((SQLException)cause).getErrorCode());
 }
 @Test void invoiceStillAcceptsComponentFactsAndReturnsComputedTotal()throws Exception{
  var staff=login("nvsan");String id=book(staff);
  var invoice=data(write(staff,"POST","/finance/bookings/"+id+"/invoice",Map.of()).andExpect(status().isOk()).andReturn());
  assertEquals(0,bookingsTotal(id).compareTo(invoice.path("invoice").path("tongTien").decimalValue()));
 }
}
