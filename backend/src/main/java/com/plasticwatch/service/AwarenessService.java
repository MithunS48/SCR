package com.plasticwatch.service;

import com.plasticwatch.dto.awareness.*;
import com.plasticwatch.entity.AwarenessItem;
import com.plasticwatch.entity.AwarenessItem.ContentStatus;
import com.plasticwatch.entity.AwarenessItem.ContentType;
import com.plasticwatch.exception.ResourceNotFoundException;
import com.plasticwatch.repository.AwarenessItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Manages awareness content (tips, facts, articles).
 */
@Service
@RequiredArgsConstructor
public class AwarenessService {

    private final AwarenessItemRepository awarenessItemRepository;

    /** Get all published items, newest first. */
    public Page<AwarenessItemResponse> getPublishedItems(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return awarenessItemRepository.findByStatusOrderByPublishedAtDesc(ContentStatus.PUBLISHED, pageable)
                .map(this::toResponse);
    }

    /** Admin: create a new awareness item. */
    @Transactional
    public AwarenessItemResponse createItem(AwarenessItemRequest request) {
        AwarenessItem item = AwarenessItem.builder()
                .title(request.getTitle())
                .body(request.getBody())
                .contentType(ContentType.valueOf(request.getContentType()))
                .iconIdentifier(request.getIconIdentifier())
                .status(ContentStatus.PUBLISHED)
                .build();

        item = awarenessItemRepository.save(item);
        return toResponse(item);
    }

    /** Admin: archive (soft-delete) an awareness item. */
    @Transactional
    public AwarenessItemResponse archiveItem(Long id) {
        AwarenessItem item = awarenessItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Awareness item not found: " + id));
        item.setStatus(ContentStatus.ARCHIVED);
        return toResponse(awarenessItemRepository.save(item));
    }

    private AwarenessItemResponse toResponse(AwarenessItem a) {
        return AwarenessItemResponse.builder()
                .id(a.getId())
                .title(a.getTitle())
                .body(a.getBody())
                .contentType(a.getContentType().name())
                .iconIdentifier(a.getIconIdentifier())
                .status(a.getStatus().name())
                .publishedAt(a.getPublishedAt())
                .build();
    }
}
