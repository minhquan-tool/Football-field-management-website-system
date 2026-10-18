package com.sanbong.config;
import com.sanbong.service.AuthService;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;

@Configuration
public class LegacyPasswordMigration {
    @Bean
    @ConditionalOnProperty(name="app.security.migrate-legacy-passwords",havingValue="true")
    ApplicationRunner migratePasswords(AuthService service) {
        return args -> service.migrateLegacyPasswords();
    }
}
