package com.plasticwatch.dto.chat;

import lombok.*;

import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ChatMessageResponse {
    private Long id;
    private Long senderId;
    private String senderDisplayName;
    private String senderRole;
    private String content;
    private Instant sentAt;
    private boolean deleted;
}
