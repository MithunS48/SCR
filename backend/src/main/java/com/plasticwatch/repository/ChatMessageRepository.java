package com.plasticwatch.repository;

import com.plasticwatch.entity.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    /** Get all non-deleted messages ordered by newest first (for pagination). */
    Page<ChatMessage> findByDeletedFalseOrderBySentAtDesc(Pageable pageable);

    /** Get all non-deleted messages ordered by oldest first (for chat display). */
    Page<ChatMessage> findByDeletedFalseOrderBySentAtAsc(Pageable pageable);
}
