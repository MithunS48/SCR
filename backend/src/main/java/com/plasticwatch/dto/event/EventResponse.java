package com.plasticwatch.dto.event;

import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EventResponse {
    private Long id;
    private Long organizerId;
    private String organizerDisplayName;
    private String title;
    private String description;
    private String locationName;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Instant eventDatetime;
    private String status;
    private int participantCount;
    private boolean registeredByCurrentUser;
    private Instant createdAt;
}
