package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "TaiKhoan")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaiKhoan {
    @Id
    @Column(name = "MaTK", length = 10)
    private String maTK;

    @Column(name = "TenDangNhap", nullable = false, length = 50, unique = true)
    private String tenDangNhap;

    @Column(name = "MatKhau", nullable = false, length = 255)
    @com.fasterxml.jackson.annotation.JsonIgnore
    @lombok.ToString.Exclude
    private String matKhau;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MaVaiTro", nullable = false)
    private VaiTro vaiTro;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MaKH")
    private KhachHang khachHang;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MaNV")
    private NhanVien nhanVien;

    @Column(name = "NgayTao", nullable = false, columnDefinition = "datetime")
    private java.time.LocalDateTime ngayTao;

    @Nationalized
    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai;
}

