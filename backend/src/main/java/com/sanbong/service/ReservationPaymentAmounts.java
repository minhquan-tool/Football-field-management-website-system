package com.sanbong.service;
import java.math.*;
import java.util.Map;
/** Presentation choices and payment validation share the same server-side amounts. */
public final class ReservationPaymentAmounts {
 private ReservationPaymentAmounts() {}
 public static Map<String,BigDecimal> options(BigDecimal total,BigDecimal paid) {
  var remaining=total.subtract(paid).max(BigDecimal.ZERO);
  // Integer VND: never round below the required 40%; never charge above the balance.
  var deposit=total.multiply(new BigDecimal("0.40")).setScale(0,RoundingMode.CEILING).subtract(paid).max(BigDecimal.ZERO).min(remaining);
  return Map.of("DEPOSIT_40",deposit,"FULL",remaining);
 }
 public static void validate(BigDecimal total,BigDecimal paid,String plan,BigDecimal amount){
  var expected=options(total,paid).get(plan==null?"":plan);
  if(expected==null||expected.signum()<=0||amount==null||amount.compareTo(expected)!=0)
   throw new IllegalArgumentException("Mức thanh toán đã thay đổi hoặc không hợp lệ. Vui lòng mở lại lượt đặt và chọn cọc 40% hoặc trả đủ.");
 }
}
