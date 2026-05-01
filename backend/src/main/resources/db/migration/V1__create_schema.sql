-- ============================================================
-- Plastic Watch Database Schema
-- V1: Initial schema creation
-- ============================================================

-- Users table
CREATE TABLE users (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    display_name  VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER',
    points        INT NOT NULL DEFAULT 0,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_role (role)
);

-- Plastic usage tracking
CREATE TABLE plastic_usage (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    entry_date    DATE NOT NULL,
    item_category VARCHAR(50) NOT NULL,
    quantity      INT NOT NULL DEFAULT 0,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_usage_user_date_category (user_id, entry_date, item_category),
    INDEX idx_usage_user_id (user_id),
    INDEX idx_usage_entry_date (entry_date),
    CONSTRAINT fk_usage_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Waste reports
CREATE TABLE waste_reports (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    image_url   VARCHAR(500) NOT NULL,
    latitude    DECIMAL(10, 8) NOT NULL,
    longitude   DECIMAL(11, 8) NOT NULL,
    description VARCHAR(500),
    status      ENUM('PENDING', 'APPROVED', 'REJECTED', 'CLEANED') NOT NULL DEFAULT 'PENDING',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reports_user_id (user_id),
    INDEX idx_reports_status (status),
    INDEX idx_reports_created_at (created_at),
    CONSTRAINT fk_reports_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Community clean-up events
CREATE TABLE events (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    organizer_id     BIGINT NOT NULL,
    title            VARCHAR(100) NOT NULL,
    description      VARCHAR(1000),
    location_name    VARCHAR(255) NOT NULL,
    latitude         DECIMAL(10, 8) NOT NULL,
    longitude        DECIMAL(11, 8) NOT NULL,
    event_datetime   DATETIME NOT NULL,
    status           ENUM('UPCOMING', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'UPCOMING',
    participant_count INT NOT NULL DEFAULT 0,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_events_organizer_id (organizer_id),
    INDEX idx_events_event_datetime (event_datetime),
    INDEX idx_events_status (status),
    CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Event participants (many-to-many)
CREATE TABLE event_participants (
    event_id   BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    joined_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id),
    INDEX idx_ep_user_id (user_id),
    CONSTRAINT fk_ep_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_ep_user  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE
);

-- QR scan logs
CREATE TABLE qr_logs (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_type       ENUM('USER', 'BIN') NOT NULL,
    entity_id         VARCHAR(100) NOT NULL,
    qr_token          VARCHAR(500) NOT NULL,
    latitude          DECIMAL(10, 8),
    longitude         DECIMAL(11, 8),
    collector_user_id BIGINT NOT NULL,
    scanned_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_qrlogs_collector (collector_user_id),
    INDEX idx_qrlogs_entity (entity_type, entity_id),
    INDEX idx_qrlogs_scanned_at (scanned_at),
    CONSTRAINT fk_qrlogs_collector FOREIGN KEY (collector_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Badges
CREATE TABLE badges (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    badge_name  VARCHAR(100) NOT NULL,
    awarded_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_badge_user_name (user_id, badge_name),
    INDEX idx_badges_user_id (user_id),
    CONSTRAINT fk_badges_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Awareness content
CREATE TABLE awareness_items (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(100) NOT NULL,
    body           TEXT NOT NULL,
    content_type   ENUM('TIP', 'FACT', 'ARTICLE') NOT NULL,
    icon_identifier VARCHAR(100),
    status         ENUM('PUBLISHED', 'ARCHIVED') NOT NULL DEFAULT 'PUBLISHED',
    published_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_awareness_status (status),
    INDEX idx_awareness_published_at (published_at)
);

-- Seed default admin user (password: Admin@1234)
INSERT INTO users (email, display_name, password_hash, role, points)
VALUES ('admin@plasticwatch.com', 'System Admin',
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i',
        'ADMIN', 0);

-- Seed sample awareness content
INSERT INTO awareness_items (title, body, content_type, icon_identifier) VALUES
('Reduce Single-Use Plastics', 'Carry a reusable bag and water bottle. Refusing single-use plastics is the most effective way to reduce plastic pollution at the source.', 'TIP', 'eco'),
('Plastic Takes 450 Years to Decompose', 'A single plastic bottle can take up to 450 years to fully decompose in a landfill. Choosing reusable alternatives makes a lasting difference.', 'FACT', 'hourglass'),
('The Great Pacific Garbage Patch', 'The Great Pacific Garbage Patch is a collection of marine debris in the North Pacific Ocean, estimated to be twice the size of Texas.', 'ARTICLE', 'water'),
('Recycle Right', 'Not all plastics are recyclable. Check the recycling number on the bottom of containers. Numbers 1 and 2 are most widely accepted.', 'TIP', 'recycling'),
('Microplastics in Our Food', 'Studies show that humans may be ingesting up to 5 grams of microplastics per week — equivalent to a credit card — through food and water.', 'FACT', 'warning');
