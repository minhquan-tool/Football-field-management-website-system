package com.sanbong;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class RuntimePermissionsTest extends RoleAuditSupport {
 int can(String table,String action){return jdbc.queryForObject("SELECT HAS_PERMS_BY_NAME(?,N'OBJECT',?)",Integer.class,"dbo."+table,action);}
 @Test void runtimeNoLongerUsesGlobalReaderWriterRoles(){
  for(String role:new String[]{"db_owner","db_datareader","db_datawriter"})assertEquals(0,jdbc.queryForObject("SELECT IS_MEMBER(?)",Integer.class,role));
  assertEquals(1,jdbc.queryForObject("SELECT IS_MEMBER(N'SanBongRuntimeRole')",Integer.class));
 }
 @Test void historyCannotBeDeletedButMutableServiceLinesCan(){
  for(String table:new String[]{"DatSan","HoaDon","ThanhToan","HoanTien","HuyDatSan","NhatKyHeThong","TaiKhoan","NhanVien","DanhGia","PhanHoi"})assertEquals(0,can(table,"DELETE"),table);
  assertEquals(1,can("ChiTietDichVu","DELETE"));
 }
 @Test void financialBusinessWritesAndReadOnlyCatalogAreSeparated(){
  for(String table:new String[]{"DatSan","HoaDon","ThanhToan","HoanTien","XacNhanSan"})for(String action:new String[]{"SELECT","INSERT","UPDATE"})assertEquals(1,can(table,action),table+action);
  for(String table:new String[]{"VaiTro","ChucNang","TieuChiDanhGia"})for(String action:new String[]{"INSERT","UPDATE","DELETE"})assertEquals(0,can(table,action),table+action);
  assertEquals(1,can("BangGia","INSERT"));assertEquals(0,can("BangGia","UPDATE"));
  assertEquals(0,can("GiaTheoCa","INSERT"));assertEquals(1,can("GiaTheoCa","UPDATE"));
 }
 @Test void applicationHasNoDatabaseAdministrationPrivileges(){
  for(String action:new String[]{"BACKUP DATABASE","ALTER","CONTROL"})assertEquals(0,jdbc.queryForObject("SELECT HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',?)",Integer.class,action));
 }
 @Test void reportsRetainReadPermissionOnTheirThreeViews(){
  for(String view:new String[]{"V_ThuChiThucNhan","V_Phase6_Revenue","V_Phase6_UsageBooking"}){
   assertEquals(1,can(view,"SELECT"),view);
   for(String action:new String[]{"INSERT","UPDATE","DELETE"})assertEquals(0,can(view,action),view+action);
  }
 }
}
