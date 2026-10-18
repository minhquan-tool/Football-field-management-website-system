package com.sanbong.dto;
import com.sanbong.model.San;

public record PitchView(String maSan,String tenSan,String maLoaiSan,String tenLoaiSan,
                        Integer soNguoi,String trangThai,String moTa) {
    public static PitchView from(San san) {
        return new PitchView(san.getMaSan(),san.getTenSan(),san.getLoaiSan().getMaLoaiSan(),
                san.getLoaiSan().getTenLoaiSan(),san.getLoaiSan().getSoNguoi(),san.getTrangThai(),san.getMoTa());
    }
}
