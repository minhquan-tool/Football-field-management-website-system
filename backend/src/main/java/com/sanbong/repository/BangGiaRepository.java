package com.sanbong.repository;
import com.sanbong.model.BangGia;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface BangGiaRepository extends JpaRepository<BangGia,String> {
    List<BangGia> findByLoaiSanMaLoaiSanOrderByNgayHieuLucDescMaBangGiaAsc(String maLoaiSan);
}
