package com.sanbong.dto;
import com.sanbong.model.BangGia;
import java.math.BigDecimal;
import java.time.*;

public record PriceView(String maBangGia,String maLoaiSan,String maKhungGio,LocalTime gioBatDau,
                        LocalTime gioKetThuc,BigDecimal thoiLuong,String loaiNgay,BigDecimal donGia,
                        LocalDate ngayHieuLuc,LocalDate ngayHetHieuLuc) {
    public static PriceView from(BangGia p) {
        var slot=p.getKhungGio();
        return new PriceView(p.getMaBangGia(),p.getLoaiSan().getMaLoaiSan(),slot.getMaKhungGio(),
                slot.getGioBatDau(),slot.getGioKetThuc(),slot.getThoiLuong(),p.getLoaiNgay(),p.getDonGia(),
                p.getNgayHieuLuc(),p.getNgayHetHieuLuc());
    }
}
