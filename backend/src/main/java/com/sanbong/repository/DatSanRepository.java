package com.sanbong.repository;
import com.sanbong.model.DatSan;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;

public interface DatSanRepository extends JpaRepository<DatSan,String>,JpaSpecificationExecutor<DatSan> {
    @Override
    @EntityGraph(attributePaths={"khachHang","san","san.loaiSan","khungGio"})
    java.util.List<DatSan> findAll(org.springframework.data.jpa.domain.Specification<DatSan> spec,org.springframework.data.domain.Sort sort);
    @Override
    @EntityGraph(attributePaths={"khachHang","san","san.loaiSan","khungGio"})
    org.springframework.data.domain.Page<DatSan> findAll(org.springframework.data.jpa.domain.Specification<DatSan> spec,
            org.springframework.data.domain.Pageable pageable);
    @Query("select count(d) from DatSan d where d.san.maSan=:id and d.ngayChoi>=:today "
            + "and d.trangThai in :states")
    long countUpcomingActive(@Param("id") String id,@Param("today") LocalDate today,
                             @Param("states") java.util.Collection<String> states);
    @Query("select d from DatSan d where d.ngayChoi=:date and d.trangThai<>:cancelled")
    java.util.List<DatSan> occupied(@Param("date") LocalDate date,@Param("cancelled") String cancelled);
    @Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from DatSan d where d.maDatSan=:id")
    java.util.Optional<DatSan> lockById(@Param("id") String id);
}
