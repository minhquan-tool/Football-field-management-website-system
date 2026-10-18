package com.sanbong.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

/** Existing operational tables and computed price column; never writes invoice/payment/refund data. */
@Repository
public class OperationsRepository {
    private final JdbcTemplate jdbc;
    public OperationsRepository(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    public List<Map<String,Object>> services() {
        return catalog(false);
    }
    public List<Map<String,Object>> catalog(boolean all) {
        return jdbc.queryForList("SELECT MaDV maDV,TenDV tenDV,DonViTinh donViTinh,DonGia donGia,TrangThai trangThai,HoTroLoc hoTroLoc FROM DichVu "
            +(all?"":"WHERE TrangThai=1 ")+"ORDER BY MaDV");
    }
    public Optional<Map<String,Object>> service(String id) {
        return jdbc.queryForList("SELECT MaDV maDV,TenDV tenDV,DonViTinh donViTinh,DonGia donGia,TrangThai trangThai,HoTroLoc hoTroLoc FROM DichVu WITH (UPDLOCK,HOLDLOCK) WHERE MaDV=?",id).stream().findFirst();
    }
    public void catalogUpdate(String id,BigDecimal price,boolean active,boolean pack) {
        jdbc.update("UPDATE DichVu SET DonGia=?,TrangThai=?,HoTroLoc=? WHERE MaDV=?",price,active,pack,id);
    }
    public void catalogCreate(String id,String name,String unit,BigDecimal price,boolean pack) {
        jdbc.update("INSERT INTO DichVu(MaDV,TenDV,DonViTinh,DonGia,TrangThai,HoTroLoc) VALUES(?,?,?,?,1,?)",id,name,unit,price,pack);
    }
    public Optional<Map<String,Object>> visit(String booking) {
        return jdbc.queryForList("SELECT MaXacNhan maXacNhan,MaNV maNV,ThoiGianNhan thoiGianNhan,"
                + "ThoiGianKetThuc thoiGianKetThuc,TinhTrangSan tinhTrangSan,GhiChu ghiChu FROM XacNhanSan WHERE MaDatSan=?",booking).stream().findFirst();
    }
    public boolean hasOpenPitch(String pitch) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan x JOIN DatSan d ON d.MaDatSan=x.MaDatSan "
                + "WHERE d.MaSan=? AND x.ThoiGianKetThuc IS NULL",Integer.class,pitch)>0;
    }
    public void checkIn(String booking,String employee,LocalDateTime now,String condition,String note) {
        jdbc.update("INSERT INTO XacNhanSan(MaXacNhan,MaDatSan,MaNV,ThoiGianNhan,TinhTrangSan,GhiChu) VALUES(?,?,?,?,?,?)",
                "XN"+UUID.randomUUID().toString().replace("-","").substring(0,8),booking,employee,now,condition,note);
    }
    public void checkOut(String booking,LocalDateTime now) {
        if(jdbc.update("UPDATE XacNhanSan SET ThoiGianKetThuc=? WHERE MaDatSan=? AND ThoiGianKetThuc IS NULL",now,booking)!=1)
            throw new IllegalStateException("Booking đã trả sân hoặc chưa nhận sân.");
    }
    public List<Map<String,Object>> lines(String booking) {
        return jdbc.queryForList("SELECT c.MaChiTiet maChiTiet,c.Nguon nguon,c.QuyCach quyCach,c.SoDonViMoiQuyCach soDonViMoiQuyCach,c.DonGiaDonViSnapshot donGiaDonViSnapshot,c.MaDV maDV,d.TenDV tenDV,d.DonViTinh donViTinh,c.SoLuong soLuong,"
                + "c.DonGia donGia,c.ThanhTien thanhTien,c.NgayGhiNhan ngayGhiNhan FROM ChiTietDichVu c "
                + "JOIN DichVu d ON d.MaDV=c.MaDV WHERE c.MaDatSan=? ORDER BY c.MaChiTiet",booking);
    }
    public Optional<Map<String,Object>> line(String booking,String service) {
        var matches=lines(booking).stream().filter(l -> service.equals(l.get("maDV"))).toList();
        if(matches.size()>1) throw new com.sanbong.service.AmbiguousServiceLineException();
        return matches.stream().findFirst();
    }
    public Optional<Map<String,Object>> lineById(String booking,long line) {
        return lines(booking).stream().filter(l -> ((Number)l.get("maChiTiet")).longValue()==line).findFirst();
    }
    public void add(String booking,String service,int quantity,String employee,String source,String pack,BigDecimal unit) {
        jdbc.update("INSERT INTO ChiTietDichVu(MaDatSan,MaDV,SoLuong,MaNV,Nguon,QuyCach,DonGiaDonViSnapshot) VALUES(?,?,?,?,?,?,?)",
            booking,service,quantity,employee,source,pack,unit);
    }
    public void quantity(String booking,long line,int quantity) {
        jdbc.update("UPDATE ChiTietDichVu SET SoLuong=? WHERE MaDatSan=? AND MaChiTiet=?",quantity,booking,line);
    }
    public void remove(String booking,long line) {
        jdbc.update("DELETE FROM ChiTietDichVu WHERE MaDatSan=? AND MaChiTiet=?",booking,line);
    }
    public boolean hasPayment(String booking) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=? AND TrangThai IN (?,?)",
                Integer.class,booking,"Chờ xử lý","Thành công")>0;
    }
}
