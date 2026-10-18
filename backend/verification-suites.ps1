function Get-SanBongVerificationTests {
 param([ValidateSet('runtime','fixtures')][string]$Suite='runtime')
 if($Suite -eq 'fixtures'){
  return 'BookingConcurrencyTest,CheckoutSnapshotTest,FinanceIntegrationTest,FutureBookingAvailabilityTest,OperationsConcurrencyTest,Phase6IntegrationTest,WalkInCustomerTest'
 }
 return 'ForwardedHeaderPolicyTest,LoginRateLimitHttpTest,RuntimePermissionsTest,LocalAssetsHttpTest,TestDatabaseSafetyListenerTest,AuditIntegrityTest,CustomerPromotionTest,PaymentQrFlowTest,StaffRoleAuditTest,AccountantRoleAuditTest,AdminRoleAuditTest,CustomerJourneyIntegrationTest,RoleBoundaryTest,WeeklyScheduleTest'
}
function Assert-SanBongVerificationProfile {
 param([ValidateSet('runtime','fixtures')][string]$Suite='runtime')
 if($env:SAN_BONG_TEST_MODE -notin @('dev','test')){throw 'Explicit SAN_BONG_TEST_MODE dev/test required'}
 if($Suite -eq 'fixtures' -and ($env:APP_DB_USER -notlike 'SanBongFixture_*' -or $env:SQLCMD_TEST_DATABASE -notlike 'QuanLySanBong_Fixtures_*')){throw 'Committed tests need a disposable fixture profile, never the web runtime profile'}
 if($Suite -eq 'runtime' -and $env:APP_DB_USER -ne 'SanBongApp'){throw 'Runtime verification must use the actual protected SanBongApp identity'}
}
