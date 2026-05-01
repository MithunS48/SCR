-- Community chat messages table
CREATE TABLE chat_messages (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    sender_id  BIGINT NOT NULL,
    content    VARCHAR(1000) NOT NULL,
    sent_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    INDEX idx_chat_sender_id (sender_id),
    INDEX idx_chat_sent_at (sent_at),
    CONSTRAINT fk_chat_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);
