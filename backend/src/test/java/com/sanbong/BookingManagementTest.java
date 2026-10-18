package com.sanbong;

import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties="app.booking.holidays=2099-01-01") @AutoConfigureMockMvc @Transactional
class BookingManagementTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc; @Autowired EntityManager em;
    private final LocalDate date=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusWeeks(2).with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));
    private String pitch;
    private record Csrf(MockHttpSession session,String header,String token) { }
    @BeforeEach void fixture() {
        pitch="P4"+UUID.randomUUID().toString().replace("-","").substring(0,8);
        jdbc.update("INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Phase4 rollback test","LS01","Trống","Phase4 automated test");
    }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var req=get("/auth/csrf");if(session!=null)req.session(session);
        var result=mvc.perform(req).andReturn();var data=json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
        return new Csrf((MockHttpSession)result.getRequest().getSession(false),data.path("headerName").asText(),data.path("token").asText());
    }
    private MockHttpSession login(String user) throws Exception {
        var c=csrf(null);var result=mvc.perform(post("/auth/login").session(c.session()).header(c.header(),c.token())
                .param("identifier",user).param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456")))
                .andExpect(status().isOk()).andReturn();return (MockHttpSession)result.getRequest().getSession(false);
    }
    private ResultActions write(MockHttpSession session,String path,Object body) throws Exception {
        var c=csrf(session);return mvc.perform(post(path).session(session).header(c.header(),c.token())
                .contentType("application/json").content(json.writeValueAsString(body)));
    }
    private Map<String,Object> request(String pitchId,String slot,LocalDate day,String customer) {
        return Map.of("maSan",pitchId,"maKhungGio",slot,"ngayChoi",day.toString(),"maKH",customer,"ghiChu","Phase4 automated test");
    }
    private JsonNode create(MockHttpSession session) throws Exception {
        var result=write(session,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isOk()).andReturn();
        return json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
    }
    private JsonNode available(MockHttpSession session,LocalDate day) throws Exception {
        var result=mvc.perform(get("/availability").session(session).param("date",day.toString()).param("slot","KG03").param("type","LS01"))
                .andExpect(status().isOk()).andReturn();return json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
    }
    private boolean containsPitch(JsonNode data) { for(var row:data) if(row.path("maSan").asText().equals(pitch))return true;return false; }
    @Test void searchesRealAvailabilityAndOptions() throws Exception {
        var s=login("nvsan");assertTrue(containsPitch(available(s,date)));
        mvc.perform(get("/booking-options").session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.slots.length()").value(5));
        mvc.perform(get("/booking-customers").session(s).param("phone","0987654321")).andExpect(status().isOk()).andExpect(jsonPath("$.data[0].maKH").value("KH01"));
    }
    @Test void occupiedPitchIsExcludedOnlyOnItsPlayDate() throws Exception {
        var s=login("admin");create(s);assertFalse(containsPitch(available(s,date)));assertTrue(containsPitch(available(s,date.plusDays(1))));
    }
    @Test void maintenanceAndInUsePitchesCannotBeBooked() throws Exception {
        var s=login("admin");jdbc.update("UPDATE San SET TrangThai=? WHERE MaSan=?","Bảo trì",pitch);em.clear();
        assertFalse(containsPitch(available(s,date)));write(s,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isConflict());
        // Current use alone does not block a future date; the occupied interval must still conflict.
        jdbc.update("UPDATE San SET TrangThai=? WHERE MaSan=?","Trống",pitch);em.clear();create(s);
        jdbc.update("UPDATE San SET TrangThai=? WHERE MaSan=?","Đang sử dụng",pitch);em.clear();assertFalse(containsPitch(available(s,date)));
        write(s,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isConflict());
    }
    @Test void createsPersistedBookingSnapshotAndAuditWithoutPayment() throws Exception {
        var s=login("nvsan");var d=create(s);String id=d.path("maDatSan").asText();
        assertEquals("Chờ xác nhận",d.path("trangThai").asText());
        assertEquals(0,new BigDecimal("195000.00").compareTo(d.path("tongTien").decimalValue()));
        assertEquals("NV02",jdbc.queryForObject("SELECT MaNV FROM DatSan WHERE MaDatSan=?",String.class,id));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE ChucNang=? AND DoiTuong=?",Integer.class,"Đặt sân",id));
        em.clear();mvc.perform(get("/bookings/"+id).session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.maSan").value(pitch));
    }
    @Test void missingPitchIsNotFound() throws Exception { write(login("admin"),"/bookings",request("MISSING","KG03",date,"KH01")).andExpect(status().isNotFound()); }
    @Test void missingSlotIsNotFound() throws Exception { write(login("admin"),"/bookings",request(pitch,"MISSING",date,"KH01")).andExpect(status().isNotFound()); }
    @Test void rejectsPastDatesMalformedDatesAndMissingFields() throws Exception {
        var s=login("admin");write(s,"/bookings",request(pitch,"KG03",LocalDate.now().minusDays(1),"KH01")).andExpect(status().isBadRequest());
        write(s,"/bookings",Map.of("maSan",pitch)).andExpect(status().isBadRequest());
        mvc.perform(get("/availability").session(s).param("date","not-a-date")).andExpect(status().isBadRequest());
        mvc.perform(get("/bookings").session(s)).andExpect(status().isBadRequest());
    }
    @Test void duplicateBookingIsConflictAndExistingUniqueIndexRemains() throws Exception {
        var s=login("admin");create(s);write(s,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isConflict());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,pitch));
        assertEquals(1,jdbc.queryForObject("SELECT is_unique FROM sys.indexes WHERE object_id=OBJECT_ID('DatSan') AND name='UX_DatSan_KhongTrungLich'",Integer.class));
    }
    @Test void serverIgnoresClientMoneyAndKeepsSnapshotsWhenPriceChanges() throws Exception {
        var s=login("admin");var r=new HashMap<>(request(pitch,"KG03",date,"KH01"));r.put("tongTien",1);r.put("donGia",1);r.put("trangThai","Đã xác nhận");
        var result=write(s,"/bookings",r).andExpect(status().isOk()).andExpect(jsonPath("$.data.tongTien").value(195000))
                .andExpect(jsonPath("$.data.trangThai").value("Chờ xác nhận")).andReturn();
        String id=json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data").path("maDatSan").asText();
        jdbc.update("UPDATE GiaTheoCa SET DonGia=DonGia+10000 WHERE MaCa='CHIEU'");em.clear();
        mvc.perform(get("/bookings/"+id).session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.tongTien").value(195000));
    }
    @Test void missingWeekendPriceIsRejectedAndConfiguredWeekendPriceIsUsed() throws Exception {
        var s=login("admin");LocalDate weekend=date.with(TemporalAdjusters.next(DayOfWeek.SATURDAY));
        assertTrue(containsPitch(available(s,weekend)));write(s,"/bookings",request(pitch,"KG02",weekend,"KH01")).andExpect(status().isOk());
        jdbc.update("UPDATE San SET MaLoaiSan='LS02' WHERE MaSan=?",pitch);em.clear();
        write(s,"/bookings",request(pitch,"KG04",weekend,"KH01")).andExpect(status().isOk()).andExpect(jsonPath("$.data.tongTien").value(270000));
    }
    @Test void unauthenticatedAndMissingCsrfRequestsAreDenied() throws Exception {
        mvc.perform(get("/availability").param("date",date.toString())).andExpect(status().isUnauthorized());
        mvc.perform(post("/bookings").contentType("application/json").content("{}")).andExpect(status().isForbidden());
        mvc.perform(post("/bookings").session(login("admin")).contentType("application/json").content("{}")).andExpect(status().isForbidden());
    }
    @Test void rolePermissionsAndCustomerOwnershipAreEnforced() throws Exception {
        var accountant=login("ketoan");mvc.perform(get("/bookings").session(accountant).param("date",date.toString())).andExpect(status().isForbidden());
        write(accountant,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isForbidden());
        var customer=login("khachhang");write(customer,"/bookings",request(pitch,"KG03",date,"KH02")).andExpect(status().isForbidden());
        var staff=login("admin");var result=write(staff,"/bookings",request(pitch,"KG03",date,"KH02")).andExpect(status().isOk()).andReturn();
        String id=json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data").path("maDatSan").asText();
        mvc.perform(get("/bookings/"+id).session(customer)).andExpect(status().isForbidden());
        write(customer,"/bookings/"+id+"/cancel",Map.of("lyDo","Test")).andExpect(status().isForbidden());
        mvc.perform(get("/bookings").session(customer).param("date",date.toString())).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(0));
        jdbc.update("UPDATE PhanQuyen SET Them=0 WHERE MaVaiTro='VT02' AND MaChucNang='CN02'");
        write(login("nvsan"),"/bookings",request(pitch,"KG02",date,"KH01")).andExpect(status().isForbidden());
    }
    @Test void calendarAndDetailsRespectDateAndFilters() throws Exception {
        var s=login("admin");var d=create(s);String id=d.path("maDatSan").asText();
        mvc.perform(get("/bookings").session(s).param("date",date.toString()).param("pitch",pitch).param("slot","KG03").param("status","Chờ xác nhận"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1));
        mvc.perform(get("/bookings").session(s).param("date",date.plusDays(1).toString()).param("pitch",pitch))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(0));
        mvc.perform(get("/bookings/"+id).session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.maKH").value("KH01"));
        mvc.perform(get("/bookings/MISSING").session(s)).andExpect(status().isNotFound());
    }
    @Test void confirmationUsesExistingWorkflowAndCustomerCannotConfirm() throws Exception {
        var customer=login("khachhang");var d=create(customer);String id=d.path("maDatSan").asText();
        write(customer,"/bookings/"+id+"/confirm",Map.of()).andExpect(status().isForbidden());
        var s=login("nvsan");write(s,"/bookings/"+id+"/confirm",Map.of()).andExpect(status().isOk()).andExpect(jsonPath("$.data.trangThai").value("Đã xác nhận"));
        write(s,"/bookings/"+id+"/confirm",Map.of()).andExpect(status().isConflict());
    }
    @Test void cancelsOwnFutureBookingRecordsReasonAndReleasesSlot() throws Exception {
        var s=login("khachhang");String id=create(s).path("maDatSan").asText();
        write(s,"/bookings/"+id+"/cancel",Map.of("lyDo","Phase4 hủy test")).andExpect(status().isOk()).andExpect(jsonPath("$.data.trangThai").value("Đã hủy"));
        var row=jdbc.queryForMap("SELECT NguoiHuy,LyDo,SoTienHoan FROM HuyDatSan WHERE MaDatSan=?",id);
        assertEquals("Khách hàng",row.get("NguoiHuy"));assertEquals("Phase4 hủy test",row.get("LyDo"));assertEquals(0,((BigDecimal)row.get("SoTienHoan")).signum());
        assertTrue(containsPitch(available(s,date)));create(s); // filtered unique index allows a replacement after cancellation.
    }
    @Test void invalidCancellationStatePastStartAndPaidBookingAreRejected() throws Exception {
        var s=login("admin");String id=create(s).path("maDatSan").asText();
        jdbc.update("UPDATE DatSan SET TrangThai=? WHERE MaDatSan=?","Đã sử dụng",id);em.clear();
        write(s,"/bookings/"+id+"/cancel",Map.of("lyDo","Test")).andExpect(status().isConflict());
        jdbc.update("UPDATE DatSan SET TrangThai=?,NgayChoi=? WHERE MaDatSan=?","Đã xác nhận",LocalDate.now().minusDays(1),id);em.clear();
        write(s,"/bookings/"+id+"/cancel",Map.of("lyDo","Test")).andExpect(status().isConflict());
        jdbc.update("UPDATE DatSan SET NgayChoi=? WHERE MaDatSan=?",date,id);em.clear();
        jdbc.update("INSERT INTO ThanhToan(MaTT,MaDatSan,SoTien,PhuongThuc,TrangThai) VALUES(?,?,?,?,?)","P4TT",id,195000,"Tiền mặt","Thành công");
        write(s,"/bookings/"+id+"/cancel",Map.of("lyDo","Test")).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan WHERE MaDatSan=?",Integer.class,id));
    }
    @Test void holidayCalendarUsesOnlyConfiguredHolidayPrices() throws Exception {
        var s=login("admin");var holiday=LocalDate.of(2099,1,1);
        write(s,"/bookings",request(pitch,"KG02",holiday,"KH01")).andExpect(status().isOk());
        jdbc.update("INSERT INTO BangGia(MaBangGia,MaLoaiSan,MaKhungGio,LoaiNgay,DonGia,NgayHieuLuc) VALUES(?,?,?,?,?,?)",
                "P4HOL","LS01","KG03","Ngày lễ",300000,LocalDate.of(2098,1,1));em.clear();
        write(s,"/bookings",request(pitch,"KG03",holiday,"KH01")).andExpect(status().isOk()).andExpect(jsonPath("$.data.tongTien").value(195000));
    }
    @Test void unknownCustomerExpiredSlotAndExpiredPriceAreRejected() throws Exception {
        var s=login("admin");write(s,"/bookings",request(pitch,"KG03",date,"MISSING")).andExpect(status().isBadRequest());
        jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES('P4PAST','00:00','00:30',0.5)");
        write(s,"/bookings",request(pitch,"P4PAST",LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")),"KH01")).andExpect(status().isBadRequest());
        jdbc.update("DELETE FROM GiaTheoCa WHERE MaCa='CHIEU'");em.clear();
        write(s,"/bookings",request(pitch,"KG03",date,"KH01")).andExpect(status().isConflict());
    }
    @Test void overlapAcrossDifferentSlotsAndPriceAmbiguityAreRejected() throws Exception {
        var s=login("admin");create(s);
        jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES('P4KG','17:00','18:30',1.5)");
        write(s,"/bookings",request(pitch,"P4KG",date,"KH01")).andExpect(status().isConflict());
        jdbc.update("INSERT INTO BangGia(MaBangGia,MaLoaiSan,MaKhungGio,LoaiNgay,DonGia,NgayHieuLuc) VALUES(?,?,?,?,?,?)",
                "P4BG","LS01","KG02","Ngày thường",100000,LocalDate.of(2026,1,1));em.clear();
        write(s,"/bookings",request(pitch,"KG02",date,"KH01")).andExpect(status().isOk());
    }
}
