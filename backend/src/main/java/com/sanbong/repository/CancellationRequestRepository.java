package com.sanbong.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Repository
public class CancellationRequestRepository {
 private final JdbcTemplate jdbc;
 public CancellationRequestRepository(JdbcTemplate jdbc){this.jdbc=jdbc;}
 public boolean ready(){return jdbc.queryForObject("SELECT CASE WHEN OBJECT_ID('dbo.YeuCauHuyDatSan','U') IS NULL THEN 0 ELSE 1 END",Integer.class)==1;}
 private static final String SELECT="SELECT r.MaYeuCau maYeuCau,r.MaDatSan maDatSan,r.MaTKGui maTKGui,r.NgayGui ngayGui,r.LyDo lyDo,r.TrangThai trangThai,r.TiLeHoanUocTinh tiLeHoan,r.ThucThuTaiGui thucThuTaiGui,r.TienHoanUocTinh tienHoanUocTinh,r.GhiChuXuLy ghiChuXuLy,r.NgayXuLy ngayXuLy,r.MaHuy maHuy,k.HoTen hoTen,k.SoDienThoai soDienThoai,s.TenSan tenSan,d.NgayChoi ngayChoi,d.GioBatDau gioBatDau,d.GioKetThuc gioKetThuc FROM dbo.YeuCauHuyDatSan r JOIN dbo.DatSan d ON d.MaDatSan=r.MaDatSan JOIN dbo.KhachHang k ON k.MaKH=d.MaKH JOIN dbo.San s ON s.MaSan=d.MaSan ";
 public Optional<Map<String,Object>> find(String id){return jdbc.queryForList(SELECT+"WHERE r.MaYeuCau=?",id).stream().findFirst();}
 public List<Map<String,Object>> list(String account,String state,int page){return jdbc.queryForList(SELECT+"WHERE (?='' OR r.MaTKGui=?) AND (?='' OR r.TrangThai=?) ORDER BY r.NgayGui DESC,r.MaYeuCau DESC OFFSET ? ROWS FETCH NEXT 20 ROWS ONLY",account,account,state,state,(page-1)*20);}
 public int count(String account,String state){return jdbc.queryForObject("SELECT COUNT(*) FROM dbo.YeuCauHuyDatSan WHERE (?='' OR MaTKGui=?) AND (?='' OR TrangThai=?)",Integer.class,account,account,state,state);}
 public Optional<Map<String,Object>> pending(String booking){if(!ready())return Optional.empty();return jdbc.queryForList(SELECT+"WHERE r.MaDatSan=? AND r.TrangThai='PENDING'",booking).stream().findFirst();}
 public void requireNoPending(String booking){if(pending(booking).isPresent())throw new IllegalStateException("Lượt đặt đang chờ duyệt yêu cầu hủy. Kế toán/chủ sân cần xử lý yêu cầu trước.");}
 public String create(String booking,String account,String reason,BigDecimal rate,BigDecimal net,BigDecimal estimate,LocalDateTime now){String id="YC"+UUID.randomUUID().toString().replace("-","").substring(0,8);jdbc.update("INSERT dbo.YeuCauHuyDatSan(MaYeuCau,MaDatSan,MaTKGui,NgayGui,LyDo,TiLeHoanUocTinh,ThucThuTaiGui,TienHoanUocTinh) VALUES(?,?,?,?,?,?,?,?)",id,booking,account,now,reason,rate,net,estimate);return id;}
 public void resolve(String id,String state,String actor,String note,String cancellation,LocalDateTime now){if(jdbc.update("UPDATE dbo.YeuCauHuyDatSan SET TrangThai=?,MaTKXuLy=?,NgayXuLy=?,GhiChuXuLy=?,MaHuy=? WHERE MaYeuCau=? AND TrangThai='PENDING'",state,actor,now,note,cancellation,id)!=1)throw new IllegalStateException("Yêu cầu đã được xử lý. Vui lòng tải lại.");}
}
