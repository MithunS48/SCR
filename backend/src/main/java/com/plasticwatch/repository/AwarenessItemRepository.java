package com.plasticwatch.repository;

import com.plasticwatch.entity.AwarenessItem;
import com.plasticwatch.entity.AwarenessItem.ContentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AwarenessItemRepository extends JpaRepository<AwarenessItem, Long> {

    Page<AwarenessItem> findByStatusOrderByPublishedAtDesc(ContentStatus status, Pageable pageable);
}
