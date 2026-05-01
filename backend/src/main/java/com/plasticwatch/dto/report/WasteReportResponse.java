package com.plasticwatch.dto.report;

import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WasteReportResponse {
    private Long id;
    private Long userId;
    private String userDisplayName;
    private String imageUrl;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String description;
    private String status;
    private Instant createdAt;
    private Instant updatedAt;
}
