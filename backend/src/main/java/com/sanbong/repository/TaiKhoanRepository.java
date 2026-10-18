package com.sanbong.repository;

import com.sanbong.model.TaiKhoan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface TaiKhoanRepository extends JpaRepository<TaiKhoan, String> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from TaiKhoan t where t.maTK=:id")
    java.util.Optional<TaiKhoan> lockById(@Param("id") String id);
    @Query("select distinct t from TaiKhoan t left join fetch t.khachHang k "
            + "left join fetch t.nhanVien n join fetch t.vaiTro "
            + "where lower(t.tenDangNhap) = lower(:identifier) or k.soDienThoai = :identifier "
            + "or lower(k.email) = lower(:identifier) or n.soDienThoai = :identifier "
            + "or lower(n.email) = lower(:identifier)")
    List<TaiKhoan> findByIdentifier(@Param("identifier") String identifier);
    boolean existsByTenDangNhapIgnoreCase(String tenDangNhap);
}
