package com.plasticwatch.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;

/**
 * Handles JWT creation and validation for both access and refresh tokens.
 */
@Service
@Slf4j
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-token-expiry-ms}")
    private long accessTokenExpiryMs;

    @Value("${jwt.refresh-token-expiry-ms}")
    private long refreshTokenExpiryMs;

    private SecretKey getSigningKey() {
        // Use the secret bytes directly — pad/truncate to 32 bytes for HMAC-SHA256
        byte[] keyBytes = secret.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        // Ensure key is at least 32 bytes (256 bits) for HS256
        byte[] paddedKey = new byte[32];
        System.arraycopy(keyBytes, 0, paddedKey, 0, Math.min(keyBytes.length, 32));
        return Keys.hmacShaKeyFor(paddedKey);
    }

    /** Generate a short-lived access token. */
    public String generateAccessToken(String subject, Map<String, Object> claims) {
        return buildToken(subject, claims, accessTokenExpiryMs);
    }

    /** Generate a long-lived refresh token. */
    public String generateRefreshToken(String subject) {
        return buildToken(subject, Map.of("type", "refresh"), refreshTokenExpiryMs);
    }

    private String buildToken(String subject, Map<String, Object> claims, long expiryMs) {
        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiryMs))
                .signWith(getSigningKey())
                .compact();
    }

    /** Extract the subject (email) from a token. */
    public String extractSubject(String token) {
        return parseClaims(token).getSubject();
    }

    /** Validate a token — returns true if valid and not expired. */
    public boolean isTokenValid(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
