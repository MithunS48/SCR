package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * A community chat message posted by any authenticated user or admin.
 */
@Entity
@Table(name = "chat_messages")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(nullable = false, length = 1000)
    private String content;

    @Column(name = "sent_at", nullable = false, updatable = false)
    private Instant sentAt;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted = false;

    @PrePersist
    protected void onCreate() {
        sentAt = Instant.now();
    }
}
