package com.plasticwatch.dto.awareness;

import lombok.*;

import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AwarenessItemResponse {
    private Long id;
    private String title;
    private String body;
    private String contentType;
    private String iconIdentifier;
    private String status;
    private Instant publishedAt;
}
