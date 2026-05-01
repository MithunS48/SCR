package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.usage.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.service.PlasticUsageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Plastic usage tracking endpoints.
 */
@RestController
@RequestMapping("/usage")
@RequiredArgsConstructor
@Tag(name = "Plastic Usage Tracker", description = "Log and retrieve plastic usage statistics")
public class PlasticUsageController {

    private final PlasticUsageService usageService;

    @PostMapping
    @Operation(summary = "Log a plastic usage entry for today")
    public ResponseEntity<ApiResponse<UsageLogResponse>> logUsage(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody UsageLogRequest request) {
        UsageLogResponse response = usageService.logUsage(user, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    @GetMapping("/history")
    @Operation(summary = "Get paginated usage history")
    public ResponseEntity<ApiResponse<Page<UsageLogResponse>>> getHistory(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(usageService.getHistory(user, page, size)));
    }

    @GetMapping("/stats/daily")
    @Operation(summary = "Get daily stats for a specific date")
    public ResponseEntity<ApiResponse<UsageStatsResponse>> getDailyStats(
            @AuthenticationPrincipal User user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ApiResponse.ok(usageService.getDailyStats(user, date)));
    }

    @GetMapping("/stats/weekly")
    @Operation(summary = "Get weekly stats for a given ISO week (e.g. year=2024&week=10)")
    public ResponseEntity<ApiResponse<UsageStatsResponse>> getWeeklyStats(
            @AuthenticationPrincipal User user,
            @RequestParam int year,
            @RequestParam int week) {
        return ResponseEntity.ok(ApiResponse.ok(usageService.getWeeklyStats(user, year, week)));
    }

    @GetMapping("/stats/monthly")
    @Operation(summary = "Get monthly stats for a given year and month")
    public ResponseEntity<ApiResponse<UsageStatsResponse>> getMonthlyStats(
            @AuthenticationPrincipal User user,
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(ApiResponse.ok(usageService.getMonthlyStats(user, year, month)));
    }

    @GetMapping("/stats/reduction")
    @Operation(summary = "Get reduction percentage vs preceding period (period=week|month, ref=2024-W10|2024-03)")
    public ResponseEntity<ApiResponse<UsageStatsResponse>> getReduction(
            @AuthenticationPrincipal User user,
            @RequestParam String period,
            @RequestParam String ref) {
        return ResponseEntity.ok(ApiResponse.ok(usageService.getReductionStats(user, period, ref)));
    }
}
