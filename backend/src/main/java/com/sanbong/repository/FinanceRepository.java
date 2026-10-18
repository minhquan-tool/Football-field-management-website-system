package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
@Repository
public class FinanceRepository {
 private final JdbcTemplate jdbc;
 public FinanceRepository(JdbcTemplate jdbc) { this.jdbc=jdbc; }
 public Optional<Map<String,Object>> invoice(String id) {
  return jdbc.queryForList("SELECT MaHoaDon maHoaDon,MaDatSan maDatSan,TienSan tienSan,TienDichVu tienDichVu,TienGiam tienGiam,TongTien tongTien,DaThanhToan daThanhToan,ConLai conLai,TrangThai trangThai,DaChot daChot,HoanTatTaiChinh hoanTatTaiChinh,NgayLap ngayLap FROM HoaDon WHERE MaDatSan=?",id).stream().findFirst();
 }
 public void invoiceCreate(String id,String actor,BigDecimal pitch,BigDecimal services,BigDecimal discount,LocalDateTime now) {
  jdbc.update("INSERT HoaDon(MaHoaDon,MaDatSan,MaTKLap,TienSan,TienDichVu,TienGiam,NgayLap) VALUES(?,?,?,?,?,?,?)",code("HD"),id,actor,pitch,services,discount,now);
 }
 public void sync(String id,BigDecimal pitch,BigDecimal services,BigDecimal discount,BigDecimal paid,boolean sealed,boolean cancelled) {
  var row=invoice(id).orElseThrow();
  if(Boolean.TRUE.equals(row.get("daChot"))) { pitch=(BigDecimal)row.get("tienSan");services=(BigDecimal)row.get("tienDichVu");discount=(BigDecimal)row.get("tienGiam"); }
  var total=pitch.add(services).subtract(discount);
  var state=cancelled?"DA_HUY":paid.compareTo(total)==0?"DA_THANH_TOAN":paid.signum()>0?"THANH_TOAN_MOT_PHAN":"CHUA_THANH_TOAN";
  jdbc.update("UPDATE HoaDon SET TienSan=?,TienDichVu=?,TienGiam=?,DaThanhToan=?,TrangThai=?,DaChot=? WHERE MaDatSan=?",pitch,services,discount,paid,state,sealed||Boolean.TRUE.equals(row.get("daChot")),id);
 }
 public List<Map<String,Object>> payments(String id) {
  return jdbc.queryForList("SELECT MaTT maTT,MaDatSan maDatSan,SoTien soTien,PhuongThuc phuongThuc,TrangThai trangThai,MaGiaoDich idempotencyKey,MaNV maNV,NgayThanhToan ngayThanhToan FROM ThanhToan WHERE MaDatSan=? ORDER BY NgayThanhToan,MaTT",id);
 }
 public Optional<Map<String,Object>> payment(String id) {
  return jdbc.queryForList("SELECT MaTT maTT,MaDatSan maDatSan,SoTien soTien,PhuongThuc phuongThuc,TrangThai trangThai,MaGiaoDich idempotencyKey FROM ThanhToan WHERE MaTT=?",id).stream().findFirst();
 }
 public Optional<Map<String,Object>> byKey(String key) {
  return jdbc.queryForList("SELECT MaTT maTT,MaDatSan maDatSan,SoTien soTien,PhuongThuc phuongThuc,TrangThai trangThai FROM ThanhToan WHERE MaGiaoDich=?",key).stream().findFirst();
 }
 public void paymentCreate(String id,BigDecimal amount,String method,String key,String employee,boolean received,LocalDateTime now) {
  jdbc.update("INSERT ThanhToan(MaTT,MaDatSan,SoTien,PhuongThuc,MaGiaoDich,TrangThai,MaNV,NgayThanhToan) VALUES(?,?,?,?,?,?,?,?)",code("TT"),id,amount,method,key,received?"Thành công":"Chờ xử lý",employee,now);
 }
 public void paymentStatus(String id,boolean received,String employee,LocalDateTime now) {
  jdbc.update("UPDATE ThanhToan SET TrangThai=?,MaNV=?,NgayThanhToan=? WHERE MaTT=? AND TrangThai=?",received?"Thành công":"Thất bại",employee,now,id,"Chờ xử lý");
 }
 public BigDecimal paid(String id) { return jdbc.queryForObject("SELECT ISNULL(SUM(SoTien),0) FROM ThanhToan WHERE MaDatSan=? AND TrangThai=?",BigDecimal.class,id,"Thành công"); }
 public BigDecimal refunded(String id) { return jdbc.queryForObject("SELECT ISNULL(SUM(h.SoTienHoan),0) FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=? AND h.TrangThai=?",BigDecimal.class,id,"Đã hoàn"); }
 public BigDecimal refundedPayment(String id) { return jdbc.queryForObject("SELECT ISNULL(SUM(SoTienHoan),0) FROM HoanTien WHERE MaTT=? AND TrangThai=?",BigDecimal.class,id,"Đã hoàn"); }
 public BigDecimal services(String id) { return jdbc.queryForObject("SELECT ISNULL(SUM(ThanhTien),0) FROM ChiTietDichVu WHERE MaDatSan=?",BigDecimal.class,id); }
 public BigDecimal rate(LocalDateTime start,LocalDateTime now) {
  var format=java.time.format.DateTimeFormatter.ofPattern("uuuu-MM-dd'T'HH:mm:ss.SSSSSS");
  return jdbc.queryForObject("SELECT dbo.fn_TyLeHoan(CAST(? AS datetime2(7)),CAST(? AS datetime2(7)))",BigDecimal.class,start.format(format),now.format(format));
 }
 public Optional<Map<String,Object>> cancellation(String id) {
  return jdbc.queryForList("SELECT MaHuy maHuy,NgayHuy ngayHuy,LyDo lyDo,TiLeHoan tiLeHoan,SoTienHoan soTienHoan,SoTienThucThuSnapshot soTienThucThuSnapshot FROM HuyDatSan WHERE MaDatSan=?",id).stream().findFirst();
 }
 public String cancel(String id,String reason,boolean customer,BigDecimal rate,BigDecimal paid,BigDecimal refund,LocalDateTime now) {
  String key=code("HY");jdbc.update("INSERT HuyDatSan(MaHuy,MaDatSan,NgayHuy,LyDo,NguoiHuy,TiLeHoan,SoTienHoan,SoTienThucThuSnapshot) VALUES(?,?,?,?,?,?,?,?)",key,id,now,reason,customer?"Khách hàng":"Nhân viên",rate,refund,paid);
  jdbc.update("UPDATE ThanhToan SET TrangThai=? WHERE MaDatSan=? AND TrangThai=?","Thất bại",id,"Chờ xử lý");return key;
 }
 public void refundCreate(String payment,String cancellation,BigDecimal amount,String method,String reason,LocalDateTime now) {
  jdbc.update("INSERT HoanTien(MaHT,MaTT,MaHuy,SoTienHoan,PhuongThuc,TrangThai,LyDo,NgayHoan) VALUES(?,?,?,?,?,?,?,?)",code("HT"),payment,cancellation,amount,method,"Chờ duyệt",reason,now);
 }
 public List<Map<String,Object>> refunds(String id) {
  return jdbc.queryForList("SELECT h.MaHT maHT,h.MaTT maTT,h.MaHuy maHuy,h.SoTienHoan soTienHoan,h.PhuongThuc phuongThuc,h.TrangThai trangThai,h.MaNV maNV,h.NgayHoan ngayYeuCau,h.NgayXacNhan ngayXacNhan,h.LyDo lyDo FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE t.MaDatSan=? ORDER BY h.MaHT",id);
 }
 public Optional<Map<String,Object>> refund(String id) {
  return jdbc.queryForList("SELECT h.MaHT maHT,h.MaTT maTT,t.MaDatSan maDatSan,h.MaHuy maHuy,h.SoTienHoan soTienHoan,h.TrangThai trangThai FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT WHERE h.MaHT=?",id).stream().findFirst();
 }
 public void refundConfirm(String id,String employee,String method,String reason,LocalDateTime now) {
  jdbc.update("UPDATE HoanTien SET TrangThai=?,MaNV=?,PhuongThuc=?,LyDo=?,NgayXacNhan=? WHERE MaHT=? AND TrangThai=?","Đã hoàn",employee,method,reason,now,id,"Chờ duyệt");
 }
 public boolean returned(String id) { return jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=? AND ThoiGianKetThuc IS NOT NULL",Integer.class,id)>0; }
 public List<Map<String,Object>> promotions() { return jdbc.queryForList("SELECT MaKM maKM,TenKM tenKM,LoaiGiam loaiGiam,MucGiam mucGiam,NgayBatDau ngayBatDau,NgayKetThuc ngayKetThuc,DieuKien dieuKien FROM KhuyenMai WHERE TrangThai=1 AND MucGiam>0 AND (LoaiGiam=N'Số tiền' OR (LoaiGiam=N'Phần trăm' AND MucGiam<=100)) ORDER BY MaKM"); }
 public List<Map<String,Object>> promotionsByCode(String code) {
  return jdbc.queryForList("SELECT MaKM maKM,TenKM tenKM,LoaiGiam loaiGiam,MucGiam mucGiam,NgayBatDau ngayBatDau,NgayKetThuc ngayKetThuc,TrangThai trangThai,DieuKien dieuKien FROM KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE UPPER(MaKM)=? OR UPPER(RIGHT(RTRIM(TenKM),LEN(?)+2))=?",code,code,"("+code+")");
 }
 public boolean hasOtherBooking(String customer,String booking) { return Boolean.TRUE.equals(jdbc.queryForObject("SELECT CAST(CASE WHEN EXISTS(SELECT 1 FROM DatSan WHERE MaKH=? AND MaDatSan<>? AND TrangThai<>N'Đã hủy') THEN 1 ELSE 0 END AS bit)",Boolean.class,customer,booking)); }
 public Optional<Map<String,Object>> promotion(String id) { return jdbc.queryForList("SELECT LoaiGiam loaiGiam,MucGiam mucGiam,NgayBatDau ngayBatDau,NgayKetThuc ngayKetThuc,TrangThai trangThai FROM KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=?",id).stream().findFirst(); }
 public List<Map<String,Object>> transactions() { return jdbc.queryForList("SELECT t.MaTT maTT,t.MaDatSan maDatSan,k.HoTen hoTen,t.PhuongThuc phuongThuc,t.SoTien soTien,t.TrangThai trangThai,CONVERT(varchar(19),t.NgayThanhToan,126) ngayThanhToan FROM ThanhToan t JOIN DatSan d ON d.MaDatSan=t.MaDatSan JOIN KhachHang k ON k.MaKH=d.MaKH ORDER BY t.NgayThanhToan DESC,t.MaTT"); }
 public List<Map<String,Object>> refundQueue() { return jdbc.queryForList("SELECT h.MaHT maHT,t.MaDatSan maDatSan,h.SoTienHoan soTienHoan,h.TrangThai trangThai,h.PhuongThuc phuongThuc FROM HoanTien h JOIN ThanhToan t ON t.MaTT=h.MaTT ORDER BY h.NgayHoan DESC,h.MaHT"); }
 public BigDecimal net() { return jdbc.queryForObject("SELECT ISNULL(SUM(SoTienThucNhan),0) FROM V_ThuChiThucNhan",BigDecimal.class); }
 public static String code(String prefix) { return prefix+UUID.randomUUID().toString().replace("-","").substring(0,8); }
}
