package com.plasticwatch.service;

import com.plasticwatch.dto.auth.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.exception.BadRequestException;
import com.plasticwatch.exception.ConflictException;
import com.plasticwatch.repository.UserRepository;
import com.plasticwatch.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.*;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * Handles user registration, login, and token refresh.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    /**
     * Register a new user.
     * Role defaults to USER.
     * ADMIN role can only be assigned if the current authenticated user is already an ADMIN.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("An account with this email address already exists");
        }

        // Determine role
        User.Role role = User.Role.USER;
        if (request.getRole() != null && !request.getRole().isBlank()) {
            try {
                User.Role requestedRole = User.Role.valueOf(request.getRole().toUpperCase());
                if (requestedRole == User.Role.ADMIN) {
                    // Only an authenticated admin can create another admin
                    var auth = SecurityContextHolder.getContext().getAuthentication();
                    boolean isCallerAdmin = auth != null &&
                            auth.getAuthorities().stream()
                                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
                    if (!isCallerAdmin) {
                        throw new BadRequestException(
                                "Only administrators can create accounts with the ADMIN role");
                    }
                }
                role = requestedRole;
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid role. Accepted values: USER, ADMIN");
            }
        }

        User user = User.builder()
                .email(request.getEmail())
                .displayName(request.getDisplayName())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .build();

        user = userRepository.save(user);
        log.info("New user registered: {} with role {}", user.getEmail(), user.getRole());

        return buildAuthResponse(user);
    }

    /**
     * Authenticate a user and return JWT tokens.
     * Returns generic error message to avoid revealing which field is wrong.
     */
    public AuthResponse login(LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        } catch (AuthenticationException e) {
            throw new BadCredentialsException("Invalid credentials");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid credentials"));

        return buildAuthResponse(user);
    }

    /**
     * Issue a new access token from a valid refresh token.
     */
    public AuthResponse refresh(RefreshTokenRequest request) {
        String token = request.getRefreshToken();
        if (!jwtService.isTokenValid(token)) {
            throw new BadCredentialsException("Invalid or expired refresh token");
        }

        String email = jwtService.extractSubject(token);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        String newAccessToken = jwtService.generateAccessToken(
                user.getEmail(), Map.of("role", user.getRole().name()));

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(token)   // keep the same refresh token
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .displayName(user.getDisplayName())
                .role(user.getRole().name())
                .build();
    }

    private AuthResponse buildAuthResponse(User user) {
        Map<String, Object> claims = Map.of("role", user.getRole().name());
        String accessToken  = jwtService.generateAccessToken(user.getEmail(), claims);
        String refreshToken = jwtService.generateRefreshToken(user.getEmail());

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .displayName(user.getDisplayName())
                .role(user.getRole().name())
                .build();
    }
}
