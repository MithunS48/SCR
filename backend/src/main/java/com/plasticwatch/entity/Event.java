package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * A community clean-up event.
 */
@Entity
@Table(name = "events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organizer_id", nullable = false)
    private User organizer;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(length = 1000)
    private String description;

    @Column(name = "location_name", nullable = false, length = 255)
    private String locationName;

    @Column(nullable = false, precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "event_datetime", nullable = false)
    private Instant eventDatetime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private EventStatus status;

    @Column(name = "participant_count", nullable = false)
    @Builder.Default
    private int participantCount = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        if (status == null) status = EventStatus.UPCOMING;
    }

    public enum EventStatus { UPCOMING, COMPLETED, CANCELLED }
}
