package com.sanbong.dto;
import com.sanbong.model.DatSan;
import java.math.BigDecimal;
import java.time.*;
public record BookingView(String maDatSan,String maKH,String hoTen,String maSan,String tenSan,
        String tenLoaiSan,LocalDate ngayChoi,String maKhungGio,LocalTime gioBatDau,LocalTime gioKetThuc,
        BigDecimal thoiLuong,BigDecimal donGia,BigDecimal tienSan,BigDecimal tienDichVu,
        BigDecimal tienGiam,BigDecimal tongTien,String trangThai,String ghiChu,LocalDateTime ngayDat) {
    public static BookingView from(DatSan d) {
        return new BookingView(d.getMaDatSan(),d.getKhachHang().getMaKH(),d.getKhachHang().getHoTen(),
                d.getSan().getMaSan(),d.getSan().getTenSan(),d.getSan().getLoaiSan().getTenLoaiSan(),
                d.getNgayChoi(),d.getKhungGio()==null?null:d.getKhungGio().getMaKhungGio(),d.getGioBatDau(),
                d.getGioKetThuc(),d.getThoiLuong(),d.getDonGia(),d.getTienSan(),
                d.getTienDichVu(),d.getTienGiam(),d.getTongTien(),d.getTrangThai(),d.getGhiChu(),d.getNgayDat());
    }
}
