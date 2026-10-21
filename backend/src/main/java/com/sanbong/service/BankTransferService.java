package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.Clock;
import java.util.*;

/** Creates receiving instructions only. It never contacts a bank or records a receipt. */
@Service
public class BankTransferService {
    private final FinanceService finance;private final Clock clock;
    private final boolean enabled;private final String bin,bankName,accountNumber,accountName;
    public BankTransferService(FinanceService finance,Clock clock,
            @Value("${app.payment.bank.enabled:false}") boolean enabled,
            @Value("${app.payment.bank.bin:}") String bin,@Value("${app.payment.bank.name:}") String bankName,
            @Value("${app.payment.bank.account-number:}") String accountNumber,@Value("${app.payment.bank.account-name:}") String accountName,
            @Value("${app.payment.bank.qr-file:}") String qrFile){
        this.finance=finance;this.clock=clock;this.enabled=enabled;this.bin=bin.trim();this.bankName=bankName.trim();this.accountNumber=accountNumber.trim();this.accountName=accountName.trim();
        if(enabled&&(!this.bin.matches("[0-9]{6}")||!this.accountNumber.matches("[A-Za-z0-9]{3,19}")||this.bankName.isEmpty()||this.bankName.length()>100||this.accountName.isEmpty()||this.accountName.length()>100))
            throw new IllegalStateException("Bank transfer configuration is incomplete or invalid.");
    }
    @Transactional(readOnly=true)
    @SuppressWarnings("unchecked")
    public Map<String,Object> instructions(String id,BigDecimal amount,AccountPrincipal actor){
        var detail=finance.detail(id,actor); // ownership checked before exposing receiving instructions
        if(!enabled)throw new IllegalStateException("Chưa cấu hình QR nhận tiền. Vui lòng chọn tiền mặt hoặc liên hệ nhân viên.");
        var booking=(com.sanbong.dto.BookingView)detail.get("booking");
        if("Đã hủy".equals(booking.trangThai()))throw new IllegalStateException("Lượt đặt đã hủy, không tạo QR thanh toán.");
        if(amount==null||amount.signum()<=0||amount.stripTrailingZeros().scale()>0)
            throw new IllegalArgumentException("Chuyển khoản chỉ hỗ trợ số tiền nguyên VND. Không tự làm tròn tiền hóa đơn.");
        var invoice=(Map<String,Object>)detail.get("invoice");
        BigDecimal paid=((List<Map<String,Object>>)detail.get("payments")).stream().filter(p->"Thành công".equals(p.get("trangThai"))).map(p->(BigDecimal)p.get("soTien")).reduce(BigDecimal.ZERO,BigDecimal::add);
        var remaining=invoice==null?booking.tongTien().subtract(paid):(BigDecimal)invoice.get("conLai");
        if(amount.compareTo(remaining)>0)throw new IllegalStateException("Số tiền QR vượt số còn thiếu. Vui lòng tải lại hóa đơn.");
        if(((List<Map<String,Object>>)detail.get("payments")).stream().anyMatch(p->"Chờ xử lý".equals(p.get("trangThai"))))
            throw new IllegalStateException("Đã có yêu cầu chờ nhân viên xác minh. Không chuyển thêm trước khi đối chiếu.");
        String memo="FCUTE "+booking.maDatSan().replaceAll("[^A-Za-z0-9]","");
        if(amount.toBigIntegerExact().toString().length()>13)throw new IllegalArgumentException("Số tiền vượt giới hạn VietQR.");
        if(actor!=null&&"VT01".equals(actor.roleId())){
            var choices=ReservationPaymentAmounts.options(invoice==null?booking.tongTien():(BigDecimal)invoice.get("tongTien"),paid);
            if(choices.values().stream().noneMatch(v->v.signum()>0&&v.compareTo(amount)==0))throw new IllegalArgumentException("Chọn số tiền cọc 40% hoặc trả đủ do máy chủ tính.");
        }
        String url="https://img.vietqr.io/image/"+bin+"-"+accountNumber+"-compact2.svg?amount="+amount.toBigIntegerExact()+"&addInfo="+java.net.URLEncoder.encode(memo,java.nio.charset.StandardCharsets.UTF_8)+"&accountName="+java.net.URLEncoder.encode(accountName,java.nio.charset.StandardCharsets.UTF_8);
        return Map.of("bankName",bankName,"bankBin",bin,"accountNumber",accountNumber,"accountName",accountName,"amount",amount,"description",memo,"qrUrl",url,"qrAvailable",true,"issuedAt",clock.instant().toString());
    }
    @Transactional(readOnly=true)
    public org.springframework.http.ResponseEntity<byte[]> image(String id,BigDecimal amount,AccountPrincipal actor){
        var quote=instructions(id,amount,actor);
        return org.springframework.http.ResponseEntity.status(302).cacheControl(org.springframework.http.CacheControl.noStore()).location(java.net.URI.create((String)quote.get("qrUrl"))).build();
    }
}
