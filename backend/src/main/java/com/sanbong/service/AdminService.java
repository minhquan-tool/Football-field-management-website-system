package com.sanbong.service;
import com.sanbong.dto.*;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.*;
import java.time.LocalDate;
import com.sanbong.security.PasswordPolicy;
import java.util.*;
@Service
public class AdminService {
 private final AdminRepository repo;private final SecurityRepository security;private final PasswordEncoder encoder;
 public AdminService(AdminRepository repo,SecurityRepository security,PasswordEncoder encoder){this.repo=repo;this.security=security;this.encoder=encoder;}
 @Transactional(readOnly=true) public Map<String,Object> options(){return Map.of("today",LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")),"roles",repo.roles());}
 public static void pagination(int page,int size){if(page<1||page>100000||size<1||size>100)throw new IllegalArgumentException("Phân trang không hợp lệ.");}
 @Transactional(readOnly=true) public Map<String,Object> employees(String q,Boolean active,int page,int size){pagination(page,size);if(q.length()>100)throw new IllegalArgumentException("Từ khóa tối đa100 ký tự.");return repo.employees(q.trim(),active,page,size);}
 @Transactional(readOnly=true) public Map<String,Object> employee(String id){return repo.employee(id,false);}
 @Transactional(isolation=Isolation.SERIALIZABLE) public Map<String,Object> createEmployee(EmployeeRequest r,String actor){repo.lockAdmins();String id=FinanceRepository.code("NV");repo.insertEmployee(id,r);audit(actor,"Thêm",id,"Tạo nhân viên");return repo.employee(id,false);}
 @Transactional(isolation=Isolation.SERIALIZABLE) public Map<String,Object> editEmployee(String id,EmployeeRequest r,String actor){var admins=repo.lockAdmins();var previous=repo.employee(id,true);
  if(repo.linked(id)) {if(!Objects.equals(previous.get("SoDienThoai"),r.soDienThoai()))checkLoginContact(r.soDienThoai(),id);if(!Objects.equals(previous.get("Email"),r.email()))checkLoginContact(r.email(),id);}
  if(!r.trangThai()) {if(admins.stream().anyMatch(a->id.equals(a.get("MaNV"))&&(actor.equals(a.get("MaTK"))||admins.size()==1)))throw new IllegalStateException("Không ngừng tài khoản quản trị đang thao tác hoặc quản trị viên cuối cùng.");repo.lockEmployeeAccounts(id);}
  repo.updateEmployee(id,r);audit(actor,"Sửa",id,r.trangThai()?"Cập nhật nhân viên":"Ngừng nhân viên; khóa tài khoản liên kết");return repo.employee(id,false);
 }
 @Transactional(isolation=Isolation.SERIALIZABLE) public Map<String,Object> createAccount(StaffAccountRequest r,String actor){PasswordPolicy.validate(r.matKhau());repo.lockAdmins();var n=repo.employee(r.maNV(),true);if(!Boolean.TRUE.equals(n.get("TrangThai")))throw new IllegalStateException("Nhân viên đã ngừng hoạt động.");if(repo.linked(r.maNV())||repo.identifierUsed(r.tenDangNhap()))throw new IllegalStateException("Nhân viên đã có tài khoản hoặc tên đăng nhập đã được sử dụng.");checkLoginContact((String)n.get("SoDienThoai"),r.maNV());checkLoginContact((String)n.get("Email"),r.maNV());String id=FinanceRepository.code("TK");repo.createAccount(id,r,encoder.encode(r.matKhau()));audit(actor,"Thêm",id,"Tạo tài khoản nhân viên "+r.maNV());return repo.account(id);}
 private void checkLoginContact(String value,String employee){if(value!=null&&!value.isBlank()&&repo.identifierUsed(value,employee))throw new IllegalStateException("Số điện thoại hoặc email trùng định danh đăng nhập của tài khoản khác.");}
 @Transactional(isolation=Isolation.SERIALIZABLE) public Map<String,Object> updateAccount(String id,AccountUpdateRequest r,String actor){var admins=repo.lockAdmins();var t=repo.account(id);
  if((t.get("MaNV")==null&&!"VT01".equals(r.maVaiTro()))||(t.get("MaNV")!=null&&"VT01".equals(r.maVaiTro())))throw new IllegalArgumentException("Không chuyển loại chủ sở hữu khách hàng/nhân viên.");
  if((!r.hoatDong()||!"VT04".equals(r.maVaiTro()))&&"VT04".equals(t.get("MaVaiTro"))&&(actor.equals(id)||admins.size()<=1))throw new IllegalStateException("Không khóa/hạ quyền chính mình hoặc quản trị viên cuối cùng.");
  if(r.hoatDong()&&t.get("MaNV")!=null&&!Boolean.TRUE.equals(repo.employee((String)t.get("MaNV"),true).get("TrangThai")))throw new IllegalStateException("Nhân viên đã ngừng hoạt động.");
  repo.updateAccount(id,r);audit(actor,"Sửa",id,"Cập nhật trạng thái/role tài khoản: "+r.maVaiTro());return repo.account(id);
 }
 @Transactional(isolation=Isolation.SERIALIZABLE) public void reset(String id,PasswordResetRequest r,String actor){PasswordPolicy.validate(r.matKhau());repo.lockAdmins();repo.account(id);repo.password(id,encoder.encode(r.matKhau()));audit(actor,"Sửa",id,"Reset mật khẩu bởi quản trị viên; phiên cũ hết hiệu lực");}
 private void audit(String actor,String action,String id,String text){security.audit(actor,action,"Quản trị",id,text);}
 @Transactional(readOnly=true) public Map<String,Object> logs(LocalDate from,LocalDate to,String actor,String action,String module,String target,int page,int size){ReportService.range(from,to);pagination(page,size);for(String s:List.of(actor,action,module,target))if(s.length()>100)throw new IllegalArgumentException("Bộ lọc quá dài.");return repo.logs(from,to,actor,action,module,target,page,size);}
}
