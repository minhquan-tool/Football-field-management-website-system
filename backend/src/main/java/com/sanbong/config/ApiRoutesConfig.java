package com.sanbong.config;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.config.annotation.*;

/** JSON endpoints keep /api; page resources are served from the application root. */
@Configuration
public class ApiRoutesConfig implements WebMvcConfigurer {
 @Override public void configurePathMatch(PathMatchConfigurer configurer){
  configurer.addPathPrefix("/api",type->type.isAnnotationPresent(RestController.class));
 }
}
