package com.plasticwatch.service;

import com.plasticwatch.dto.report.WasteReportResponse;
import com.plasticwatch.entity.User;
import com.plasticwatch.entity.WasteReport;
import com.plasticwatch.entity.WasteReport.ReportStatus;
import com.plasticwatch.exception.*;
import com.plasticwatch.repository.WasteReportRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WasteReportServiceTest {

    @Mock WasteReportRepository reportRepository;
    @Mock GamificationService gamificationService;

    @InjectMocks WasteReportService reportService;

    private User user;

    @BeforeEach
    void setUp() {
        user = User.builder().id(1L).email("u@test.com").displayName("User")
                .role(User.Role.USER).points(0).build();
        ReflectionTestUtils.setField(reportService, "uploadDir", System.getProperty("java.io.tmpdir"));
        ReflectionTestUtils.setField(reportService, "baseUrl", "http://localhost:8080/api");
    }

    // ---- Submission ----

    @Test
    void submitReport_validJpeg_persistsAndReturns() throws IOException {
        MockMultipartFile image = new MockMultipartFile(
                "image", "test.jpg", "image/jpeg", new byte[100]);

        WasteReport saved = WasteReport.builder()
                .id(1L).user(user).imageUrl("http://localhost/img.jpg")
                .latitude(BigDecimal.valueOf(12.97)).longitude(BigDecimal.valueOf(77.59))
                .description("test").status(ReportStatus.PENDING).build();
        ReflectionTestUtils.setField(saved, "createdAt", java.time.Instant.now());
        ReflectionTestUtils.setField(saved, "updatedAt", java.time.Instant.now());

        when(reportRepository.save(any())).thenReturn(saved);

        WasteReportResponse response = reportService.submitReport(
                user, image, BigDecimal.valueOf(12.97), BigDecimal.valueOf(77.59), "test");

        assertThat(response.getStatus()).isEqualTo("PENDING");
        assertThat(response.getUserId()).isEqualTo(1L);
    }

    @Test
    void submitReport_wrongMimeType_throwsUnsupportedMedia() {
        MockMultipartFile gif = new MockMultipartFile(
                "image", "test.gif", "image/gif", new byte[100]);

        assertThatThrownBy(() -> reportService.submitReport(
                user, gif, BigDecimal.ONE, BigDecimal.ONE, null))
                .isInstanceOf(UnsupportedMediaTypeException.class);
    }

    @Test
    void submitReport_noImage_throwsBadRequest() {
        assertThatThrownBy(() -> reportService.submitReport(
                user, null, BigDecimal.ONE, BigDecimal.ONE, null))
                .isInstanceOf(BadRequestException.class);
    }

    // ---- Status transitions ----

    @Test
    void approveReport_pendingReport_setsApproved() {
        WasteReport report = buildReport(ReportStatus.PENDING);
        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));
        when(reportRepository.save(any())).thenReturn(report);

        WasteReportResponse response = reportService.approveReport(1L);

        assertThat(response.getStatus()).isEqualTo("APPROVED");
        verify(gamificationService).awardPoints(eq(user), eq(10), anyString());
    }

    @Test
    void rejectReport_pendingReport_setsRejected() {
        WasteReport report = buildReport(ReportStatus.PENDING);
        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));
        when(reportRepository.save(any())).thenReturn(report);

        WasteReportResponse response = reportService.rejectReport(1L);

        assertThat(response.getStatus()).isEqualTo("REJECTED");
    }

    @Test
    void markCleaned_approvedReport_setsCleaned() {
        WasteReport report = buildReport(ReportStatus.APPROVED);
        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));
        when(reportRepository.save(any())).thenReturn(report);

        WasteReportResponse response = reportService.markCleaned(1L);

        assertThat(response.getStatus()).isEqualTo("CLEANED");
    }

    @Test
    void approveReport_alreadyApproved_throwsUnprocessable() {
        WasteReport report = buildReport(ReportStatus.APPROVED);
        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.approveReport(1L))
                .isInstanceOf(UnprocessableEntityException.class);
    }

    @Test
    void markCleaned_pendingReport_throwsUnprocessable() {
        WasteReport report = buildReport(ReportStatus.PENDING);
        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.markCleaned(1L))
                .isInstanceOf(UnprocessableEntityException.class);
    }

    @Test
    void approveReport_notFound_throwsResourceNotFound() {
        when(reportRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.approveReport(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ---- Helpers ----

    private WasteReport buildReport(ReportStatus status) {
        WasteReport r = WasteReport.builder()
                .id(1L).user(user).imageUrl("http://img.jpg")
                .latitude(BigDecimal.ONE).longitude(BigDecimal.ONE)
                .status(status).build();
        ReflectionTestUtils.setField(r, "createdAt", java.time.Instant.now());
        ReflectionTestUtils.setField(r, "updatedAt", java.time.Instant.now());
        return r;
    }
}
