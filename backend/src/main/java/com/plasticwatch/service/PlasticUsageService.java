package com.plasticwatch.service;

import com.plasticwatch.dto.usage.*;
import com.plasticwatch.entity.PlasticUsage;
import com.plasticwatch.entity.User;
import com.plasticwatch.repository.PlasticUsageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.IsoFields;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Manages plastic usage logging and statistics.
 */
@Service
@RequiredArgsConstructor
public class PlasticUsageService {

    private final PlasticUsageRepository usageRepository;
    private final GamificationService gamificationService;

    /** Log a plastic usage entry for today. */
    @Transactional
    public UsageLogResponse logUsage(User user, UsageLogRequest request) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);

        PlasticUsage usage = PlasticUsage.builder()
                .user(user)
                .entryDate(today)
                .itemCategory(request.getItemCategory().toLowerCase())
                .quantity(request.getQuantity())
                .build();

        usage = usageRepository.save(usage);

        // Award gamification points
        gamificationService.awardPoints(user, 5, "Logged plastic usage");

        return toResponse(usage);
    }

    /** Get paginated history for a user. */
    public Page<UsageLogResponse> getHistory(User user, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return usageRepository.findByUserIdOrderByEntryDateDesc(user.getId(), pageable)
                .map(this::toResponse);
    }

    /** Daily stats for a specific date. */
    public UsageStatsResponse getDailyStats(User user, LocalDate date) {
        List<PlasticUsage> entries = usageRepository.findByUserIdAndEntryDate(user.getId(), date);
        Map<String, Long> byCategory = entries.stream()
                .collect(Collectors.groupingBy(PlasticUsage::getItemCategory,
                         Collectors.summingLong(PlasticUsage::getQuantity)));
        long total = byCategory.values().stream().mapToLong(Long::longValue).sum();
        return UsageStatsResponse.builder().totalItems(total).byCategory(byCategory).build();
    }

    /** Weekly stats for a given ISO week. */
    public UsageStatsResponse getWeeklyStats(User user, int year, int week) {
        LocalDate weekStart = LocalDate.ofYearDay(year, 1)
                .with(IsoFields.WEEK_OF_WEEK_BASED_YEAR, week)
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate weekEnd = weekStart.plusDays(6);

        List<PlasticUsage> entries = usageRepository.findByUserIdAndDateRange(
                user.getId(), weekStart, weekEnd);

        Map<String, Long> byDay = new LinkedHashMap<>();
        for (int i = 0; i < 7; i++) {
            LocalDate d = weekStart.plusDays(i);
            byDay.put(d.toString(), 0L);
        }
        entries.forEach(e -> byDay.merge(e.getEntryDate().toString(),
                (long) e.getQuantity(), Long::sum));

        long total = byDay.values().stream().mapToLong(Long::longValue).sum();
        return UsageStatsResponse.builder().totalItems(total).byPeriod(byDay).build();
    }

    /** Monthly stats for a given year/month. */
    public UsageStatsResponse getMonthlyStats(User user, int year, int month) {
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd   = monthStart.with(TemporalAdjusters.lastDayOfMonth());

        List<PlasticUsage> entries = usageRepository.findByUserIdAndDateRange(
                user.getId(), monthStart, monthEnd);

        // Group by ISO week number
        Map<String, Long> byWeek = new LinkedHashMap<>();
        entries.forEach(e -> {
            String weekKey = "W" + e.getEntryDate().get(IsoFields.WEEK_OF_WEEK_BASED_YEAR);
            byWeek.merge(weekKey, (long) e.getQuantity(), Long::sum);
        });

        long total = byWeek.values().stream().mapToLong(Long::longValue).sum();
        return UsageStatsResponse.builder().totalItems(total).byPeriod(byWeek).build();
    }

    /** Reduction percentage vs the preceding equivalent period. */
    public UsageStatsResponse getReductionStats(User user, String period, String ref) {
        // period = "week" or "month", ref = ISO week (2024-W10) or month (2024-03)
        long current, previous;
        if ("week".equalsIgnoreCase(period)) {
            String[] parts = ref.split("-W");
            int year = Integer.parseInt(parts[0]);
            int week = Integer.parseInt(parts[1]);
            LocalDate weekStart = LocalDate.ofYearDay(year, 1)
                    .with(IsoFields.WEEK_OF_WEEK_BASED_YEAR, week)
                    .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
            current  = usageRepository.sumQuantityByUserIdAndDateRange(
                    user.getId(), weekStart, weekStart.plusDays(6));
            LocalDate prevStart = weekStart.minusWeeks(1);
            previous = usageRepository.sumQuantityByUserIdAndDateRange(
                    user.getId(), prevStart, prevStart.plusDays(6));
        } else {
            String[] parts = ref.split("-");
            int year  = Integer.parseInt(parts[0]);
            int month = Integer.parseInt(parts[1]);
            LocalDate monthStart = LocalDate.of(year, month, 1);
            LocalDate monthEnd   = monthStart.with(TemporalAdjusters.lastDayOfMonth());
            current  = usageRepository.sumQuantityByUserIdAndDateRange(
                    user.getId(), monthStart, monthEnd);
            LocalDate prevStart = monthStart.minusMonths(1);
            LocalDate prevEnd   = prevStart.with(TemporalAdjusters.lastDayOfMonth());
            previous = usageRepository.sumQuantityByUserIdAndDateRange(
                    user.getId(), prevStart, prevEnd);
        }

        if (previous == 0) {
            return UsageStatsResponse.builder()
                    .totalItems(current)
                    .reductionPercentage(null)
                    .reductionMessage("No data available for the preceding period to calculate reduction.")
                    .build();
        }

        double reduction = ((double)(previous - current) / previous) * 100.0;
        double rounded   = Math.round(reduction * 10.0) / 10.0;

        return UsageStatsResponse.builder()
                .totalItems(current)
                .reductionPercentage(rounded)
                .build();
    }

    private UsageLogResponse toResponse(PlasticUsage u) {
        return UsageLogResponse.builder()
                .id(u.getId())
                .entryDate(u.getEntryDate())
                .itemCategory(u.getItemCategory())
                .quantity(u.getQuantity())
                .createdAt(u.getCreatedAt())
                .build();
    }
}
