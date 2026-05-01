package com.plasticwatch.service;

import com.plasticwatch.dto.usage.*;
import com.plasticwatch.entity.*;
import com.plasticwatch.repository.PlasticUsageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.*;
import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PlasticUsageServiceTest {

    @Mock PlasticUsageRepository usageRepository;
    @Mock GamificationService gamificationService;

    @InjectMocks PlasticUsageService usageService;

    private User user;

    @BeforeEach
    void setUp() {
        user = User.builder().id(1L).email("u@test.com").displayName("User")
                .role(User.Role.USER).points(0).build();
    }

    // ---- Log usage ----

    @Test
    void logUsage_validEntry_persistsAndAwardsPoints() {
        PlasticUsage saved = PlasticUsage.builder()
                .id(1L).user(user).entryDate(LocalDate.now())
                .itemCategory("bottle").quantity(3).build();
        org.springframework.test.util.ReflectionTestUtils.setField(saved, "createdAt", Instant.now());

        when(usageRepository.save(any())).thenReturn(saved);

        UsageLogResponse response = usageService.logUsage(user, new UsageLogRequest("bottle", 3));

        assertThat(response.getItemCategory()).isEqualTo("bottle");
        assertThat(response.getQuantity()).isEqualTo(3);
        verify(gamificationService).awardPoints(eq(user), eq(5), anyString());
    }

    @Test
    void logUsage_categoryNormalized_toLowercase() {
        PlasticUsage saved = PlasticUsage.builder()
                .id(1L).user(user).entryDate(LocalDate.now())
                .itemCategory("bottle").quantity(1).build();
        org.springframework.test.util.ReflectionTestUtils.setField(saved, "createdAt", Instant.now());

        when(usageRepository.save(any())).thenReturn(saved);

        usageService.logUsage(user, new UsageLogRequest("BOTTLE", 1));

        verify(usageRepository).save(argThat(u -> u.getItemCategory().equals("bottle")));
    }

    // ---- Daily stats ----

    @Test
    void getDailyStats_withEntries_returnsTotals() {
        LocalDate today = LocalDate.now();
        PlasticUsage b1 = PlasticUsage.builder().itemCategory("bottle").quantity(2).build();
        PlasticUsage b2 = PlasticUsage.builder().itemCategory("bag").quantity(3).build();

        when(usageRepository.findByUserIdAndEntryDate(1L, today)).thenReturn(List.of(b1, b2));

        UsageStatsResponse stats = usageService.getDailyStats(user, today);

        assertThat(stats.getTotalItems()).isEqualTo(5);
        assertThat(stats.getByCategory()).containsEntry("bottle", 2L);
        assertThat(stats.getByCategory()).containsEntry("bag", 3L);
    }

    @Test
    void getDailyStats_noEntries_returnsZero() {
        when(usageRepository.findByUserIdAndEntryDate(anyLong(), any())).thenReturn(List.of());

        UsageStatsResponse stats = usageService.getDailyStats(user, LocalDate.now());

        assertThat(stats.getTotalItems()).isEqualTo(0);
        assertThat(stats.getByCategory()).isEmpty();
    }

    // ---- Reduction stats ----

    @Test
    void getReductionStats_withPriorData_calculatesPercentage() {
        // Current week: 80 items, previous week: 100 items → 20% reduction
        when(usageRepository.sumQuantityByUserIdAndDateRange(eq(1L), any(), any()))
                .thenReturn(80L)   // current
                .thenReturn(100L); // previous

        UsageStatsResponse stats = usageService.getReductionStats(user, "week", "2024-W10");

        assertThat(stats.getReductionPercentage()).isEqualTo(20.0);
    }

    @Test
    void getReductionStats_noPriorData_returnsNullWithMessage() {
        when(usageRepository.sumQuantityByUserIdAndDateRange(eq(1L), any(), any()))
                .thenReturn(50L)  // current
                .thenReturn(0L);  // previous (no data)

        UsageStatsResponse stats = usageService.getReductionStats(user, "week", "2024-W10");

        assertThat(stats.getReductionPercentage()).isNull();
        assertThat(stats.getReductionMessage()).isNotBlank();
    }
}
