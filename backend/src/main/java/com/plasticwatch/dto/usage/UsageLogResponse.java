package com.plasticwatch.dto.usage;

import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UsageLogResponse {
    private Long id;
    private LocalDate entryDate;
    private String itemCategory;
    private int quantity;
    private Instant createdAt;
}
