package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.RegisterRequest;
import com.sanbong.dto.CustomerPasswordRequest;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import com.sanbong.security.PasswordPolicy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;

@Service
public class AuthService implements UserDetailsService {
    private static final Logger log=LoggerFactory.getLogger(AuthService.class);
    private final TaiKhoanRepository accounts;
    private final KhachHangRepository customers;
    private final VaiTroRepository roles;
    private final SecurityRepository security;
    private final PasswordEncoder encoder;

    public AuthService(TaiKhoanRepository accounts, KhachHangRepository customers,
                       VaiTroRepository roles, SecurityRepository security, PasswordEncoder encoder) {
        this.accounts=accounts; this.customers=customers; this.roles=roles;
        this.security=security; this.encoder=encoder;
    }

    @Override
    @Transactional(readOnly=true)
    public UserDetails loadUserByUsername(String identifier) {
        if(identifier==null || identifier.length()>100 || identifier.isBlank())
            throw new UsernameNotFoundException("Invalid credentials");
        var matches=accounts.findByIdentifier(identifier.trim());
        if(matches.size()!=1) throw new UsernameNotFoundException("Invalid credentials");
        return principal(matches.getFirst());
    }

    @Transactional(readOnly=true)
    public AccountPrincipal reload(String id) {
        return principal(accounts.findById(id).orElseThrow(() -> new UsernameNotFoundException("Account missing")));
    }

    private AccountPrincipal principal(TaiKhoan account) {
        String role=switch(account.getVaiTro().getMaVaiTro()) {
            case "VT01" -> "CUSTOMER"; case "VT02" -> "PITCH_STAFF";
            case "VT03" -> "ACCOUNTANT"; case "VT04" -> "ADMIN";
            default -> throw new UsernameNotFoundException("Unsupported role");
        };
        var authorities=new ArrayList<SimpleGrantedAuthority>();
        authorities.add(new SimpleGrantedAuthority("ROLE_"+role));
        for(var row:security.permissions(account.getVaiTro().getMaVaiTro())) {
            for(String action:List.of("Xem","Them","Sua","Xoa")) {
                Object value=row.get(action);
                if(Boolean.TRUE.equals(value) || value instanceof Number n && n.intValue()!=0)
                    authorities.add(new SimpleGrantedAuthority(row.get("MaChucNang")+"_"+action.toUpperCase(Locale.ROOT)));
            }
        }
        return new AccountPrincipal(account,authorities);
    }

    @Transactional(isolation=Isolation.SERIALIZABLE)
    public void register(RegisterRequest r) {
        PasswordPolicy.validate(r.matKhau());
        String username=r.tenDangNhap().trim(),phone=r.soDienThoai().trim();
        String email=r.email()==null || r.email().isBlank() ? null : r.email().trim().toLowerCase(Locale.ROOT);
        if(accounts.existsByTenDangNhapIgnoreCase(username) || customers.existsBySoDienThoai(phone)
                || email!=null && customers.existsByEmailIgnoreCase(email)
                || !accounts.findByIdentifier(username).isEmpty() || !accounts.findByIdentifier(phone).isEmpty()
                || email!=null && !accounts.findByIdentifier(email).isEmpty())
            throw new IllegalStateException("Tên đăng nhập, số điện thoại hoặc email đã được sử dụng.");
        var customer=new KhachHang();
        customer.setMaKH(id("KH")); customer.setHoTen(r.hoTen().trim()); customer.setSoDienThoai(phone);
        customer.setEmail(email); customer.setNgayDangKy(LocalDate.now());
        customers.saveAndFlush(customer);
        var account=new TaiKhoan();
        account.setMaTK(id("TK")); account.setTenDangNhap(username); account.setMatKhau(encoder.encode(r.matKhau()));
        account.setVaiTro(roles.findById("VT01").orElseThrow()); account.setKhachHang(customer);
        account.setNgayTao(LocalDateTime.now()); account.setTrangThai("Hoạt động");
        accounts.saveAndFlush(account);
        security.audit(account.getMaTK(),"Thêm","Đăng ký tài khoản khách hàng");
        log.info("Account registered accountId={}",account.getMaTK());
    }

    @Transactional
    public void audit(String id,String action,String detail) {
        security.audit(id,action,detail);
        log.info("Security action={} accountId={}",action,id);
    }

    /** Only the authenticated customer's password; serialize competing changes. */
    @Transactional
    public void changeCustomerPassword(AccountPrincipal actor, CustomerPasswordRequest r) {
        if (!"VT01".equals(actor.roleId()))
            throw new org.springframework.security.access.AccessDeniedException("Chỉ dành cho khách hàng.");
        var account=accounts.lockById(actor.accountId()).orElseThrow();
        if (!"VT01".equals(account.getVaiTro().getMaVaiTro()) || account.getKhachHang()==null)
            throw new org.springframework.security.access.AccessDeniedException("Chỉ dành cho khách hàng.");
        if (!encoder.matches(r.matKhauHienTai(),account.getMatKhau()))
            throw new IllegalArgumentException("Mật khẩu hiện tại không đúng.");
        if (!r.matKhauMoi().equals(r.xacNhanMatKhau()))
            throw new IllegalArgumentException("Xác nhận mật khẩu mới không khớp.");
        PasswordPolicy.validate(r.matKhauMoi());
        if (encoder.matches(r.matKhauMoi(),account.getMatKhau()))
            throw new IllegalArgumentException("Mật khẩu mới phải khác mật khẩu hiện tại.");
        account.setMatKhau(encoder.encode(r.matKhauMoi()));
        accounts.saveAndFlush(account);
        security.audit(actor.accountId(),"Sửa","Khách hàng tự đổi mật khẩu; phiên cũ hết hiệu lực");
    }

    /** Opt-in, idempotent conversion of a database known to contain legacy plaintext. */
    @Transactional
    public void migrateLegacyPasswords() {
        int changed=0;
        for(var account:accounts.findAll()) {
            String password=account.getMatKhau();
            if(PasswordPolicy.isBcryptHash(password)) continue;
            if(password.startsWith("$") || password.startsWith("{")
                    || password.getBytes(StandardCharsets.UTF_8).length>PasswordPolicy.MAX_BYTES)
                throw new IllegalStateException("Unsupported legacy password format; migration stopped");
            try { PasswordPolicy.validate(password); }
            catch (IllegalArgumentException e) {
                throw new IllegalStateException("Legacy password does not meet the shared policy; migration stopped without changing passwords.");
            }
            account.setMatKhau(encoder.encode(password)); changed++;
        }
        accounts.flush();
        log.info("Legacy password migration completed count={}",changed);
    }

    @Transactional(readOnly=true)
    public String credentialFingerprint(String id) { return fingerprint(accounts.findById(id).orElseThrow().getMatKhau()); }
    public static String fingerprint(String hash) {
        try { return HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(hash.getBytes(StandardCharsets.UTF_8))); }
        catch(java.security.NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
    private static String id(String prefix) {
        return prefix+UUID.randomUUID().toString().replace("-","").substring(0,8);
    }
}
