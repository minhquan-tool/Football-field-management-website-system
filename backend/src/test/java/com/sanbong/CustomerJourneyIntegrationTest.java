package com.sanbong;

import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** New customers, pitches and business writes all roll back; global DEV/test guard remains. */
@SpringBootTest @AutoConfigureMockMvc @Transactional
class CustomerJourneyIntegrationTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JdbcTemplate jdbc;
    @Autowired PasswordEncoder encoder; @Autowired EntityManager em;
    @Autowired com.sanbong.repository.FinanceRepository finance;
    static final String PASSWORD="CustomerJourney2026!";
    record Customer(String username,String phone,String email,String id,MockHttpSession session) {}
    JsonNode data(MvcResult result)throws Exception{return json.readTree(result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8)).path("data");}
    ResultActions write(MockHttpSession session,String method,String path,Object body)throws Exception{
        var req=get("/auth/csrf");if(session!=null)req.session(session);
        var result=mvc.perform(req).andExpect(status().isOk()).andReturn();var token=data(result);
        return mvc.perform(request(org.springframework.http.HttpMethod.valueOf(method),path)
            .session((MockHttpSession)result.getRequest().getSession()).header(token.path("headerName").asText(),token.path("token").asText())
            .contentType("application/json").content(json.writeValueAsString(body)));
    }
    MockHttpSession login(String identifier,String password)throws Exception{
        var result=mvc.perform(get("/auth/csrf")).andReturn();var token=data(result);
        return (MockHttpSession)mvc.perform(post("/auth/login").session((MockHttpSession)result.getRequest().getSession())
            .header(token.path("headerName").asText(),token.path("token").asText()).param("identifier",identifier).param("password",password))
            .andExpect(status().isOk()).andReturn().getRequest().getSession();
    }
    Map<String,Object> registration(){String suffix=UUID.randomUUID().toString().replace("-","").substring(0,12);
        return new LinkedHashMap<>(Map.of("hoTen","Khách kiểm thử Unicode Võ Minh Quân","soDienThoai","09"+String.format("%08d",new java.security.SecureRandom().nextInt(100000000)),
            "email","cj-"+suffix+"@example.invalid","tenDangNhap","cj_"+suffix,"matKhau",PASSWORD));}
    Customer customer()throws Exception{var body=registration();write(null,"POST","/auth/register",body).andExpect(status().isOk());
        String username=body.get("tenDangNhap").toString();return new Customer(username,body.get("soDienThoai").toString(),body.get("email").toString(),
            jdbc.queryForObject("SELECT MaKH FROM TaiKhoan WHERE TenDangNhap=?",String.class,username),login(username,PASSWORD));}
    String pitch(){String id="CJ"+UUID.randomUUID().toString().replace("-","").substring(0,8);
        jdbc.update("INSERT San(MaSan,TenSan,MaLoaiSan,TrangThai) VALUES(?,?,?,N'Trống')",id,"Customer journey rollback","LS01");return id;}
    LocalDate future(){return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(20);}
    Map<String,Object> bookingBody(String pitch,String start,String end){return new LinkedHashMap<>(Map.of("maSan",pitch,"ngayChoi",future().toString(),"gioBatDau",start,"gioKetThuc",end));}
    String book(Customer customer,String pitch,String start,String end)throws Exception{return data(write(customer.session(),"POST","/bookings",bookingBody(pitch,start,end)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();}
    int count(String table){return jdbc.queryForObject("SELECT COUNT(*) FROM "+table,Integer.class);}

    @Test void registrationKeepsUnicodeHashesPasswordAndForcesCustomerRole()throws Exception{
        var body=registration();body.put("maVaiTro","VT04");body.put("trangThai","Quản trị");
        var response=write(null,"POST","/auth/register",body).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String username=body.get("tenDangNhap").toString();assertFalse(response.contains(PASSWORD));
        var account=jdbc.queryForMap("SELECT t.MaVaiTro,t.MatKhau,k.HoTen FROM TaiKhoan t JOIN KhachHang k ON k.MaKH=t.MaKH WHERE t.TenDangNhap=?",username);
        assertEquals("VT01",account.get("MaVaiTro"));assertEquals(body.get("hoTen"),account.get("HoTen"));assertTrue(encoder.matches(PASSWORD,account.get("MatKhau").toString()));
        for(String identifier:List.of(username,body.get("email").toString(),body.get("soDienThoai").toString())){
            var s=login(identifier,PASSWORD);var profile=mvc.perform(get("/auth/me").session(s)).andExpect(status().isOk()).andExpect(jsonPath("$.data.maVaiTro").value("VT01")).andReturn();
            assertFalse(profile.getResponse().getContentAsString().contains("matKhau"));
            write(s,"POST","/auth/logout",Map.of()).andExpect(status().isOk());assertTrue(s.isInvalid());
        }
    }
    @ParameterizedTest @ValueSource(strings={"tenDangNhap","soDienThoai","email"})
    void duplicateIdentityDoesNotLeaveOrphanCustomerOrAccount(String field)throws Exception{
        var first=registration();write(null,"POST","/auth/register",first).andExpect(status().isOk());
        var second=registration();second.put(field,first.get(field));int customers=count("KhachHang"),accounts=count("TaiKhoan");
        write(null,"POST","/auth/register",second).andExpect(status().isConflict());assertEquals(customers,count("KhachHang"));assertEquals(accounts,count("TaiKhoan"));
    }
    @ParameterizedTest @ValueSource(strings={"+++++++++","090+1234567","++8490123456"})
    void malformedPhoneCannotRegister(String phone)throws Exception{
        var body=registration();body.put("soDienThoai",phone);int before=count("KhachHang");
        write(null,"POST","/auth/register",body).andExpect(status().isBadRequest());assertEquals(before,count("KhachHang"));
    }
    @Test void profileChangePreservesUnicodeAndNewContactCanLogin()throws Exception{
        var c=customer();String phone="+849"+String.format("%08d",new java.security.SecureRandom().nextInt(100000000)),email="new-"+UUID.randomUUID()+"@example.invalid";
        write(c.session(),"PUT","/customer/profile",Map.of("hoTen","Nguyễn Ánh Đào","soDienThoai",phone,"email",email,"diaChi","Thủ Đức"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.hoTen").value("Nguyễn Ánh Đào"));
        em.clear();mvc.perform(get("/customer/profile").session(login(email,PASSWORD))).andExpect(status().isOk()).andExpect(jsonPath("$.data.soDienThoai").value(phone));
        mvc.perform(get("/auth/me").session(login(phone,PASSWORD))).andExpect(status().isOk());
    }
    @Test void profileCannotSaveMalformedPhone()throws Exception{
        var c=customer();write(c.session(),"PUT","/customer/profile",Map.of("hoTen","Khách","soDienThoai","+++++++","email",c.email(),"diaChi",""))
            .andExpect(status().isBadRequest());assertEquals(c.phone(),jdbc.queryForObject("SELECT SoDienThoai FROM KhachHang WHERE MaKH=?",String.class,c.id()));
    }
    @Test void historyBookingServiceFinanceAndFeedbackArePrivate()throws Exception{
        var a=customer();var b=customer();String pitch=pitch(),own=book(a,pitch,"08:00","09:00"),other=book(b,pitch,"09:00","10:00");
        mvc.perform(get("/customer/history").session(a.session())).andExpect(status().isOk()).andExpect(jsonPath("$.data.bookings.length()").value(1)).andExpect(jsonPath("$.data.bookings[0].maDatSan").value(own));
        mvc.perform(get("/bookings").param("date",future().toString()).session(a.session())).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1));
        for(String path:List.of("/bookings/"+other,"/bookings/"+other+"/services","/finance/bookings/"+other,"/finance/bookings/"+other+"/cancel-preview"))mvc.perform(get(path).session(a.session())).andExpect(status().isForbidden());
        write(a.session(),"POST","/bookings/"+other+"/cancel",Map.of("lyDo","Không được hủy hộ")).andExpect(status().isForbidden());
        write(a.session(),"POST","/feedback",Map.of("maDatSan",other,"loaiPhanHoi","Góp ý","noiDung","Không được phản hồi hộ")).andExpect(status().isForbidden());
        write(b.session(),"POST","/feedback",Map.of("maDatSan",other,"loaiPhanHoi","Góp ý","noiDung","CJ_PRIVATE_"+other)).andExpect(status().isOk());
        var feedback=mvc.perform(get("/feedback").session(a.session())).andExpect(status().isOk()).andReturn();assertFalse(feedback.getResponse().getContentAsString().contains("CJ_PRIVATE_"+other));
    }
    @Test void customerCannotSpoofOwnerOrPrice()throws Exception{
        var a=customer();var b=customer();String pitch=pitch();var spoof=bookingBody(pitch,"08:00","09:00");spoof.put("maKH",b.id());
        write(a.session(),"POST","/bookings",spoof).andExpect(status().isForbidden());
        var body=bookingBody(pitch,"08:00","09:00");body.put("tongTien",1);body.put("donGia",1);body.put("trangThai","Đã sử dụng");
        var d=data(write(a.session(),"POST","/bookings",body).andExpect(status().isOk()).andReturn());assertEquals(a.id(),d.path("maKH").asText());assertEquals("Chờ xác nhận",d.path("trangThai").asText());
        var rate=jdbc.queryForObject("SELECT DonGia FROM GiaTheoCa WHERE GioBatDau<='08:00' AND GioKetThuc>'08:00'",BigDecimal.class);assertEquals(0,rate.compareTo(d.path("tongTien").decimalValue()));
    }
    @Test void customerCannotConfirmVisitIssueInvoiceOrReadInternalLedger()throws Exception{
        var c=customer();String id=book(c,pitch(),"08:00","09:00");
        for(String path:List.of("/bookings/"+id+"/confirm","/operations/bookings/"+id+"/check-in","/operations/bookings/"+id+"/check-out","/finance/bookings/"+id+"/invoice","/finance/bookings/"+id+"/payments"))
            write(c.session(),"POST",path,Map.of("soTien",10000,"phuongThuc","Tiền mặt","idempotencyKey",UUID.randomUUID().toString(),"daNhanTien",true)).andExpect(status().isForbidden());
        for(String path:List.of("/booking-customers?phone="+c.phone(),"/finance/transactions","/security/accounts","/reports/dashboard"))mvc.perform(get(path).session(c.session())).andExpect(status().isForbidden());
        assertEquals("Chờ xác nhận",jdbc.queryForObject("SELECT TrangThai FROM DatSan WHERE MaDatSan=?",String.class,id));
    }
    @Test void paymentRequestRetryDoesNotBecomeReceiptOrDuplicate()throws Exception{
        var c=customer();String id=book(c,pitch(),"08:00","09:00"),key=UUID.randomUUID().toString();
        var body=Map.of("soTien",10000,"phuongThuc","Chuyển khoản","idempotencyKey",key,"daNhanTien",true);
        for(int n=0;n<2;n++)write(c.session(),"POST","/finance/bookings/"+id+"/payment-requests",body).andExpect(status().isOk()).andExpect(jsonPath("$.data.thucThu").value(0));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));assertEquals("Chờ xử lý",jdbc.queryForObject("SELECT TrangThai FROM ThanhToan WHERE MaDatSan=?",String.class,id));
        var changed=new LinkedHashMap<String,Object>(body);changed.put("soTien",10001);write(c.session(),"POST","/finance/bookings/"+id+"/payment-requests",changed).andExpect(status().isConflict());
    }
    @Test void completedBookingReviewPersistsOnceAndCancelledBookingCannotReview()throws Exception{
        var c=customer();String pitch=pitch(),used=book(c,pitch,"08:00","09:00"),cancelled=book(c,pitch,"09:00","10:00");
        jdbc.update("UPDATE DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=?",used);em.clear();
        var scores=new LinkedHashMap<String,Integer>();jdbc.queryForList("SELECT MaTieuChi FROM TieuChiDanhGia",String.class).forEach(code->scores.put(code,5));assertFalse(scores.isEmpty());
        write(c.session(),"POST","/customer/bookings/"+used+"/review",Map.of("diem",scores,"noiDung","Dữ liệu kiểm thử có dấu")).andExpect(status().isOk());
        write(c.session(),"POST","/customer/bookings/"+used+"/review",Map.of("diem",scores)).andExpect(status().isConflict());
        write(c.session(),"POST","/bookings/"+cancelled+"/cancel",Map.of("lyDo","Kiểm thử hủy trước giờ")).andExpect(status().isOk());
        write(c.session(),"POST","/customer/bookings/"+cancelled+"/review",Map.of("diem",scores)).andExpect(status().isConflict());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM DanhGia WHERE MaDatSan=?",Integer.class,used));
    }
    @ParameterizedTest @CsvSource({"36000,100","35999,50","7200,50","7199,0","0,0","-1,0"})
    void refundRateUsesExactTenHourAndTwoHourBoundaries(int seconds,int expected){
        var start=LocalDateTime.of(2030,1,20,18,0);
        assertEquals(0,BigDecimal.valueOf(expected).compareTo(finance.rate(start,start.minusSeconds(seconds))));
    }
    @Test void invalidAndExcessivePaymentRequestsNeverCreateReceipt()throws Exception{
        var c=customer();String id=book(c,pitch(),"08:00","09:00");
        for(Object amount:List.of(0,-1,new BigDecimal("0.001"))){
            write(c.session(),"POST","/finance/bookings/"+id+"/payment-requests",Map.of("soTien",amount,"phuongThuc","Chuyển khoản","idempotencyKey",UUID.randomUUID().toString())).andExpect(status().isBadRequest());
        }
        write(c.session(),"POST","/finance/bookings/"+id+"/payment-requests",Map.of("soTien",999999999,"phuongThuc","Chuyển khoản","idempotencyKey",UUID.randomUUID().toString())).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
    }
    @Test void invalidReviewScoresAndEmptyFeedbackCannotPersist()throws Exception{
        var c=customer();String id=book(c,pitch(),"08:00","09:00");
        for(int score:List.of(0,6))write(c.session(),"POST","/customer/bookings/"+id+"/review",Map.of("diem",Map.of("TC1",score))).andExpect(status().isBadRequest());
        write(c.session(),"POST","/feedback",Map.of("maDatSan",id,"loaiPhanHoi","Góp ý","noiDung"," ")).andExpect(status().isBadRequest());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM DanhGia WHERE MaDatSan=?",Integer.class,id));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM PhanHoi WHERE MaKH=?",Integer.class,c.id()));
    }
    @Test void unpaidCancellationReleasesAvailabilityWithoutInventingRefund()throws Exception{
        var c=customer();String pitch=pitch(),id=book(c,pitch,"08:00","09:00");
        write(c.session(),"POST","/bookings/"+id+"/cancel",Map.of("lyDo","Hủy lượt đặt kiểm thử")).andExpect(status().isOk());
        assertEquals(0,jdbc.queryForObject("SELECT SoTienHoan FROM HuyDatSan WHERE MaDatSan=?",BigDecimal.class,id).signum());
        write(c.session(),"POST","/bookings/"+id+"/cancel",Map.of("lyDo","Không hủy lần hai")).andExpect(status().isConflict());
        assertNotEquals(id,book(c,pitch,"08:00","09:00"));
    }
    @Test void differentCustomersCannotOverlapButCanBookAdjacentTimes()throws Exception{
        var a=customer();var b=customer();String pitch=pitch();book(a,pitch,"08:00","09:00");
        write(b.session(),"POST","/bookings",bookingBody(pitch,"08:30","09:30")).andExpect(status().isConflict());
        book(b,pitch,"09:00","10:00");assertEquals(2,jdbc.queryForObject("SELECT COUNT(*) FROM DatSan WHERE MaSan=?",Integer.class,pitch));
    }
}
