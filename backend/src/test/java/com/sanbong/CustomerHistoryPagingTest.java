package com.sanbong;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.mock.web.MockHttpSession;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** New customers/bookings only, all protected by the inherited DEV/test guard and rollback. */
class CustomerHistoryPagingTest extends RoleAuditSupport {
    record Customer(MockHttpSession session,String id,String phone,String email) {}
    Customer newCustomer()throws Exception{
        String username="hp_"+UUID.randomUUID().toString().replace("-","").substring(0,12),password="Paging-"+UUID.randomUUID(),phone=phone(),email=username+"@example.invalid";
        var r=mvc.perform(get("/auth/csrf")).andReturn();var c=data(r);
        mvc.perform(post("/auth/register").session((MockHttpSession)r.getRequest().getSession()).header(c.path("headerName").asText(),c.path("token").asText()).contentType("application/json")
                .content(json.writeValueAsString(Map.of("hoTen",marker,"soDienThoai",phone,"email",email,"tenDangNhap",username,"matKhau",password)))).andExpect(status().isOk());
        return new Customer(login(username,password),jdbc.queryForObject("SELECT MaKH FROM TaiKhoan WHERE TenDangNhap=?",String.class,username),phone,email);
    }
    String booking(Customer c,int offset)throws Exception{
        return data(write(c.session(),"POST","/bookings",Map.of("maSan",pitch(),"ngayChoi",day().plusDays(offset).toString(),"gioBatDau","08:00","gioKetThuc","09:00","ghiChu",marker)).andExpect(status().isOk()).andReturn()).path("maDatSan").asText();
    }
    JsonNode page(Customer c,int page,int size,String q,String state,String order)throws Exception{
        return data(mvc.perform(get("/customer/history").session(c.session()).param("page",String.valueOf(page)).param("size",String.valueOf(size)).param("q",q).param("state",state).param("order",order)).andExpect(status().isOk()).andReturn());
    }
    @Test void pagesAreBoundedStableAndDefaultNoLongerReturnsEntireHistory()throws Exception{
        var c=newCustomer();var ids=new ArrayList<String>();for(int i=0;i<23;i++)ids.add(booking(c,i));
        var first=page(c,1,10,"","","desc");var second=page(c,2,10,"","","desc");var last=page(c,3,10,"","","desc");
        assertEquals(23,first.path("total").asInt());assertEquals(3,first.path("totalPages").asInt());assertEquals(10,first.path("bookings").size());assertEquals(3,last.path("bookings").size());
        var combined=new ArrayList<String>();for(var result:List.of(first,second,last))result.path("bookings").forEach(b->combined.add(b.path("maDatSan").asText()));
        Collections.reverse(ids);assertEquals(ids,combined);assertEquals(23,new HashSet<>(combined).size());
        var defaults=data(mvc.perform(get("/customer/history").session(c.session())).andExpect(status().isOk()).andReturn());assertEquals(20,defaults.path("bookings").size());assertEquals(23,defaults.path("total").asInt());
        assertEquals(ids.getLast(),page(c,1,10,"","","asc").path("bookings").get(0).path("maDatSan").asText());
    }
    @Test void searchAndStateFiltersApplyAcrossAllPagesAndNeverExposeAnotherCustomer()throws Exception{
        var a=newCustomer();var b=newCustomer();String old=booking(a,0),recent=booking(a,1),other=booking(b,2);
        write(a.session(),"POST","/bookings/"+old+"/cancel",Map.of("lyDo","Paging rollback")).andExpect(status().isOk());
        assertEquals(old,page(a,1,1,old,"","desc").path("bookings").get(0).path("maDatSan").asText());
        assertEquals(old,page(a,1,1,"","Đã hủy","desc").path("bookings").get(0).path("maDatSan").asText());
        assertEquals(recent,page(a,1,1,"","Chờ xác nhận","desc").path("bookings").get(0).path("maDatSan").asText());
        assertEquals(0,page(a,1,10,other,"","desc").path("total").asInt());assertEquals(0,page(b,1,10,old,"","asc").path("total").asInt());
        var spoof=data(mvc.perform(get("/customer/history").session(a.session()).param("page","1").param("maKH",b.id())).andExpect(status().isOk()).andReturn());assertEquals(2,spoof.path("total").asInt());
    }
    @Test void searchTreatsSqlWildcardsAsLiteralCharacters()throws Exception{
        var c=newCustomer();booking(c,0);String name="Sân 100%_[ thật "+UUID.randomUUID().toString().substring(0,8);
        jdbc.update("UPDATE San SET TenSan=? WHERE MaSan=?",name,pitch());em.clear();
        for(String q:List.of("100%_[","[","%","_"))assertEquals(1,page(c,1,10,q,"","desc").path("total").asInt(),q);
        assertEquals(0,page(c,1,10,"not_found%","","desc").path("total").asInt());
        assertEquals(0,page(c,1,10,"' OR 1=1 --","","desc").path("total").asInt());
    }
    @Test void onlyReviewsForCurrentPageAreLoaded()throws Exception{
        var c=newCustomer();String old=booking(c,0),recent=booking(c,1);
        var scores=new LinkedHashMap<String,Integer>();jdbc.queryForList("SELECT MaTieuChi FROM TieuChiDanhGia",String.class).forEach(id->scores.put(id,5));
        for(String id:List.of(old,recent)){jdbc.update("UPDATE DatSan SET TrangThai=N'Đã sử dụng' WHERE MaDatSan=?",id);em.clear();write(c.session(),"POST","/customer/bookings/"+id+"/review",Map.of("diem",scores,"noiDung",marker)).andExpect(status().isOk());}
        var first=page(c,1,1,"","","desc");var second=page(c,2,1,"","","desc");
        assertEquals(1,first.path("reviews").size());assertEquals(recent,first.path("reviews").get(0).path("maDatSan").asText());assertEquals(old,second.path("reviews").get(0).path("maDatSan").asText());
    }
    @ParameterizedTest @CsvSource({"page,0","page,100001","size,0","size,51","order,invalid","state,invalid","page,not-a-number"})
    void invalidPagingOrFiltersReturn400(String key,String value)throws Exception{
        var c=newCustomer();mvc.perform(get("/customer/history").session(c.session()).param(key,value)).andExpect(status().isBadRequest());
    }
    @Test void emptyAndOutOfRangePagesDoNotReturnOtherRows()throws Exception{
        var c=newCustomer();var empty=page(c,1,10,"","","desc");assertEquals(0,empty.path("total").asInt());assertTrue(empty.path("bookings").isEmpty());
        booking(c,0);var beyond=page(c,99,10,"","","desc");assertEquals(1,beyond.path("total").asInt());assertTrue(beyond.path("bookings").isEmpty());assertTrue(beyond.path("reviews").isEmpty());
        mvc.perform(get("/customer/history").session(c.session()).param("q","x".repeat(101))).andExpect(status().isBadRequest());
    }
    @Test void profileDuplicateChecksStillProtectUnlinkedCustomerContacts()throws Exception{
        var c=newCustomer();String contact=phone(),email="unlinked-"+UUID.randomUUID()+"@example.invalid";
        jdbc.update("INSERT KhachHang(MaKH,HoTen,SoDienThoai,Email) VALUES(?,?,?,?)",code("HP"),marker,contact,email);
        for(var body:List.of(Map.of("hoTen",marker,"soDienThoai",contact,"email",c.email()),Map.of("hoTen",marker,"soDienThoai",c.phone(),"email",email)))write(c.session(),"PUT","/customer/profile",body).andExpect(status().isConflict());
        write(c.session(),"PUT","/customer/profile",Map.of("hoTen",marker,"soDienThoai",c.phone(),"email",c.email())).andExpect(status().isOk());
    }
}
