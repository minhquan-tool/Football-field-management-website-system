package com.sanbong.repository;
import com.sanbong.model.San;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface SanRepository extends JpaRepository<San,String>,JpaSpecificationExecutor<San> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from San s where s.maSan=:id")
    Optional<San> lockById(@Param("id") String id);
}
