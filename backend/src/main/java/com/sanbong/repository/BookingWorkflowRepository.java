package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.UUID;
/** Existing cancellation/payment tables; no financial processing in Phase 4. */
@Repository
public class BookingWorkflowRepository {
    private final JdbcTemplate jdbc;
    public BookingWorkflowRepository(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    public boolean hasCheckIn(String id) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,id)>0;
    }
    public boolean hasFinancialHistory(String id) {
        return jdbc.queryForObject("SELECT (SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?)+(SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?)",Integer.class,id,id)>0;
    }
    public boolean hasPaymentInProgressOrSuccessful(String id) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WITH (UPDLOCK,HOLDLOCK) "
                + "WHERE MaDatSan=? AND TrangThai IN (?,?)",Integer.class,id,"Chờ xử lý","Thành công")>0;
    }
    public void cancel(String id,String reason,boolean customer) {
        jdbc.update("INSERT INTO HuyDatSan(MaHuy,MaDatSan,NgayHuy,LyDo,NguoiHuy,TiLeHoan,SoTienHoan) "
                + "VALUES(?,?,?,?,?,0,0)","HY"+UUID.randomUUID().toString().replace("-","").substring(0,8),
                id,LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")),reason,
                customer?"Khách hàng":"Nhân viên");
    }
}
