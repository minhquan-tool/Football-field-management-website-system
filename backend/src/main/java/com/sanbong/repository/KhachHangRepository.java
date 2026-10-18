package com.sanbong.repository;
import com.sanbong.model.KhachHang;
import org.springframework.data.jpa.repository.JpaRepository;
public interface KhachHangRepository extends JpaRepository<KhachHang, String> {
    java.util.Optional<KhachHang> findBySoDienThoai(String phone);
    boolean existsBySoDienThoai(String soDienThoai);
    boolean existsByEmailIgnoreCase(String email);
    boolean existsByMaKHNotAndSoDienThoai(String maKH,String soDienThoai);
    boolean existsByMaKHNotAndEmailIgnoreCase(String maKH,String email);
}
