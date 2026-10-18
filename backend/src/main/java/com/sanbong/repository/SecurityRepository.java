package com.sanbong.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import com.sanbong.dto.PermissionRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Repository
public class SecurityRepository {
    private final JdbcTemplate jdbc;
    public SecurityRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public List<Map<String, Object>> permissions(String role) {
        return jdbc.queryForList("SELECT c.MaChucNang,c.TenChucNang, "
                + "ISNULL(p.Xem,0) Xem,ISNULL(p.Them,0) Them,ISNULL(p.Sua,0) Sua,ISNULL(p.Xoa,0) Xoa "
                + "FROM ChucNang c LEFT JOIN PhanQuyen p ON p.MaChucNang=c.MaChucNang "
                + "AND p.MaVaiTro=? ORDER BY c.MaChucNang", role);
    }

    public List<Map<String, Object>> accounts() {
        return jdbc.queryForList("SELECT t.MaTK,t.MaNV,t.MaKH,t.TenDangNhap,t.MaVaiTro,v.TenVaiTro,t.TrangThai,t.NgayTao, "
                + "COALESCE(k.HoTen,n.HoTen) HoTen FROM TaiKhoan t JOIN VaiTro v ON v.MaVaiTro=t.MaVaiTro "
                + "LEFT JOIN KhachHang k ON k.MaKH=t.MaKH LEFT JOIN NhanVien n ON n.MaNV=t.MaNV ORDER BY t.MaTK");
    }

    public void savePermission(String role, PermissionRequest p) {
        if (jdbc.update("UPDATE PhanQuyen SET Xem=?,Them=?,Sua=?,Xoa=? WHERE MaVaiTro=? AND MaChucNang=?",
                p.xem(),p.them(),p.sua(),p.xoa(),role,p.maChucNang()) == 0) {
            jdbc.update("INSERT INTO PhanQuyen(MaVaiTro,MaChucNang,Xem,Them,Sua,Xoa) VALUES(?,?,?,?,?,?)",
                    role,p.maChucNang(),p.xem(),p.them(),p.sua(),p.xoa());
        }
    }

    public void audit(String account, String action, String detail) {
        audit(account,action,"Authentication / Phân quyền",account,detail);
    }

    public void audit(String account,String action,String function,String target,String detail) {
        jdbc.update("INSERT INTO NhatKyHeThong(MaNhatKy,MaTK,ThaoTac,ChucNang,DoiTuong,NoiDungThayDoi) "
                        + "VALUES(?,?,?,?,?,?)", UUID.randomUUID().toString().replace("-", "").substring(0,15),
                account,action,function,target,detail);
    }
}
