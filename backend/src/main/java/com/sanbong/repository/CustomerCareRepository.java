package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;
@Repository
public class CustomerCareRepository {
    private final JdbcTemplate jdbc;
    public CustomerCareRepository(JdbcTemplate jdbc){this.jdbc=jdbc;}
    public List<Map<String,Object>> criteria(){return jdbc.queryForList("SELECT MaTieuChi AS maTieuChi,TenTieuChi AS tenTieuChi FROM TieuChiDanhGia ORDER BY MaTieuChi");}
    public List<Map<String,Object>> reviews(String customer){return jdbc.queryForList("SELECT MaDatSan AS maDatSan,DiemTrungBinh AS diemTrungBinh,NoiDung AS noiDung FROM DanhGia WHERE MaKH=?",customer);}
    public List<Map<String,Object>> reviews(String customer,List<String> bookingIds){
        if(bookingIds.isEmpty())return List.of();
        var parameters=new ArrayList<Object>();parameters.add(customer);parameters.addAll(bookingIds);
        String placeholders=String.join(",",Collections.nCopies(bookingIds.size(),"?"));
        return jdbc.queryForList("SELECT MaDatSan AS maDatSan,DiemTrungBinh AS diemTrungBinh,NoiDung AS noiDung FROM DanhGia WHERE MaKH=? AND MaDatSan IN ("+placeholders+")",parameters.toArray());
    }
    public List<Map<String,Object>> promotions(){return jdbc.queryForList("SELECT MaKM AS maKM,TenKM AS tenKM,LoaiGiam AS loaiGiam,MucGiam AS mucGiam,DieuKien AS dieuKien,NgayBatDau AS tuNgay,NgayKetThuc AS denNgay FROM KhuyenMai WHERE TrangThai=1 AND MucGiam>0 AND (LoaiGiam=N'Số tiền' OR (LoaiGiam=N'Phần trăm' AND MucGiam<=100)) AND NgayBatDau<=CONVERT(date,GETDATE()) AND NgayKetThuc>=CONVERT(date,GETDATE()) ORDER BY MaKM");}
    public void review(String id,String booking,String customer,String pitch,String content,Map<String,Integer> scores){
        jdbc.update("INSERT INTO DanhGia(MaDanhGia,MaDatSan,MaKH,MaSan,NoiDung) VALUES(?,?,?,?,?)",id,booking,customer,pitch,content);
        scores.forEach((criterion,score)->jdbc.update("INSERT INTO ChiTietDanhGia(MaDanhGia,MaTieuChi,Diem) VALUES(?,?,?)",id,criterion,score));
        jdbc.update("UPDATE DanhGia SET DiemTrungBinh=(SELECT AVG(CAST(Diem AS decimal(5,2))) FROM ChiTietDanhGia WHERE MaDanhGia=?) WHERE MaDanhGia=?",id,id);
    }
    public boolean hasReview(String booking){return jdbc.queryForObject("SELECT COUNT(*) FROM DanhGia WITH(UPDLOCK,HOLDLOCK) WHERE MaDatSan=?",Integer.class,booking)>0;}
    public List<Map<String,Object>> feedback(String customer){
        return jdbc.queryForList("SELECT p.MaPhanHoi AS maPhanHoi,p.MaDatSan AS maDatSan,k.HoTen AS hoTen,p.LoaiPhanHoi AS loaiPhanHoi,p.NoiDung AS noiDung,p.TrangThaiXuLy AS trangThai,p.KetQuaXuLy AS ketQua,p.NgayGui AS ngayGui FROM PhanHoi p JOIN KhachHang k ON p.MaKH=k.MaKH "+(customer==null?"":"WHERE p.MaKH=? ")+"ORDER BY p.NgayGui DESC,p.MaPhanHoi",customer==null?new Object[]{}:new Object[]{customer});
    }
    public void feedback(String id,String customer,String booking,String type,String content){jdbc.update("INSERT INTO PhanHoi(MaPhanHoi,MaKH,MaDatSan,LoaiPhanHoi,NoiDung) VALUES(?,?,?,?,?)",id,customer,booking,type,content);}
    public void resolve(String id,String state,String result,String employee){
        jdbc.update("UPDATE PhanHoi SET TrangThaiXuLy=?,KetQuaXuLy=?,MaNV=?,NgayXuLy=GETDATE() WHERE MaPhanHoi=?",state,result,employee,id);
    }
    public Optional<String> lockedFeedbackState(String id){return jdbc.queryForList("SELECT TrangThaiXuLy FROM PhanHoi WITH(UPDLOCK,HOLDLOCK) WHERE MaPhanHoi=?",String.class,id).stream().findFirst();}
}
