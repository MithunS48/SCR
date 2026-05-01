# Requirements Document

## Introduction

The Plastic Waste Monitoring and Awareness Program is a cross-platform mobile application (Flutter) backed by a Spring Boot REST API and MySQL database. It enables users to track their personal plastic consumption, report plastic waste in the field, visualize pollution hotspots on a map, participate in community clean-up events, scan QR codes at waste collection points, and earn gamification rewards. An AI module (TensorFlow Lite) provides on-device plastic detection from the device camera. Administrators manage reports, events, and content through role-based access controls secured with JWT authentication.

---

## Glossary

- **System**: The Plastic Waste Monitoring and Awareness Program as a whole (mobile app + backend).
- **App**: The Flutter mobile application.
- **Backend**: The Spring Boot REST API server.
- **Database**: The MySQL relational database.
- **User**: An authenticated individual with the "USER" role (student or general public).
- **Admin**: An authenticated individual with the "ADMIN" role who manages content and reports.
- **JWT**: JSON Web Token used for stateless authentication and authorization.
- **WasteReport**: A record submitted by a User containing an image, GPS coordinates, and description of observed plastic waste.
- **PlasticUsage**: A daily log entry recording the types and quantities of plastic items consumed by a User.
- **Event**: A community clean-up event with a title, description, location, date/time, and participant list.
- **QRLog**: A record created when a QR code is scanned, capturing timestamp, GPS location, and collector identity.
- **Badge**: A digital achievement awarded to a User upon meeting defined gamification criteria.
- **Points**: A numeric score accumulated by a User through tracked actions (logging usage, reporting waste, attending events, scanning QR codes).
- **Leaderboard**: A ranked list of Users ordered by Points.
- **Heatmap**: A Google Maps overlay visualizing WasteReport density by geographic area.
- **TFLite_Model**: The on-device TensorFlow Lite model used for plastic detection.
- **DTO**: Data Transfer Object — a typed payload used in API requests and responses.
- **Tracker**: The plastic usage tracking feature of the App.
- **Awareness_Module**: The section of the App displaying environmental tips, facts, and educational content.
- **QR_Scanner**: The in-app QR code scanning feature.
- **Auth_Service**: The backend service responsible for authentication and JWT issuance.
- **Report_Service**: The backend service responsible for WasteReport management.
- **Usage_Service**: The backend service responsible for PlasticUsage management.
- **Event_Service**: The backend service responsible for Event management.
- **QR_Service**: The backend service responsible for QR code generation and QRLog management.
- **Gamification_Service**: The backend service responsible for Points, Badges, and Leaderboard.
- **Awareness_Service**: The backend service responsible for Awareness_Module content.

---

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a visitor, I want to register and log in securely, so that I can access personalized features and my data is protected.

#### Acceptance Criteria

1. WHEN a visitor submits a registration request with a unique email address, display name, and a password of at least 8 characters, THE Auth_Service SHALL create a User account, store the password as a bcrypt hash, assign the "USER" role, and return an HTTP 201 response containing a JWT access token and a refresh token.
2. IF a visitor submits a registration request with an email address that already exists in the Database, THEN THE Auth_Service SHALL return an HTTP 409 response with a descriptive error message and SHALL NOT create a duplicate account.
3. IF a visitor submits a registration request with a password shorter than 8 characters or a malformed email address, THEN THE Auth_Service SHALL return an HTTP 400 response listing each validation failure and SHALL NOT create an account.
4. WHEN a registered User submits valid credentials (email and password), THE Auth_Service SHALL verify the bcrypt hash, generate a signed JWT access token with a 15-minute expiry and a refresh token with a 7-day expiry, and return both tokens in an HTTP 200 response.
5. IF a visitor submits a login request with an unrecognized email address or an incorrect password, THEN THE Auth_Service SHALL return an HTTP 401 response with a generic "Invalid credentials" message and SHALL NOT reveal which field was incorrect.
6. WHEN a client submits a valid refresh token before its expiry, THE Auth_Service SHALL issue a new JWT access token and return it in an HTTP 200 response.
7. IF a client submits an expired or tampered JWT access token to any protected endpoint, THEN THE Backend SHALL return an HTTP 401 response and SHALL NOT process the request.
8. WHEN an Admin account is required, THE Auth_Service SHALL support assigning the "ADMIN" role to a User account via a privileged backend operation, and WHILE a User holds the "ADMIN" role, THE Backend SHALL grant access to all admin-only endpoints.
9. THE Backend SHALL enforce role-based access control such that endpoints designated as admin-only return HTTP 403 for requests authenticated with the "USER" role.

---

### Requirement 2: Plastic Usage Tracker

**User Story:** As a User, I want to log my daily plastic consumption and view statistics, so that I can understand and reduce my plastic footprint over time.

#### Acceptance Criteria

1. WHEN an authenticated User submits a usage log entry specifying at least one plastic item category (e.g., bottle, bag, straw, container) and a non-negative integer quantity for each category, THE Usage_Service SHALL persist a PlasticUsage record linked to the User with the current date and return an HTTP 201 response containing the created record.
2. IF an authenticated User submits a usage log entry with a negative quantity for any item category, THEN THE Usage_Service SHALL return an HTTP 400 response listing the invalid fields and SHALL NOT persist the record.
3. WHEN an authenticated User requests daily statistics for a specified date, THE Usage_Service SHALL return the total item count and per-category breakdown for that date, or zero values if no entry exists for that date.
4. WHEN an authenticated User requests weekly statistics for a specified ISO week, THE Usage_Service SHALL return the total item count per day and the weekly aggregate for that week.
5. WHEN an authenticated User requests monthly statistics for a specified year and month, THE Usage_Service SHALL return the total item count per week and the monthly aggregate for that month.
6. WHEN an authenticated User requests a reduction percentage for a specified period (week or month), THE Usage_Service SHALL calculate the percentage change in total plastic items compared to the immediately preceding equivalent period and return the result rounded to one decimal place; WHERE no data exists for the preceding period, THE Usage_Service SHALL return a null reduction value with an explanatory message.
7. THE Database SHALL store all PlasticUsage records with a User foreign key, item category, quantity, and entry date, and SHALL enforce a unique constraint on (user_id, entry_date, item_category).
8. WHEN an authenticated User requests the full history of PlasticUsage records, THE Usage_Service SHALL return all records for that User ordered by entry date descending, paginated with a default page size of 20.

---

### Requirement 3: Waste Reporting System

**User Story:** As a User, I want to photograph and report plastic waste at a location, so that pollution hotspots can be identified and addressed.

#### Acceptance Criteria

1. WHEN an authenticated User submits a waste report containing an image file (JPEG or PNG, maximum 10 MB), GPS latitude and longitude coordinates, and a text description of at most 500 characters, THE Report_Service SHALL persist a WasteReport record with status "PENDING", store the image in the configured file storage, and return an HTTP 201 response containing the created report including a public image URL.
2. IF an authenticated User submits a waste report with a missing image, missing coordinates, or a description exceeding 500 characters, THEN THE Report_Service SHALL return an HTTP 400 response listing each validation failure and SHALL NOT persist the report.
3. IF an authenticated User submits an image file exceeding 10 MB or with a MIME type other than image/jpeg or image/png, THEN THE Report_Service SHALL return an HTTP 413 or HTTP 415 response respectively and SHALL NOT persist the report.
4. WHEN an authenticated User requests a list of their own WasteReports, THE Report_Service SHALL return all reports submitted by that User ordered by submission timestamp descending, paginated with a default page size of 20.
5. WHEN an authenticated Admin requests the list of all WasteReports, THE Report_Service SHALL return all reports across all Users, filterable by status ("PENDING", "APPROVED", "REJECTED", "CLEANED"), ordered by submission timestamp descending, paginated with a default page size of 20.
6. WHEN an authenticated Admin submits an approval action for a WasteReport with status "PENDING", THE Report_Service SHALL update the report status to "APPROVED" and return an HTTP 200 response with the updated report.
7. WHEN an authenticated Admin submits a rejection action for a WasteReport with status "PENDING", THE Report_Service SHALL update the report status to "REJECTED" and return an HTTP 200 response with the updated report.
8. WHEN an authenticated Admin marks a WasteReport with status "APPROVED" as cleaned, THE Report_Service SHALL update the report status to "CLEANED" and return an HTTP 200 response with the updated report.
9. IF an authenticated Admin attempts a status transition that is not permitted (e.g., "CLEANED" → "PENDING"), THEN THE Report_Service SHALL return an HTTP 422 response with a descriptive error message and SHALL NOT update the report.

---

### Requirement 4: Heatmap of Polluted Areas

**User Story:** As a User or Admin, I want to view a map showing pollution hotspots, so that I can understand where plastic waste is concentrated.

#### Acceptance Criteria

1. WHEN an authenticated User or Admin requests heatmap data, THE Report_Service SHALL return a list of GPS coordinate pairs and associated density weights derived from all WasteReports with status "APPROVED" or "CLEANED".
2. THE App SHALL render the heatmap data as a Google Maps overlay using the Google Maps API, displaying each coordinate cluster with a color corresponding to its density: red for high density (top 33% of clusters), yellow for medium density (middle 33%), and green for low density (bottom 33%).
3. WHEN the heatmap data set is empty, THE App SHALL display the Google Maps base layer with no overlay and a message indicating no approved reports are available.
4. THE App SHALL refresh heatmap data each time the heatmap screen is opened.
5. IF the device has no network connectivity when the heatmap screen is opened, THEN THE App SHALL display the last cached heatmap data and a banner indicating the data may be outdated.

---

### Requirement 5: AI Plastic Detection

**User Story:** As a User, I want to point my camera at an object and have the app detect whether it is plastic, so that I can quickly identify plastic waste.

#### Acceptance Criteria

1. WHEN an authenticated User opens the AI detection screen and grants camera permission, THE App SHALL activate the device camera and begin passing frames to the TFLite_Model for inference.
2. WHILE the camera is active on the AI detection screen, THE App SHALL run the TFLite_Model on each captured frame and display either "Plastic Detected" or "No Plastic Detected" as an overlay on the live camera feed, updated at a minimum rate of 5 frames per second.
3. IF the User denies camera permission, THEN THE App SHALL display an explanatory message and a button to open the device permission settings, and SHALL NOT attempt to access the camera.
4. THE App SHALL bundle the TFLite_Model as a local asset so that plastic detection functions without a network connection.
5. WHEN the TFLite_Model inference confidence score for the "plastic" class meets or exceeds 0.70, THE App SHALL display "Plastic Detected"; WHERE the confidence score is below 0.70, THE App SHALL display "No Plastic Detected".
6. WHEN a User taps the capture button on the AI detection screen while "Plastic Detected" is shown, THE App SHALL pre-populate the waste report submission form with the captured image and navigate to the report screen.

---

### Requirement 6: Community Clean-Up Events

**User Story:** As a User, I want to discover, register for, and create community clean-up events, so that I can participate in organized environmental action.

#### Acceptance Criteria

1. WHEN an authenticated User or Admin requests the list of Events, THE Event_Service SHALL return all Events ordered by event date ascending, paginated with a default page size of 20, including the title, description, location name, GPS coordinates, event date/time, organizer display name, and current participant count.
2. WHEN an authenticated User submits a new Event with a title (max 100 characters), description (max 1000 characters), location name, GPS coordinates, and a future event date/time, THE Event_Service SHALL persist the Event with status "UPCOMING", set the submitting User as organizer, and return an HTTP 201 response with the created Event.
3. IF an authenticated User submits a new Event with a past event date/time or missing required fields, THEN THE Event_Service SHALL return an HTTP 400 response listing each validation failure and SHALL NOT persist the Event.
4. WHEN an authenticated User registers for an Event with status "UPCOMING", THE Event_Service SHALL create a participation record linking the User to the Event, increment the participant count, and return an HTTP 200 response; IF the User is already registered, THEN THE Event_Service SHALL return an HTTP 409 response and SHALL NOT create a duplicate record.
5. WHEN an authenticated User cancels registration for an Event with status "UPCOMING", THE Event_Service SHALL remove the participation record, decrement the participant count, and return an HTTP 200 response.
6. WHEN an authenticated Admin updates an Event's status to "COMPLETED", THE Event_Service SHALL update the status and trigger the Gamification_Service to award participation badges and Points to all registered Users.
7. WHEN an authenticated Admin cancels an Event by setting its status to "CANCELLED", THE Event_Service SHALL update the status and return an HTTP 200 response.
8. WHERE the badge feature is enabled, THE Gamification_Service SHALL award a "Participant" badge to each User attending their first completed Event and a "Community Champion" badge to each User attending five or more completed Events.

---

### Requirement 7: QR-Based Waste Collection Tracking

**User Story:** As a waste collector or User, I want to scan a QR code at a collection point, so that waste collection events are logged with time, location, and collector identity.

#### Acceptance Criteria

1. WHEN an authenticated Admin requests a QR code for a User or a waste bin, THE QR_Service SHALL generate a unique QR code encoding a signed payload containing the entity type ("USER" or "BIN"), entity ID, and a server-generated token, and return the QR code as a PNG image in an HTTP 200 response.
2. WHEN an authenticated User opens the QR_Scanner and grants camera permission, THE App SHALL activate the device camera and scan for QR codes.
3. WHEN the QR_Scanner successfully decodes a valid QR code payload, THE App SHALL capture the current GPS coordinates and submit a scan event to the QR_Service containing the decoded payload, GPS coordinates, and the authenticated User's identity.
4. WHEN the QR_Service receives a valid scan event, THE QR_Service SHALL persist a QRLog record containing the entity type, entity ID, GPS coordinates, timestamp, and collector User ID, and return an HTTP 201 response with the created log.
5. IF the QR_Service receives a scan event with a tampered or unrecognized QR payload token, THEN THE QR_Service SHALL return an HTTP 400 response and SHALL NOT persist a QRLog record.
6. WHEN an authenticated Admin requests QRLog records, THE QR_Service SHALL return all logs filterable by entity type, entity ID, and date range, ordered by timestamp descending, paginated with a default page size of 20.
7. IF the device has no network connectivity when a QR code is scanned, THEN THE App SHALL queue the scan event locally and submit it to the QR_Service when connectivity is restored.

---

### Requirement 8: Awareness Module

**User Story:** As a User, I want to read environmental tips, facts, and educational content, so that I can learn how to reduce plastic waste.

#### Acceptance Criteria

1. THE Awareness_Service SHALL maintain a collection of Awareness content items, each containing a title (max 100 characters), body text (max 2000 characters), content type ("TIP", "FACT", or "ARTICLE"), and an optional icon identifier.
2. WHEN an authenticated User requests the Awareness content list, THE Awareness_Service SHALL return all published content items ordered by publication date descending, paginated with a default page size of 20.
3. WHEN an authenticated Admin creates an Awareness content item with valid title, body, and content type, THE Awareness_Service SHALL persist the item with status "PUBLISHED" and return an HTTP 201 response with the created item.
4. IF an authenticated Admin submits an Awareness content item with a title exceeding 100 characters or a body exceeding 2000 characters, THEN THE Awareness_Service SHALL return an HTTP 400 response listing each validation failure and SHALL NOT persist the item.
5. WHEN an authenticated Admin deletes an Awareness content item, THE Awareness_Service SHALL set the item status to "ARCHIVED" and return an HTTP 200 response; THE Awareness_Service SHALL NOT return archived items in the public content list.
6. THE App SHALL display Awareness content items as cards with the icon, title, and a truncated preview of the body text; WHEN a User taps a card, THE App SHALL display the full content item.

---

### Requirement 9: Gamification System

**User Story:** As a User, I want to earn points and badges for my environmental actions and see my rank on a leaderboard, so that I am motivated to continue reducing plastic waste.

#### Acceptance Criteria

1. THE Gamification_Service SHALL award Points to a User for the following actions at the specified rates: logging a PlasticUsage entry (5 points), submitting an approved WasteReport (10 points), registering for and attending a completed Event (20 points), and scanning a valid QR code (5 points).
2. WHEN a User's total Points reach a defined threshold, THE Gamification_Service SHALL award the corresponding Badge: "Eco Beginner" at 50 points, "Plastic Warrior" at 200 points, and "Community Champion" at 500 points.
3. WHEN an authenticated User requests their profile, THE Backend SHALL return the User's current total Points, list of earned Badges with award timestamps, and current leaderboard rank.
4. WHEN an authenticated User or Admin requests the Leaderboard, THE Gamification_Service SHALL return the top 50 Users ordered by total Points descending, each entry containing the User's display name, total Points, and earned Badge count.
5. THE Gamification_Service SHALL be idempotent with respect to Badge awards: awarding a Badge that a User already holds SHALL NOT create a duplicate Badge record.
6. WHEN Points are awarded to a User, THE Gamification_Service SHALL check all Badge thresholds and award any newly qualifying Badges in the same transaction.

---

### Requirement 10: Backend Architecture and API Standards

**User Story:** As a developer, I want the backend to follow consistent architectural and API standards, so that the system is maintainable, testable, and extensible.

#### Acceptance Criteria

1. THE Backend SHALL implement a layered architecture with three distinct layers: Controller (HTTP handling), Service (business logic), and Repository (data access), with no direct Database access from the Controller layer.
2. THE Backend SHALL use DTOs for all API request and response payloads, and SHALL NOT expose JPA entity objects directly in API responses.
3. WHEN any request payload fails Bean Validation constraints, THE Backend SHALL return an HTTP 400 response containing a structured error body with a field-level breakdown of all validation failures.
4. WHEN an unhandled exception occurs during request processing, THE Backend SHALL return an HTTP 500 response with a generic error message and SHALL log the full stack trace internally without exposing internal details to the client.
5. THE Backend SHALL document all REST API endpoints using OpenAPI 3.0 annotations, and SHALL expose the generated specification at the `/api-docs` path.
6. THE Backend SHALL apply database indexing on all foreign key columns and on columns used in frequent filter or sort operations (user_id, report status, event date, entry date, timestamp).
7. THE Backend SHALL enforce a maximum request body size of 15 MB to accommodate image uploads with metadata.
8. THE Backend SHALL return all timestamps in ISO 8601 format (UTC).

---

### Requirement 11: Mobile Application Architecture and UX

**User Story:** As a User, I want a clean, fast, and intuitive mobile experience, so that I can use all features without friction.

#### Acceptance Criteria

1. THE App SHALL implement the following named screens: Login, Register, Dashboard, Report Waste, Heatmap, Tracker, Events, Event Detail, AI Detection, QR Scanner, Awareness, Profile, and Leaderboard.
2. THE App SHALL use reusable widget components for common UI elements including form fields, buttons, cards, loading indicators, and error banners, and SHALL NOT duplicate widget implementations across screens.
3. WHEN an API call is in progress, THE App SHALL display a loading indicator and SHALL disable interactive controls that would trigger duplicate requests.
4. WHEN an API call returns an error response, THE App SHALL display a human-readable error message derived from the response body and SHALL NOT display raw HTTP status codes or stack traces to the User.
5. THE App SHALL store the JWT access token and refresh token in secure device storage (e.g., Flutter Secure Storage) and SHALL NOT store tokens in plain-text shared preferences.
6. WHEN the JWT access token has expired and a refresh token is available, THE App SHALL automatically attempt token refresh before retrying the failed request, transparent to the User.
7. WHEN a User logs out, THE App SHALL delete all locally stored tokens and cached user data and navigate to the Login screen.
8. THE App SHALL support both Android and iOS platforms.
9. THE App SHALL request GPS location permission before accessing device location; IF the User denies location permission, THEN THE App SHALL display an explanatory message and disable location-dependent features gracefully.
