package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.awareness.*;
import com.plasticwatch.service.AwarenessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Awareness content endpoints (tips, facts, articles).
 */
@RestController
@RequestMapping("/awareness")
@RequiredArgsConstructor
@Tag(name = "Awareness", description = "Environmental tips, facts, and educational content")
public class AwarenessController {

    private final AwarenessService awarenessService;

    @GetMapping
    @Operation(summary = "Get published awareness content")
    public ResponseEntity<ApiResponse<Page<AwarenessItemResponse>>> getItems(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(awarenessService.getPublishedItems(page, size)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: create a new awareness content item")
    public ResponseEntity<ApiResponse<AwarenessItemResponse>> createItem(
            @Valid @RequestBody AwarenessItemRequest request) {
        AwarenessItemResponse response = awarenessService.createItem(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: archive (soft-delete) an awareness item")
    public ResponseEntity<ApiResponse<AwarenessItemResponse>> archiveItem(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(awarenessService.archiveItem(id)));
    }
}
