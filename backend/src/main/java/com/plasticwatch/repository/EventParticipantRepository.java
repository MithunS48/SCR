package com.plasticwatch.repository;

import com.plasticwatch.entity.EventParticipant;
import com.plasticwatch.entity.EventParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface EventParticipantRepository extends JpaRepository<EventParticipant, EventParticipantId> {

    boolean existsByEventIdAndUserId(Long eventId, Long userId);

    @Transactional
    void deleteByEventIdAndUserId(Long eventId, Long userId);

    List<EventParticipant> findByEventId(Long eventId);

    @Query("SELECT ep.user.id FROM EventParticipant ep WHERE ep.event.id = :eventId")
    List<Long> findUserIdsByEventId(@Param("eventId") Long eventId);

    /** Count how many completed events a user has attended. */
    @Query("SELECT COUNT(ep) FROM EventParticipant ep WHERE ep.user.id = :userId " +
           "AND ep.event.status = :status")
    long countCompletedEventsByUserId(@Param("userId") Long userId,
            @Param("status") com.plasticwatch.entity.Event.EventStatus status);
}
