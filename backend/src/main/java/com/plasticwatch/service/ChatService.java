package com.plasticwatch.service;

import com.plasticwatch.dto.chat.*;
import com.plasticwatch.entity.ChatMessage;
import com.plasticwatch.entity.User;
import com.plasticwatch.exception.ResourceNotFoundException;
import com.plasticwatch.repository.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Community chat service — all authenticated users and admins can post and read messages.
 */
@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;

    /** Post a new message. */
    @Transactional
    public ChatMessageResponse postMessage(User sender, ChatMessageRequest request) {
        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .content(request.getContent())
                .deleted(false)
                .build();
        message = chatMessageRepository.save(message);
        return toResponse(message);
    }

    /** Get paginated messages ordered oldest → newest (for chat display). */
    public Page<ChatMessageResponse> getMessages(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return chatMessageRepository
                .findByDeletedFalseOrderBySentAtAsc(pageable)
                .map(this::toResponse);
    }

    /** Get latest messages (newest first) — for polling. */
    public Page<ChatMessageResponse> getLatestMessages(int size) {
        Pageable pageable = PageRequest.of(0, size);
        return chatMessageRepository
                .findByDeletedFalseOrderBySentAtDesc(pageable)
                .map(this::toResponse);
    }

    /** Admin: soft-delete a message. */
    @Transactional
    public ChatMessageResponse deleteMessage(Long messageId) {
        ChatMessage message = chatMessageRepository.findById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found: " + messageId));
        message.setDeleted(true);
        return toResponse(chatMessageRepository.save(message));
    }

    private ChatMessageResponse toResponse(ChatMessage m) {
        return ChatMessageResponse.builder()
                .id(m.getId())
                .senderId(m.getSender().getId())
                .senderDisplayName(m.getSender().getDisplayName())
                .senderRole(m.getSender().getRole().name())
                .content(m.isDeleted() ? "[Message deleted]" : m.getContent())
                .sentAt(m.getSentAt())
                .deleted(m.isDeleted())
                .build();
    }
}
