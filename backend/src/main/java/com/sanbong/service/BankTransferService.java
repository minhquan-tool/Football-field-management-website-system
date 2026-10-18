package com.sanbong.service;

import com.sanbong.config.AccountPrincipal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import java.time.Clock;
import java.util.*;

/** Creates receiving instructions only. It never contacts a bank or records a receipt. */
@Service
public class BankTransferService {
    private final FinanceService finance;private final Clock clock;
    private final boolean enabled;private final String bin,bankName,accountNumber,accountName;
    private final byte[] qrImage;
    private final String qrContentType;
    public BankTransferService(FinanceService finance,Clock clock,
            @Value("${app.payment.bank.enabled:false}") boolean enabled,
            @Value("${app.payment.bank.bin:}") String bin,@Value("${app.payment.bank.name:}") String bankName,
            @Value("${app.payment.bank.account-number:}") String accountNumber,@Value("${app.payment.bank.account-name:}") String accountName,
            @Value("${app.payment.bank.qr-file:}") String qrFile){
        this.finance=finance;this.clock=clock;this.enabled=enabled;this.bin=bin.trim();this.bankName=bankName.trim();this.accountNumber=accountNumber.trim();this.accountName=accountName.trim();
        if(enabled&&(!this.bin.matches("[0-9]{6}")||!this.accountNumber.matches("[A-Za-z0-9]{3,19}")||this.bankName.isEmpty()||this.bankName.length()>100||this.accountName.isEmpty()||this.accountName.length()>100))
            throw new IllegalStateException("Bank transfer configuration is incomplete or invalid.");
        byte[] image=null;String contentType="image/png";
        if(enabled&&!qrFile.isBlank())try{
            Path path=Path.of(qrFile);long size=Files.size(path);
            if(size<8||size>5*1024*1024)throw new IllegalArgumentException("QR image must be at most 5 MB.");
            image=Files.readAllBytes(path);
            boolean png=image.length>=8&&image[0]==(byte)137&&image[1]==80&&image[2]==78&&image[3]==71;
            boolean jpeg=image[0]==(byte)255&&image[1]==(byte)216&&image[2]==(byte)255;
            if(!png&&!jpeg)throw new IllegalArgumentException("QR image must be PNG or JPEG.");
            try(var stream=ImageIO.createImageInputStream(new ByteArrayInputStream(image))){
                var readers=ImageIO.getImageReaders(stream);
                if(!readers.hasNext())throw new IllegalArgumentException("Invalid QR image.");
                var reader=readers.next();try{reader.setInput(stream);if(reader.getWidth(0)>4096||reader.getHeight(0)>4096)throw new IllegalArgumentException("QR image dimensions exceed 4096 pixels.");if(reader.read(0)==null)throw new IllegalArgumentException("Invalid QR image.");}finally{reader.dispose();}
            }
            contentType=png?"image/png":"image/jpeg";
        }catch(Exception ex){throw new IllegalStateException("Cannot load configured local bank QR image. Use a valid PNG/JPEG file.",ex);}
        this.qrImage=image;this.qrContentType=contentType;
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
        String url=qrImage==null?"":"./finance/bookings/"+booking.maDatSan()+"/bank-qr?amount="+amount.toBigIntegerExact();
        return Map.of("bankName",bankName,"bankBin",bin,"accountNumber",accountNumber,"accountName",accountName,"amount",amount,"description",memo,"qrUrl",url,"qrAvailable",qrImage!=null,"issuedAt",clock.instant().toString());
    }
    @Transactional(readOnly=true)
    public org.springframework.http.ResponseEntity<byte[]> image(String id,BigDecimal amount,AccountPrincipal actor){
        instructions(id,amount,actor);
        if(qrImage==null)return org.springframework.http.ResponseEntity.notFound().build();
        return org.springframework.http.ResponseEntity.ok().cacheControl(org.springframework.http.CacheControl.noStore()).contentType(org.springframework.http.MediaType.parseMediaType(qrContentType)).body(qrImage.clone());
    }
}
