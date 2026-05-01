package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * A gamification badge awarded to a user.
 */
@Entity
@Table(name = "badges",
       uniqueConstraints = @UniqueConstraint(
           name = "uq_badge_user_name",
           columnNames = {"user_id", "badge_name"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Badge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "badge_name", nullable = false, length = 100)
    private String badgeName;

    @Column(name = "awarded_at", nullable = false, updatable = false)
    private Instant awardedAt;

    @PrePersist
    protected void onCreate() {
        awardedAt = Instant.now();
    }
}
