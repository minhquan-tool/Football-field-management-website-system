package com.sanbong;

import org.junit.jupiter.api.Test;
import com.sanbong.security.BoundedBcryptPasswordEncoder;
import com.sanbong.security.PasswordPolicy;
import static org.junit.jupiter.api.Assertions.*;

class BcryptSecurityRegressionTest {
 private final BoundedBcryptPasswordEncoder encoder = new BoundedBcryptPasswordEncoder();
 @Test void exactAsciiBoundaryMatchesButSuffixDoesNot() {
  String password = "A".repeat(72), hash = encoder.encode(password);
  assertTrue(encoder.matches(password, hash));
  assertFalse(encoder.matches(password + "!", hash));
  assertFalse(encoder.matches("B" + password.substring(1), hash));
  assertTrue(hash.startsWith("$2a$12$"));
 }
 @Test void exactUnicodeBoundaryMatchesButSuffixDoesNot() {
  String password = "\u20ac".repeat(24), hash = encoder.encode(password);
  assertTrue(encoder.matches(password, hash));
  assertFalse(encoder.matches(password + "\u20ac", hash));
 }
 @Test void unicodeSuffixCrossingBoundaryCannotAuthenticate() {
  String password = "A".repeat(71), hash = encoder.encode(password);
  assertTrue(encoder.matches(password, hash));
  assertFalse(encoder.matches(password + "\u20ac", hash));
 }
 @Test void writePolicyStillRejectsOversizedInputs() {
  assertDoesNotThrow(() -> PasswordPolicy.validate("A".repeat(72)));
  assertDoesNotThrow(() -> PasswordPolicy.validate("\u20ac".repeat(24)));
  assertThrows(IllegalArgumentException.class, () -> PasswordPolicy.validate("A".repeat(73)));
  assertThrows(IllegalArgumentException.class, () -> PasswordPolicy.validate("\u20ac".repeat(25)));
 }
 @Test void existingWeakLegacyHashRemainsUsableWithoutWritePolicyAtLogin() {
  String legacy = "123456";
  String oldHash = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder(12).encode(legacy);
  assertTrue(encoder.matches(legacy, oldHash));
 }
 @Test void loginDoesNotTrimOrNormalize() {
  String spaced = "  boundary-value  ", hash = encoder.encode(spaced);
  assertTrue(encoder.matches(spaced, hash));
  assertFalse(encoder.matches(spaced.trim(), hash));
  String composed = "\u00e9".repeat(12), unicodeHash = encoder.encode(composed);
  assertFalse(encoder.matches("e\u0301".repeat(12), unicodeHash));
 }
}
