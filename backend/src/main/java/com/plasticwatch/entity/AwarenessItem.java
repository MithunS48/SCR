package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * An educational content item (tip, fact, or article) in the awareness module.
 */
@Entity
@Table(name = "awareness_items")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AwarenessItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Enumerated(EnumType.STRING)
    @Column(name = "content_type", nullable = false, length = 10)
    private ContentType contentType;

    @Column(name = "icon_identifier", length = 100)
    private String iconIdentifier;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private ContentStatus status;

    @Column(name = "published_at", nullable = false, updatable = false)
    private Instant publishedAt;

    @PrePersist
    protected void onCreate() {
        publishedAt = Instant.now();
        if (status == null) status = ContentStatus.PUBLISHED;
    }

    public enum ContentType    { TIP, FACT, ARTICLE }
    public enum ContentStatus  { PUBLISHED, ARCHIVED }
}
