package com.plasticwatch;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Smoke test — verifies the Spring application context loads without errors.
 */
@SpringBootTest
@ActiveProfiles("test")
class PlasticWatchApplicationTests {

    @Test
    void contextLoads() {
        // If this test passes, the full Spring context wired up correctly
    }
}
