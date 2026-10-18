package com.sanbong;
import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
/** All fixture/business writes are rolled back. Global marker/opt-in guard is retained. */
@SpringBootTest @AutoConfigureMockMvc @Transactional
class RoleWorkflowIntegrationTest {
    @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired JdbcTemplate jdbc;
    @Autowired jakarta.persistence.EntityManager entityManager;
    JsonNode data(MvcResult r)throws Exception{return json.readTree(r.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
    MockHttpSession login(String name)throws Exception{var csrf=mvc.perform(get("/auth/csrf")).andReturn();var s=(MockHttpSession)csrf.getRequest().getSession();var c=data(csrf);mvc.perform(post("/auth/login").session(s).header(c.path("headerName").asText(),c.path("token").asText()).param("identifier",name).param("password",System.getenv().getOrDefault("AUTH_TEST_PASSWORD","123456"))).andExpect(status().isOk());return s;}
    ResultActions write(MockHttpSession s,String method,String path,Object body)throws Exception{var c=data(mvc.perform(get("/auth/csrf").session(s)).andReturn());return mvc.perform(request(org.springframework.http.HttpMethod.valueOf(method),path).session(s).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json").content(json.writeValueAsString(body)));}
    String id(String prefix){return prefix+UUID.randomUUID().toString().replace("-","").substring(0,8);}
    String pitch(){String id=id("RF");jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai) VALUES(?,?,?,N'Trống')",id,"Role workflow rollback",jdbc.queryForObject("SELECT TOP(1) MaLoaiSan FROM LoaiSan ORDER BY MaLoaiSan",String.class));return id;}
    String customer(){return jdbc.queryForObject("SELECT MaKH FROM TaiKhoan WHERE TenDangNhap='khachhang'",String.class);}
    LocalDate future(){return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(30);}
    String booking(MockHttpSession staff,String pitch)throws Exception{return data(write(staff,"POST","/bookings",Map.of("maSan",pitch,"maKH",customer(),"ngayChoi",future().toString(),"gioBatDau","08:00","gioKetThuc","09:00")).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
    @Test void initialBookingOptionsCanSearchWithoutEditingPastDefaults()throws Exception{
        var staff=login("nvsan");var options=data(mvc.perform(get("/booking-options").session(staff)).andExpect(status().isOk()).andReturn());
        mvc.perform(get("/availability").param("date",options.path("defaultDate").asText()).param("start",options.path("defaultStart").asText()).param("end",options.path("defaultEnd").asText()).session(staff)).andExpect(status().isOk());
    }
    @Test void profileRoundTripAndDuplicateContactAreRealSqlTransactions()throws Exception{
        var s=login("khachhang");var p=data(mvc.perform(get("/customer/profile").session(s)).andExpect(status().isOk()).andReturn());
        var body=new HashMap<String,Object>();body.put("hoTen","Role workflow rollback");body.put("soDienThoai",p.path("soDienThoai").asText());body.put("email",p.path("email").isNull()?null:p.path("email").asText());body.put("diaChi","Test rollback");
        write(s,"PUT","/customer/profile",body).andExpect(status().isOk()).andExpect(jsonPath("$.data.hoTen").value("Role workflow rollback"));
        assertEquals("Role workflow rollback",jdbc.queryForObject("SELECT HoTen FROM KhachHang WHERE MaKH=?",String.class,customer()));
        var otherPhone=jdbc.queryForList("SELECT TOP(1) SoDienThoai FROM KhachHang WHERE MaKH<>?",String.class,customer());if(!otherPhone.isEmpty()){body.put("soDienThoai",otherPhone.getFirst());write(s,"PUT","/customer/profile",body).andExpect(status().isConflict());}
    }
    @Test void completedOwnBookingReviewIsUniqueAndCriteriaArePersisted()throws Exception{
        var staff=login("nvsan");String booking=booking(staff,pitch());jdbc.update("UPDATE DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=?",booking);entityManager.clear();
        var customer=login("khachhang");var criteria=jdbc.queryForList("SELECT MaTieuChi FROM TieuChiDanhGia",String.class);assertFalse(criteria.isEmpty());var scores=new LinkedHashMap<String,Integer>();criteria.forEach(c->scores.put(c,4));
        write(customer,"POST","/customer/bookings/"+booking+"/review",Map.of("diem",scores,"noiDung","Role workflow rollback")).andExpect(status().isOk());
        assertEquals(0,new BigDecimal("4.00").compareTo(jdbc.queryForObject("SELECT DiemTrungBinh FROM DanhGia WHERE MaDatSan=?",BigDecimal.class,booking)));
        write(customer,"POST","/customer/bookings/"+booking+"/review",Map.of("diem",scores)).andExpect(status().isConflict());
        mvc.perform(get("/customer/history").session(customer)).andExpect(status().isOk());
    }
    @Test void feedbackCanBeReceivedResolvedAndCannotOverwriteClosedHistory()throws Exception{
        var customer=login("khachhang");String marker="Role workflow "+UUID.randomUUID();write(customer,"POST","/feedback",Map.of("loaiPhanHoi","Góp ý","noiDung",marker)).andExpect(status().isOk());
        String id=jdbc.queryForObject("SELECT MaPhanHoi FROM PhanHoi WHERE NoiDung=?",String.class,marker);var staff=login("nvsan");
        write(staff,"PUT","/feedback/"+id,Map.of("trangThai","Đang xử lý","ketQua","Đã tiếp nhận")).andExpect(status().isOk());
        write(staff,"PUT","/feedback/"+id,Map.of("trangThai","Đã xử lý","ketQua","Đã hỗ trợ")).andExpect(status().isOk());
        write(staff,"PUT","/feedback/"+id,Map.of("trangThai","Đang xử lý","ketQua","Không ghi đè")).andExpect(status().isConflict());
        assertNotNull(jdbc.queryForObject("SELECT MaNV FROM PhanHoi WHERE MaPhanHoi=?",String.class,id));
    }
    @Test void reschedulePreservesServicesAndStopsAfterInvoice()throws Exception{
        var staff=login("nvsan");String booking=booking(staff,pitch());
        write(staff,"POST","/bookings/"+booking+"/reschedule",Map.of("ngayChoi",future().plusDays(1).toString(),"gioBatDau","08:00","gioKetThuc","09:30","lyDo","Role workflow rollback")).andExpect(status().isOk());
        var expected=jdbc.queryForObject("SELECT DonGia*1.5 FROM GiaTheoCa WHERE GioBatDau<='08:00' AND GioKetThuc>'08:00'",BigDecimal.class);assertEquals(0,expected.compareTo(jdbc.queryForObject("SELECT TienSan FROM DatSan WHERE MaDatSan=?",BigDecimal.class,booking)));
        write(staff,"POST","/finance/bookings/"+booking+"/invoice",Map.of()).andExpect(status().isOk());
        write(staff,"POST","/bookings/"+booking+"/reschedule",Map.of("ngayChoi",future().plusDays(2).toString(),"gioBatDau","08:00","gioKetThuc","09:00","lyDo","Cannot rewrite invoice")).andExpect(status().isConflict());
    }
    @Test void customerPaymentAccountantConfirmationCancellationAndRefundStayConsistent()throws Exception{
        var staff=login("nvsan");String booking=booking(staff,pitch());var customer=login("khachhang");
        var pending=data(write(customer,"POST","/finance/bookings/"+booking+"/payment-requests",Map.of("soTien",10000,"phuongThuc","Chuyển khoản","idempotencyKey",UUID.randomUUID().toString(),"daNhanTien",false)).andExpect(status().isOk()).andReturn());
        String payment=pending.path("payments").get(0).path("maTT").asText();assertEquals("Chờ xử lý",pending.path("payments").get(0).path("trangThai").asText());
        var accountant=login("ketoan");write(accountant,"POST","/finance/payments/"+payment+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isOk());
        var ledger=data(mvc.perform(get("/finance/transactions").session(accountant)).andExpect(status().isOk()).andReturn());
        boolean found=false;for(var row:ledger.path("payments")){if(payment.equals(row.path("maTT").asText())){found=true;assertTrue(row.path("ngayThanhToan").asText().startsWith(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).toString()));}}
        assertTrue(found);
        write(customer,"POST","/bookings/"+booking+"/cancel",Map.of("lyDo","Rollback cancellation test")).andExpect(status().isOk());
        String refund=jdbc.queryForObject("SELECT MaHT FROM HoanTien WHERE MaTT=?",String.class,payment);
        var confirmation=Map.of("phuongThuc","Chuyển khoản","daHoanTien",true,"lyDo","Rollback refund test");
        write(staff,"POST","/finance/refunds/"+refund+"/confirm",confirmation).andExpect(status().isForbidden());
        write(accountant,"POST","/finance/refunds/"+refund+"/confirm",confirmation).andExpect(status().isOk());
        write(accountant,"POST","/finance/refunds/"+refund+"/confirm",confirmation).andExpect(status().isOk());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM HoanTien WHERE MaTT=? AND TrangThai=N'Đã hoàn'",Integer.class,payment));
        mvc.perform(get("/finance/bookings/"+booking).session(customer)).andExpect(status().isOk()).andExpect(jsonPath("$.data.thucThu").value(0));
        var query=get("/reports/reconciliation").param("from",future().toString()).param("to",future().toString());
        var reconciliation=data(mvc.perform(query.session(accountant)).andExpect(status().isOk()).andReturn());
        boolean reconciled=false;for(var row:reconciliation.path("rows"))if(booking.equals(row.path("maDatSan").asText())){reconciled=true;assertEquals("Khớp sổ nội bộ",row.path("ketQua").asText());assertEquals(10000,row.path("tienThu").asInt());assertEquals(10000,row.path("tienHoan").asInt());}assertTrue(reconciled);
        jdbc.update("UPDATE HoaDon SET DaThanhToan=9999 WHERE MaDatSan=?",booking);
        var mismatch=data(mvc.perform(get("/reports/reconciliation").param("from",future().toString()).param("to",future().toString()).session(accountant)).andExpect(status().isOk()).andReturn());
        boolean detected=false;for(var row:mismatch.path("rows"))if(booking.equals(row.path("maDatSan").asText())){detected=true;assertEquals("Cần kiểm tra",row.path("ketQua").asText());assertEquals(-1,row.path("chenhLechThu").asInt());}assertTrue(detected);
    }
    @Test void unusedLegacySlotAndPriceCanBeConfiguredWithoutChangingUsedSlots()throws Exception{
        var admin=login("admin");String type=id("RT"),slot=id("RK"),price=id("RG");
        write(admin,"PUT","/configuration/types",Map.of("id",type,"ten","Rollback type","soNguoi",5)).andExpect(status().isOk());
        write(admin,"PUT","/configuration/slots",Map.of("id",slot,"batDau","00:00","ketThuc","00:30")).andExpect(status().isOk());
        write(admin,"PUT","/configuration/prices",Map.of("id",price,"loaiSan",type,"khungGio",slot,"loaiNgay","Ngày thường","donGia",10000,"tuNgay","2099-01-01","denNgay","2099-01-31")).andExpect(status().isOk());
        assertEquals(0,new BigDecimal("0.50").compareTo(jdbc.queryForObject("SELECT ThoiLuong FROM KhungGio WHERE MaKhungGio=?",BigDecimal.class,slot)));
        write(admin,"PUT","/configuration/slots",Map.of("id",slot,"batDau","00:00","ketThuc","00:45")).andExpect(status().isBadRequest());
    }
    @Test void usedPromotionCanBeStoppedWithoutRewritingDiscountOrInvoice()throws Exception{
        var admin=login("admin");String promo=id("RM"),booking=booking(admin,pitch());var today=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        write(admin,"PUT","/configuration/promotions",Map.of("id",promo,"ten","Rollback promo","donGia",10,"tuNgay",today.toString(),"denNgay",today.plusDays(90).toString(),"hoatDong",true)).andExpect(status().isOk());
        var customer=login("khachhang");var offers=data(mvc.perform(get("/customer/promotions").session(customer)).andExpect(status().isOk()).andReturn());boolean visible=false;for(var offer:offers){assertTrue(Set.of("Phần trăm","Số tiền").contains(offer.path("loaiGiam").asText()));if(promo.equals(offer.path("maKM").asText()))visible=true;}assertTrue(visible);
        write(admin,"POST","/finance/bookings/"+booking+"/invoice",Map.of("maKM",promo)).andExpect(status().isOk());
        var before=jdbc.queryForMap("SELECT TienSan,TienGiam,TongTien FROM HoaDon WHERE MaDatSan=?",booking);
        write(admin,"PUT","/configuration/promotion-status",Map.of("id",promo,"hoatDong",false)).andExpect(status().isOk());
        assertEquals(false,jdbc.queryForObject("SELECT TrangThai FROM KhuyenMai WHERE MaKM=?",Boolean.class,promo));
        assertEquals(before,jdbc.queryForMap("SELECT TienSan,TienGiam,TongTien FROM HoaDon WHERE MaDatSan=?",booking));
        assertEquals(0,new BigDecimal("10").compareTo(jdbc.queryForObject("SELECT MucGiam FROM KhuyenMai WHERE MaKM=?",BigDecimal.class,promo)));
    }
    @Test void adminConfigurationAndNewSkuPersistWithoutChangingExistingBookingSnapshots()throws Exception{
        var admin=login("admin");var before=jdbc.queryForList("SELECT MaDatSan,DonGia,TienSan,TongTien FROM DatSan ORDER BY MaDatSan");
        var hour=jdbc.queryForMap("SELECT TOP(1) MaCa,DonGia FROM GiaTheoCa ORDER BY MaCa");
        write(admin,"PUT","/configuration/hourly",Map.of("id",hour.get("MaCa"),"donGia",new BigDecimal("99999"))).andExpect(status().isOk());
        assertEquals(before,jdbc.queryForList("SELECT MaDatSan,DonGia,TienSan,TongTien FROM DatSan ORDER BY MaDatSan"));
        String type=id("RT");write(admin,"PUT","/configuration/types",Map.of("id",type,"ten","Role test","soNguoi",5)).andExpect(status().isOk());
        String sku=id("RV");write(admin,"POST","/service-catalog",Map.of("maDV",sku,"tenDV","Role rollback","donViTinh","Chai","donGia",10000,"hoTroLoc",true)).andExpect(status().isOk());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DichVu WHERE MaDV=?",Integer.class,sku));
        mvc.perform(get("/finance/transactions").session(admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.payments").isArray());
        write(admin,"POST","/service-catalog",Map.of("maDV",sku,"tenDV","Duplicate","donViTinh","Chai","donGia",10000,"hoTroLoc",true)).andExpect(status().isConflict());
    }
}
