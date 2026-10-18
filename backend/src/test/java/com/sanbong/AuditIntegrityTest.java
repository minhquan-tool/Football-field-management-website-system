package com.sanbong;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/** Runtime SQL identity, DEV/test guard and transaction rollback inherited from support. */
class AuditIntegrityTest extends RoleAuditSupport {
    @Test void runtimeCanAppendAndReadButCannotRewriteHistory() {
        assertEquals("SanBongApp",jdbc.queryForObject("SELECT CURRENT_USER",String.class));
        for(String permission:new String[]{"INSERT","SELECT"})
            assertEquals(1,jdbc.queryForObject("SELECT HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',?)",Integer.class,permission));
        for(String permission:new String[]{"UPDATE","DELETE"})
            assertEquals(0,jdbc.queryForObject("SELECT HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',?)",Integer.class,permission));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.NhatKyHeThong') AND HAS_PERMS_BY_NAME(N'dbo.NhatKyHeThong',N'OBJECT',N'UPDATE',name,N'COLUMN')=1",Integer.class));
    }

    @Test void businessWritesStillAppendReadableAuditRecords() throws Exception {
        String id=book(login("nvsan"));
        assertTrue(jdbc.queryForObject("SELECT COUNT(*) FROM NhatKyHeThong WHERE DoiTuong=?",Integer.class,id)>0);
        assertEquals(marker,jdbc.queryForObject("SELECT GhiChu FROM DatSan WHERE MaDatSan=?",String.class,id));
        // Both the booking and its audit rows roll back together; never DELETE audit to clean up.
    }
}
