package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.event.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.service.EventService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Community clean-up event endpoints.
 */
@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
@Tag(name = "Events", description = "Community clean-up event management")
public class EventController {

    private final EventService eventService;

    @GetMapping
    @Operation(summary = "List all events ordered by date")
    public ResponseEntity<ApiResponse<Page<EventResponse>>> listEvents(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(eventService.listEvents(user, page, size)));
    }

    @PostMapping
    @Operation(summary = "Create a new community event")
    public ResponseEntity<ApiResponse<EventResponse>> createEvent(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody EventRequest request) {
        EventResponse response = eventService.createEvent(user, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    @PostMapping("/{id}/register")
    @Operation(summary = "Register for an event")
    public ResponseEntity<ApiResponse<EventResponse>> register(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.ok(eventService.registerForEvent(id, user)));
    }

    @DeleteMapping("/{id}/register")
    @Operation(summary = "Cancel registration for an event")
    public ResponseEntity<ApiResponse<EventResponse>> cancelRegistration(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.ok(eventService.cancelRegistration(id, user)));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: update event status (COMPLETED or CANCELLED)")
    public ResponseEntity<ApiResponse<EventResponse>> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String status = body.get("status");
        return ResponseEntity.ok(ApiResponse.ok(eventService.updateStatus(id, status)));
    }
}
