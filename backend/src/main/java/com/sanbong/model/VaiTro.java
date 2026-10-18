package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "VaiTro")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class VaiTro {
    @Id
    @Column(name = "MaVaiTro", length = 10)
    private String maVaiTro;

    @Nationalized
    @Column(name = "TenVaiTro", nullable = false, length = 50)
    private String tenVaiTro;

    @Nationalized
    @Column(name = "MoTa", length = 255)
    private String moTa;
}

