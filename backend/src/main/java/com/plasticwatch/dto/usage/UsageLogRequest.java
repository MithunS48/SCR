package com.plasticwatch.dto.usage;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UsageLogRequest {

    @NotBlank(message = "Item category is required")
    @Size(max = 50, message = "Item category must not exceed 50 characters")
    private String itemCategory;

    @Min(value = 0, message = "Quantity must be a non-negative integer")
    @NotNull(message = "Quantity is required")
    private Integer quantity;
}
