package com.sanbong;

import com.sanbong.config.InternalReadiness;
import com.sanbong.controller.HealthController;
import com.sanbong.service.RuntimeSafetyService;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import javax.sql.DataSource;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class RuntimeHardeningTest {
    @Test void unhealthyDatabaseReturns503WithoutDriverDetails() throws Exception {
        DataSource ds=mock(DataSource.class);
        when(ds.getConnection()).thenThrow(new SQLException("private driver details"));
        var response=new HealthController(ds,mock(RuntimeSafetyService.class)).health();
        assertEquals(503,response.getStatusCode().value());
        assertEquals(Map.of("status","DOWN","database","DOWN"),response.getBody());
    }
    @Test void fixturesRequireBothApplicationAndDatabaseOptIn() {
        JdbcTemplate jdbc=mock(JdbcTemplate.class);
        var env=new MockEnvironment().withProperty("app.environment","dev");
        var safety=new RuntimeSafetyService(env,jdbc);
        String query="SELECT CONVERT(nvarchar(20),value) FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment'";
        when(jdbc.queryForList(query,String.class)).thenReturn(List.of("internal"));
        assertFalse(safety.fixtureTestsAllowed());
        when(jdbc.queryForList(query,String.class)).thenReturn(List.of("test"));
        assertTrue(safety.fixtureTestsAllowed());
        env.setProperty("app.environment","internal");
        assertFalse(safety.fixtureTestsAllowed());
        env.setProperty("app.environment","dev");
        when(jdbc.queryForList(query,String.class)).thenReturn(List.of());
        assertFalse(safety.fixtureTestsAllowed());
    }
    private InternalReadiness readiness(String marker,int sysadmin,int owner,String password,boolean debug) {
        var safety=mock(RuntimeSafetyService.class);when(safety.databaseEnvironment()).thenReturn(marker);
        var jdbc=mock(JdbcTemplate.class);
        when(jdbc.queryForMap(anyString())).thenReturn(Map.of("admin",sysadmin,"owner",owner));
        when(jdbc.queryForList(anyString(),eq(String.class))).thenReturn(List.of(password));
        var env=new MockEnvironment().withProperty("spring.jpa.hibernate.ddl-auto","validate").withProperty("debug",String.valueOf(debug));
        return new InternalReadiness(safety,jdbc,env,new BCryptPasswordEncoder());
    }
    @Test void internalAcceptsScopedIdentityAndStrongHash() {
        assertDoesNotThrow(()->readiness("internal",0,0,new BCryptPasswordEncoder().encode("secure-random-7f82baf95c"),false).afterPropertiesSet());
    }
    @Test void internalRefusesDevelopmentDatabase() {
        assertThrows(IllegalStateException.class,()->readiness("dev",0,0,"unused",false).afterPropertiesSet());
    }
    @Test void internalRefusesPrivilegedRuntimeIdentity() {
        assertThrows(IllegalStateException.class,()->readiness("internal",1,0,"unused",false).afterPropertiesSet());
        assertThrows(IllegalStateException.class,()->readiness("internal",0,1,"unused",false).afterPropertiesSet());
    }
    @Test void internalRefusesDebugPlaintextAndDemoHash() {
        assertThrows(IllegalStateException.class,()->readiness("internal",0,0,"unused",true).afterPropertiesSet());
        assertThrows(IllegalStateException.class,()->readiness("internal",0,0,"plaintext",false).afterPropertiesSet());
        assertThrows(IllegalStateException.class,()->readiness("internal",0,0,new BCryptPasswordEncoder().encode("123456"),false).afterPropertiesSet());
    }
}
