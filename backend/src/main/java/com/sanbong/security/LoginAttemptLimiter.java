package com.sanbong.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.function.LongSupplier;

/** Bounded, single-server login protection. Never stores passwords or raw identifiers/IPs. */
public final class LoginAttemptLimiter {
    private final int pairLimit,ipLimit,maxEntries;
    private final long windowMillis;
    private final LongSupplier clock;
    private final Map<String,Bucket> buckets=new HashMap<>();
    private long lastSweep;
    private static final class Bucket {
        final long expiresAt;
        int failures,inFlight;
        Bucket(long expiresAt){this.expiresAt=expiresAt;}
    }
    public static final class Attempt {
        private final Bucket pair,ip;
        private boolean completed;
        private Attempt(Bucket pair,Bucket ip){this.pair=pair;this.ip=ip;}
    }
    public record Admission(Attempt attempt,int retryAfterSeconds) {
        public boolean allowed(){return attempt!=null;}
    }
    public LoginAttemptLimiter(int pairLimit,int ipLimit,int windowSeconds,int maxEntries){
        this(pairLimit,ipLimit,windowSeconds,maxEntries,()->System.nanoTime()/1_000_000);
    }
    public LoginAttemptLimiter(int pairLimit,int ipLimit,int windowSeconds,int maxEntries,LongSupplier clock){
        if(pairLimit<1||pairLimit>100||ipLimit<pairLimit||ipLimit>10000||windowSeconds<1||windowSeconds>3600||maxEntries<2||maxEntries>100000)
            throw new IllegalArgumentException("Invalid login limit configuration.");
        this.pairLimit=pairLimit;this.ipLimit=ipLimit;this.windowMillis=windowSeconds*1000L;this.maxEntries=maxEntries;this.clock=Objects.requireNonNull(clock);
    }
    public synchronized Admission acquire(String remoteAddress,String identifier){
        long now=clock.getAsLong();
        if(now-lastSweep>=10000){sweep(now);lastSweep=now;}
        String peer=remoteAddress==null?"unknown":remoteAddress;
        // AuthService trims/case-folds identifiers; cap untrusted input before hashing.
        String normalized=identifier==null?"":identifier.trim().toLowerCase(Locale.ROOT);
        if(normalized.length()>100)normalized=normalized.substring(0,100);
        String ipKey="ip:"+digest(peer),pairKey="pair:"+digest(peer+'\0'+normalized);
        Bucket ip=current(ipKey,now),pair=current(pairKey,now);
        int wait=0;
        if(ip!=null&&ip.failures+ip.inFlight>=ipLimit)wait=retry(ip,now);
        if(pair!=null&&pair.failures+pair.inFlight>=pairLimit)wait=Math.max(wait,retry(pair,now));
        if(wait>0)return new Admission(null,wait);
        int needed=(ip==null?1:0)+(pair==null?1:0);
        if(buckets.size()+needed>maxEntries){
            sweep(now);
            if(buckets.size()+needed>maxEntries)return new Admission(null,(int)(windowMillis/1000));
        }
        if(ip==null){ip=new Bucket(now+windowMillis);buckets.put(ipKey,ip);}
        if(pair==null){pair=new Bucket(now+windowMillis);buckets.put(pairKey,pair);}
        ip.inFlight++;pair.inFlight++;
        return new Admission(new Attempt(pair,ip),0);
    }
    public synchronized void complete(Attempt attempt,boolean success,boolean credentialFailure){
        if(attempt==null||attempt.completed)return;
        attempt.completed=true;attempt.pair.inFlight--;attempt.ip.inFlight--;
        if(success)attempt.pair.failures=0;
        else if(credentialFailure){attempt.pair.failures++;attempt.ip.failures++;}
        // Successful logins do not erase the IP's failures against other identities.
    }
    private Bucket current(String key,long now){
        Bucket bucket=buckets.get(key);
        if(bucket!=null&&bucket.expiresAt<=now&&bucket.inFlight==0){buckets.remove(key);return null;}
        return bucket;
    }
    private void sweep(long now){buckets.values().removeIf(bucket->bucket.expiresAt<=now&&bucket.inFlight==0);}
    private static int retry(Bucket bucket,long now){return (int)Math.max(1,(bucket.expiresAt-now+999)/1000);}
    private static String digest(String value){
        try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}
        catch(NoSuchAlgorithmException e){throw new IllegalStateException(e);}
    }
}
