package com.plasticwatch.repository;

import com.plasticwatch.entity.WasteReport;
import com.plasticwatch.entity.WasteReport.ReportStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WasteReportRepository extends JpaRepository<WasteReport, Long> {

    Page<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    Page<WasteReport> findByStatusOrderByCreatedAtDesc(ReportStatus status, Pageable pageable);

    Page<WasteReport> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /** Returns coordinate + weight data for heatmap (APPROVED and CLEANED reports). */
    @Query("SELECT w.latitude, w.longitude, COUNT(w) as weight FROM WasteReport w " +
           "WHERE w.status IN :statuses " +
           "GROUP BY w.latitude, w.longitude")
    List<Object[]> findHeatmapData(
            @Param("statuses") java.util.List<WasteReport.ReportStatus> statuses);

    @Query("SELECT w FROM WasteReport w WHERE (:status IS NULL OR w.status = :status) " +
           "ORDER BY w.createdAt DESC")
    Page<WasteReport> findAllByOptionalStatus(@Param("status") ReportStatus status, Pageable pageable);
}
