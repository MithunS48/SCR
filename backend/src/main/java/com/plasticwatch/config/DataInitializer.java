package com.plasticwatch.config;

import com.plasticwatch.entity.User;
import com.plasticwatch.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Runs on startup to ensure the default admin account has the correct password hash.
 * This fixes any mismatch between the SQL seed hash and the actual BCrypt encoder.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements ApplicationRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String ADMIN_EMAIL    = "admin@plasticwatch.com";
    private static final String ADMIN_PASSWORD = "Admin@1234";

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        userRepository.findByEmail(ADMIN_EMAIL).ifPresent(admin -> {
            // Re-encode and update the password to ensure it's correct
            if (!passwordEncoder.matches(ADMIN_PASSWORD, admin.getPasswordHash())) {
                admin.setPasswordHash(passwordEncoder.encode(ADMIN_PASSWORD));
                userRepository.save(admin);
                log.info("Admin password hash updated for: {}", ADMIN_EMAIL);
            } else {
                log.info("Admin password hash is already correct for: {}", ADMIN_EMAIL);
            }
        });

        // Create admin if not exists (in case Flyway seed failed)
        if (!userRepository.existsByEmail(ADMIN_EMAIL)) {
            User admin = User.builder()
                    .email(ADMIN_EMAIL)
                    .displayName("System Admin")
                    .passwordHash(passwordEncoder.encode(ADMIN_PASSWORD))
                    .role(User.Role.ADMIN)
                    .build();
            userRepository.save(admin);
            log.info("Default admin account created: {}", ADMIN_EMAIL);
        }
    }
}
