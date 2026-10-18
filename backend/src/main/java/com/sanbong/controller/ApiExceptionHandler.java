package com.sanbong.controller;
import com.sanbong.dto.ApiResponse;
import org.slf4j.*;
import org.springframework.dao.DataAccessException;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.http.converter.HttpMessageNotReadableException;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(org.springframework.web.HttpRequestMethodNotSupportedException.class)
    ResponseEntity<?> unsupportedMethod(Exception e) {
        return ResponseEntity.status(405).body(ApiResponse.error("Thao tác này không được hỗ trợ."));
    }
    @ExceptionHandler({com.sanbong.service.PitchNotFoundException.class,com.sanbong.service.BookingNotFoundException.class})
    ResponseEntity<?> notFound(Exception e) {
        return ResponseEntity.status(404).body(ApiResponse.error(e.getMessage()));
    }
    private static final Logger log=LoggerFactory.getLogger(ApiExceptionHandler.class);
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<?> invalidFields(MethodArgumentNotValidException e) {
        // Describe constraints, never serialize rejected values (especially passwords).
        var errors=new java.util.TreeMap<String,String>();
        var labels=java.util.Map.ofEntries(
                java.util.Map.entry("hoTen","Họ tên"),java.util.Map.entry("soDienThoai","Số điện thoại"),
                java.util.Map.entry("email","Email"),java.util.Map.entry("diaChi","Địa chỉ"),
                java.util.Map.entry("tenDangNhap","Tên đăng nhập"),java.util.Map.entry("matKhau","Mật khẩu"),
                java.util.Map.entry("matKhauHienTai","Mật khẩu hiện tại"),java.util.Map.entry("matKhauMoi","Mật khẩu mới"),
                java.util.Map.entry("xacNhanMatKhau","Xác nhận mật khẩu"));
        for(var error:e.getBindingResult().getFieldErrors()) {
            String label=labels.getOrDefault(error.getField(),"Trường "+error.getField());
            String message=switch(error.getCode()==null?"":error.getCode()) {
                case "NotBlank","NotNull","NotEmpty" -> label+": vui lòng nhập đầy đủ.";
                case "Email" -> label+": địa chỉ email không hợp lệ.";
                case "Size" -> label+": độ dài không hợp lệ.";
                default -> label+": định dạng hoặc giá trị không hợp lệ.";
            };
            if("tenDangNhap".equals(error.getField()) && "Pattern".equals(error.getCode()))
                message="Tên đăng nhập: dùng 3–50 ký tự không dấu gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang; không có khoảng trắng.";
            if("soDienThoai".equals(error.getField()) && "Pattern".equals(error.getCode()))
                message=error.getDefaultMessage();
            if("matKhau".equals(error.getField()) && "Size".equals(error.getCode()))
                message="Mật khẩu phải có 10–72 ký tự và tối đa 72 byte UTF-8.";
            errors.putIfAbsent(error.getField(),message);
        }
        return ResponseEntity.badRequest().body(new ApiResponse<>(false,String.join(" ",errors.values()),java.util.Map.of("fieldErrors",errors)));
    }
    @ExceptionHandler({IllegalArgumentException.class,
            HandlerMethodValidationException.class,HttpMessageNotReadableException.class,
            org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class,
            org.springframework.web.bind.MissingServletRequestParameterException.class})
    ResponseEntity<?> invalid(Exception e) {
        String message=e instanceof IllegalArgumentException ? e.getMessage() : "Dữ liệu gửi lên không hợp lệ.";
        return ResponseEntity.badRequest().body(ApiResponse.error(message));
    }
    @ExceptionHandler({IllegalStateException.class,com.sanbong.service.AmbiguousServiceLineException.class})
    ResponseEntity<?> conflict(RuntimeException e) {
        return ResponseEntity.status(409).body(ApiResponse.error(e.getMessage()));
    }
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    ResponseEntity<?> duplicate(Exception e) {
        return ResponseEntity.status(409).body(ApiResponse.error("Dữ liệu bị trùng hoặc vi phạm ràng buộc."));
    }
    @ExceptionHandler(org.springframework.dao.PessimisticLockingFailureException.class)
    ResponseEntity<?> concurrent(Exception e) {
        return ResponseEntity.status(409).body(ApiResponse.error("Dữ liệu đang được cập nhật bởi yêu cầu khác. Tra cứu lại và thử lại."));
    }
    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<?> forbidden(Exception e) {
        return ResponseEntity.status(403).body(ApiResponse.error("Bạn không có quyền thực hiện thao tác này."));
    }
    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<?> unavailable(Exception e) {
        log.error("Database operation failed type={}",e.getClass().getSimpleName());
        if(e instanceof DataAccessException data && data.getMostSpecificCause() instanceof java.sql.SQLException sql)
            log.error("SQL error code={} state={}",sql.getErrorCode(),sql.getSQLState());
        return ResponseEntity.status(503).body(ApiResponse.error("Database tạm thời không khả dụng."));
    }
    @ExceptionHandler(Exception.class)
    ResponseEntity<?> unexpected(Exception e) {
        log.error("API operation failed type={}",e.getClass().getSimpleName());
        return ResponseEntity.internalServerError().body(ApiResponse.error("Không thể hoàn tất thao tác."));
    }
}
