package com.plasticwatch.service;

import com.plasticwatch.dto.gamification.*;
import com.plasticwatch.entity.*;
import com.plasticwatch.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.*;

import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GamificationServiceTest {

    @Mock UserRepository userRepository;
    @Mock BadgeRepository badgeRepository;
    @Mock EventParticipantRepository eventParticipantRepository;

    @InjectMocks GamificationService gamificationService;

    private User user;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .id(1L).email("user@test.com").displayName("Tester")
                .role(User.Role.USER).points(0).build();
    }

    // ---- Points ----

    @Test
    void awardPoints_updatesUserPoints() {
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(badgeRepository.existsByUserIdAndBadgeName(anyLong(), anyString())).thenReturn(true);

        gamificationService.awardPoints(user, 10, "test");

        assertThat(user.getPoints()).isEqualTo(10);
        verify(userRepository).save(user);
    }

    @Test
    void awardPoints_multipleAwards_accumulate() {
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(badgeRepository.existsByUserIdAndBadgeName(anyLong(), anyString())).thenReturn(true);

        gamificationService.awardPoints(user, 5, "first");
        gamificationService.awardPoints(user, 5, "second");

        assertThat(user.getPoints()).isEqualTo(10);
    }

    // ---- Badge thresholds ----

    @Test
    void checkBadges_ecoBeginnerAt50Points_awardsBadge() {
        user.setPoints(50);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Eco Beginner")).thenReturn(false);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Plastic Warrior")).thenReturn(true);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Community Champion")).thenReturn(true);

        gamificationService.checkAndAwardBadges(user);

        verify(badgeRepository).save(argThat(b -> b.getBadgeName().equals("Eco Beginner")));
    }

    @Test
    void checkBadges_plasticWarriorAt200Points_awardsBadge() {
        user.setPoints(200);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Eco Beginner")).thenReturn(true);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Plastic Warrior")).thenReturn(false);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Community Champion")).thenReturn(true);

        gamificationService.checkAndAwardBadges(user);

        verify(badgeRepository).save(argThat(b -> b.getBadgeName().equals("Plastic Warrior")));
    }

    @Test
    void checkBadges_idempotent_doesNotDuplicateBadge() {
        user.setPoints(50);
        when(badgeRepository.existsByUserIdAndBadgeName(anyLong(), anyString())).thenReturn(true);

        gamificationService.checkAndAwardBadges(user);

        verify(badgeRepository, never()).save(any());
    }

    // ---- Leaderboard ----

    @Test
    void getLeaderboard_returnsTop50WithRanks() {
        User u1 = User.builder().id(1L).displayName("Alice").points(100).role(User.Role.USER).build();
        User u2 = User.builder().id(2L).displayName("Bob").points(80).role(User.Role.USER).build();

        Page<User> page = new PageImpl<>(List.of(u1, u2));
        when(userRepository.findAll(any(Pageable.class))).thenReturn(page);
        when(badgeRepository.countByUserId(anyLong())).thenReturn(2L);

        List<LeaderboardEntryDto> result = gamificationService.getLeaderboard();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getRank()).isEqualTo(1);
        assertThat(result.get(0).getDisplayName()).isEqualTo("Alice");
        assertThat(result.get(1).getRank()).isEqualTo(2);
    }

    // ---- Event badges ----

    @Test
    void awardEventBadges_firstEvent_awardsParticipantBadge() {
        when(eventParticipantRepository.countCompletedEventsByUserId(1L,
                com.plasticwatch.entity.Event.EventStatus.COMPLETED)).thenReturn(1L);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Participant")).thenReturn(false);

        gamificationService.awardEventBadges(user);

        verify(badgeRepository).save(argThat(b -> b.getBadgeName().equals("Participant")));
    }

    @Test
    void awardEventBadges_fiveEvents_awardsCommunityChampion() {
        when(eventParticipantRepository.countCompletedEventsByUserId(1L,
                com.plasticwatch.entity.Event.EventStatus.COMPLETED)).thenReturn(5L);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Participant")).thenReturn(true);
        when(badgeRepository.existsByUserIdAndBadgeName(1L, "Community Champion")).thenReturn(false);

        gamificationService.awardEventBadges(user);

        verify(badgeRepository).save(argThat(b -> b.getBadgeName().equals("Community Champion")));
    }
}
