package com.sanbong;

import java.lang.annotation.*;

/** Committed legacy fixtures need a separate disposable DEV/test database and fixture identity. */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Inherited
public @interface AuditCleanupFixture {}
