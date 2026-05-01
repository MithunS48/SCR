package com.plasticwatch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Records a user's daily plastic item consumption by category.
 */
@Entity
@Table(name = "plastic_usage",
       uniqueConstraints = @UniqueConstraint(
           name = "uq_usage_user_date_category",
           columnNames = {"user_id", "entry_date", "item_category"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PlasticUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "entry_date", nullable = false)
    private LocalDate entryDate;

    @Column(name = "item_category", nullable = false, length = 50)
    private String itemCategory;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
    }
}
