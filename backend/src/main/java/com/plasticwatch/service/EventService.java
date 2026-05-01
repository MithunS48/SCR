package com.plasticwatch.service;

import com.plasticwatch.dto.event.*;
import com.plasticwatch.entity.*;
import com.plasticwatch.entity.Event.EventStatus;
import com.plasticwatch.exception.*;
import com.plasticwatch.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Manages community clean-up events and participant registration.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EventService {

    private final EventRepository eventRepository;
    private final EventParticipantRepository participantRepository;
    private final UserRepository userRepository;
    private final GamificationService gamificationService;

    /** List all events ordered by date ascending. */
    public Page<EventResponse> listEvents(User currentUser, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return eventRepository.findAllByOrderByEventDatetimeAsc(pageable)
                .map(e -> toResponse(e, currentUser));
    }

    /** Create a new event. */
    @Transactional
    public EventResponse createEvent(User organizer, EventRequest request) {
        if (!request.getEventDatetime().isAfter(Instant.now())) {
            throw new BadRequestException("Event date/time must be in the future");
        }

        Event event = Event.builder()
                .organizer(organizer)
                .title(request.getTitle())
                .description(request.getDescription())
                .locationName(request.getLocationName())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .eventDatetime(request.getEventDatetime())
                .status(EventStatus.UPCOMING)
                .participantCount(0)
                .build();

        event = eventRepository.save(event);
        log.info("Event {} created by user {}", event.getId(), organizer.getId());
        return toResponse(event, organizer);
    }

    /** Register current user for an event. */
    @Transactional
    public EventResponse registerForEvent(Long eventId, User user) {
        Event event = findById(eventId);
        if (event.getStatus() != EventStatus.UPCOMING) {
            throw new BadRequestException("Can only register for UPCOMING events");
        }
        if (participantRepository.existsByEventIdAndUserId(eventId, user.getId())) {
            throw new ConflictException("You are already registered for this event");
        }

        EventParticipant participant = EventParticipant.builder()
                .event(event)
                .user(user)
                .build();
        participantRepository.save(participant);

        event.setParticipantCount(event.getParticipantCount() + 1);
        event = eventRepository.save(event);

        return toResponse(event, user);
    }

    /** Cancel registration for an event. */
    @Transactional
    public EventResponse cancelRegistration(Long eventId, User user) {
        Event event = findById(eventId);
        if (event.getStatus() != EventStatus.UPCOMING) {
            throw new BadRequestException("Can only cancel registration for UPCOMING events");
        }
        if (!participantRepository.existsByEventIdAndUserId(eventId, user.getId())) {
            throw new ResourceNotFoundException("You are not registered for this event");
        }

        participantRepository.deleteByEventIdAndUserId(eventId, user.getId());
        event.setParticipantCount(Math.max(0, event.getParticipantCount() - 1));
        event = eventRepository.save(event);

        return toResponse(event, user);
    }

    /** Admin: update event status. */
    @Transactional
    public EventResponse updateStatus(Long eventId, String newStatus) {
        Event event = findById(eventId);
        EventStatus target;
        try {
            target = EventStatus.valueOf(newStatus.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid event status: " + newStatus);
        }

        event.setStatus(target);
        event = eventRepository.save(event);

        // If completed, award points and badges to all participants
        if (target == EventStatus.COMPLETED) {
            List<Long> participantIds = participantRepository.findUserIdsByEventId(eventId);
            for (Long userId : participantIds) {
                userRepository.findById(userId).ifPresent(u -> {
                    gamificationService.awardPoints(u, 20, "Attended completed event");
                    gamificationService.awardEventBadges(u);
                });
            }
        }

        return toResponse(event, null);
    }

    private Event findById(Long id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + id));
    }

    private EventResponse toResponse(Event e, User currentUser) {
        boolean registered = currentUser != null &&
                participantRepository.existsByEventIdAndUserId(e.getId(), currentUser.getId());

        return EventResponse.builder()
                .id(e.getId())
                .organizerId(e.getOrganizer().getId())
                .organizerDisplayName(e.getOrganizer().getDisplayName())
                .title(e.getTitle())
                .description(e.getDescription())
                .locationName(e.getLocationName())
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .eventDatetime(e.getEventDatetime())
                .status(e.getStatus().name())
                .participantCount(e.getParticipantCount())
                .registeredByCurrentUser(registered)
                .createdAt(e.getCreatedAt())
                .build();
    }
}
