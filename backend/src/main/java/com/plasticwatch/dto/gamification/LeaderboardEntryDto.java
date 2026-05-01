package com.plasticwatch.dto.gamification;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LeaderboardEntryDto {
    private long rank;
    private Long userId;
    private String displayName;
    private int totalPoints;
    private long badgeCount;
}
