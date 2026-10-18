package com.sanbong.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.time.LocalTime;
@Repository
public class TimePriceRepository {
    private final JdbcTemplate jdbc;
    public TimePriceRepository(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    public BigDecimal price(LocalTime start) {
        var values=jdbc.queryForList("SELECT DonGia FROM GiaTheoCa WHERE GioBatDau<=CAST(? AS time) AND GioKetThuc>CAST(? AS time)",
                BigDecimal.class,start.toString(),start.toString());
        return values.size()==1?values.getFirst():null;
    }
}
