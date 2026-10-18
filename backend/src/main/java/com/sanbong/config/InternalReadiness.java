package com.sanbong.config;
import com.sanbong.service.RuntimeSafetyService;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.sanbong.security.PasswordPolicy;
@Component @Profile("internal")
public class InternalReadiness implements InitializingBean {
 private final RuntimeSafetyService safety;private final JdbcTemplate jdbc;private final Environment env;private final PasswordEncoder encoder;
 public InternalReadiness(RuntimeSafetyService safety,JdbcTemplate jdbc,Environment env,PasswordEncoder encoder){this.safety=safety;this.jdbc=jdbc;this.env=env;this.encoder=encoder;}
 public void afterPropertiesSet(){
  if(!"internal".equals(safety.databaseEnvironment()))throw new IllegalStateException("Internal startup requires a database explicitly marked internal.");
  if(!"validate".equals(env.getProperty("spring.jpa.hibernate.ddl-auto"))||env.getProperty("app.security.migrate-legacy-passwords",Boolean.class,false)||env.getProperty("debug",Boolean.class,false))throw new IllegalStateException("Internal startup requires validate, no password migration and no debug.");
  var privileges=jdbc.queryForMap("SELECT IS_SRVROLEMEMBER('sysadmin') admin,IS_MEMBER('db_owner') owner");
  if(((Number)privileges.get("admin")).intValue()!=0||((Number)privileges.get("owner")).intValue()!=0)throw new IllegalStateException("Internal runtime database identity must not be sysadmin/db_owner.");
  for(String hash:jdbc.queryForList("SELECT MatKhau FROM TaiKhoan WHERE TrangThai=N'Hoạt động'",String.class)){
   PasswordPolicy.validateStoredHash(hash,encoder);
  }
 }
}
