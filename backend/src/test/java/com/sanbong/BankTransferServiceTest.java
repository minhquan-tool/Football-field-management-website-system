package com.sanbong;

import com.sanbong.service.*;
import com.sanbong.dto.BookingView;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import java.nio.file.*;
import java.math.BigDecimal;
import java.time.Clock;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class BankTransferServiceTest {
    @TempDir Path folder;
    final FinanceService finance=mock(FinanceService.class);
    BankTransferService service(boolean enabled,String file){return new BankTransferService(finance,Clock.systemUTC(),enabled,"970422","TEST BANK","0000123456","TEST ONLY",file);}
    void booking(){
        var view=new BookingView("DS123",null,null,null,null,null,null,null,null,null,null,null,null,null,null,new BigDecimal("90000"),"Đã xác nhận",null,null);
        when(finance.detail("DS123",null)).thenReturn(new HashMap<>(Map.of("booking",view,"payments",List.of())));
    }
    @Test void localPngIsServedWithoutExternalUrlAndCannotBeChangedByCaller()throws Exception{
        Path file=folder.resolve("bank.png");ImageIO.write(new BufferedImage(2,2,BufferedImage.TYPE_INT_RGB),"png",file.toFile());
        byte[] expected=Files.readAllBytes(file);booking();var service=service(true,file.toString());
        var instructions=service.instructions("DS123",new BigDecimal("5000"),null);
        assertEquals(true,instructions.get("qrAvailable"));assertEquals("./finance/bookings/DS123/bank-qr?amount=5000",instructions.get("qrUrl"));
        var response=service.image("DS123",new BigDecimal("5000"),null);
        assertEquals("image/png",response.getHeaders().getContentType().toString());assertEquals("no-store",response.getHeaders().getCacheControl());assertArrayEquals(expected,response.getBody());
        response.getBody()[0]=0;assertArrayEquals(expected,service.image("DS123",new BigDecimal("5000"),null).getBody());
    }
    @Test void absentImageKeepsManualInstructionsButNeverInventsQr(){booking();var result=service(true,"").instructions("DS123",BigDecimal.ONE,null);assertEquals(false,result.get("qrAvailable"));assertEquals("",result.get("qrUrl"));}
    @Test void svgAndInvalidImagesAreRejected()throws Exception{Path file=folder.resolve("bank.svg");Files.writeString(file,"<svg>not a bank QR</svg>");assertThrows(IllegalStateException.class,()->service(true,file.toString()));}
    @Test void oversizedImageIsRejected()throws Exception{Path file=folder.resolve("huge.png");Files.write(file,new byte[5*1024*1024+1]);assertThrows(IllegalStateException.class,()->service(true,file.toString()));}
    @Test void disabledTransferNeverReadsConfiguredPath(){booking();var service=service(false,"does-not-exist.png");assertThrows(IllegalStateException.class,()->service.instructions("DS123",BigDecimal.ONE,null));}
}
