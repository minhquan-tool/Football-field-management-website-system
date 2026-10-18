package com.sanbong.dto;
import java.math.BigDecimal;
import java.time.*;
public record AvailableSlot(String maSan,String tenSan,String maLoaiSan,String tenLoaiSan,
        String trangThai,LocalDate ngayChoi,String maKhungGio,LocalTime gioBatDau,LocalTime gioKetThuc,
        BigDecimal thoiLuong,String maBangGia,String loaiNgay,BigDecimal donGia,BigDecimal tongTien) { }
