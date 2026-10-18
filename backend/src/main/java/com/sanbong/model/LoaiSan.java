package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "LoaiSan")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoaiSan {
    @Id
    @Column(name = "MaLoaiSan", length = 10)
    private String maLoaiSan;

    @Nationalized
    @Column(name = "TenLoaiSan", nullable = false, length = 50)
    private String tenLoaiSan;

    @Nationalized
    @Column(name = "MoTa", length = 255)
    private String moTa;

    @Column(name = "SoNguoi", nullable = false)
    private Integer soNguoi;
}

