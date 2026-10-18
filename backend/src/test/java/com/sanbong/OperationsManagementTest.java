package com.sanbong;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class OperationsManagementTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc; @Autowired EntityManager em;
    private String pitch,slot,booking;
    private record Csrf(MockHttpSession session,String header,String token) { }
    @BeforeEach void fixture() {
        String key=UUID.randomUUID().toString().replace("-","").substring(0,8);pitch="P5"+key;slot="P5"+key;booking="P5"+key;
        jdbc.update("INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Phase5 rollback test","LS01","Trống","Phase5 operations automated test");
        jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES(?,'00:00','23:59:59',23.99)",slot);
        jdbc.update("INSERT INTO DatSan(GioBatDau,GioKetThuc,MaDatSan,MaKH,MaSan,MaKhungGio,NgayChoi,ThoiLuongLegacySnapshot,DonGia,TienSanLegacySnapshot,TrangThai,GhiChu) "
                + "VALUES('00:00','23:59:59',?,?,?,?,?,23.99,150000,150000,?,?)",booking,"KH01",pitch,slot,LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")),"Đã xác nhận","Phase5 operations automated test");
    }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var req=get("/auth/csrf");if(session!=null)req.session(session);var result=mvc.perform(req).andReturn();
        var data=json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
        return new Csrf((MockHttpSession)result.getRequest().getSession(false),data.path("headerName").asText(),data.path("token").asText());
    }
    private MockHttpSession login(String username) throws Exception {
        var c=csrf(null);var result=mvc.perform(post("/auth/login").session(c.session()).header(c.header(),c.token()).param("identifier",username)
                .param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn();
        return (MockHttpSession)result.getRequest().getSession(false);
    }
    private ResultActions write(MockHttpSession session,org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder req,Object body) throws Exception {
        var c=csrf(session);return mvc.perform(req.session(session).header(c.header(),c.token()).contentType("application/json").content(json.writeValueAsString(body)));
    }
    private String path() { return "/operations/bookings/"+booking; }
    private MockHttpSession checkedIn() throws Exception { var s=login("nvsan");write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isOk());return s; }
    @Test void checkInCreatesVisitAndOccupancyWithAudit() throws Exception {
        checkedIn();assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,booking));
        assertEquals("Đang sử dụng",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,pitch));
        assertEquals("Đã xác nhận",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,booking));
        assertEquals("NV02",jdbc.queryForObject("SELECT MaNV FROM XacNhanSan WHERE MaDatSan=?",String.class,booking));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE ChucNang=? AND DoiTuong=?",Integer.class,"Nhận sân / Dịch vụ",booking));
    }
    @Test void missingBookingIs404() throws Exception {write(login("admin"),post("/operations/bookings/MISSING/check-in"),Map.of()).andExpect(status().isNotFound());}
    @Test void cancelledBookingCannotCheckIn() throws Exception {
        jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã hủy",booking);em.clear();
        write(login("admin"),post(path()+"/check-in"),Map.of()).andExpect(status().isConflict());
    }
    @Test void duplicateCheckInIs409AndDoesNotDuplicateVisit() throws Exception {
        var s=checkedIn();write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isConflict());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,booking));
    }
    @Test void rolesRevokedPermissionsAndCsrfAreEnforced() throws Exception {
        for(String user:List.of("khachhang","ketoan")) {
            var s=login(user);write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isForbidden());
            mvc.perform(get("/services").session(s)).andExpect(status().isForbidden());
        }
        mvc.perform(get("/services")).andExpect(status().isUnauthorized());
        var s=login("nvsan");mvc.perform(post(path()+"/check-in").session(s).contentType("application/json").content("{}"))
                .andExpect(status().isForbidden());
        jdbc.update("UPDATE PhanQuyen SET Sua=0 WHERE MaVaiTro='VT02' AND MaChucNang='CN02'");
        write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isForbidden());
    }
    @Test void loadsRealActiveServicePrices() throws Exception {
        mvc.perform(get("/services").session(login("nvsan"))).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(13))
                .andExpect(jsonPath("$.data[0].maDV").value("DV01")).andExpect(jsonPath("$.data[0].donGia").value(10000));
    }
    @Test void addsServicesAndTriggerRecomputesRatherThanAddsTwice() throws Exception {
        var s=checkedIn();write(s,post(path()+"/services/DV01"),Map.of("soLuong",2)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.booking.tienDichVu").value(20000)).andExpect(jsonPath("$.data.booking.tongTien").value(170000));
        write(s,post(path()+"/services/DV03"),Map.of("soLuong",1)).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(50000))
                .andExpect(jsonPath("$.data.booking.tongTien").value(200000));
        assertEquals(0,new BigDecimal("50000").compareTo(jdbc.queryForObject("SELECT TienDichVu FROM DatSan WHERE MaDatSan=?",BigDecimal.class,booking)));
    }
    @Test void nonpositiveOrOutOfRangeQuantityIs400() throws Exception {
        var s=checkedIn();for(Object q:List.of(0,-1,2147483648L)) write(s,post(path()+"/services/DV01"),Map.of("soLuong",q)).andExpect(status().isBadRequest());
        write(s,post(path()+"/services/DV01"),Map.of()).andExpect(status().isBadRequest());
    }
    @Test void missingServiceIs404() throws Exception {write(checkedIn(),post(path()+"/services/MISSING"),Map.of("soLuong",1)).andExpect(status().isNotFound());}
    @Test void inactiveServiceCannotBeAdded() throws Exception {
        var s=checkedIn();jdbc.update("UPDATE DichVu SET TrangThai=0 WHERE MaDV='DV01'");
        write(s,post(path()+"/services/DV01"),Map.of("soLuong",1)).andExpect(status().isConflict());
        mvc.perform(get("/services").session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(12));
    }
    @Test void quantityEditPreservesSnapshotAfterCatalogPriceChanges() throws Exception {
        var s=checkedIn();write(s,post(path()+"/services/DV01"),Map.of("soLuong",2,"donGia",1,"tongTien",1)).andExpect(status().isOk());
        jdbc.update("UPDATE DichVu SET DonGia=50000 WHERE MaDV='DV01'");
        write(s,put(path()+"/services/DV01"),Map.of("soLuong",3)).andExpect(status().isOk()).andExpect(jsonPath("$.data.services[0].donGia").value(10000))
                .andExpect(jsonPath("$.data.services[0].thanhTien").value(30000)).andExpect(jsonPath("$.data.booking.tongTien").value(180000));
    }
    @Test void duplicateLineIsConflictAndCompositeKeyRemains() throws Exception {
        var s=checkedIn();write(s,post(path()+"/services/DV01"),Map.of("soLuong",1)).andExpect(status().isOk());
        write(s,post(path()+"/services/DV01"),Map.of("soLuong",1)).andExpect(status().isConflict());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaDatSan=?",Integer.class,booking));
    }
    @Test void removeRequiresDeletePermissionAndRecomputesTotalWithoutTouchingOldBooking() throws Exception {
        var old=jdbc.queryForMap("SELECT DonGia,TienDichVu,TongTien FROM DatSan WHERE MaDatSan='DS01'");
        var s=checkedIn();write(s,post(path()+"/services/DV01"),Map.of("soLuong",1)).andExpect(status().isOk());
        write(s,delete(path()+"/services/DV01"),Map.of()).andExpect(status().isForbidden());
        write(login("admin"),delete(path()+"/services/DV01"),Map.of()).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.tienDichVu").value(0))
                .andExpect(jsonPath("$.data.booking.tongTien").value(150000));assertEquals(old,jdbc.queryForMap("SELECT DonGia,TienDichVu,TongTien FROM DatSan WHERE MaDatSan='DS01'"));
    }
    @Test void checkoutReleasesPitchAndFreezesServicesButDoesNotPretendPayment() throws Exception {
        var s=checkedIn();write(s,post(path()+"/check-out"),Map.of()).andExpect(status().isOk()).andExpect(jsonPath("$.data.booking.trangThai").value("Đã sử dụng"));
        assertEquals("Trống",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,pitch));
        assertNotNull(jdbc.queryForObject("SELECT ThoiGianKetThuc FROM XacNhanSan WHERE MaDatSan=?",java.sql.Timestamp.class,booking));
        write(s,post(path()+"/check-out"),Map.of()).andExpect(status().isConflict());
        write(s,post(path()+"/services/DV01"),Map.of("soLuong",1)).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,booking));
    }
    @Test void activeVisitCannotBeBypassedByPitchUpdateOrPhase4Cancellation() throws Exception {
        var s=checkedIn();var c=csrf(s);
        mvc.perform(patch("/pitches/"+pitch+"/status").session(s).header(c.header(),c.token()).contentType("application/json").content("{\"trangThai\":\"Trống\"}"))
                .andExpect(status().isConflict());
        jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",LocalDate.now().plusDays(2),booking);em.clear();
        write(s,post("/bookings/"+booking+"/cancel"),Map.of("lyDo","Test")).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan WHERE MaDatSan=?",Integer.class,booking));
    }
    @Test void futureDatePendingStateAndExpiredSlotAreRejected() throws Exception {
        var s=login("nvsan");jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",LocalDate.now().plusDays(1),booking);em.clear();
        write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isConflict());
        jdbc.update("UPDATE DatSan SET NgayChoi=?,TrangThai=? WHERE MaDatSan=?",LocalDate.now(),"Chờ xác nhận",booking);em.clear();
        write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isConflict());
        jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã xác nhận",booking);
        jdbc.update("UPDATE DatSan SET GioKetThuc='00:00:01' WHERE MaDatSan=?",booking);em.clear();
        write(s,post(path()+"/check-in"),Map.of()).andExpect(status().isConflict());
    }
    @Test void serviceMutationsRejectAlreadyPaidBookingAndMoneyOverflow() throws Exception {
        var s=checkedIn();jdbc.update("UPDATE DichVu SET DonGia=9999999999999999.99 WHERE MaDV='DV01'");
        write(s,post(path()+"/services/DV01"),Map.of("soLuong",2)).andExpect(status().isBadRequest());
        jdbc.update("INSERT INTO ThanhToan(MaTT,MaDatSan,SoTien,PhuongThuc,TrangThai) VALUES(?,?,?,?,?)","P5TT",booking,150000,"Tiền mặt","Thành công");
        write(s,post(path()+"/services/DV03"),Map.of("soLuong",1)).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaDatSan=?",Integer.class,booking));
    }
}
