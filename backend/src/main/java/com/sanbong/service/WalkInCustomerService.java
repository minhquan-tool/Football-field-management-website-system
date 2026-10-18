package com.sanbong.service;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.dto.WalkInCustomerRequest;
import com.sanbong.model.KhachHang;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.time.*;
import java.util.*;

@Service
public class WalkInCustomerService {
 private final KhachHangRepository customers;
 private final SecurityRepository security;
 public WalkInCustomerService(KhachHangRepository customers,SecurityRepository security){this.customers=customers;this.security=security;}
 @Transactional(isolation=Isolation.READ_COMMITTED)
 public Map<String,String> create(WalkInCustomerRequest request,AccountPrincipal actor){
  if(customers.existsBySoDienThoai(request.soDienThoai()))throw new IllegalStateException("Khách hàng với số điện thoại này đã tồn tại.");
  var customer=new KhachHang();customer.setMaKH("KH"+UUID.randomUUID().toString().replace("-","").substring(0,8));
  customer.setHoTen(request.hoTen());customer.setSoDienThoai(request.soDienThoai());customer.setNgayDangKy(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")));
  // Existing SQL unique phone constraint is the final arbiter for concurrent inserts, including self-registration.
  customers.saveAndFlush(customer);
  security.audit(actor.accountId(),"Thêm","Đặt sân",customer.getMaKH(),"Tạo hồ sơ khách tại quầy");
  return Map.of("maKH",customer.getMaKH(),"hoTen",customer.getHoTen(),"soDienThoai",customer.getSoDienThoai());
 }
}
