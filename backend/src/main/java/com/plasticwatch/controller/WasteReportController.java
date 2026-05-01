package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.report.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.entity.WasteReport.ReportStatus;
import com.plasticwatch.service.WasteReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

/**
 * Waste report submission, moderation, and heatmap endpoints.
 */
@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
@Tag(name = "Waste Reports", description = "Submit and manage plastic waste reports")
public class WasteReportController {

    private final WasteReportService reportService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Submit a new waste report with image")
    public ResponseEntity<ApiResponse<WasteReportResponse>> submitReport(
            @AuthenticationPrincipal User user,
            @RequestPart("image") MultipartFile image,
            @RequestParam BigDecimal latitude,
            @RequestParam BigDecimal longitude,
            @RequestParam(required = false) String description) throws IOException {
        WasteReportResponse response = reportService.submitReport(user, image, latitude, longitude, description);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    @GetMapping("/mine")
    @Operation(summary = "Get current user's waste reports")
    public ResponseEntity<ApiResponse<Page<WasteReportResponse>>> getMyReports(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getMyReports(user, page, size)));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: get all reports with optional status filter")
    public ResponseEntity<ApiResponse<Page<WasteReportResponse>>> getAllReports(
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getAllReports(status, page, size)));
    }

    @PatchMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: approve a pending report")
    public ResponseEntity<ApiResponse<WasteReportResponse>> approveReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.approveReport(id)));
    }

    @PatchMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: reject a pending report")
    public ResponseEntity<ApiResponse<WasteReportResponse>> rejectReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.rejectReport(id)));
    }

    @PatchMapping("/{id}/clean")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: mark an approved report as cleaned")
    public ResponseEntity<ApiResponse<WasteReportResponse>> markCleaned(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.markCleaned(id)));
    }

    @GetMapping("/heatmap")
    @Operation(summary = "Get heatmap data for approved/cleaned reports")
    public ResponseEntity<ApiResponse<List<HeatmapPointDto>>> getHeatmap() {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getHeatmapData()));
    }
}
