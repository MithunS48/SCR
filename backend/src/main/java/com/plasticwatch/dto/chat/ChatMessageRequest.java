package com.plasticwatch.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ChatMessageRequest {

    @NotBlank(message = "Message content is required")
    @Size(max = 1000, message = "Message must not exceed 1000 characters")
    private String content;
}
