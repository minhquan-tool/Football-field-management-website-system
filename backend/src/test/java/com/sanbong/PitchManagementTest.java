package com.sanbong;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class PitchManagementTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired EntityManager em;
    private record Csrf(MockHttpSession session,String header,String token) { }
    private Csrf csrf(MockHttpSession session) throws Exception {
        var req=get("/auth/csrf");if(session!=null)req.session(session);
        var result=mvc.perform(req).andExpect(status().isOk()).andReturn();
        var data=json.readTree(result.getResponse().getContentAsString()).path("data");
        return new Csrf((MockHttpSession)result.getRequest().getSession(false),data.path("headerName").asText(),data.path("token").asText());
    }
    private MockHttpSession login(String user) throws Exception {
        var csrf=csrf(null);
        var result=mvc.perform(post("/auth/login").session(csrf.session()).header(csrf.header(),csrf.token())
                .param("identifier",user).param("password","123456")).andExpect(status().isOk()).andReturn();
        return (MockHttpSession)result.getRequest().getSession(false);
    }
    private String body(String id,String name,String type,String status) throws Exception {
        return json.writeValueAsString(Map.of("maSan",id,"tenSan",name,"maLoaiSan",type,"trangThai",status,"moTa","Phase 3 test"));
    }
    private ResultActions write(MockHttpSession session,org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,String body) throws Exception {
        var csrf=csrf(session);
        return mvc.perform(request.session(session).header(csrf.header(),csrf.token()).contentType("application/json").content(body));
    }

    @Test
    void readsListDetailFiltersTypesAndRealPrices() throws Exception {
        var session=login("admin");
        mvc.perform(get("/pitches").session(session)).andExpect(status().isOk()).andExpect(jsonPath("$.data").isArray());
        mvc.perform(get("/pitches/S01").session(session)).andExpect(status().isOk()).andExpect(jsonPath("$.data.maSan").value("S01"));
        mvc.perform(get("/pitches").param("q","S01").param("type","LS01").param("status","Trống").session(session))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1));
        mvc.perform(get("/pitches").param("q","%").session(session)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(0));
        mvc.perform(get("/pitch-types").session(session)).andExpect(status().isOk()).andExpect(jsonPath("$.data[0].soNguoi").isNumber());
        var result=mvc.perform(get("/pitches/S01/prices").session(session)).andExpect(status().isOk()).andReturn();
        var prices=json.readTree(result.getResponse().getContentAsString()).path("data");assertTrue(prices.size()>0);
        for(var price:prices)assertTrue(price.path("donGia").decimalValue().signum()>0);
        mvc.perform(get("/pitches/DOESNOTEX").session(session)).andExpect(status().isNotFound());
    }

    @Test
    void createsUpdatesChangesStatusAndReadsPersistedSqlData() throws Exception {
        var session=login("admin");String id="STP3A";
        write(session,post("/pitches"),body(id,"Phase3 sân test","LS01","Trống")).andExpect(status().isOk());
        assertEquals("Phase3 sân test",jdbc.queryForObject("SELECT TenSan FROM San WHERE MaSan=?",String.class,id));
        write(session,put("/pitches/"+id),body(id,"Phase3 sân đã sửa","LS02","Trống")).andExpect(status().isOk());
        assertEquals("LS02",jdbc.queryForObject("SELECT MaLoaiSan FROM San WHERE MaSan=?",String.class,id));
        session=login("nvsan");
        write(session,post("/pitches"),body("DENIEDP3","Staff cannot create","LS01","Trống")).andExpect(status().isForbidden());
        write(session,put("/pitches/"+id),body(id,"Staff cannot rename","LS02","Trống")).andExpect(status().isForbidden());
        write(session,patch("/pitches/"+id+"/status"),"{\"trangThai\":\"Bảo trì\"}").andExpect(status().isOk());
        assertEquals("Bảo trì",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan=?",String.class,id));
        write(session,patch("/pitches/"+id+"/status"),"{\"trangThai\":\"Trống\"}").andExpect(status().isOk());
        write(session,patch("/pitches/"+id+"/status"),"{\"trangThai\":\"Đang sử dụng\"}").andExpect(status().isOk());
        em.clear();
        mvc.perform(get("/pitches/"+id).session(session)).andExpect(status().isOk()).andExpect(jsonPath("$.data.trangThai").value("Đang sử dụng"));
        assertEquals(5,jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE ChucNang=N'Quản lý sân' AND DoiTuong=?",Integer.class,id));
    }

    @Test
    void duplicateCodeAndBackendValidationRejectBadRequests() throws Exception {
        var session=login("admin");
        write(session,post("/pitches"),body("S01","Trùng mã","LS01","Trống")).andExpect(status().isConflict());
        write(session,post("/pitches"),body("STP3B"," ","LS01","Trống")).andExpect(status().isBadRequest());
        write(session,post("/pitches"),body("STP3B","Test","MISSING","Trống")).andExpect(status().isBadRequest());
        write(session,post("/pitches"),body("STP3B","Test","LS01","Ngừng hoạt động")).andExpect(status().isBadRequest());
        write(session,patch("/pitches/S01/status"),"{\"trangThai\":\"INVALID\"}").andExpect(status().isBadRequest());
        write(session,put("/pitches/S01"),body("S02","Test","LS01","Trống")).andExpect(status().isBadRequest());
        mvc.perform(get("/pitches").param("status","INVALID").session(session)).andExpect(status().isBadRequest());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM San WHERE MaSan='STP3B'",Integer.class));
    }

    @Test
    void maintenanceDetectsFutureBookingAndKeepsBookingPricesUnchanged() throws Exception {
        var session=login("admin");
        var before=jdbc.queryForMap("SELECT DonGia,TienSan,TongTien FROM DatSan WHERE MaDatSan='DS01'");
        jdbc.update("UPDATE DatSan SET NgayChoi=DATEADD(day,1,CAST(GETDATE() AS date)) WHERE MaDatSan='DS01'");em.clear();
        write(session,patch("/pitches/S01/status"),"{\"trangThai\":\"Bảo trì\"}").andExpect(status().isConflict());
        assertEquals("Trống",jdbc.queryForObject("SELECT TrangThai FROM San WHERE MaSan='S01'",String.class));
        write(session,put("/pitches/S01"),body("S01","Test type edit","LS02","Trống")).andExpect(status().isOk());
        assertEquals(before,jdbc.queryForMap("SELECT DonGia,TienSan,TongTien FROM DatSan WHERE MaDatSan='DS01'"));
    }

    @Test
    void deniesUnauthenticatedWrongRolesCsrfAndViewOnlyWrites() throws Exception {
        mvc.perform(get("/pitches")).andExpect(status().isUnauthorized());
        for(String role:new String[]{"khachhang","ketoan"}) {
            var session=login(role);
            mvc.perform(get("/pitches").session(session)).andExpect(status().isForbidden());
            write(session,post("/pitches"),body("STP3C","Test","LS01","Trống")).andExpect(status().isForbidden());
        }
        var staff=login("nvsan");
        mvc.perform(post("/pitches").session(staff).contentType("application/json").content(body("STP3C","Test","LS01","Trống")))
                .andExpect(status().isForbidden());
        jdbc.update("UPDATE PhanQuyen SET Them=0,Sua=0 WHERE MaVaiTro='VT02' AND MaChucNang='CN02'");
        mvc.perform(get("/pitches").session(staff)).andExpect(status().isOk());
        write(staff,post("/pitches"),body("STP3C","Test","LS01","Trống")).andExpect(status().isForbidden());
        write(staff,patch("/pitches/S01/status"),"{\"trangThai\":\"Bảo trì\"}").andExpect(status().isForbidden());
    }

    @Test
    void refusesMaintenanceWhileInUseAndDoesNotOfferPhysicalDelete() throws Exception {
        var session=login("admin");
        jdbc.update("UPDATE San SET TrangThai=N'Đang sử dụng' WHERE MaSan='S01'");em.clear();
        write(session,patch("/pitches/S01/status"),"{\"trangThai\":\"Bảo trì\"}").andExpect(status().isConflict());
        write(session,delete("/pitches/S01"),"").andExpect(status().isMethodNotAllowed());
        assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan='S01'",Integer.class)>0);
    }
}
