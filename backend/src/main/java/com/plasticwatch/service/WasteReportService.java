package com.plasticwatch.service;

import com.plasticwatch.dto.report.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.entity.WasteReport;
import com.plasticwatch.entity.WasteReport.ReportStatus;
import com.plasticwatch.exception.*;
import com.plasticwatch.repository.WasteReportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.*;
import java.util.*;

/**
 * Manages waste report submission, moderation, and heatmap data.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WasteReportService {

    private final WasteReportRepository reportRepository;
    private final GamificationService gamificationService;

    @Value("${storage.upload-dir}")
    private String uploadDir;

    @Value("${storage.base-url}")
    private String baseUrl;

    private static final Set<String> ALLOWED_TYPES = Set.of("image/jpeg", "image/png");
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

    /** Submit a new waste report with image upload. */
    @Transactional
    public WasteReportResponse submitReport(User user,
                                            MultipartFile image,
                                            BigDecimal latitude,
                                            BigDecimal longitude,
                                            String description) throws IOException {
        // Validate image
        if (image == null || image.isEmpty()) {
            throw new BadRequestException("Image is required");
        }
        if (!ALLOWED_TYPES.contains(image.getContentType())) {
            throw new UnsupportedMediaTypeException("Only JPEG and PNG images are accepted");
        }
        if (image.getSize() > MAX_FILE_SIZE) {
            throw new BadRequestException("Image file size must not exceed 10 MB");
        }

        // Store image
        String imageUrl = storeImage(image);

        WasteReport report = WasteReport.builder()
                .user(user)
                .imageUrl(imageUrl)
                .latitude(latitude)
                .longitude(longitude)
                .description(description)
                .status(ReportStatus.PENDING)
                .build();

        report = reportRepository.save(report);
        log.info("Waste report {} submitted by user {}", report.getId(), user.getId());

        return toResponse(report);
    }

    /** Get current user's reports. */
    public Page<WasteReportResponse> getMyReports(User user, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return reportRepository.findByUserIdOrderByCreatedAtDesc(user.getId(), pageable)
                .map(this::toResponse);
    }

    /** Admin: get all reports with optional status filter. */
    public Page<WasteReportResponse> getAllReports(ReportStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        if (status != null) {
            return reportRepository.findByStatusOrderByCreatedAtDesc(status, pageable)
                    .map(this::toResponse);
        }
        return reportRepository.findAllByOrderByCreatedAtDesc(pageable).map(this::toResponse);
    }

    /** Admin: approve a PENDING report. */
    @Transactional
    public WasteReportResponse approveReport(Long reportId) {
        WasteReport report = findById(reportId);
        validateTransition(report.getStatus(), ReportStatus.APPROVED);
        report.setStatus(ReportStatus.APPROVED);
        report = reportRepository.save(report);

        // Award points to the reporter
        gamificationService.awardPoints(report.getUser(), 10, "Waste report approved");

        return toResponse(report);
    }

    /** Admin: reject a PENDING report. */
    @Transactional
    public WasteReportResponse rejectReport(Long reportId) {
        WasteReport report = findById(reportId);
        validateTransition(report.getStatus(), ReportStatus.REJECTED);
        report.setStatus(ReportStatus.REJECTED);
        return toResponse(reportRepository.save(report));
    }

    /** Admin: mark an APPROVED report as cleaned. */
    @Transactional
    public WasteReportResponse markCleaned(Long reportId) {
        WasteReport report = findById(reportId);
        validateTransition(report.getStatus(), ReportStatus.CLEANED);
        report.setStatus(ReportStatus.CLEANED);
        return toResponse(reportRepository.save(report));
    }

    /** Get heatmap data (APPROVED + CLEANED reports). */
    public List<HeatmapPointDto> getHeatmapData() {
        List<Object[]> raw = reportRepository.findHeatmapData(
                List.of(ReportStatus.APPROVED, ReportStatus.CLEANED));
        List<HeatmapPointDto> result = new ArrayList<>();
        for (Object[] row : raw) {
            result.add(HeatmapPointDto.builder()
                    .latitude((BigDecimal) row[0])
                    .longitude((BigDecimal) row[1])
                    .weight((Long) row[2])
                    .build());
        }
        return result;
    }

    // ---- Helpers ----

    private WasteReport findById(Long id) {
        return reportRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Waste report not found: " + id));
    }

    private void validateTransition(ReportStatus current, ReportStatus target) {
        boolean valid = switch (target) {
            case APPROVED -> current == ReportStatus.PENDING;
            case REJECTED -> current == ReportStatus.PENDING;
            case CLEANED  -> current == ReportStatus.APPROVED;
            default       -> false;
        };
        if (!valid) {
            throw new UnprocessableEntityException(
                    "Cannot transition report from " + current + " to " + target);
        }
    }

    private String storeImage(MultipartFile file) throws IOException {
        Path uploadPath = Paths.get(uploadDir);
        Files.createDirectories(uploadPath);
        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path filePath = uploadPath.resolve(filename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
        return baseUrl + "/files/" + filename;
    }

    private WasteReportResponse toResponse(WasteReport r) {
        return WasteReportResponse.builder()
                .id(r.getId())
                .userId(r.getUser().getId())
                .userDisplayName(r.getUser().getDisplayName())
                .imageUrl(r.getImageUrl())
                .latitude(r.getLatitude())
                .longitude(r.getLongitude())
                .description(r.getDescription())
                .status(r.getStatus().name())
                .createdAt(r.getCreatedAt())
                .updatedAt(r.getUpdatedAt())
                .build();
    }
}
