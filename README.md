# PlasticWatch — Plastic Waste Monitoring and Awareness Program

A full-stack mobile application to track plastic usage, report waste, visualize pollution hotspots, and drive community environmental action.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Android + iOS) |
| Backend | Spring Boot 3.2 (Java 17) |
| Database | MySQL 8.0 |
| Auth | JWT (jjwt 0.12) |
| Maps | Google Maps Flutter |
| AI | TensorFlow Lite (on-device) |
| QR | ZXing (backend) + mobile_scanner (Flutter) |

## Features

- **Auth** — JWT login/register, role-based access (User / Admin)
- **Plastic Tracker** — Daily usage logging, weekly/monthly charts, reduction %
- **Waste Reports** — Photo + GPS reports, admin moderation (Approve/Reject/Clean)
- **Heatmap** — Google Maps overlay with red/yellow/green pollution density
- **AI Detection** — Real-time TFLite plastic detection from camera (≥0.70 confidence)
- **Events** — Create, browse, register for community clean-up events
- **QR Tracking** — Generate QR codes for bins/users, scan to log collection events
- **Awareness** — Tips, facts, and articles with card UI
- **Gamification** — Points, badges (Eco Beginner / Plastic Warrior / Community Champion), leaderboard

## Quick Start

```bash
# 1. Start MySQL + Backend via Docker
docker-compose up -d

# 2. Run Flutter app
cd frontend
flutter pub get
flutter run
```

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for full setup instructions.

## Project Structure

```
├── backend/          # Spring Boot REST API
├── frontend/         # Flutter mobile app
├── docker-compose.yml
├── SETUP_GUIDE.md
└── README.md
```

## Default Admin

```
Email:    admin@plasticwatch.com
Password: Admin@1234
```

## API Docs

Once the backend is running:
- Swagger UI: http://localhost:8080/api/swagger-ui.html
- OpenAPI JSON: http://localhost:8080/api/api-docs
