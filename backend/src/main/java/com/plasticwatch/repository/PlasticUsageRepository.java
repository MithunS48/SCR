package com.plasticwatch.repository;

import com.plasticwatch.entity.PlasticUsage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface PlasticUsageRepository extends JpaRepository<PlasticUsage, Long> {

    Page<PlasticUsage> findByUserIdOrderByEntryDateDesc(Long userId, Pageable pageable);

    List<PlasticUsage> findByUserIdAndEntryDate(Long userId, LocalDate entryDate);

    @Query("SELECT p FROM PlasticUsage p WHERE p.user.id = :userId " +
           "AND p.entryDate >= :startDate AND p.entryDate <= :endDate " +
           "ORDER BY p.entryDate ASC")
    List<PlasticUsage> findByUserIdAndDateRange(
            @Param("userId") Long userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    @Query("SELECT COALESCE(SUM(p.quantity), 0) FROM PlasticUsage p " +
           "WHERE p.user.id = :userId AND p.entryDate >= :startDate AND p.entryDate <= :endDate")
    long sumQuantityByUserIdAndDateRange(
            @Param("userId") Long userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
