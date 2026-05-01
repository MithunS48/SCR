package com.plasticwatch.dto.gamification;

import lombok.*;

import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BadgeDto {
    private Long id;
    private String badgeName;
    private Instant awardedAt;
}
