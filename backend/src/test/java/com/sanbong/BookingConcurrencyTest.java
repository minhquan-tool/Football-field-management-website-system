package com.sanbong;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sanbong.repository.SecurityRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Independent committed transactions: an outer rollback transaction would hide the race. */
@AuditCleanupFixture
@SpringBootTest @AutoConfigureMockMvc
class BookingConcurrencyTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager manager; @SpyBean SecurityRepository security;
    private String pitch;
    private final LocalDate date=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusWeeks(2).with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));
    private record Csrf(MockHttpSession session,String header,String token) { }
    @BeforeEach void fixture() {
        pitch="P4"+UUID.randomUUID().toString().replace("-","").substring(0,8);
        jdbc.update("INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",pitch,"Phase4 concurrent test","LS01","Trống","Phase4 automated concurrent test");
    }
    @AfterEach void cleanup() {
        reset(security);
        new TransactionTemplate(manager).executeWithoutResult(tx -> {
            assertEquals("Phase4 automated concurrent test",jdbc.queryForObject("SELECT MoTa FROM San WHERE MaSan=?",String.class,pitch));
            var ids=jdbc.queryForList("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch);
            for(var id:ids) {
                assertEquals("Phase4 automated concurrent test",jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));
                jdbc.update("DELETE FROM NhatKyHeThong WHERE ChucNang=? AND DoiTuong=?","Đặt sân",id);
                jdbc.update("DELETE FROM HuyDatSan WHERE MaDatSan=?",id);
                jdbc.update("DELETE FROM HoaDon WHERE MaDatSan=?",id);
                jdbc.update("DELETE FROM NhatKyHeThong WHERE ChucNang=? AND DoiTuong=?","Tài chính",id);
                jdbc.update("DELETE FROM DatSan WHERE MaDatSan=?",id);
            }
            jdbc.update("DELETE FROM San WHERE MaSan=? AND MoTa=?",pitch,"Phase4 automated concurrent test");
        });
    }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var req=get("/api/auth/csrf");if(session!=null)req.session(session);
        var result=mvc.perform(req).andExpect(status().isOk()).andReturn();var data=json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
        return new Csrf((MockHttpSession)result.getRequest().getSession(false),data.path("headerName").asText(),data.path("token").asText());
    }
    private Csrf session() throws Exception {
        var c=csrf(null);var result=mvc.perform(post("/api/auth/login").session(c.session()).header(c.header(),c.token())
                .param("identifier","admin").param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456")))
                .andExpect(status().isOk()).andReturn();return csrf((MockHttpSession)result.getRequest().getSession(false));
    }
    private String request() throws Exception {
        return json.writeValueAsString(Map.of("maSan",pitch,"maKhungGio","KG03","ngayChoi",date.toString(),"maKH","KH01","ghiChu","Phase4 automated concurrent test"));
    }
    private int create(Csrf c,String body) throws Exception {
        return mvc.perform(post("/api/bookings").session(c.session()).header(c.header(),c.token()).contentType("application/json").content(body)).andReturn().getResponse().getStatus();
    }
    @Test void concurrentRequestsProduceExactlyOneValidBooking() throws Exception {
        var a=session();var b=session();String body=request();var ready=new CountDownLatch(2);var start=new CountDownLatch(1);
        var pool=Executors.newFixedThreadPool(2);
        try {
            var first=pool.submit(() -> {ready.countDown();assertTrue(start.await(10,TimeUnit.SECONDS));return create(a,body);});
            var second=pool.submit(() -> {ready.countDown();assertTrue(start.await(10,TimeUnit.SECONDS));return create(b,body);});
            assertTrue(ready.await(10,TimeUnit.SECONDS));start.countDown();
            var statuses=new ArrayList<>(List.of(first.get(30,TimeUnit.SECONDS),second.get(30,TimeUnit.SECONDS)));Collections.sort(statuses);
            assertEquals(List.of(200,409),statuses);
            assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=? AND NgayChoi=? AND MaKhungGio=? AND TrangThai<>?",Integer.class,pitch,date,"KG03","Đã hủy"));
        } finally { start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS)); }
    }
    @Test void auditFailureRollsBackAlreadyFlushedBooking() throws Exception {
        var c=session();
        doThrow(new RuntimeException("Phase4 injected audit failure"))
                .when(security).audit(anyString(),eq("Thêm"),eq("Đặt sân"),anyString(),anyString());
        assertEquals(500,create(c,request()));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,pitch));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan h JOIN DatSan d ON d.MaDatSan=h.MaDatSan WHERE d.MaSan=?",Integer.class,pitch));
    }
    @Test void concurrentDifferentFreeIntervalsCannotOverlap() throws Exception {
        var a=session();var b=session();var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        String one=json.writeValueAsString(Map.of("maSan",pitch,"gioBatDau","08:00","gioKetThuc","10:00","ngayChoi",date.toString(),"maKH","KH01","ghiChu","Phase4 automated concurrent test"));
        String two=json.writeValueAsString(Map.of("maSan",pitch,"gioBatDau","09:00","gioKetThuc","11:00","ngayChoi",date.toString(),"maKH","KH01","ghiChu","Phase4 automated concurrent test"));
        try {
            var f=pool.submit(() -> {start.await();return create(a,one);});
            var g=pool.submit(() -> {start.await();return create(b,two);});start.countDown();
            var statuses=new ArrayList<>(List.of(f.get(30,TimeUnit.SECONDS),g.get(30,TimeUnit.SECONDS)));Collections.sort(statuses);
            assertEquals(List.of(200,409),statuses);
            assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=? AND MaKhungGio IS NULL",Integer.class,pitch));
        } finally {start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
    }
    @Test void cancellationAuditFailureRollsBackCancellationRecordAndState() throws Exception {
        var c=session();assertEquals(200,create(c,request()));
        String id=jdbc.queryForObject("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch);
        doThrow(new RuntimeException("Phase4 injected cancellation audit failure"))
                .when(security).audit(anyString(),eq("Sửa"),eq("Đặt sân"),eq(id),anyString());
        mvc.perform(post("/api/bookings/"+id+"/cancel").session(c.session()).header(c.header(),c.token())
                .contentType("application/json").content("{\"lyDo\":\"Phase4 rollback cancellation test\"}"))
                .andExpect(status().isInternalServerError()).andExpect(jsonPath("$.success").value(false));
        assertEquals("Chờ xác nhận",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,id));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan WHERE MaDatSan=?",Integer.class,id));
    }
    @Test void concurrentConfirmationAndCancellationNeverReviveCancelledBooking() throws Exception {
        var a=session();var b=session();assertEquals(200,create(a,request()));
        String id=jdbc.queryForObject("SELECT MaDatSan FROM DatSan WHERE MaSan=?",String.class,pitch);
        var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try {
            var confirm=pool.submit(() -> {start.await();return mvc.perform(post("/api/bookings/"+id+"/confirm").session(a.session()).header(a.header(),a.token())).andReturn().getResponse().getStatus();});
            var cancel=pool.submit(() -> {start.await();return mvc.perform(post("/api/bookings/"+id+"/cancel").session(b.session()).header(b.header(),b.token()).contentType("application/json").content("{\"lyDo\":\"Phase4 race test\"}")).andReturn().getResponse().getStatus();});
            start.countDown();assertTrue(List.of(200,409).contains(confirm.get(30,TimeUnit.SECONDS)));assertEquals(200,cancel.get(30,TimeUnit.SECONDS));
            assertEquals("Đã hủy",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,id));
            assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HuyDatSan WHERE MaDatSan=?",Integer.class,id));
        } finally {start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
    }
}
