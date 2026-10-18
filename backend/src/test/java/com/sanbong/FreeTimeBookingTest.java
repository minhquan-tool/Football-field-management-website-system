package com.sanbong;
import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.web.servlet.*;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class FreeTimeBookingTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
    String pitch; MockHttpSession session;
    LocalDate day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(15);
    @BeforeEach void fixture() throws Exception {
        pitch="FA"+UUID.randomUUID().toString().replace("-","").substring(0,8);
        jdbc.update("INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Free time rollback","LS01","Trống","Phase5.1A test");
        var c=mvc.perform(get("/auth/csrf")).andReturn();session=(MockHttpSession)c.getRequest().getSession(false);
        var token=data(c).path("token").asText();var header=data(c).path("headerName").asText();
        var login=mvc.perform(post("/auth/login").session(session).header(header,token).param("identifier","admin")
            .param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk()).andReturn();
        session=(MockHttpSession)login.getRequest().getSession(false);
    }
    JsonNode data(MvcResult result) throws Exception { return json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data"); }
    ResultActions create(String start,String end) throws Exception {
        var c=data(mvc.perform(get("/auth/csrf").session(session)).andReturn());
        return mvc.perform(post("/bookings").session(session).header(c.path("headerName").asText(),c.path("token").asText())
            .contentType("application/json").content(json.writeValueAsString(Map.of("maSan",pitch,"ngayChoi",day.toString(),
                "gioBatDau",start,"gioKetThuc",end,"maKH","KH01","ghiChu","Phase5.1A test"))));
    }
    @ParameterizedTest @CsvSource({"08:00,12:30,405000","12:20,14:20,180000","13:00,15:00,260000","18:30,20:00,195000","19:00,20:00,180000"})
    void pricesEntireBookingByStart(String start,String end,int expected) throws Exception {
        var row=data(create(start,end).andExpect(status().isOk()).andExpect(jsonPath("$.data.tienSan").value(expected)).andReturn());
        String id=row.path("maDatSan").asText();
        assertNull(jdbc.queryForObject("SELECT MaKhungGio FROM DatSan WHERE MaDatSan=?",String.class,id));
        assertEquals("GIA_GIO",jdbc.queryForObject("SELECT CheDoGia FROM DatSan WHERE MaDatSan=?",String.class,id));
        mvc.perform(get("/bookings").session(session).param("date",day.toString()).param("pitch",pitch))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].maDatSan").value(id));
    }
    @ParameterizedTest @CsvSource({"07:30,08:30,409","09:30,10:30,409","08:30,09:30,409","07:30,10:30,409","07:00,08:00,200","10:00,11:30,200"})
    void intervalOverlapAndAdjacentEdges(String start,String end,int result) throws Exception {
        create("08:00","10:00").andExpect(status().isOk());
        create(start,end).andExpect(status().is(result));
    }
    @ParameterizedTest @CsvSource({"06:59,08:00","21:00,22:01","22:00,22:00","09:00,09:00","10:00,09:00","08:00:01,09:00"})
    void operatingBoundariesReject(String start,String end) throws Exception { create(start,end).andExpect(status().isBadRequest()); }
    @Test void minutesNotRoundedHoursAndSnapshotSurvivesPriceChange() throws Exception {
        var row=data(create("07:00","08:01").andExpect(status().isOk()).andExpect(jsonPath("$.data.tienSan").value(91500)).andReturn());
        jdbc.update("UPDATE GiaTheoCa SET DonGia=100000 WHERE MaCa='SANG'");
        mvc.perform(get("/bookings/"+row.path("maDatSan").asText()).session(session)).andExpect(status().isOk())
            .andExpect(jsonPath("$.data.tienSan").value(91500)).andExpect(jsonPath("$.data.donGia").value(90000));
    }
    @Test void legacySnapshotAndSlotEditsDoNotMoveExistingBooking() throws Exception {
        String slot=pitch;
        jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES(?,'08:00','10:00',2)",slot);
        jdbc.update("INSERT INTO DatSan(MaDatSan,MaKH,MaSan,MaKhungGio,NgayChoi,GioBatDau,GioKetThuc,ThoiLuongLegacySnapshot,DonGia,TienSanLegacySnapshot) VALUES(?,?,?,?,?,'08:00','10:00',2,150000,150000)",pitch,"KH01",pitch,slot,day);
        jdbc.update("UPDATE KhungGio SET GioBatDau='10:00',GioKetThuc='12:00' WHERE MaKhungGio=?",slot);
        create("09:00","11:00").andExpect(status().isConflict());
        create("10:00","11:00").andExpect(status().isOk());
        assertEquals(0,new java.math.BigDecimal("150000").compareTo(jdbc.queryForObject("SELECT TienSan FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,pitch)));
    }
    @Test void authenticLegacyBookingsKeepMoney() {
        for(var expected:List.of(Map.entry("DS01",230000),Map.entry("DS02",300000),Map.entry("DS3b97491a",200000))) {
            assertEquals(0,java.math.BigDecimal.valueOf(expected.getValue()).compareTo(jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,expected.getKey())));
            assertEquals("GIA_KHUNG",jdbc.queryForObject("SELECT CheDoGia FROM DatSan WHERE MaDatSan=?",String.class,expected.getKey()));
        }
    }
}
