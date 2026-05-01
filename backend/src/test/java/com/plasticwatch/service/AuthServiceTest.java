package com.plasticwatch.service;

import com.plasticwatch.dto.auth.*;
import com.plasticwatch.entity.User;
import com.plasticwatch.exception.ConflictException;
import com.plasticwatch.repository.UserRepository;
import com.plasticwatch.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtService jwtService;
    @Mock AuthenticationManager authenticationManager;

    @InjectMocks AuthService authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;

    @BeforeEach
    void setUp() {
        registerRequest = new RegisterRequest("test@example.com", "Test User", "password123", "USER");
        loginRequest    = new LoginRequest("test@example.com", "password123");
    }

    @Test
    void register_success_returnsTokens() {
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(1L);
            return u;
        });
        when(jwtService.generateAccessToken(anyString(), anyMap())).thenReturn("access-token");
        when(jwtService.generateRefreshToken(anyString())).thenReturn("refresh-token");

        AuthResponse response = authService.register(registerRequest);

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getEmail()).isEqualTo("test@example.com");
        assertThat(response.getRole()).isEqualTo("USER");
    }

    @Test
    void register_duplicateEmail_throwsConflict() {
        when(userRepository.existsByEmail("test@example.com")).thenReturn(true);
        assertThatThrownBy(() -> authService.register(registerRequest))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void login_validCredentials_returnsTokens() {
        User user = User.builder()
                .id(1L).email("test@example.com").displayName("Test User")
                .passwordHash("hashed").role(User.Role.USER).build();

        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(jwtService.generateAccessToken(anyString(), anyMap())).thenReturn("access-token");
        when(jwtService.generateRefreshToken(anyString())).thenReturn("refresh-token");

        AuthResponse response = authService.login(loginRequest);
        assertThat(response.getAccessToken()).isEqualTo("access-token");
    }

    @Test
    void login_invalidCredentials_throwsBadCredentials() {
        doThrow(new BadCredentialsException("bad"))
                .when(authenticationManager).authenticate(any());
        assertThatThrownBy(() -> authService.login(loginRequest))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void refresh_validToken_returnsNewAccessToken() {
        User user = User.builder()
                .id(1L).email("test@example.com").displayName("Test User")
                .passwordHash("hashed").role(User.Role.USER).build();

        when(jwtService.isTokenValid("valid-refresh")).thenReturn(true);
        when(jwtService.extractSubject("valid-refresh")).thenReturn("test@example.com");
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(jwtService.generateAccessToken(anyString(), anyMap())).thenReturn("new-access-token");

        AuthResponse response = authService.refresh(new RefreshTokenRequest("valid-refresh"));
        assertThat(response.getAccessToken()).isEqualTo("new-access-token");
    }
}
