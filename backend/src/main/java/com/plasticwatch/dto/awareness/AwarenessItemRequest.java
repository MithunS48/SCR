package com.plasticwatch.dto.awareness;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class AwarenessItemRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 100, message = "Title must not exceed 100 characters")
    private String title;

    @NotBlank(message = "Body is required")
    @Size(max = 2000, message = "Body must not exceed 2000 characters")
    private String body;

    @NotBlank(message = "Content type is required")
    @Pattern(regexp = "TIP|FACT|ARTICLE", message = "Content type must be TIP, FACT, or ARTICLE")
    private String contentType;

    private String iconIdentifier;
}
