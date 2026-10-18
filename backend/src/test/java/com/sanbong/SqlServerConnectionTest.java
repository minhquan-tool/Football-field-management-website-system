package com.sanbong;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.Environment;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;

import static org.junit.jupiter.api.Assertions.*;

/** Integration check against the configured SQL Server; executes SELECTs only. */
@SpringBootTest
@Transactional(readOnly = true)
class SqlServerConnectionTest {
    @Autowired
    private DataSource dataSource;

    @Autowired
    private Environment environment;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void validatesSchemaAndReadsExistingDataOverDirectTcp() throws Exception {
        assertEquals("validate", environment.getProperty("spring.jpa.hibernate.ddl-auto"));
        try (var connection = dataSource.getConnection();
             var statement = connection.createStatement();
             var result = statement.executeQuery(
                     "SELECT DB_NAME(), CONNECTIONPROPERTY('net_transport'), "
                             + "CONNECTIONPROPERTY('local_tcp_port'), (SELECT COUNT(*) FROM dbo.San)")) {
            assertTrue(result.next());
            assertEquals("QuanLySanBong", result.getString(1));
            assertEquals("TCP", result.getString(2));
            assertTrue(result.getInt(3) > 0, "SQL Server must expose a direct TCP port");
            assertTrue(result.getInt(4) > 0, "Existing sample pitches should be readable");
            System.out.printf("SQL_SERVER_READ_OK database=%s transport=%s port=%d pitches=%d%n",
                    result.getString(1), result.getString(2), result.getInt(3), result.getInt(4));
        }

        for (String entity : new String[]{"VaiTro", "TaiKhoan", "NhanVien", "KhachHang",
                "LoaiSan", "KhungGio", "San", "DatSan"}) {
            var rows = entityManager.createQuery("select e from " + entity + " e")
                    .setMaxResults(1).getResultList();
            assertFalse(rows.isEmpty(), entity + " sample data should be readable through JPA");
            System.out.println("JPA_READ_OK entity=" + entity);
        }
    }
}
