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
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
@AuditCleanupFixture
class OperationsConcurrencyTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager manager; @SpyBean SecurityRepository security;
    private String id;
    private record Csrf(MockHttpSession session,String header,String token) { }
    @BeforeEach void fixture() {
        id="P5"+UUID.randomUUID().toString().replace("-","").substring(0,8);
        jdbc.update("INSERT INTO San(MaSan,TenSan,MaLoaiSan,TrangThai,MoTa) VALUES(?,?,?,?,?)",id,"Phase5 concurrency test","LS01","Trống","Phase5 operations concurrency test");
        jdbc.update("INSERT INTO KhungGio(MaKhungGio,GioBatDau,GioKetThuc,ThoiLuong) VALUES(?,'00:00','23:59:59',23.99)",id);
        jdbc.update("INSERT INTO DatSan(GioBatDau,GioKetThuc,MaDatSan,MaKH,MaSan,MaKhungGio,NgayChoi,ThoiLuongLegacySnapshot,DonGia,TienSanLegacySnapshot,TrangThai,GhiChu) VALUES('00:00','23:59:59',?,?,?,?,?,23.99,150000,150000,?,?)",
                id,"KH01",id,id,LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")),"Đã xác nhận","Phase5 operations concurrency test");
    }
    @AfterEach void cleanup() {
        reset(security);new TransactionTemplate(manager).executeWithoutResult(tx -> {
            assertEquals("Phase5 operations concurrency test",jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));
            jdbc.update("DELETE FROM ChiTietDichVu WHERE MaDatSan=?",id);jdbc.update("DELETE FROM XacNhanSan WHERE MaDatSan=?",id);
            jdbc.update("DELETE FROM NhatKyHeThong WHERE ChucNang=? AND DoiTuong=?","Nhận sân / Dịch vụ",id);
            jdbc.update("DELETE FROM DatSan WHERE MaDatSan=?",id);
            jdbc.update("DELETE FROM San WHERE MaSan=? AND MoTa=?",id,"Phase5 operations concurrency test");
            jdbc.update("DELETE FROM KhungGio WHERE MaKhungGio=?",id);
        });
    }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var req=get("/auth/csrf");if(session!=null)req.session(session);var r=mvc.perform(req).andReturn();
        var d=json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");
        return new Csrf((MockHttpSession)r.getRequest().getSession(false),d.path("headerName").asText(),d.path("token").asText());
    }
    private Csrf login() throws Exception {
        var c=csrf(null);var r=mvc.perform(post("/auth/login").session(c.session()).header(c.header(),c.token())
                .param("identifier","admin").param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456")))
                .andExpect(status().isOk()).andReturn();return csrf((MockHttpSession)r.getRequest().getSession(false));
    }
    private int write(Csrf c,String path,Object body) throws Exception {
        return mvc.perform(post("/operations/bookings/"+id+path).session(c.session()).header(c.header(),c.token())
                .contentType("application/json").content(json.writeValueAsString(body))).andReturn().getResponse().getStatus();
    }
    @Test void twoCheckInRequestsCreateExactlyOneVisit() throws Exception {
        var a=login();var b=login();var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try {
            var f=pool.submit(() -> {start.await();return write(a,"/check-in",Map.of());});
            var g=pool.submit(() -> {start.await();return write(b,"/check-in",Map.of());});start.countDown();
            var result=new ArrayList<>(List.of(f.get(30,TimeUnit.SECONDS),g.get(30,TimeUnit.SECONDS)));Collections.sort(result);assertEquals(List.of(200,409),result);
            assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,id));
        } finally { start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS)); }
    }
    @Test void failedCheckInAuditRollsBackVisitAndPitchStatus() throws Exception {
        var c=login();doThrow(new RuntimeException("Injected operations audit failure")).when(security)
                .audit(anyString(),eq("Thêm"),eq("Nhận sân / Dịch vụ"),eq(id),anyString());
        assertEquals(500,write(c,"/check-in",Map.of()));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM XacNhanSan WHERE MaDatSan=?",Integer.class,id));
        assertEquals("Trống",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,id));
    }
    @Test void serviceAuditFailureRollsBackLineAndTriggerMoney() throws Exception {
        var c=login();assertEquals(200,write(c,"/check-in",Map.of()));
        doThrow(new RuntimeException("Injected service audit failure")).when(security)
                .audit(anyString(),eq("Thêm"),eq("Nhận sân / Dịch vụ"),eq(id),anyString());
        assertEquals(500,write(c,"/services/DV01",Map.of("soLuong",2)));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaDatSan=?",Integer.class,id));
        assertEquals(0,jdbc.queryForObject("SELECT TienDichVu FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,id).signum());
        assertEquals(0,new java.math.BigDecimal("150000").compareTo(jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,id)));
    }
    @Test void concurrentSameServiceAddDoesNotDoubleCharge() throws Exception {
        var a=login();var b=login();assertEquals(200,write(a,"/check-in",Map.of()));var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try {
            var f=pool.submit(() -> {start.await();return write(a,"/services/DV01",Map.of("soLuong",2));});
            var g=pool.submit(() -> {start.await();return write(b,"/services/DV01",Map.of("soLuong",2));});start.countDown();
            var result=new ArrayList<>(List.of(f.get(30,TimeUnit.SECONDS),g.get(30,TimeUnit.SECONDS)));Collections.sort(result);assertEquals(List.of(200,409),result);
            assertEquals(0,new java.math.BigDecimal("170000").compareTo(jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,id)));
        } finally {start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
    }

    @Test void invalidPrebookServiceRollsBackBookingAndAllPreviousLines() throws Exception {
        var c=login();var day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(30);
        int before=jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,id);
        int response=mvc.perform(post("/bookings").session(c.session()).header(c.header(),c.token()).contentType("application/json")
            .content(json.writeValueAsString(Map.of("maSan",id,"maKH","KH01","ngayChoi",day.toString(),"gioBatDau","08:00","gioKetThuc","09:00",
                "dichVu",List.of(Map.of("maDV","SV03","quyCach","DON_VI","soLuong",1),Map.of("maDV","ZZMISSING","quyCach","DON_VI","soLuong",1))))))
            .andReturn().getResponse().getStatus();
        assertEquals(404,response);assertEquals(before,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,id));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu c JOIN DatSan d ON c.MaDatSan=d.MaDatSan WHERE d.MaSan=?",Integer.class,id));
    }
    @Test void twoDifferentPacksAddedConcurrentlyKeepBothAndExactTriggerTotal() throws Exception {
        var a=login();var b=login();assertEquals(200,write(a,"/check-in",Map.of()));var latch=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try {
            var f=pool.submit(() -> {latch.await();return write(a,"/services/SV03",Map.of("soLuong",1,"quyCach","DON_VI"));});
            var g=pool.submit(() -> {latch.await();return write(b,"/services/SV03",Map.of("soLuong",1,"quyCach","LOC_6"));});latch.countDown();
            assertEquals(200,f.get(30,TimeUnit.SECONDS));assertEquals(200,g.get(30,TimeUnit.SECONDS));
            assertEquals(2,jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaDatSan=?",Integer.class,id));
            assertEquals(0,new java.math.BigDecimal("68200").compareTo(jdbc.queryForObject("SELECT TienDichVu FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,id)));
        } finally {latch.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
    }
    @Test void concurrentQuantityEditsSerializeAndTriggerMatchesFinalLine() throws Exception {
        var a=login();var b=login();assertEquals(200,write(a,"/check-in",Map.of()));assertEquals(200,write(a,"/services/SV03",Map.of("soLuong",1)));
        long line=jdbc.queryForObject("SELECT MaChiTiet FROM ChiTietDichVu WHERE MaDatSan=?",Long.class,id);
        var latch=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try {
            var f=pool.submit(() -> {latch.await();return mvc.perform(put("/operations/bookings/"+id+"/service-lines/"+line).session(a.session()).header(a.header(),a.token()).contentType("application/json").content("{\"soLuong\":3}")).andReturn().getResponse().getStatus();});
            var g=pool.submit(() -> {latch.await();return mvc.perform(put("/operations/bookings/"+id+"/service-lines/"+line).session(b.session()).header(b.header(),b.token()).contentType("application/json").content("{\"soLuong\":5}")).andReturn().getResponse().getStatus();});latch.countDown();
            assertEquals(200,f.get(30,TimeUnit.SECONDS));assertEquals(200,g.get(30,TimeUnit.SECONDS));
            var amount=jdbc.queryForObject("SELECT ThanhTien FROM ChiTietDichVu WHERE MaChiTiet=?",java.math.BigDecimal.class,line);
            assertEquals(0,amount.compareTo(jdbc.queryForObject("SELECT TienDichVu FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,id)));
            assertTrue(List.of(3,5).contains(jdbc.queryForObject("SELECT SoLuong FROM ChiTietDichVu WHERE MaChiTiet=?",Integer.class,line)));
        } finally {latch.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(30,TimeUnit.SECONDS));}
    }
}
