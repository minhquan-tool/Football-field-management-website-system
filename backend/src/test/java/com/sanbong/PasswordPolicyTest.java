package com.sanbong;

import com.sanbong.security.PasswordPolicy;
import com.sanbong.service.AuthService;
import com.sanbong.model.TaiKhoan;
import com.sanbong.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PasswordPolicyTest {
 @ParameterizedTest @ValueSource(strings={"123456","12345678","admin","password","demo123"})
 void denylistRejectedOnWriteAndStartup(String value){var e=new BCryptPasswordEncoder(12);assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate(value));assertThrows(IllegalStateException.class,()->PasswordPolicy.validateStoredHash(e.encode(value),e));}
 @Test void boundsAreCheckedInUtf8WithoutTrimming(){
  assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate(null));assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate(" ".repeat(12)));assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate("a".repeat(9)));
  for(String value:List.of("a".repeat(10),"a".repeat(72),"ắ".repeat(24))){assertDoesNotThrow(()->PasswordPolicy.validate(value));var e=new BCryptPasswordEncoder(12);String hash=e.encode(value);assertTrue(e.matches(value,hash));assertDoesNotThrow(()->PasswordPolicy.validateStoredHash(hash,e));}
  assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate("a".repeat(73)));assertThrows(IllegalArgumentException.class,()->PasswordPolicy.validate("ắ".repeat(25)));
 }
 @Test void legacyMigrationCannotHashDeniedPlaintext(){
  var accounts=mock(TaiKhoanRepository.class);var e=mock(org.springframework.security.crypto.password.PasswordEncoder.class);var a=new TaiKhoan();a.setMatKhau("12345678");when(accounts.findAll()).thenReturn(List.of(a));
  var service=new AuthService(accounts,mock(KhachHangRepository.class),mock(VaiTroRepository.class),mock(SecurityRepository.class),e);
  assertThrows(IllegalStateException.class,service::migrateLegacyPasswords);verify(e,never()).encode(anyString());verify(accounts,never()).flush();assertEquals("12345678",a.getMatKhau());
 }
 @Test void existingBcryptIsNotRehashedOrResetByMigration(){
  var e=new BCryptPasswordEncoder(12);String hash=e.encode(java.util.UUID.randomUUID().toString());var a=new TaiKhoan();a.setMatKhau(hash);var accounts=mock(TaiKhoanRepository.class);when(accounts.findAll()).thenReturn(List.of(a));var encoder=mock(org.springframework.security.crypto.password.PasswordEncoder.class);
  new AuthService(accounts,mock(KhachHangRepository.class),mock(VaiTroRepository.class),mock(SecurityRepository.class),encoder).migrateLegacyPasswords();verify(encoder,never()).encode(anyString());assertEquals(hash,a.getMatKhau());
 }
}
