package com.plasticwatch.service;

import com.plasticwatch.dto.event.*;
import com.plasticwatch.entity.*;
import com.plasticwatch.entity.Event.EventStatus;
import com.plasticwatch.exception.*;
import com.plasticwatch.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock EventRepository eventRepository;
    @Mock EventParticipantRepository participantRepository;
    @Mock UserRepository userRepository;
    @Mock GamificationService gamificationService;

    @InjectMocks EventService eventService;

    private User organizer;
    private EventRequest validRequest;

    @BeforeEach
    void setUp() {
        organizer = User.builder().id(1L).email("org@test.com").displayName("Organizer")
                .role(User.Role.USER).points(0).build();

        validRequest = new EventRequest(
                "Beach Cleanup", "Clean the beach",
                "Juhu Beach", BigDecimal.valueOf(19.09), BigDecimal.valueOf(72.82),
                Instant.now().plus(7, ChronoUnit.DAYS));
    }

    // ---- Create event ----

    @Test
    void createEvent_futureDate_persistsEvent() {
        Event saved = buildEvent(EventStatus.UPCOMING);
        when(eventRepository.save(any())).thenReturn(saved);

        EventResponse response = eventService.createEvent(organizer, validRequest);

        assertThat(response.getStatus()).isEqualTo("UPCOMING");
        assertThat(response.getTitle()).isEqualTo("Beach Cleanup");
    }

    @Test
    void createEvent_pastDate_throwsBadRequest() {
        validRequest = new EventRequest(
                "Old Event", "desc", "Location",
                BigDecimal.ONE, BigDecimal.ONE,
                Instant.now().minus(1, ChronoUnit.DAYS));

        assertThatThrownBy(() -> eventService.createEvent(organizer, validRequest))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("future");
    }

    // ---- Registration ----

    @Test
    void registerForEvent_notRegistered_createsParticipation() {
        Event event = buildEvent(EventStatus.UPCOMING);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));
        when(participantRepository.existsByEventIdAndUserId(1L, 1L)).thenReturn(false);
        when(eventRepository.save(any())).thenReturn(event);

        EventResponse response = eventService.registerForEvent(1L, organizer);

        assertThat(response.getParticipantCount()).isEqualTo(1);
        verify(participantRepository).save(any(EventParticipant.class));
    }

    @Test
    void registerForEvent_alreadyRegistered_throwsConflict() {
        Event event = buildEvent(EventStatus.UPCOMING);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));
        when(participantRepository.existsByEventIdAndUserId(1L, 1L)).thenReturn(true);

        assertThatThrownBy(() -> eventService.registerForEvent(1L, organizer))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void registerForEvent_completedEvent_throwsBadRequest() {
        Event event = buildEvent(EventStatus.COMPLETED);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> eventService.registerForEvent(1L, organizer))
                .isInstanceOf(BadRequestException.class);
    }

    // ---- Cancel registration ----

    @Test
    void cancelRegistration_registered_removesParticipation() {
        Event event = buildEvent(EventStatus.UPCOMING);
        event.setParticipantCount(2);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));
        when(participantRepository.existsByEventIdAndUserId(1L, 1L)).thenReturn(true);
        when(eventRepository.save(any())).thenReturn(event);

        EventResponse response = eventService.cancelRegistration(1L, organizer);

        assertThat(response.getParticipantCount()).isEqualTo(1);
        verify(participantRepository).deleteByEventIdAndUserId(1L, 1L);
    }

    // ---- Admin status update ----

    @Test
    void updateStatus_toCompleted_triggersGamification() {
        Event event = buildEvent(EventStatus.UPCOMING);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));
        when(eventRepository.save(any())).thenReturn(event);
        when(participantRepository.findUserIdsByEventId(1L)).thenReturn(List.of(1L));
        when(userRepository.findById(1L)).thenReturn(Optional.of(organizer));

        eventService.updateStatus(1L, "COMPLETED");

        verify(gamificationService).awardPoints(eq(organizer), eq(20), anyString());
        verify(gamificationService).awardEventBadges(organizer);
    }

    @Test
    void updateStatus_invalidStatus_throwsBadRequest() {
        Event event = buildEvent(EventStatus.UPCOMING);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> eventService.updateStatus(1L, "INVALID"))
                .isInstanceOf(BadRequestException.class);
    }

    // ---- Helpers ----

    private Event buildEvent(EventStatus status) {
        Event e = Event.builder()
                .id(1L).organizer(organizer).title("Beach Cleanup")
                .description("Clean the beach").locationName("Juhu Beach")
                .latitude(BigDecimal.valueOf(19.09)).longitude(BigDecimal.valueOf(72.82))
                .eventDatetime(Instant.now().plus(7, ChronoUnit.DAYS))
                .status(status).participantCount(0).build();
        org.springframework.test.util.ReflectionTestUtils.setField(e, "createdAt", Instant.now());
        return e;
    }
}
