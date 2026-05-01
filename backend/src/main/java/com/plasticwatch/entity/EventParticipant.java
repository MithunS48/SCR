package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * Join table entity for event participants (many-to-many between Event and User).
 */
@Entity
@Table(name = "event_participants")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(EventParticipantId.class)
public class EventParticipant {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt;

    @PrePersist
    protected void onCreate() {
        joinedAt = Instant.now();
    }
}
