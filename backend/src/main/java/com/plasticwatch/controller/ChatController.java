package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.chat.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Community chat endpoints — all authenticated users and admins can participate.
 */
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
@Tag(name = "Community Chat", description = "Real-time community chat for all users and admins")
public class ChatController {

    private final ChatService chatService;

    @GetMapping
    @Operation(summary = "Get paginated chat messages (oldest first)")
    public ResponseEntity<ApiResponse<Page<ChatMessageResponse>>> getMessages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(ApiResponse.ok(chatService.getMessages(page, size)));
    }

    @GetMapping("/latest")
    @Operation(summary = "Get latest N messages (newest first) — for polling")
    public ResponseEntity<ApiResponse<Page<ChatMessageResponse>>> getLatest(
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(chatService.getLatestMessages(size)));
    }

    @PostMapping
    @Operation(summary = "Post a new chat message")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> postMessage(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ChatMessageRequest request) {
        ChatMessageResponse response = chatService.postMessage(user, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: soft-delete a chat message")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> deleteMessage(
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(chatService.deleteMessage(id)));
    }
}
