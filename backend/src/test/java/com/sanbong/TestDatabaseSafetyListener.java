package com.sanbong;
import org.springframework.test.context.TestContext;
import org.springframework.test.context.support.AbstractTestExecutionListener;
import com.sanbong.service.RuntimeSafetyService;
/** Global test guard runs before fixture setup, including existing Phase1–6 suites. */
public class TestDatabaseSafetyListener extends AbstractTestExecutionListener {
 @Override public void beforeTestClass(TestContext context){
  if(!java.util.Set.of("dev","test").contains(System.getenv().getOrDefault("SAN_BONG_TEST_MODE","")))throw new IllegalStateException("Set SAN_BONG_TEST_MODE=dev/test explicitly before fixture tests.");
  if(!context.getApplicationContext().getBean(RuntimeSafetyService.class).fixtureTestsAllowed())throw new IllegalStateException("Fixture tests refused: target is not classified dev/test.");
  validateAuditCleanupIdentity(context);
 }
 static void validateAuditCleanupIdentity(TestContext context){
  if(!context.getTestClass().isAnnotationPresent(AuditCleanupFixture.class))return;
  var jdbc=context.getApplicationContext().getBean(org.springframework.jdbc.core.JdbcTemplate.class);
  var rights=jdbc.queryForMap("SELECT CURRENT_USER AS identityName,HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'DELETE') AS canDeleteAudit,(SELECT TRY_CONVERT(int,value) FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase') AS disposableFixture");
  if(!(rights.get("identityName") instanceof String identity)||identity.equalsIgnoreCase("SanBongApp")
      ||!(rights.get("canDeleteAudit") instanceof Number allowed)||allowed.intValue()!=1
      ||!(rights.get("disposableFixture") instanceof Number disposable)||disposable.intValue()!=1)
   throw new IllegalStateException("Committed audit-cleanup fixtures refused before setup: use a separate disposable DEV/test database and fixture identity; never grant audit DELETE to the web runtime. Use rollback-based suites with SanBongApp.");
 }
}
