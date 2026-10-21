package com.sanbong;
import com.sanbong.service.ReservationPaymentAmounts;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
class ReservationPaymentAmountsTest {
 BigDecimal n(String n){return new BigDecimal(n);}
 @Test void fortyPercentUsesNetTotalIncludingServices(){var options=ReservationPaymentAmounts.options(n("375000"),BigDecimal.ZERO);assertEquals(0,n("150000").compareTo(options.get("DEPOSIT_40")));assertEquals(0,n("375000").compareTo(options.get("FULL")));}
 @Test void subtractsConfirmedPaymentsAndStopsRepeatingDeposit(){var o=ReservationPaymentAmounts.options(n("375000"),n("100000"));assertEquals(0,n("50000").compareTo(o.get("DEPOSIT_40")));assertEquals(0,n("275000").compareTo(o.get("FULL")));assertEquals(0,ReservationPaymentAmounts.options(n("375000"),n("150000")).get("DEPOSIT_40").signum());}
 @Test void roundsDepositUpToVndWithoutExceedingBalance(){assertEquals(0,n("36001").compareTo(ReservationPaymentAmounts.options(n("90001"),BigDecimal.ZERO).get("DEPOSIT_40")));assertEquals(0,n("0.50").compareTo(ReservationPaymentAmounts.options(n("0.50"),BigDecimal.ZERO).get("DEPOSIT_40")));}
 @Test void rejectsTamperingMissingPlanAndStaleAmounts(){for(String plan:new String[]{null,"OTHER","DEPOSIT_40","FULL"})assertThrows(IllegalArgumentException.class,()->ReservationPaymentAmounts.validate(n("90000"),BigDecimal.ZERO,plan,n("1")));assertDoesNotThrow(()->ReservationPaymentAmounts.validate(n("90000"),BigDecimal.ZERO,"DEPOSIT_40",n("36000")));assertThrows(IllegalArgumentException.class,()->ReservationPaymentAmounts.validate(n("90000"),n("36000"),"DEPOSIT_40",n("36000")));}
}
