package com.sanbong;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.test.context.TestPropertySource;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** No bank calls/transfers; QR config is a dummy test recipient. All business writes roll back. */
@TestPropertySource(properties={"app.payment.bank.enabled=true","app.payment.bank.bin=970422","app.payment.bank.name=MB TEST ONLY","app.payment.bank.account-number=000000123456","app.payment.bank.account-name=TEST RECIPIENT","app.payment.bank.qr-file="})
class PaymentQrFlowTest extends RoleAuditSupport {
    String paymentId(com.fasterxml.jackson.databind.JsonNode data){return data.path("payments").get(0).path("maTT").asText();}
    Map<String,Object> request(String method){return Map.of("soTien",5000,"phuongThuc",method,"idempotencyKey",UUID.randomUUID().toString(),"daNhanTien",true);}
    @Test void qrUsesConfiguredRecipientAndActualBookingMemoWithoutCreatingMoneyOrInvoice()throws Exception{
        String id=book(login("nvsan"));var customer=login("khachhang");
        var result=data(mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(customer).param("amount","5000").param("accountNumber","attacker")).andExpect(status().isOk()).andReturn());
        assertEquals("000000123456",result.path("accountNumber").asText());assertEquals("FCUTE "+id,result.path("description").asText());assertEquals(5000,result.path("amount").asInt());
        assertFalse(result.path("qrAvailable").asBoolean());assertEquals("",result.path("qrUrl").asText());
        mvc.perform(get("/finance/bookings/"+id+"/bank-qr").session(customer).param("amount","5000")).andExpect(status().isNotFound());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaDatSan=?",Integer.class,id));
    }
    @ParameterizedTest @ValueSource(strings={"0","-1","1.5","NaN"})
    void qrRejectsInvalidOrFractionalVndWithoutRounding(String amount)throws Exception{
        String id=book(login("nvsan"));mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(login("khachhang")).param("amount",amount)).andExpect(status().isBadRequest());
    }
    @Test void customerCashRequestWaitsForStaffReceiptAndRetryDoesNotDoubleCount()throws Exception{
        var staff=login("nvsan");String id=book(staff);var customer=login("khachhang");
        var result=data(write(customer,"POST","/finance/bookings/"+id+"/payment-requests",request("Tiền mặt")).andExpect(status().isOk()).andReturn());String payment=paymentId(result);
        assertEquals("Chờ xử lý",result.path("payments").get(0).path("trangThai").asText());assertEquals(0,result.path("invoice").path("daThanhToan").decimalValue().signum());
        write(customer,"POST","/finance/payments/"+payment+"/confirm-cash",Map.of("daNhanTien",true)).andExpect(status().isForbidden());
        write(staff,"POST","/finance/payments/"+payment+"/confirm-cash",Map.of("daNhanTien",false)).andExpect(status().isBadRequest());
        for(int i=0;i<2;i++){var confirmed=data(write(staff,"POST","/finance/payments/"+payment+"/confirm-cash",Map.of("daNhanTien",true)).andExpect(status().isOk()).andReturn());assertEquals(5000,confirmed.path("invoice").path("daThanhToan").intValue());}
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=? AND TrangThai=N'Thành công'",Integer.class,id));
        assertEquals(jdbc.queryForObject("SELECT MaNV FROM TaiKhoan WHERE TenDangNhap='nvsan'",String.class),jdbc.queryForObject("SELECT MaNV FROM ThanhToan WHERE MaTT=?",String.class,payment));
    }
    @Test void transferWaitsForAccountantAndStaffCannotUseCashOrDirectPaymentToBypass()throws Exception{
        var staff=login("nvsan");String id=book(staff);var customer=login("khachhang");var accountant=login("ketoan");var body=request("Chuyển khoản");
        var result=data(write(customer,"POST","/finance/bookings/"+id+"/payment-requests",body).andExpect(status().isOk()).andReturn());String payment=paymentId(result);
        assertEquals(0,result.path("invoice").path("daThanhToan").decimalValue().signum());
        write(staff,"POST","/finance/payments/"+payment+"/confirm-cash",Map.of("daNhanTien",true)).andExpect(status().isForbidden());
        write(staff,"POST","/finance/bookings/"+id+"/payments",body).andExpect(status().isForbidden());
        write(customer,"POST","/finance/payments/"+payment+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isForbidden());
        mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(customer).param("amount","5000")).andExpect(status().isConflict());
        for(int i=0;i<2;i++){var confirmed=data(write(accountant,"POST","/finance/payments/"+payment+"/confirm",Map.of("daNhanTien",true)).andExpect(status().isOk()).andReturn());assertEquals(5000,confirmed.path("invoice").path("daThanhToan").intValue());}
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaDatSan=?",Integer.class,id));
    }
    @Test void cancelledOrFullyPaidBookingsCannotProduceAnotherQr()throws Exception{
        var staff=login("nvsan");String cancelled=book(staff),paid=book(staff,"09:00","10:00");var customer=login("khachhang");
        write(customer,"POST","/bookings/"+cancelled+"/cancel",Map.of("lyDo","QR rollback")).andExpect(status().isOk());
        mvc.perform(get("/finance/bookings/"+cancelled+"/transfer-instructions").session(customer).param("amount","1")).andExpect(status().isConflict());
        var total=jdbc.queryForObject("SELECT TongTien FROM DatSan WHERE MaDatSan=?",java.math.BigDecimal.class,paid);
        write(login("ketoan"),"POST","/finance/bookings/"+paid+"/payments",Map.of("soTien",total,"phuongThuc","Tiền mặt","daNhanTien",true,"idempotencyKey",UUID.randomUUID().toString())).andExpect(status().isOk());
        mvc.perform(get("/finance/bookings/"+paid+"/transfer-instructions").session(customer).param("amount","1")).andExpect(status().isConflict());
    }
    @Test void qrOwnershipAndAmountLimitsAreEnforcedOnBackend()throws Exception{
        String id=book(login("nvsan"));var customer=login("khachhang");
        mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(customer).param("amount","999999999")).andExpect(status().isConflict());
        String username="qrc_"+UUID.randomUUID().toString().replace("-","").substring(0,12),password="QrOwner-"+UUID.randomUUID();
        write(customer,"POST","/auth/register",Map.of("hoTen",marker,"soDienThoai",phone(),"email",username+"@example.invalid","tenDangNhap",username,"matKhau",password)).andExpect(status().isOk());var other=login(username,password);
        mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(other).param("amount","5000")).andExpect(status().isForbidden());
        mvc.perform(get("/finance/bookings/"+id+"/bank-qr").session(other).param("amount","5000")).andExpect(status().isForbidden());
        mvc.perform(get("/finance/bookings/"+id+"/transfer-instructions").session(login("nvsan")).param("amount","5000")).andExpect(status().isForbidden());
    }
}
