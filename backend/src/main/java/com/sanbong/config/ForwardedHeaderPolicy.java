package com.sanbong.config;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/** Direct/LAN origin mode: proxy trust requires a separately reviewed deployment boundary. */
@Component
public final class ForwardedHeaderPolicy implements InitializingBean {
    private final Environment environment;
    public ForwardedHeaderPolicy(Environment environment){this.environment=environment;}
    @Override public void afterPropertiesSet(){
        if(!"none".equalsIgnoreCase(environment.getProperty("server.forward-headers-strategy","none").trim()))
            throw new IllegalStateException("Forwarded headers are disabled for the direct origin. Review proxy isolation/trust before enabling framework/native forwarding.");
        for(String key:new String[]{"server.tomcat.remoteip.remote-ip-header","server.tomcat.remoteip.protocol-header","server.tomcat.remoteip.host-header","server.tomcat.remoteip.port-header"})
            if(!environment.getProperty(key,"").isBlank())throw new IllegalStateException("Tomcat forwarded-header overrides require a reviewed proxy deployment; direct origin startup refused.");
    }
}
