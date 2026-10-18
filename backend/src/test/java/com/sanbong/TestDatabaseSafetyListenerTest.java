package com.sanbong;

import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationContext;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestContext;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TestDatabaseSafetyListenerTest {
    @AuditCleanupFixture static class CommittedFixture {}
    static class RollbackFixture {}
    void checkIdentity(Map<String,Object> rights,boolean accept) {
        var context=mock(TestContext.class);var application=mock(ApplicationContext.class);var jdbc=mock(JdbcTemplate.class);
        doReturn(CommittedFixture.class).when(context).getTestClass();
        when(context.getApplicationContext()).thenReturn(application);when(application.getBean(JdbcTemplate.class)).thenReturn(jdbc);
        when(jdbc.queryForMap(anyString())).thenReturn(rights);
        if(accept)assertDoesNotThrow(()->TestDatabaseSafetyListener.validateAuditCleanupIdentity(context));
        else assertThrows(IllegalStateException.class,()->TestDatabaseSafetyListener.validateAuditCleanupIdentity(context));
        verify(jdbc,never()).update(anyString());
    }
    @Test void runtimeIsRejectedEvenIfSomeoneRegrantsDelete(){checkIdentity(Map.of("identityName","SanBongApp","canDeleteAudit",1),false);}
    @Test void protectedRuntimeIsRejectedBeforeFixtures(){checkIdentity(Map.of("identityName","SanBongApp","canDeleteAudit",0),false);}
    @Test void fixtureIdentityWithoutCleanupPermissionIsRejected(){checkIdentity(Map.of("identityName","DisposableFixture","canDeleteAudit",0),false);}
    @Test void unknownIdentityOrPermissionFailsClosed(){checkIdentity(Map.of(),false);}
    @Test void dedicatedFixtureCanProceedToItsExistingDevTestGuard(){checkIdentity(Map.of("identityName","DisposableFixture","canDeleteAudit",1,"disposableFixture",1),true);}
    @Test void broadWriterOnOrdinaryDevDatabaseCannotRunCommittedCleanup(){checkIdentity(Map.of("identityName","DisposableFixture","canDeleteAudit",1),false);}
    @Test void rollbackSuitesDoNotNeedCleanupPrivileges(){var context=mock(TestContext.class);doReturn(RollbackFixture.class).when(context).getTestClass();assertDoesNotThrow(()->TestDatabaseSafetyListener.validateAuditCleanupIdentity(context));verify(context,never()).getApplicationContext();}
    @Test void legacyCleanupSuitesAreExplicitlyMarked(){for(Class<?> type:List.of(BookingConcurrencyTest.class,CheckoutSnapshotTest.class,FinanceIntegrationTest.class,FutureBookingAvailabilityTest.class,OperationsConcurrencyTest.class,Phase6IntegrationTest.class,WalkInCustomerTest.class))assertTrue(type.isAnnotationPresent(AuditCleanupFixture.class),type.getSimpleName());}
}
