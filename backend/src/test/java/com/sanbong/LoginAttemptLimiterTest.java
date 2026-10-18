package com.sanbong;

import com.sanbong.security.LoginAttemptLimiter;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicLong;
import static org.junit.jupiter.api.Assertions.*;

class LoginAttemptLimiterTest {
    final AtomicLong now=new AtomicLong();
    LoginAttemptLimiter limiter(int pair,int ip,int capacity){return new LoginAttemptLimiter(pair,ip,300,capacity,now::get);}
    void fail(LoginAttemptLimiter limiter,String ip,String id){var a=limiter.acquire(ip,id);assertTrue(a.allowed());limiter.complete(a.attempt(),false,true);}
    @Test void blocksAtThresholdAndRecoversAtExactWindowBoundary(){
        var l=limiter(5,30,100);for(int i=0;i<5;i++)fail(l,"peer","user");
        assertEquals(300,l.acquire("peer","user").retryAfterSeconds());now.set(299001);assertEquals(1,l.acquire("peer","user").retryAfterSeconds());
        now.set(300000);assertTrue(l.acquire("peer","user").allowed());
    }
    @Test void caseAndOuterWhitespaceDoNotBypassIdentifierLimit(){
        var l=limiter(1,30,100);fail(l,"peer"," Quan_Da ");assertFalse(l.acquire("peer","quan_da").allowed());
    }
    @Test void ipBudgetStopsUsernameRotationAndSuccessDoesNotEraseIt(){
        var l=limiter(2,3,100);fail(l,"peer","a");fail(l,"peer","b");
        var success=l.acquire("peer","c");l.complete(success.attempt(),true,false);fail(l,"peer","d");
        assertFalse(l.acquire("peer","different").allowed());assertTrue(l.acquire("another-peer","different").allowed());
    }
    @Test void successfulLoginResetsOnlyItsPair(){
        var l=limiter(2,30,100);fail(l,"peer","user");var success=l.acquire("peer","user");l.complete(success.attempt(),true,false);
        fail(l,"peer","user");assertTrue(l.acquire("peer","user").allowed());
    }
    @Test void concurrentRequestsReserveSlotsBeforePasswordWork()throws Exception{
        var l=limiter(2,30,100);var ready=new CountDownLatch(12);var start=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(12);
        try{var futures=new ArrayList<Future<LoginAttemptLimiter.Admission>>();for(int i=0;i<12;i++)futures.add(pool.submit(()->{ready.countDown();assertTrue(start.await(5,TimeUnit.SECONDS));return l.acquire("peer","user");}));
            assertTrue(ready.await(5,TimeUnit.SECONDS));start.countDown();var admitted=new ArrayList<LoginAttemptLimiter.Admission>();
            for(var future:futures){var result=future.get(5,TimeUnit.SECONDS);if(result.allowed())admitted.add(result);}
            assertEquals(2,admitted.size());admitted.forEach(a->l.complete(a.attempt(),false,false));assertTrue(l.acquire("peer","user").allowed());
        }finally{start.countDown();pool.shutdownNow();assertTrue(pool.awaitTermination(5,TimeUnit.SECONDS));}
    }
    @Test void completionIsIdempotentAndInfrastructureErrorsReleaseReservation(){
        var l=limiter(1,30,100);for(int i=0;i<10;i++){var a=l.acquire("peer","user");assertTrue(a.allowed());l.complete(a.attempt(),false,false);l.complete(a.attempt(),false,false);}
        var next=l.acquire("peer","user");assertTrue(next.allowed());assertFalse(l.acquire("peer","user").allowed());
    }
    @Test void boundedCapacityRejectsNewKeysWithoutEvictingBlockedKeys(){
        var l=limiter(1,30,4);fail(l,"peer-a","a");fail(l,"peer-b","b");
        assertFalse(l.acquire("peer-c","c").allowed());assertFalse(l.acquire("peer-a","a").allowed());
        now.set(300000);assertTrue(l.acquire("peer-c","c").allowed());
    }
    @Test void expiredWindowCannotEvictAnAttemptStillInFlight(){
        var l=limiter(1,30,100);var first=l.acquire("peer","user");now.set(300000);assertFalse(l.acquire("peer","user").allowed());l.complete(first.attempt(),false,true);assertTrue(l.acquire("peer","user").allowed());
    }
    @ParameterizedTest @CsvSource({"0,30,300,100","5,4,300,100","5,30,0,100","5,30,300,1","5,30,300,100001"})
    void invalidConfigurationFailsClosed(int pair,int ip,int seconds,int capacity){assertThrows(IllegalArgumentException.class,()->new LoginAttemptLimiter(pair,ip,seconds,capacity,now::get));}
}
