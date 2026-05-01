package com.plasticwatch.repository;

import com.plasticwatch.entity.Badge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BadgeRepository extends JpaRepository<Badge, Long> {

    List<Badge> findByUserIdOrderByAwardedAtDesc(Long userId);

    boolean existsByUserIdAndBadgeName(Long userId, String badgeName);

    long countByUserId(Long userId);
}
