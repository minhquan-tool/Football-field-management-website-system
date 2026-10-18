package com.sanbong;
import com.sanbong.config.ForwardedHeaderPolicy;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.mock.env.MockEnvironment;
import static org.junit.jupiter.api.Assertions.*;

class ForwardedHeaderPolicyTest {
 @Test void directOriginDefaultsAndExplicitNoneAreAccepted(){
  assertDoesNotThrow(()->new ForwardedHeaderPolicy(new MockEnvironment()).afterPropertiesSet());
  assertDoesNotThrow(()->new ForwardedHeaderPolicy(new MockEnvironment().withProperty("server.forward-headers-strategy","NONE")).afterPropertiesSet());
 }
 @ParameterizedTest @ValueSource(strings={"framework","native"})
 void forwardingCannotSilentlyChangeLoginLimiterPeer(String strategy){assertThrows(IllegalStateException.class,()->new ForwardedHeaderPolicy(new MockEnvironment().withProperty("server.forward-headers-strategy",strategy)).afterPropertiesSet());}
 @ParameterizedTest @ValueSource(strings={"remote-ip-header","protocol-header","host-header","port-header"})
 void tomcatHeaderOverrideCannotBypassDirectOriginPolicy(String header){assertThrows(IllegalStateException.class,()->new ForwardedHeaderPolicy(new MockEnvironment().withProperty("server.tomcat.remoteip."+header,"X-Unreviewed-Header")).afterPropertiesSet());}
}
