package com.plasticwatch.service;

import com.plasticwatch.dto.gamification.*;
import com.plasticwatch.entity.*;
import com.plasticwatch.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Awards points and badges, and provides leaderboard data.
 *
 * Badge thresholds:
 *   Eco Beginner      → 50 pts
 *   Plastic Warrior   → 200 pts
 *   Community Champion→ 500 pts
 *
 * Event badges:
 *   Participant       → first completed event
 *   Community Champion→ 5th completed event
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GamificationService {

    private static final Map<String, Integer> BADGE_THRESHOLDS = Map.of(
            "Eco Beginner",       50,
            "Plastic Warrior",    200,
            "Community Champion", 500
    );

    private final UserRepository userRepository;
    private final BadgeRepository badgeRepository;
    private final EventParticipantRepository eventParticipantRepository;

    /**
     * Award points to a user and check badge thresholds — all in one transaction.
     * Point rates:
     *   - Log plastic usage: 5 pts
     *   - Waste report approved: 10 pts
     *   - Attend completed event: 20 pts
     */
    @Transactional
    public void awardPoints(User user, int points, String reason) {
        user.setPoints(user.getPoints() + points);
        userRepository.save(user);
        log.debug("Awarded {} points to user {} for: {}", points, user.getId(), reason);
        checkAndAwardBadges(user);
    }

    /**
     * Check all point-based badge thresholds and award any newly qualifying badges.
     * Idempotent — will not create duplicate badge records.
     */
    @Transactional
    public void checkAndAwardBadges(User user) {
        BADGE_THRESHOLDS.forEach((badgeName, threshold) -> {
            if (user.getPoints() >= threshold) {
                awardBadgeIfNotExists(user, badgeName);
            }
        });
    }

    /**
     * Award event-based badges after a user attends a completed event.
     */
    @Transactional
    public void awardEventBadges(User user) {
        long completedCount = eventParticipantRepository.countCompletedEventsByUserId(
                user.getId(), com.plasticwatch.entity.Event.EventStatus.COMPLETED);
        if (completedCount >= 1) {
            awardBadgeIfNotExists(user, "Participant");
        }
        if (completedCount >= 5) {
            awardBadgeIfNotExists(user, "Community Champion");
        }
    }

    /** Idempotent badge award — no duplicate records. */
    private void awardBadgeIfNotExists(User user, String badgeName) {
        if (!badgeRepository.existsByUserIdAndBadgeName(user.getId(), badgeName)) {
            Badge badge = Badge.builder()
                    .user(user)
                    .badgeName(badgeName)
                    .build();
            badgeRepository.save(badge);
            log.info("Awarded badge '{}' to user {}", badgeName, user.getId());
        }
    }

    /** Build profile response with points, badges, and rank. */
    public ProfileResponse getProfile(User user) {
        List<Badge> badges = badgeRepository.findByUserIdOrderByAwardedAtDesc(user.getId());
        long rank = userRepository.findRankByUserId(user.getId());

        List<BadgeDto> badgeDtos = badges.stream()
                .map(b -> BadgeDto.builder()
                        .id(b.getId())
                        .badgeName(b.getBadgeName())
                        .awardedAt(b.getAwardedAt())
                        .build())
                .collect(Collectors.toList());

        return ProfileResponse.builder()
                .userId(user.getId())
                .email(user.getEmail())
                .displayName(user.getDisplayName())
                .role(user.getRole().name())
                .totalPoints(user.getPoints())
                .leaderboardRank(rank)
                .badges(badgeDtos)
                .build();
    }

    /** Top 50 users by points. */
    public List<LeaderboardEntryDto> getLeaderboard() {
        Pageable top50 = PageRequest.of(0, 50, Sort.by(Sort.Direction.DESC, "points"));
        List<User> users = userRepository.findAll(top50).getContent();

        List<LeaderboardEntryDto> result = new ArrayList<>();
        for (int i = 0; i < users.size(); i++) {
            User u = users.get(i);
            long badgeCount = badgeRepository.countByUserId(u.getId());
            result.add(LeaderboardEntryDto.builder()
                    .rank(i + 1L)
                    .userId(u.getId())
                    .displayName(u.getDisplayName())
                    .totalPoints(u.getPoints())
                    .badgeCount(badgeCount)
                    .build());
        }
        return result;
    }
}
