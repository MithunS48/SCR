package com.plasticwatch.dto.gamification;

import lombok.*;

import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProfileResponse {
    private Long userId;
    private String email;
    private String displayName;
    private String role;
    private int totalPoints;
    private long leaderboardRank;
    private List<BadgeDto> badges;
}
