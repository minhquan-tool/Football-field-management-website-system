package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "KhachHang")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class KhachHang {
    @Id
    @Column(name = "MaKH", length = 10)
    private String maKH;

    @Nationalized
    @Column(name = "HoTen", nullable = false, length = 100)
    private String hoTen;

    @Column(name = "SoDienThoai", nullable = false, length = 15, unique = true)
    private String soDienThoai;

    @Column(name = "Email", length = 100)
    private String email;

    @Nationalized
    @Column(name = "DiaChi", length = 255)
    private String diaChi;

    @Column(name = "NgayDangKy", nullable = false)
    private LocalDate ngayDangKy;

    @Nationalized
    @Column(name = "GhiChu", length = 255)
    private String ghiChu;
}

