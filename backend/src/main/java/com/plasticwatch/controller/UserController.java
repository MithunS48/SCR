package com.plasticwatch.controller;

import com.plasticwatch.dto.ApiResponse;
import com.plasticwatch.dto.gamification.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.service.GamificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * User profile and leaderboard endpoints.
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Tag(name = "Users & Gamification", description = "User profile, badges, points, and leaderboard")
public class UserController {

    private final GamificationService gamificationService;

    @GetMapping("/me")
    @Operation(summary = "Get current user's profile with points, badges, and rank")
    public ResponseEntity<ApiResponse<ProfileResponse>> getProfile(
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.ok(gamificationService.getProfile(user)));
    }

    @GetMapping("/leaderboard")
    @Operation(summary = "Get top 50 users by points")
    public ResponseEntity<ApiResponse<List<LeaderboardEntryDto>>> getLeaderboard() {
        return ResponseEntity.ok(ApiResponse.ok(gamificationService.getLeaderboard()));
    }
}
