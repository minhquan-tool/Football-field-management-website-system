package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.*;
@Repository
public class ReportRepository {
 private final JdbcTemplate jdbc;public ReportRepository(JdbcTemplate jdbc){this.jdbc=jdbc;}
 public List<Map<String,Object>> usage(LocalDate from,LocalDate to,String pitch){
  return jdbc.queryForList("EXEC dbo.usp_ReportUsage ?,?,?",from,to,pitch);
 }
 public List<Map<String,Object>> finance(LocalDate from,LocalDate to,String pitch){
  return jdbc.queryForList("EXEC dbo.usp_ReportFinance ?,?,?",from,to,pitch);
 }
 public List<Map<String,Object>> methods(LocalDate from,LocalDate to,String pitch){
  return jdbc.queryForList("EXEC dbo.usp_ReportPaymentMethods ?,?,?",from,to,pitch);
 }
 public Map<String,Object> refunds(LocalDate from,LocalDate to,String status,String booking,String method,int page,int size){
  String where=" FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT JOIN HuyDatSan c ON c.MaHuy=h.MaHuy LEFT JOIN NhanVien n ON n.MaNV=h.MaNV WHERE COALESCE(h.NgayXacNhan,h.NgayHoan)>=? AND COALESCE(h.NgayXacNhan,h.NgayHoan)<? AND (?='' OR h.TrangThai=?) AND (?='' OR t.MaDatSan=?) AND (?='' OR h.PhuongThuc=?)";
  Object[] args={from,to.plusDays(1),status,status,booking,booking,method,method};var count=jdbc.queryForObject("SELECT COUNT(*)"+where,Integer.class,args);var list=new ArrayList<Object>(Arrays.asList(args));list.add((page-1)*size);list.add(size);
  var rows=jdbc.queryForList("SELECT h.MaHT maHT,t.MaDatSan maDatSan,t.MaTT maTT,t.SoTien tienThuGiaoDich,c.SoTienThucThuSnapshot thucThuTaiHuy,c.TiLeHoan tiLeHoan,c.SoTienHoan duocHoanBooking,h.SoTienHoan soTienHoan,h.TrangThai trangThai,h.PhuongThuc phuongThuc,h.MaNV maNV,n.HoTen nguoiXuLy,h.NgayHoan ngayYeuCau,h.NgayXacNhan ngayXacNhan,h.LyDo lyDo"+where+" ORDER BY COALESCE(h.NgayXacNhan,h.NgayHoan) DESC,h.MaHT OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",list.toArray());return Map.of("rows",rows,"total",count,"page",page,"size",size);
 }
 public List<Map<String,Object>> choices(){return jdbc.queryForList("SELECT MaSan maSan,TenSan tenSan FROM San ORDER BY MaSan");}
 public List<Map<String,Object>> reconciliation(LocalDate from,LocalDate to,String pitch){
  return jdbc.queryForList("EXEC dbo.usp_ReportReconciliation ?,?,?",from,to,pitch);
 }
 public Map<String,Object> pitches(){return jdbc.queryForMap("SELECT COUNT(*) tongSan,ISNULL(SUM(CASE WHEN s.TrangThai=N'Bảo trì' THEN 1 ELSE 0 END),0) sanBaoTri,(SELECT COUNT(DISTINCT d.MaSan) FROM DatSan d JOIN XacNhanSan x ON x.MaDatSan=d.MaDatSan WHERE x.ThoiGianKetThuc IS NULL AND d.TrangThai<>N'Đã hủy') sanDangSuDung FROM San s");}
 public List<Map<String,Object>> topServices(LocalDate day){
  return jdbc.queryForList("EXEC dbo.usp_ReportTopServices ?",day);
 }
 public List<Map<String,Object>> todayBookings(LocalDate day){return jdbc.queryForList("SELECT TOP(10) d.MaDatSan maDatSan,d.MaSan maSan,s.TenSan tenSan,k.HoTen khachHang,d.GioBatDau gioBatDau,d.GioKetThuc gioKetThuc,d.TrangThai trangThai FROM DatSan d JOIN San s ON s.MaSan=d.MaSan JOIN KhachHang k ON k.MaKH=d.MaKH WHERE d.NgayChoi=? ORDER BY d.GioBatDau,d.MaDatSan",day);}
}
