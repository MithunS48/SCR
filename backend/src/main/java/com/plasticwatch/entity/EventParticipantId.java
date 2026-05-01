package com.plasticwatch.entity;

import lombok.*;

import java.io.Serializable;

/**
 * Composite primary key for EventParticipant.
 * Fields must match the type of the @Id fields in EventParticipant.
 * With @ManyToOne @Id, JPA expects the FK column type (Long) here.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
public class EventParticipantId implements Serializable {
    private Long event;   // matches event_id FK
    private Long user;    // matches user_id FK
}
