package com.sanbong.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.math.BigDecimal;

@Entity
@Table(name = "DatSan")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DatSan {
    @Id
    @Column(name = "MaDatSan", length = 10)
    private String maDatSan;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MaKH", nullable = false)
    private KhachHang khachHang;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MaSan", nullable = false)
    private San san;

    @Column(name = "NgayChoi", nullable = false)
    private LocalDate ngayChoi;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MaKhungGio")
    private KhungGio khungGio;

    @Column(name="GioBatDau",nullable=false,columnDefinition="time(0)")
    private LocalTime gioBatDau;
    @Column(name="GioKetThuc",nullable=false,columnDefinition="time(0)")
    private LocalTime gioKetThuc;
    @Column(name="CheDoGia",nullable=false,length=12)
    private String cheDoGia="GIA_KHUNG";
    @Column(name="HinhThucDat",nullable=false,length=12)
    private String hinhThucDat="KHONG_RO";

    public LocalTime getGioBatDau() { return gioBatDau!=null?gioBatDau:khungGio.getGioBatDau(); }
    public LocalTime getGioKetThuc() { return gioKetThuc!=null?gioKetThuc:khungGio.getGioKetThuc(); }
    @PrePersist
    void initializeLegacyTimes() {
        if(gioBatDau==null && khungGio!=null) gioBatDau=khungGio.getGioBatDau();
        if(gioKetThuc==null && khungGio!=null) gioKetThuc=khungGio.getGioKetThuc();
        if("GIA_KHUNG".equals(cheDoGia)) {
            if(thoiLuongLegacySnapshot==null) thoiLuongLegacySnapshot=thoiLuong;
            if(tienSanLegacySnapshot==null) tienSanLegacySnapshot=tienSan;
        }
    }

    @org.hibernate.annotations.Generated(event={org.hibernate.generator.EventType.INSERT,org.hibernate.generator.EventType.UPDATE})
    @Column(name = "ThoiLuong", insertable=false,updatable=false,precision = 4, scale = 2)
    private BigDecimal thoiLuong;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal donGia;

    @org.hibernate.annotations.Generated(event={org.hibernate.generator.EventType.INSERT,org.hibernate.generator.EventType.UPDATE})
    @Column(name = "TienSan", insertable=false,updatable=false,precision = 18, scale = 2)
    private BigDecimal tienSan;

    @Column(name = "TienDichVu", nullable = false, precision = 18, scale = 2)
    private BigDecimal tienDichVu;

    @Column(name = "MaKM", length = 10)
    private String maKM;

    @Column(name = "TienGiam", nullable = false, precision = 18, scale = 2)
    private BigDecimal tienGiam;

    @org.hibernate.annotations.Generated(event={org.hibernate.generator.EventType.INSERT,org.hibernate.generator.EventType.UPDATE})
    @Column(name = "TongTien", insertable=false,updatable=false,precision = 18, scale = 2)
    private BigDecimal tongTien;

    @Column(name="ThoiLuongLegacySnapshot",precision=4,scale=2)
    private BigDecimal thoiLuongLegacySnapshot;
    @Column(name="TienSanLegacySnapshot",precision=18,scale=2)
    private BigDecimal tienSanLegacySnapshot;

    @Nationalized
    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai;  // Chờ xác nhận, Đã xác nhận, Đã sử dụng, Đã hủy

    @Nationalized
    @Column(name = "GhiChu", length = 255)
    private String ghiChu;

    @Column(name = "NgayDat", nullable = false, columnDefinition = "datetime")
    private LocalDateTime ngayDat;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MaNV")
    private NhanVien nhanVien;
}

