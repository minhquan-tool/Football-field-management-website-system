package com.sanbong.service;

import com.sanbong.dto.PermissionRequest;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.util.*;

@Service
public class PermissionService {
    private final SecurityRepository security;
    private final VaiTroRepository roles;
    public PermissionService(SecurityRepository security,VaiTroRepository roles) {
        this.security=security; this.roles=roles;
    }
    @Transactional(readOnly=true)
    public List<Map<String,Object>> accounts() { return security.accounts(); }
    @Transactional(readOnly=true)
    public Map<String,Object> matrix(String role) {
        if(!roles.existsById(role)) throw new IllegalArgumentException("Vai trò không tồn tại.");
        return Map.of("roles",roles.findAll().stream().map(r -> Map.of("maVaiTro",r.getMaVaiTro(),
                "tenVaiTro",r.getTenVaiTro())).toList(),"permissions",security.permissions(role));
    }
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public void save(String role,List<PermissionRequest> permissions,String actor) {
        if(!roles.existsById(role)) throw new IllegalArgumentException("Vai trò không tồn tại.");
        var codes=new HashSet<String>();
        permissions.forEach(p -> codes.add(p.maChucNang()));
        if(permissions.size()!=8 || codes.size()!=8)
            throw new IllegalArgumentException("Cần cung cấp đủ 8 chức năng, không trùng mã.");
        if("VT04".equals(role) && permissions.stream().anyMatch(p ->
                "CN07".equals(p.maChucNang()) && !p.xem()
                || "CN08".equals(p.maChucNang()) && (!p.xem() || !p.sua())))
            throw new IllegalArgumentException("Phải giữ quyền quản trị tài khoản và phân quyền cho quản trị viên.");
        permissions.forEach(p -> security.savePermission(role,p));
        security.audit(actor,"Sửa","Cập nhật phân quyền vai trò "+role);
    }
}
