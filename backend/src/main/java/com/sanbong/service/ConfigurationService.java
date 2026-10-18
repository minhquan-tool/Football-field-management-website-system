package com.sanbong.service;
import com.sanbong.dto.ConfigurationRequest;
import com.sanbong.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.util.*;
import java.time.*;
@Service
public class ConfigurationService {
    private final ConfigurationRepository repository;
    private final SecurityRepository audit;
    public ConfigurationService(ConfigurationRepository repository,SecurityRepository audit){this.repository=repository;this.audit=audit;}
    @Transactional(readOnly=true) public Map<String,Object> list(){return Map.of("types",repository.types(),"slots",repository.slots(),"hourly",repository.hourly(),"promotions",repository.promotions(),"prices",repository.prices());}
    @Transactional(isolation=Isolation.SERIALIZABLE)
    public void save(String kind,ConfigurationRequest r,String actor){
        String id=r.id();
        switch(kind){
            case "hourly" -> {
                required(r.donGia()!=null,"Cần đơn giá theo giờ hợp lệ.");
                required(repository.hourlyExists(id),"Chỉ cập nhật giá ca có sẵn; giữ nguyên khoảng 07:00–22:00.");
                repository.hourlyPrice(id,r.donGia());
            }
            case "types" -> {
                required(r.ten()!=null&&!r.ten().isBlank()&&r.ten().length()<=50&&r.soNguoi()!=null,"Cần tên loại sân tối đa 50 ký tự và số người.");
                repository.saveType(r);
            }
            case "slots" -> {
                required(r.batDau()!=null&&r.ketThuc()!=null&&r.batDau().isBefore(r.ketThuc())&&r.batDau().getSecond()==0&&r.ketThuc().getSecond()==0&&r.batDau().getNano()==0&&r.ketThuc().getNano()==0,"Giờ bắt đầu/kết thúc phải hợp lệ theo phút.");
                required(!repository.slotUsed(id),"Khung giờ đã được dùng: giữ nguyên lịch sử, tạo mã mới.");
                required(!repository.slotOverlaps(r),"Khung giờ bị chồng lấn.");
                var duration=java.math.BigDecimal.valueOf(Duration.between(r.batDau(),r.ketThuc()).toMinutes()).divide(java.math.BigDecimal.valueOf(60),2,java.math.RoundingMode.HALF_UP);
                repository.saveSlot(r,duration);
            }
            case "promotions" -> {
                required(r.ten()!=null&&!r.ten().isBlank()&&r.donGia()!=null&&r.donGia().compareTo(java.math.BigDecimal.valueOf(100))<=0&&r.tuNgay()!=null&&r.denNgay()!=null&&!r.denNgay().isBefore(r.tuNgay())&&r.hoatDong()!=null,"Khuyến mãi phần trăm 0–100, tên và ngày áp dụng hợp lệ là bắt buộc.");
                var old=repository.promotionType(id);
                if(old.isEmpty())repository.createPromotion(r);
                else {
                    required("Phần trăm".equals(old.get()),"Giữ nguyên khuyến mãi số tiền legacy; tạo mã phần trăm mới.");
                    required(!repository.promotionUsed(id),"Khuyến mãi đã sử dụng: không sửa chính sách lịch sử, tạo mã mới.");
                    repository.updatePromotion(r);
                }
            }
            case "promotion-status" -> {
                required(r.hoatDong()!=null,"Cần chọn trạng thái khuyến mãi.");
                required(repository.promotionActive(id,r.hoatDong()),"Khuyến mãi không tồn tại.");
            }
            case "prices" -> {
                required(r.loaiSan()!=null&&r.khungGio()!=null&&Set.of("Ngày thường","Cuối tuần","Ngày lễ").contains(Objects.toString(r.loaiNgay(),""))&&r.donGia()!=null&&r.tuNgay()!=null&&(r.denNgay()==null||!r.denNgay().isBefore(r.tuNgay())),"Cần loại sân, khung giờ, loại ngày, giá và hiệu lực hợp lệ.");
                required(!repository.priceExists(id),"Bảng giá legacy chỉ thêm mã mới, không ghi đè snapshot.");
                required(!repository.priceOverlaps(r),"Khoảng hiệu lực bảng giá chồng lấn.");
                repository.createPrice(r);
            }
            default -> throw new IllegalArgumentException("Danh mục không được hỗ trợ.");
        }
        audit.audit(actor,"Sửa","Cấu hình "+kind+" "+id+"; giữ nguyên snapshot lịch sử");
    }
    private static void required(boolean valid,String message){if(!valid)throw new IllegalArgumentException(message);}
}
