package com.plasticwatch.dto.usage;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UsageStatsResponse {
    private long totalItems;
    private Map<String, Long> byCategory;
    private Map<String, Long> byPeriod;   // day-of-week or week-of-month key
    private Double reductionPercentage;
    private String reductionMessage;
}
