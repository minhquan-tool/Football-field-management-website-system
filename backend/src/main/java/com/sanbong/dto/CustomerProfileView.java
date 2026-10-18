package com.sanbong.dto;
import com.sanbong.model.KhachHang;
public record CustomerProfileView(String maKH,String hoTen,String soDienThoai,String email,String diaChi) {
    public static CustomerProfileView from(KhachHang customer){return new CustomerProfileView(customer.getMaKH(),customer.getHoTen(),customer.getSoDienThoai(),customer.getEmail(),customer.getDiaChi());}
}
