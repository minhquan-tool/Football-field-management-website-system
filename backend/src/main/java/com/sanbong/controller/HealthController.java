package com.sanbong.controller;
import com.sanbong.service.RuntimeSafetyService;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import javax.sql.DataSource;
import java.util.Map;
@RestController
public class HealthController {
 private final DataSource source;private final RuntimeSafetyService safety;
 public HealthController(DataSource source,RuntimeSafetyService safety){this.source=source;this.safety=safety;}
 @GetMapping("/health") public ResponseEntity<?> health(){
  try(var connection=source.getConnection();var statement=connection.createStatement()){
   statement.setQueryTimeout(2);try(var result=statement.executeQuery("SELECT 1")){if(result.next())return ResponseEntity.ok(Map.of("status","UP","database","UP"));}
  }catch(Exception ignored){}return ResponseEntity.status(503).body(Map.of("status","DOWN","database","DOWN"));
 }
 @GetMapping("/admin/test-safety") @PreAuthorize("hasRole('ADMIN')")
 public Map<String,Object> tests(){return Map.of("fixtureTestsAllowed",safety.fixtureTestsAllowed(),"databaseName",safety.databaseName());}
}
