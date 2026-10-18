package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "NhanVien")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NhanVien {
    @Id
    @Column(name = "MaNV", length = 10)
    private String maNV;

    @Nationalized
    @Column(name = "HoTen", nullable = false, length = 100)
    private String hoTen;

    @Column(name = "SoDienThoai", length = 15)
    private String soDienThoai;

    @Column(name = "Email", length = 100)
    private String email;

    @Nationalized
    @Column(name = "ChucVu", length = 50)
    private String chucVu;

    @Nationalized
    @Column(name = "BoPhan", length = 50)
    private String boPhan;

    @Column(name = "NgayVaoLam")
    private LocalDate ngayVaoLam;

    @Column(name = "TrangThai", nullable = false)
    private Boolean trangThai;
}

