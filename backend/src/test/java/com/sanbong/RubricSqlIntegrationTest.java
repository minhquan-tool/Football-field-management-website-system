package com.sanbong;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.dao.DataAccessException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Rollback-only SQL tests, nevertheless restricted to disposable fixtures because they
 * probe immutable records and trigger failure paths using a non-runtime test identity. */
@AuditCleanupFixture
class RubricSqlIntegrationTest extends RoleAuditSupport {
 void blocked(String sql,int expected){
  DataAccessException error=assertThrows(DataAccessException.class,()->jdbc.update(sql));
  Throwable cause=error;while(cause!=null&&!(cause instanceof SQLException))cause=cause.getCause();
  assertNotNull(cause);assertEquals(expected,((SQLException)cause).getErrorCode());
 }
 @Test void expectedBusinessObjectsExist(){
  assertEquals(5,jdbc.queryForObject("SELECT COUNT(*) FROM sys.procedures WHERE name IN ('usp_ReportUsage','usp_ReportFinance','usp_ReportPaymentMethods','usp_ReportReconciliation','usp_ReportTopServices')",Integer.class));
  assertEquals(5,jdbc.queryForObject("SELECT COUNT(*) FROM sys.objects WHERE name IN ('fn_TyLeHoan','fn_ReportDays','fn_BookingReceipts','fn_BookingRefunds','fn_BookingNetCash') AND type IN('FN','IF','TF')",Integer.class));
  assertEquals(5,jdbc.queryForObject("SELECT COUNT(*) FROM sys.triggers WHERE is_disabled=0 AND name IN ('TRG_CapNhatTienDatSan','TRG_AuditContentImmutable','TRG_ServicePriceSnapshot','TRG_SuccessfulPaymentSnapshot','TRG_SealedInvoiceSnapshot')",Integer.class));
 }
 @Test void dateFunctionHandlesLeapDayAndRejectsOversizedOrInvertedRanges(){
  assertEquals(3,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_ReportDays('20240228','20240301')",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_ReportDays('20240301','20240228')",Integer.class));
  assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM dbo.fn_ReportDays('20200101','20260101')",Integer.class));
 }
 @Test void bookingFunctionsMatchIndependentAggregates(){
  for(String id:jdbc.queryForList("SELECT MaDatSan FROM DatSan",String.class)){
   var cash=jdbc.queryForMap("SELECT p.thu,r.hoan,r.choHoan,n.net FROM dbo.fn_BookingReceipts(?) p CROSS JOIN dbo.fn_BookingRefunds(?) r CROSS JOIN dbo.fn_BookingNetCash(?) n",id,id,id);
   BigDecimal paid=jdbc.queryForObject("SELECT ISNULL(SUM(SoTien),0) FROM ThanhToan WHERE MaDatSan=? AND TrangThai=N'Thành công'",BigDecimal.class,id);
   BigDecimal refunded=jdbc.queryForObject("SELECT ISNULL(SUM(h.SoTienHoan),0) FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=? AND h.TrangThai=N'Đã hoàn'",BigDecimal.class,id);
   assertEquals(0,paid.compareTo((BigDecimal)cash.get("thu")));assertEquals(0,refunded.compareTo((BigDecimal)cash.get("hoan")));
   assertEquals(0,paid.subtract(refunded).compareTo((BigDecimal)cash.get("net")));
  }
 }
 @ParameterizedTest @ValueSource(strings={"usp_ReportUsage","usp_ReportFinance","usp_ReportPaymentMethods","usp_ReportReconciliation"})
 void proceduresRejectInvalidDates(String proc){blocked("EXEC dbo."+proc+" '20260102','20260101',''",51010);}
 @Test void topServicesRejectsMissingDay(){blocked("EXEC dbo.usp_ReportTopServices NULL",51010);}
 @Test void auditMultirowRewriteIsBlocked(){assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong",Integer.class)>1);blocked("UPDATE NhatKyHeThong SET GhiChu=N'forbidden rubric probe'",51023);}
 @Test void serviceMultirowSkuRewriteIsBlocked(){
  assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu",Integer.class)>1);
  blocked("UPDATE ChiTietDichVu SET MaDV=CASE WHEN MaDV='SV01' THEN 'SV02' ELSE 'SV01' END",51024);
 }
 @Test void receivedPaymentCannotBeRewritten(){
  assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE TrangThai=N'Thành công'",Integer.class)>0);
  blocked("UPDATE ThanhToan SET SoTien=SoTien+1 WHERE TrangThai=N'Thành công'",51025);
 }
 @Test void sealedInvoicesRejectMultirowRepricing(){
  assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE DaChot=1",Integer.class)>1);
  blocked("UPDATE HoaDon SET TienSan=TienSan+1 WHERE DaChot=1",51026);
 }
 @Test void noOpUpdatesRemainValid(){
  jdbc.update("UPDATE ChiTietDichVu SET DonGiaDonViSnapshot=DonGiaDonViSnapshot");
  jdbc.update("UPDATE ThanhToan SET SoTien=SoTien WHERE TrangThai=N'Thành công'");
  jdbc.update("UPDATE HoaDon SET TienSan=TienSan WHERE DaChot=1");
 }
 @ParameterizedTest @ValueSource(strings={"DichVu SET DonGia=0","ChiTietDichVu SET SoLuong=0","KhuyenMai SET NgayKetThuc=DATEADD(day,-1,NgayBatDau)","ThanhToan SET SoTien=0","KhungGio SET GioKetThuc=GioBatDau"})
 void fiveBusinessConstraintsRejectInvalidWrites(String mutation){
  String table=mutation.substring(0,mutation.indexOf(' '));
  assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM "+table,Integer.class)>0);
  blocked("UPDATE "+mutation,547);
 }
 @Test void reportRoutesKeepWebRoleBoundaries()throws Exception{
  String day=LocalDate.now().toString();
  var customer=login("khachhang");var staff=login("nvsan");var accountant=login("ketoan");var manager=login("admin");
  mvc.perform(get("/reports/usage").param("from",day).param("to",day).session(customer)).andExpect(status().isForbidden());
  mvc.perform(get("/reports/finance").param("from",day).param("to",day).session(staff)).andExpect(status().isForbidden());
  mvc.perform(get("/reports/finance").param("from",day).param("to",day).session(accountant)).andExpect(status().isOk());
  mvc.perform(get("/reports/dashboard").session(manager)).andExpect(status().isOk());
  mvc.perform(get("/reports/reconciliation").param("from",day).param("to",day).session(accountant)).andExpect(status().isOk());
 }
}
