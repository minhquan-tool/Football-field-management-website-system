package com.sanbong.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name="BangGia")
@Data
public class BangGia {
    @Id @Column(name="MaBangGia",length=10)
    private String maBangGia;
    @ManyToOne @JoinColumn(name="MaLoaiSan",nullable=false)
    private LoaiSan loaiSan;
    @ManyToOne @JoinColumn(name="MaKhungGio",nullable=false)
    private KhungGio khungGio;
    @Nationalized @Column(name="LoaiNgay",length=20,nullable=false)
    private String loaiNgay;
    @Column(name="DonGia",precision=18,scale=2,nullable=false)
    private BigDecimal donGia;
    @Column(name="NgayHieuLuc",nullable=false)
    private LocalDate ngayHieuLuc;
    @Column(name="NgayHetHieuLuc")
    private LocalDate ngayHetHieuLuc;
}
