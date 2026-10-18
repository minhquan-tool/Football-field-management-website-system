package com.sanbong.config;

import com.sanbong.model.TaiKhoan;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;
import java.util.Collection;
import java.util.Map;

public class AccountPrincipal extends User {
    private final String accountId;
    private final String roleId;
    private final String displayName;

    public AccountPrincipal(TaiKhoan account, Collection<? extends GrantedAuthority> authorities) {
        super(account.getTenDangNhap(),account.getMatKhau(),"Hoạt động".equals(account.getTrangThai()) && (account.getNhanVien()==null || Boolean.TRUE.equals(account.getNhanVien().getTrangThai())),
                true,true,true,authorities);
        accountId=account.getMaTK();
        roleId=account.getVaiTro().getMaVaiTro();
        displayName=account.getKhachHang()!=null ? account.getKhachHang().getHoTen()
                : account.getNhanVien()!=null ? account.getNhanVien().getHoTen() : account.getTenDangNhap();
    }
    public String accountId() { return accountId; }
    public String roleId() { return roleId; }
    public Map<String,Object> profile() {
        return Map.of("maTK",accountId,"tenDangNhap",getUsername(),"hoTen",displayName,"maVaiTro",roleId,
                "permissions",getAuthorities().stream().map(GrantedAuthority::getAuthority).toList());
    }
}
