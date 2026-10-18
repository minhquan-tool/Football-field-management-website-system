package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import com.sanbong.dto.*;
import java.util.*;
@Repository
public class AdminRepository {
 private final JdbcTemplate jdbc;
 public AdminRepository(JdbcTemplate jdbc){this.jdbc=jdbc;}
 public List<Map<String,Object>> roles(){return jdbc.queryForList("SELECT MaVaiTro maVaiTro,TenVaiTro tenVaiTro FROM VaiTro ORDER BY MaVaiTro");}
 public Map<String,Object> employees(String search,Boolean active,int page,int size){
  String where=" FROM NhanVien n WHERE (? IS NULL OR n.TrangThai=?) AND (n.HoTen LIKE ? OR n.MaNV LIKE ? OR n.SoDienThoai LIKE ?)";
  String term="%"+search+"%";Object[] args={active,active,term,term,term};
  var count=jdbc.queryForObject("SELECT COUNT(*)"+where,Integer.class,args);
  var list=new ArrayList<Object>(Arrays.asList(args));list.add((page-1)*size);list.add(size);
  var rows=jdbc.queryForList("SELECT n.*, (SELECT STRING_AGG(t.TenDangNhap,', ') FROM TaiKhoan t WHERE t.MaNV=n.MaNV) TaiKhoan"+where+" ORDER BY n.MaNV OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",list.toArray());
  return Map.of("rows",rows,"total",count,"page",page,"size",size);
 }
 public Map<String,Object> employee(String id,boolean lock){return jdbc.queryForList("SELECT * FROM NhanVien "+(lock?"WITH(UPDLOCK,HOLDLOCK) ":"")+"WHERE MaNV=?",id).stream().findFirst().orElseThrow(()->new com.sanbong.service.BookingNotFoundException("Nhân viên không tồn tại."));}
 public void insertEmployee(String id,EmployeeRequest r){jdbc.update("INSERT NhanVien(MaNV,HoTen,SoDienThoai,Email,ChucVu,BoPhan,NgayVaoLam,TrangThai) VALUES(?,?,?,?,?,?,?,?)",id,r.hoTen().trim(),r.soDienThoai(),r.email(),r.chucVu(),r.boPhan(),r.ngayVaoLam(),r.trangThai());}
 public void updateEmployee(String id,EmployeeRequest r){jdbc.update("UPDATE NhanVien SET HoTen=?,SoDienThoai=?,Email=?,ChucVu=?,BoPhan=?,NgayVaoLam=?,TrangThai=? WHERE MaNV=?",r.hoTen().trim(),r.soDienThoai(),r.email(),r.chucVu(),r.boPhan(),r.ngayVaoLam(),r.trangThai(),id);}
 public Map<String,Object> account(String id){return jdbc.queryForList("SELECT MaTK,MaNV,MaKH,MaVaiTro,TrangThai FROM TaiKhoan WITH(UPDLOCK,HOLDLOCK) WHERE MaTK=?",id).stream().findFirst().orElseThrow(()->new com.sanbong.service.BookingNotFoundException("Tài khoản không tồn tại."));}
 public List<Map<String,Object>> lockAdmins(){return jdbc.queryForList("SELECT t.MaTK,t.MaNV FROM TaiKhoan t WITH(UPDLOCK,HOLDLOCK) JOIN NhanVien n ON n.MaNV=t.MaNV WHERE t.MaVaiTro='VT04' AND t.TrangThai=N'Hoạt động' AND n.TrangThai=1 ORDER BY t.MaTK");}
 public boolean linked(String id){return jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan WHERE MaNV=?",Integer.class,id)>0;}
 public boolean identifierUsed(String id){return identifierUsed(id,"");}
 public boolean identifierUsed(String id,String excludedEmployee){return jdbc.queryForObject("SELECT COUNT(*) FROM TaiKhoan t LEFT JOIN NhanVien n ON n.MaNV=t.MaNV LEFT JOIN KhachHang k ON k.MaKH=t.MaKH WHERE (t.MaNV IS NULL OR t.MaNV<>?) AND (LOWER(t.TenDangNhap)=LOWER(?) OR n.SoDienThoai=? OR LOWER(n.Email)=LOWER(?) OR k.SoDienThoai=? OR LOWER(k.Email)=LOWER(?))",Integer.class,excludedEmployee,id,id,id,id,id)>0;}
 public void createAccount(String id,StaffAccountRequest r,String hash){jdbc.update("INSERT TaiKhoan(MaTK,TenDangNhap,MatKhau,MaVaiTro,MaNV,TrangThai) VALUES(?,?,?,?,?,N'Hoạt động')",id,r.tenDangNhap(),hash,r.maVaiTro(),r.maNV());}
 public void updateAccount(String id,AccountUpdateRequest r){jdbc.update("UPDATE TaiKhoan SET MaVaiTro=?,TrangThai=? WHERE MaTK=?",r.maVaiTro(),r.hoatDong()?"Hoạt động":"Khóa",id);}
 public void lockEmployeeAccounts(String id){jdbc.update("UPDATE TaiKhoan SET TrangThai=N'Khóa' WHERE MaNV=?",id);}
 public void password(String id,String hash){jdbc.update("UPDATE TaiKhoan SET MatKhau=? WHERE MaTK=?",hash,id);}
 public Map<String,Object> logs(java.time.LocalDate from,java.time.LocalDate to,String actor,String action,String module,String target,int page,int size){
  String where=" FROM NhatKyHeThong l JOIN TaiKhoan t ON t.MaTK=l.MaTK WHERE l.ThoiGian>=? AND l.ThoiGian<? AND (?='' OR l.MaTK=?) AND (?='' OR l.ThaoTac=?) AND (?='' OR l.ChucNang LIKE ?) AND (?='' OR l.DoiTuong LIKE ?)";
  Object[] args={from,to.plusDays(1),actor,actor,action,action,module,"%"+module+"%",target,"%"+target+"%"};
  var count=jdbc.queryForObject("SELECT COUNT(*)"+where,Integer.class,args);var list=new ArrayList<Object>(Arrays.asList(args));list.add((page-1)*size);list.add(size);
  var rows=jdbc.queryForList("SELECT l.MaNhatKy,l.MaTK,t.TenDangNhap,l.ThoiGian,l.ThaoTac,l.ChucNang,l.DoiTuong,l.NoiDungThayDoi,l.KetQua"+where+" ORDER BY l.ThoiGian DESC,l.MaNhatKy OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",list.toArray());return Map.of("rows",rows,"total",count,"page",page,"size",size);
 }
}
