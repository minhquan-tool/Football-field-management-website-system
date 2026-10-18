package com.sanbong.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalTime;
import java.math.BigDecimal;

@Entity
@Table(name = "KhungGio")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class KhungGio {
    @Id
    @Column(name = "MaKhungGio", length = 10)
    private String maKhungGio;

    @Column(name = "GioBatDau", nullable = false)
    private LocalTime gioBatDau;

    @Column(name = "GioKetThuc", nullable = false)
    private LocalTime gioKetThuc;

    @Column(name = "ThoiLuong", nullable = false, precision = 4, scale = 2)
    private BigDecimal thoiLuong;
}

