package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "San")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class San {
    @Id
    @Column(name = "MaSan", length = 10)
    private String maSan;

    @Nationalized
    @Column(name = "TenSan", nullable = false, length = 50)
    private String tenSan;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MaLoaiSan", nullable = false)
    private LoaiSan loaiSan;

    @Nationalized
    @Column(name = "MoTa", length = 255)
    private String moTa;

    @Nationalized
    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai;  // Trống, Đang sử dụng, Bảo trì
}

