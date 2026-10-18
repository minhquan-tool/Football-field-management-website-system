package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;
import com.sanbong.dto.ConfigurationRequest;
import java.math.BigDecimal;
import java.time.*;
@Repository
public class ConfigurationRepository {
    private final JdbcTemplate jdbc;
    public ConfigurationRepository(JdbcTemplate jdbc){this.jdbc=jdbc;}
    public List<Map<String,Object>> types(){return jdbc.queryForList("SELECT MaLoaiSan AS id,TenLoaiSan AS ten,SoNguoi AS soNguoi,MoTa AS moTa FROM LoaiSan ORDER BY MaLoaiSan");}
    public List<Map<String,Object>> slots(){return jdbc.queryForList("SELECT MaKhungGio AS id,GioBatDau AS batDau,GioKetThuc AS ketThuc,ThoiLuong AS thoiLuong FROM KhungGio ORDER BY GioBatDau");}
    public List<Map<String,Object>> hourly(){return jdbc.queryForList("SELECT * FROM GiaTheoCa ORDER BY GioBatDau");}
    public List<Map<String,Object>> promotions(){return jdbc.queryForList("SELECT MaKM AS id,TenKM AS ten,LoaiGiam AS loaiGiam,MucGiam AS donGia,DieuKien AS moTa,NgayBatDau AS tuNgay,NgayKetThuc AS denNgay,TrangThai AS hoatDong FROM KhuyenMai ORDER BY NgayBatDau DESC");}
    public List<Map<String,Object>> prices(){return jdbc.queryForList("SELECT MaBangGia AS id,MaLoaiSan AS loaiSan,MaKhungGio AS khungGio,LoaiNgay AS loaiNgay,DonGia AS donGia,NgayHieuLuc AS tuNgay,NgayHetHieuLuc AS denNgay FROM BangGia ORDER BY NgayHieuLuc DESC");}
    public boolean hourlyExists(String id){return jdbc.queryForObject("SELECT COUNT(*) FROM GiaTheoCa WITH(UPDLOCK,HOLDLOCK) WHERE MaCa=?",Integer.class,id)==1;}
    public void hourlyPrice(String id,BigDecimal price){jdbc.update("UPDATE GiaTheoCa SET DonGia=? WHERE MaCa=?",price,id);}
    public void saveType(ConfigurationRequest r){
        if(jdbc.queryForObject("SELECT COUNT(*) FROM LoaiSan WITH(UPDLOCK,HOLDLOCK) WHERE MaLoaiSan=?",Integer.class,r.id())==0)jdbc.update("INSERT INTO LoaiSan(MaLoaiSan,TenLoaiSan,SoNguoi,MoTa) VALUES(?,?,?,?)",r.id(),r.ten().trim(),r.soNguoi(),r.moTa());
        else jdbc.update("UPDATE LoaiSan SET TenLoaiSan=?,SoNguoi=?,MoTa=? WHERE MaLoaiSan=?",r.ten().trim(),r.soNguoi(),r.moTa(),r.id());
    }
    public boolean slotUsed(String id){return jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaKhungGio=?",Integer.class,id)>0||jdbc.queryForObject("SELECT COUNT(*) FROM BangGia WHERE MaKhungGio=?",Integer.class,id)>0;}
    public boolean slotOverlaps(ConfigurationRequest r){return jdbc.queryForObject("SELECT COUNT(*) FROM KhungGio WITH(UPDLOCK,HOLDLOCK) WHERE MaKhungGio<>? AND GioBatDau<CAST(? AS time) AND GioKetThuc>CAST(? AS time)",Integer.class,r.id(),r.ketThuc().toString(),r.batDau().toString())>0;}
    public void saveSlot(ConfigurationRequest r,BigDecimal duration){
        if(jdbc.queryForObject("SELECT COUNT(*) FROM KhungGio WHERE MaKhungGio=?",Integer.class,r.id())==0)jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES(?,CAST(? AS time),CAST(? AS time),?)",r.id(),r.batDau().toString(),r.ketThuc().toString(),duration);
        else jdbc.update("UPDATE KhungGio SET GioBatDau=CAST(? AS time),GioKetThuc=CAST(? AS time),ThoiLuong=? WHERE MaKhungGio=?",r.batDau().toString(),r.ketThuc().toString(),duration,r.id());
    }
    public Optional<String> promotionType(String id){return jdbc.queryForList("SELECT LoaiGiam FROM KhuyenMai WITH(UPDLOCK,HOLDLOCK) WHERE MaKM=?",String.class,id).stream().findFirst();}
    public boolean promotionUsed(String id){return jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaKM=?",Integer.class,id)>0;}
    public void createPromotion(ConfigurationRequest r){jdbc.update("INSERT INTO KhuyenMai(MaKM,TenKM,LoaiGiam,MucGiam,DieuKien,NgayBatDau,NgayKetThuc,TrangThai) VALUES(?,?,N'Phần trăm',?,?,?,?,?)",r.id(),r.ten().trim(),r.donGia(),r.moTa(),r.tuNgay(),r.denNgay(),r.hoatDong());}
    public void updatePromotion(ConfigurationRequest r){jdbc.update("UPDATE KhuyenMai SET TenKM=?,MucGiam=?,DieuKien=?,NgayBatDau=?,NgayKetThuc=?,TrangThai=? WHERE MaKM=?",r.ten().trim(),r.donGia(),r.moTa(),r.tuNgay(),r.denNgay(),r.hoatDong(),r.id());}
    public boolean promotionActive(String id,boolean active){return jdbc.update("UPDATE KhuyenMai SET TrangThai=? WHERE MaKM=?",active,id)==1;}
    public boolean priceExists(String id){return jdbc.queryForObject("SELECT COUNT(*) FROM BangGia WITH(UPDLOCK,HOLDLOCK) WHERE MaBangGia=?",Integer.class,id)>0;}
    public boolean priceOverlaps(ConfigurationRequest r){return jdbc.queryForObject("SELECT COUNT(*) FROM BangGia WHERE MaLoaiSan=? AND MaKhungGio=? AND LoaiNgay=? AND NgayHieuLuc<=? AND (NgayHetHieuLuc IS NULL OR NgayHetHieuLuc>=?)",Integer.class,r.loaiSan(),r.khungGio(),r.loaiNgay(),r.denNgay()==null?LocalDate.of(9999,12,31):r.denNgay(),r.tuNgay())>0;}
    public void createPrice(ConfigurationRequest r){jdbc.update("INSERT INTO BangGia(MaBangGia,MaLoaiSan,MaKhungGio,LoaiNgay,DonGia,NgayHieuLuc,NgayHetHieuLuc) VALUES(?,?,?,?,?,?,?)",r.id(),r.loaiSan(),r.khungGio(),r.loaiNgay(),r.donGia(),r.tuNgay(),r.denNgay());}
}
