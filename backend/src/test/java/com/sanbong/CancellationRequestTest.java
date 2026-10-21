package com.sanbong;
import com.sanbong.config.AccountPrincipal;
import com.sanbong.model.*;
import com.sanbong.repository.*;
import com.sanbong.service.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CancellationRequestTest {
 CancellationRequestRepository requests=mock(CancellationRequestRepository.class);
 DatSanRepository bookings=mock(DatSanRepository.class);SanRepository pitches=mock(SanRepository.class);
 TaiKhoanRepository accounts=mock(TaiKhoanRepository.class);BookingWorkflowRepository workflow=mock(BookingWorkflowRepository.class);
 FinanceRepository ledger=mock(FinanceRepository.class);FinanceService finance=mock(FinanceService.class);SecurityRepository audit=mock(SecurityRepository.class);
 Clock clock=Clock.fixed(Instant.parse("2026-10-21T00:00:00Z"),ZoneOffset.UTC);
 CancellationRequestService service=new CancellationRequestService(requests,bookings,pitches,accounts,workflow,ledger,finance,audit,clock);
 AccountPrincipal customer=mock(AccountPrincipal.class),reviewer=mock(AccountPrincipal.class);DatSan d=new DatSan();
 Map<String,Object> row=new HashMap<>();
 BigDecimal n(String s){return new BigDecimal(s);}
 @BeforeEach void setup(){ReflectionTestUtils.setField(service,"em",mock(EntityManager.class));when(requests.ready()).thenReturn(true);when(customer.roleId()).thenReturn("VT01");when(customer.accountId()).thenReturn("KH_ACC");when(reviewer.roleId()).thenReturn("VT03");when(reviewer.accountId()).thenReturn("KT_ACC");
  var kh=new KhachHang();kh.setMaKH("KH1");var ca=new TaiKhoan();ca.setKhachHang(kh);when(accounts.findById("KH_ACC")).thenReturn(Optional.of(ca));var employee=new NhanVien();employee.setTrangThai(true);var ea=new TaiKhoan();ea.setNhanVien(employee);when(accounts.findById("KT_ACC")).thenReturn(Optional.of(ea));
  var pitch=new San();pitch.setMaSan("S1");d.setMaDatSan("DS1");d.setSan(pitch);d.setKhachHang(kh);d.setTrangThai("Đã xác nhận");d.setNgayChoi(LocalDate.of(2026,10,22));d.setGioBatDau(LocalTime.of(10,0));when(bookings.findById("DS1")).thenReturn(Optional.of(d));when(bookings.lockById("DS1")).thenReturn(Optional.of(d));when(pitches.lockById("S1")).thenReturn(Optional.of(pitch));
  when(ledger.paid("DS1")).thenReturn(n("200000"));when(ledger.refunded("DS1")).thenReturn(BigDecimal.ZERO);when(ledger.rate(any(),any())).thenReturn(n("50"));when(ledger.invoice("DS1")).thenReturn(Optional.of(Map.of()));
  row.put("maYeuCau","YC1");row.put("maDatSan","DS1");row.put("trangThai","PENDING");row.put("lyDo","Khách bận");row.put("tiLeHoan",n("50"));when(requests.find("YC1")).thenReturn(Optional.of(row));when(requests.create(anyString(),anyString(),anyString(),any(),any(),any(),any())).thenReturn("YC1");
 }
 @Test void submittingKeepsPitchOccupiedAndSnapshotsRate(){service.submit("DS1"," Khách bận ",customer);assertEquals("Đã xác nhận",d.getTrangThai());verify(requests).create(eq("DS1"),eq("KH_ACC"),eq("Khách bận"),eq(n("50")),eq(n("200000")),eq(n("100000.00")),any());verifyNoInteractions(finance);var ordered=inOrder(pitches,bookings,requests);ordered.verify(pitches).lockById("S1");ordered.verify(bookings).lockById("DS1");ordered.verify(requests).pending("DS1");}
 @Test void duplicateSubmissionReturnsExistingWithoutCreatingAnother(){when(requests.pending("DS1")).thenReturn(Optional.of(row));assertSame(row,service.submit("DS1","Lặp",customer));verify(requests,never()).create(any(),any(),any(),any(),any(),any(),any());}
 @Test void crossCustomerCannotReadOrLockOthersBooking(){var other=new KhachHang();other.setMaKH("OTHER");d.setKhachHang(other);assertThrows(AccessDeniedException.class,()->service.submit("DS1","Lý do",customer));verify(pitches,never()).lockById(any());}
 @Test void staffCannotSubmitOrDecide(){when(customer.roleId()).thenReturn("VT02");assertThrows(AccessDeniedException.class,()->service.submit("DS1","Lý do",customer));assertThrows(AccessDeniedException.class,()->service.decide("YC1",true,"Duyệt",customer));}
 @Test void checkedInOrPastBookingCannotSubmit(){when(workflow.hasCheckIn("DS1")).thenReturn(true);assertThrows(IllegalStateException.class,()->service.submit("DS1","Lý do",customer));when(workflow.hasCheckIn("DS1")).thenReturn(false);d.setNgayChoi(LocalDate.of(2026,10,20));assertThrows(IllegalStateException.class,()->service.submit("DS1","Lý do",customer));}
 @Test void approvalUsesSavedRateEvenAfterStartWithoutCheckIn(){d.setNgayChoi(LocalDate.of(2026,10,20));when(ledger.cancellation("DS1")).thenReturn(Optional.of(Map.of("maHuy","HY1")));service.decide("YC1",true,"Đã đối chiếu",reviewer);verify(finance).cancelRequestedLocked(d,"Khách bận",n("50"),reviewer);verify(ledger,never()).rate(any(),any());verify(requests).resolve(eq("YC1"),eq("APPROVED"),eq("KT_ACC"),eq("Đã đối chiếu"),eq("HY1"),any());assertEquals("Đã hủy",d.getTrangThai());}
 @Test void rejectingKeepsBookingAndMoneyUnchanged(){service.decide("YC1",false,"Khách tiếp tục sử dụng",reviewer);assertEquals("Đã xác nhận",d.getTrangThai());verifyNoInteractions(finance);verify(requests).resolve(eq("YC1"),eq("REJECTED"),eq("KT_ACC"),anyString(),isNull(),any());}
 @Test void repeatApprovalDoesNotCancelOrRefundTwice(){row.put("trangThai","APPROVED");service.decide("YC1",true,"Lặp",reviewer);verifyNoInteractions(finance);verify(requests,never()).resolve(any(),any(),any(),any(),any(),any());assertThrows(IllegalStateException.class,()->service.decide("YC1",false,"Khác",reviewer));}
 @Test void checkedInBookingCannotBeApprovedButCanBeRejected(){when(workflow.hasCheckIn("DS1")).thenReturn(true);assertThrows(IllegalStateException.class,()->service.decide("YC1",true,"Duyệt",reviewer));service.decide("YC1",false,"Đã nhận sân",reviewer);verifyNoInteractions(finance);}
 @Test void invalidNotesAndMissingSchemaNeverCreateRequests(){assertThrows(IllegalArgumentException.class,()->service.submit("DS1"," ",customer));when(requests.ready()).thenReturn(false);assertThrows(IllegalStateException.class,()->service.submit("DS1","Lý do",customer));verify(requests,never()).create(any(),any(),any(),any(),any(),any(),any());}
 @Test void customerHistoryIsAlwaysScopedToAccount(){when(requests.list("KH_ACC","",1)).thenReturn(List.of());service.list(customer,"",1);verify(requests).list("KH_ACC","",1);assertThrows(IllegalArgumentException.class,()->service.list(customer,"BAD",1));}
 @Test void estimateNeverExceedsNetAndRejectsInvalidValues(){assertEquals(n("45000.00"),CancellationRequestService.estimate(n("90000"),n("50")));assertEquals(n("0.00"),CancellationRequestService.estimate(BigDecimal.ZERO,n("100")));assertThrows(IllegalStateException.class,()->CancellationRequestService.estimate(n("-1"),n("50")));assertThrows(IllegalStateException.class,()->CancellationRequestService.estimate(n("1"),n("101")));}
 @Test void financeRecomputesRefundFromCurrentNetAtSavedRate(){
  var actual=new FinanceService(ledger,bookings,pitches,accounts,audit,clock);d.setTienSan(n("250000"));d.setTienDichVu(BigDecimal.ZERO);d.setTienGiam(BigDecimal.ZERO);d.setTongTien(n("250000"));
  when(ledger.invoice("DS1")).thenReturn(Optional.of(Map.of("daChot",true,"tongTien",n("250000"))));when(ledger.refunded("DS1")).thenReturn(n("50000"));when(ledger.payments("DS1")).thenReturn(List.of(Map.of("maTT","TT1","soTien",n("200000"),"trangThai","Thành công","phuongThuc","Chuyển khoản")));when(ledger.refundedPayment("TT1")).thenReturn(n("50000"));when(ledger.cancel(eq("DS1"),any(),eq(true),any(),any(),any(),any())).thenReturn("HY1");
  actual.cancelRequestedLocked(d,"Khách bận",n("50"),reviewer);
  verify(ledger).cancel(eq("DS1"),eq("Khách bận"),eq(true),eq(n("50")),eq(n("150000")),eq(n("75000.00")),any());verify(ledger).refundCreate(eq("TT1"),eq("HY1"),eq(n("75000.00")),eq("Chuyển khoản"),any(),any());verify(ledger,never()).rate(any(),any());verify(ledger,never()).refundConfirm(any(),any(),any(),any(),any());
 }
}
