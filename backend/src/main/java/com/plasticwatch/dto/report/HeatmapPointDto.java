package com.plasticwatch.dto.report;

import lombok.*;

import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HeatmapPointDto {
    private BigDecimal latitude;
    private BigDecimal longitude;
    private long weight;
}
