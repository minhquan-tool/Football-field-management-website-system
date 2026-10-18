package com.sanbong.service;
import org.springframework.stereotype.Service;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.Set;
@Service
public class RuntimeSafetyService {
 private final Environment env;private final JdbcTemplate jdbc;
 public RuntimeSafetyService(Environment env,JdbcTemplate jdbc){this.env=env;this.jdbc=jdbc;}
 public String databaseEnvironment(){return jdbc.queryForList("SELECT CONVERT(nvarchar(20),value) FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment'",String.class).stream().findFirst().orElse("");}
 public String databaseName(){return jdbc.queryForObject("SELECT DB_NAME()",String.class);}
 public boolean fixtureTestsAllowed(){return Set.of("dev","test").contains(env.getProperty("app.environment",""))&&Set.of("dev","test").contains(databaseEnvironment());}
}
