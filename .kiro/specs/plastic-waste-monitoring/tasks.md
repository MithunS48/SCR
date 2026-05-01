# Implementation Plan: Plastic Waste Monitoring and Awareness Program

## Overview

Implement a cross-platform Flutter mobile application backed by a Spring Boot REST API and MySQL database. The system covers user authentication, plastic usage tracking, waste reporting, heatmap visualization, AI plastic detection (TFLite), community events, QR-based collection tracking, an awareness module, and a gamification system.

## Tasks

- [x] 1. Project scaffolding and shared infrastructure
  - Initialize Spring Boot project with dependencies: Spring Web, Spring Security, Spring Data JPA, MySQL Driver, Lombok, Validation, SpringDoc OpenAPI, jjwt
  - Initialize Flutter project with packages: dio, flutter_secure_storage, provider (or riverpod), google_maps_flutter, mobile_scanner, camera, tflite_flutter, geolocator
  - Configure MySQL datasource, JPA dialect, and Flyway (or Liquibase) for schema migrations
  - Define global exception handler (`@RestControllerAdvice`) returning structured HTTP 400/500 error bodies with field-level breakdown
  - Configure OpenAPI 3.0 via SpringDoc and expose spec at `/api-docs`
  - Set maximum request body size to 15 MB in Spring Boot configuration
  - Create base DTO classes and shared response envelope
  - Create reusable Flutter widgets: `AppTextField`, `AppButton`, `AppCard`, `LoadingOverlay`, `ErrorBanner`
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.7, 10.8, 11.2_

- [x] 2. Database schema and entity layer
  - [x] 2.1 Write Flyway migration scripts for all tables
    - `users` (id, email, display_name, password_hash, role, points, created_at)
    - `plastic_usage` (id, user_id, entry_date, item_category, quantity) with unique constraint on (user_id, entry_date, item_category)
    - `waste_reports` (id, user_id, image_url, latitude, longitude, description, status, created_at)
    - `events` (id, organizer_id, title, description, location_name, latitude, longitude, event_datetime, status, participant_count)
    - `event_participants` (event_id, user_id)
    - `qr_logs` (id, entity_type, entity_id, latitude, longitude, collector_user_id, timestamp)
    - `badges` (id, user_id, badge_name, awarded_at) with unique constraint on (user_id, badge_name)
    - `awareness_items` (id, title, body, content_type, icon_identifier, status, published_at)
    - Add indexes on all foreign key columns and filter/sort columns (user_id, status, event_datetime, entry_date, timestamp)
    - _Requirements: 2.7, 10.6_

  - [x] 2.2 Create JPA entity classes
    - `User`, `PlasticUsage`, `WasteReport`, `Event`, `EventParticipant`, `QRLog`, `Badge`, `AwarenessItem`
    - Map all relationships, constraints, and enum types (Role, ReportStatus, EventStatus, ContentType, EntityType)
    - _Requirements: 2.7, 10.1_

- [x] 3. Authentication and authorization (Backend)
  - [x] 3.1 Implement `Auth_Service` — registration endpoint
    - `POST /api/auth/register`: validate email uniqueness, validate password ≥ 8 chars and email format, bcrypt hash password, assign USER role, persist User, return HTTP 201 with JWT access token (15 min) and refresh token (7 days)
    - Return HTTP 409 on duplicate email; HTTP 400 on validation failures
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 3.2 Implement `Auth_Service` — login and token refresh endpoints
    - `POST /api/auth/login`: verify bcrypt hash, generate signed JWT + refresh token, return HTTP 200; return HTTP 401 with generic message on failure
    - `POST /api/auth/refresh`: validate refresh token, issue new JWT access token, return HTTP 200
    - _Requirements: 1.4, 1.5, 1.6_

  - [x] 3.3 Implement JWT security filter and RBAC
    - Spring Security filter chain: validate JWT on every protected request, return HTTP 401 on expired/tampered token
    - Role-based access: admin-only endpoints return HTTP 403 for USER role
    - Support ADMIN role assignment via privileged backend operation
    - _Requirements: 1.7, 1.8, 1.9_

  - [ ]* 3.4 Write unit tests for Auth_Service
    - Test registration happy path, duplicate email, password validation, login success, invalid credentials, token refresh
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 4. Authentication screens (Flutter)
  - [x] 4.1 Implement Login and Register screens
    - `LoginScreen`: email + password fields, submit calls `POST /api/auth/login`, stores JWT + refresh token in Flutter Secure Storage on success
    - `RegisterScreen`: email, display name, password fields with client-side validation, calls `POST /api/auth/register`
    - Display `ErrorBanner` on API error; show `LoadingOverlay` during request; disable submit button while in-flight
    - _Requirements: 1.1, 1.4, 11.1, 11.3, 11.4, 11.5_

  - [x] 4.2 Implement token refresh interceptor and logout
    - Dio interceptor: on 401 response, attempt `POST /api/auth/refresh` transparently, retry original request
    - Logout: delete all tokens and cached data from secure storage, navigate to Login screen
    - _Requirements: 11.5, 11.6, 11.7_

- [ ] 5. Checkpoint — Auth layer complete
  - Ensure all backend auth tests pass and the Flutter login/register flow works end-to-end against the running backend. Ask the user if questions arise.

- [x] 6. Plastic Usage Tracker (Backend)
  - [x] 6.1 Implement `Usage_Service` — log and history endpoints
    - `POST /api/usage`: validate item categories and non-negative quantities, persist PlasticUsage, return HTTP 201; return HTTP 400 on negative quantity
    - `GET /api/usage/history`: return all records for authenticated user ordered by entry_date desc, paginated (default page size 20)
    - _Requirements: 2.1, 2.2, 2.7, 2.8_

  - [x] 6.2 Implement `Usage_Service` — statistics endpoints
    - `GET /api/usage/stats/daily?date=`: return total count and per-category breakdown; return zeros if no entry
    - `GET /api/usage/stats/weekly?week=&year=`: return per-day totals and weekly aggregate
    - `GET /api/usage/stats/monthly?month=&year=`: return per-week totals and monthly aggregate
    - `GET /api/usage/stats/reduction?period=&ref=`: calculate percentage change vs preceding period, return null with message if no prior data
    - _Requirements: 2.3, 2.4, 2.5, 2.6_

  - [ ]* 6.3 Write unit tests for Usage_Service
    - Test log creation, negative quantity rejection, daily/weekly/monthly stats, reduction calculation with and without prior data
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 7. Plastic Usage Tracker (Flutter)
  - Implement `TrackerScreen`: form to select item category and enter quantity, submit calls `POST /api/usage`
  - Display daily stats chart (bar chart per category) and weekly/monthly trend line
  - Show reduction percentage badge when available; show explanatory message when null
  - _Requirements: 2.1, 2.3, 2.4, 2.5, 2.6, 11.1, 11.3, 11.4_

- [x] 8. Waste Reporting System (Backend)
  - [x] 8.1 Implement `Report_Service` — submission endpoint
    - `POST /api/reports` (multipart): validate image (JPEG/PNG, ≤ 10 MB), GPS coordinates, description ≤ 500 chars; store image in configured file storage; persist WasteReport with status PENDING; return HTTP 201 with public image URL
    - Return HTTP 400 on missing fields/description overflow, HTTP 413 on oversized image, HTTP 415 on wrong MIME type
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 8.2 Implement `Report_Service` — listing and admin moderation endpoints
    - `GET /api/reports/mine`: return user's own reports, ordered by created_at desc, paginated (default 20)
    - `GET /api/reports` (admin): return all reports filterable by status, ordered by created_at desc, paginated (default 20)
    - `PATCH /api/reports/{id}/approve` (admin): PENDING → APPROVED
    - `PATCH /api/reports/{id}/reject` (admin): PENDING → REJECTED
    - `PATCH /api/reports/{id}/clean` (admin): APPROVED → CLEANED
    - Return HTTP 422 on invalid status transitions
    - _Requirements: 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

  - [x] 8.3 Implement heatmap data endpoint
    - `GET /api/reports/heatmap`: return list of {latitude, longitude, weight} for all APPROVED and CLEANED reports
    - _Requirements: 4.1_

  - [ ]* 8.4 Write unit tests for Report_Service
    - Test submission validation, image size/type rejection, status transitions, invalid transition rejection
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 3.7, 3.8, 3.9_

- [x] 9. Waste Reporting and Heatmap (Flutter)
  - [x] 9.1 Implement `ReportWasteScreen`
    - Camera/gallery image picker, GPS coordinate capture (request location permission; show message and disable if denied), description field (500 char limit), submit calls `POST /api/reports`
    - Show `LoadingOverlay` during upload; display `ErrorBanner` on failure
    - _Requirements: 3.1, 3.2, 11.1, 11.3, 11.4, 11.9_

  - [x] 9.2 Implement `HeatmapScreen`
    - Fetch heatmap data from `GET /api/reports/heatmap` on screen open; render Google Maps overlay with density color coding (red/yellow/green by tertile)
    - Show empty-state message when data set is empty
    - Cache last-fetched data; show outdated-data banner when offline
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 10. Checkpoint — Reporting and heatmap complete
  - Ensure all backend report tests pass and Flutter report submission + heatmap rendering work correctly. Ask the user if questions arise.

- [x] 11. AI Plastic Detection (Flutter)
  - [x] 11.1 Bundle TFLite model and implement inference
    - Add TFLite model file as a Flutter asset
    - Initialize `tflite_flutter` interpreter; run inference on each camera frame at ≥ 5 FPS
    - Apply confidence threshold: display "Plastic Detected" if score ≥ 0.70, else "No Plastic Detected"
    - _Requirements: 5.1, 5.2, 5.4, 5.5_

  - [x] 11.2 Implement `AIDetectionScreen`
    - Request camera permission; show explanatory message + settings button if denied
    - Render live camera feed with detection label overlay
    - Capture button (visible when "Plastic Detected"): capture frame, pre-populate `ReportWasteScreen` with image, navigate to report screen
    - _Requirements: 5.1, 5.2, 5.3, 5.6, 11.1_

- [x] 12. Community Clean-Up Events (Backend)
  - [x] 12.1 Implement `Event_Service` — listing and creation endpoints
    - `GET /api/events`: return all events ordered by event_datetime asc, paginated (default 20), including organizer display name and participant count
    - `POST /api/events`: validate title ≤ 100 chars, description ≤ 1000 chars, future event_datetime, required fields; persist with status UPCOMING, set organizer; return HTTP 201
    - Return HTTP 400 on past date or missing fields
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 12.2 Implement `Event_Service` — registration and admin status endpoints
    - `POST /api/events/{id}/register`: create participation record, increment participant_count; return HTTP 409 if already registered
    - `DELETE /api/events/{id}/register`: remove participation record, decrement participant_count
    - `PATCH /api/events/{id}/status` (admin): set COMPLETED (triggers gamification) or CANCELLED
    - _Requirements: 6.4, 6.5, 6.6, 6.7_

  - [ ]* 12.3 Write unit tests for Event_Service
    - Test event creation validation, duplicate registration, cancellation, status transitions, gamification trigger on COMPLETED
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [x] 13. Community Events (Flutter)
  - Implement `EventsScreen`: paginated list of events with title, date, location, participant count
  - Implement `EventDetailScreen`: full event details, register/cancel registration button, status badge
  - Show `LoadingOverlay` during API calls; display `ErrorBanner` on errors
  - _Requirements: 6.1, 6.2, 6.4, 6.5, 11.1, 11.3, 11.4_

- [x] 14. QR-Based Waste Collection Tracking (Backend)
  - [x] 14.1 Implement `QR_Service` — QR code generation endpoint
    - `POST /api/qr/generate` (admin): generate unique QR code encoding signed payload {entityType, entityId, token}; return PNG image in HTTP 200
    - _Requirements: 7.1_

  - [x] 14.2 Implement `QR_Service` — scan event and log endpoints
    - `POST /api/qr/scan`: validate payload token signature; persist QRLog {entity_type, entity_id, latitude, longitude, collector_user_id, timestamp}; return HTTP 201
    - Return HTTP 400 on tampered/unrecognized token
    - `GET /api/qr/logs` (admin): return logs filterable by entity_type, entity_id, date range; ordered by timestamp desc, paginated (default 20)
    - _Requirements: 7.3, 7.4, 7.5, 7.6_

  - [ ]* 14.3 Write unit tests for QR_Service
    - Test QR generation, valid scan persistence, tampered token rejection, log filtering
    - _Requirements: 7.1, 7.4, 7.5, 7.6_

- [x] 15. QR Scanner (Flutter)
  - Implement `QRScannerScreen`: request camera permission; activate `mobile_scanner`; on successful decode, capture GPS coordinates and call `POST /api/qr/scan`
  - Queue scan event locally (shared preferences or SQLite) if offline; submit queued events when connectivity is restored
  - Show success/error feedback after submission
  - _Requirements: 7.2, 7.3, 7.4, 7.7, 11.1, 11.9_

- [ ] 16. Checkpoint — Events and QR tracking complete
  - Ensure all backend event and QR tests pass and Flutter event/QR screens work correctly. Ask the user if questions arise.

- [x] 17. Awareness Module (Backend)
  - [x] 17.1 Implement `Awareness_Service` — content endpoints
    - `GET /api/awareness`: return all PUBLISHED items ordered by published_at desc, paginated (default 20)
    - `POST /api/awareness` (admin): validate title ≤ 100 chars, body ≤ 2000 chars, valid content_type; persist with status PUBLISHED; return HTTP 201
    - `DELETE /api/awareness/{id}` (admin): set status to ARCHIVED; return HTTP 200; exclude ARCHIVED items from public list
    - Return HTTP 400 on validation failures
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ]* 17.2 Write unit tests for Awareness_Service
    - Test content creation, title/body length validation, archiving, exclusion of archived items from public list
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 18. Awareness Module (Flutter)
  - Implement `AwarenessScreen`: paginated list of content cards showing icon, title, and truncated body preview
  - On card tap, navigate to full content detail view
  - _Requirements: 8.2, 8.6, 11.1_

- [x] 19. Gamification System (Backend)
  - [x] 19.1 Implement `Gamification_Service` — points and badge award logic
    - Award points on: PlasticUsage log (5 pts), approved WasteReport (10 pts), completed Event attendance (20 pts), valid QR scan (5 pts)
    - In the same transaction as point award, check all badge thresholds and award newly qualifying badges (idempotent — no duplicate badge records)
    - Badge thresholds: "Eco Beginner" at 50 pts, "Plastic Warrior" at 200 pts, "Community Champion" at 500 pts
    - Event badges: "Participant" on first completed event, "Community Champion" on fifth completed event
    - _Requirements: 9.1, 9.2, 9.5, 9.6_

  - [x] 19.2 Implement profile and leaderboard endpoints
    - `GET /api/users/me`: return current user's total points, list of badges with award timestamps, and leaderboard rank
    - `GET /api/leaderboard`: return top 50 users ordered by points desc, each with display name, total points, and badge count
    - _Requirements: 9.3, 9.4_

  - [x] 19.3 Wire gamification triggers into other services
    - Call `Gamification_Service.awardPoints` from `Usage_Service` (on log creation), `Report_Service` (on report approval), `Event_Service` (on event COMPLETED), `QR_Service` (on valid scan)
    - _Requirements: 9.1, 9.6_

  - [ ]* 19.4 Write unit tests for Gamification_Service
    - Test point award rates, badge threshold triggers, idempotent badge award, leaderboard ordering
    - _Requirements: 9.1, 9.2, 9.4, 9.5, 9.6_

- [x] 20. Profile and Leaderboard (Flutter)
  - Implement `ProfileScreen`: display total points, earned badges with timestamps, and current leaderboard rank; fetch from `GET /api/users/me`
  - Implement `LeaderboardScreen`: display top 50 users with display name, points, and badge count; fetch from `GET /api/leaderboard`
  - _Requirements: 9.3, 9.4, 11.1_

- [x] 21. Dashboard and navigation wiring (Flutter)
  - Implement `DashboardScreen`: summary cards for points, recent reports, upcoming events, and a quick-action row
  - Wire bottom navigation or drawer to all named screens: Login, Register, Dashboard, Report Waste, Heatmap, Tracker, Events, Event Detail, AI Detection, QR Scanner, Awareness, Profile, Leaderboard
  - Ensure all screens use shared reusable widgets (`AppTextField`, `AppButton`, `AppCard`, `LoadingOverlay`, `ErrorBanner`) with no duplicated widget implementations
  - _Requirements: 11.1, 11.2, 11.8_

- [x] 22. Final checkpoint — Full integration
  - Ensure all backend unit tests pass across all services
  - Verify Flutter app navigates correctly across all 13 screens on both Android and iOS
  - Confirm JWT refresh interceptor works transparently and logout clears all stored data
  - Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at logical milestones
- The design document is currently empty; tasks are derived directly from the requirements specification
- Tech stack is defined in the requirements: Flutter (mobile), Spring Boot (backend), MySQL (database), TensorFlow Lite (on-device AI)
- Unit tests cover service-layer logic; Flutter widget tests are not included but can be added as optional sub-tasks
