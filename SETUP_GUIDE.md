# PlasticWatch — Setup Guide

## Prerequisites

| Tool | Version |
|------|---------|
| Java JDK | 17+ |
| Maven | 3.9+ |
| MySQL | 8.0+ |
| Flutter SDK | 3.19+ |
| Android Studio / Xcode | Latest |
| Git | Any |

---

## 1. Database Setup

```sql
-- Connect to MySQL as root
CREATE DATABASE plastic_watch CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'plasticwatch'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON plastic_watch.* TO 'plasticwatch'@'localhost';
FLUSH PRIVILEGES;
```

Flyway will automatically run all migration scripts in `backend/src/main/resources/db/migration/` on first startup.

---

## 2. Backend Setup (Spring Boot)

### Configure environment variables

```bash
export DB_USERNAME=plasticwatch
export DB_PASSWORD=your_password
export JWT_SECRET=YourSuperSecretJWTKeyThatIsAtLeast256BitsLong
export UPLOAD_DIR=/path/to/uploads
export BASE_URL=http://localhost:8080/api
```

Or edit `backend/src/main/resources/application.yml` directly.

### Build and run

```bash
cd backend
mvn clean install -DskipTests
mvn spring-boot:run
```

The backend starts on **http://localhost:8080/api**

### Verify

- Swagger UI: http://localhost:8080/api/swagger-ui.html
- OpenAPI spec: http://localhost:8080/api/api-docs

### Default admin credentials

```
Email:    admin@plasticwatch.com
Password: Admin@1234
```

---

## 3. Frontend Setup (Flutter)

### Install dependencies

```bash
cd frontend
flutter pub get
```

### Configure API URL

Edit `frontend/lib/core/constants/api_constants.dart`:

```dart
// For Android emulator (default)
static const String baseUrl = 'http://10.0.2.2:8080/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:8080/api';

// For physical device (use your machine's local IP)
static const String baseUrl = 'http://192.168.1.x:8080/api';
```

### Configure Google Maps API Key

1. Get a key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable: Maps SDK for Android, Maps SDK for iOS
3. **Android**: Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `frontend/android/app/src/main/AndroidManifest.xml`
4. **iOS**: Add to `frontend/ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_KEY_HERE")
   ```

### Add TFLite model

Place your plastic detection model at:
```
frontend/assets/models/plastic_detection.tflite
```

A compatible pre-trained model can be downloaded from:
- [TensorFlow Hub — MobileNet](https://tfhub.dev/google/imagenet/mobilenet_v2_100_224/classification/5)
- Or use any image classification model fine-tuned for plastic detection

The model should output a 2-class probability: `[plastic_score, non_plastic_score]`

### Run on Android

```bash
flutter run
```

### Run on iOS

```bash
cd ios && pod install && cd ..
flutter run
```

### Build release APK

```bash
flutter build apk --release
```

---

## 4. Project Structure

```
plastic-watch/
├── backend/                          # Spring Boot backend
│   ├── src/main/java/com/plasticwatch/
│   │   ├── PlasticWatchApplication.java
│   │   ├── controller/               # REST controllers
│   │   ├── service/                  # Business logic
│   │   ├── repository/               # JPA repositories
│   │   ├── entity/                   # JPA entities
│   │   ├── dto/                      # Request/response DTOs
│   │   ├── security/                 # JWT + Spring Security
│   │   └── exception/                # Exception handling
│   └── src/main/resources/
│       ├── application.yml
│       └── db/migration/             # Flyway SQL scripts
│
└── frontend/                         # Flutter mobile app
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/            # API URLs
        │   ├── models/               # Data models
        │   ├── network/              # Dio API client
        │   ├── providers/            # State management
        │   ├── router/               # Navigation
        │   └── theme/                # App theme
        ├── features/
        │   ├── auth/                 # Login / Register
        │   ├── dashboard/            # Home screen
        │   ├── tracker/              # Plastic usage tracker
        │   ├── reports/              # Waste reporting
        │   ├── map/                  # Heatmap
        │   ├── events/               # Community events
        │   ├── ai/                   # AI plastic detection
        │   ├── qr/                   # QR scanner
        │   ├── awareness/            # Tips & facts
        │   ├── profile/              # User profile
        │   └── gamification/         # Leaderboard
        └── shared/
            └── widgets/              # Reusable UI components
```

---

## 5. API Quick Reference

### Authentication

```bash
# Register
POST /api/auth/register
{"email":"user@example.com","displayName":"John","password":"password123"}

# Login
POST /api/auth/login
{"email":"user@example.com","password":"password123"}

# Refresh token
POST /api/auth/refresh
{"refreshToken":"<refresh_token>"}
```

### Plastic Usage

```bash
# Log usage
POST /api/usage
Authorization: Bearer <token>
{"itemCategory":"bottle","quantity":3}

# Get daily stats
GET /api/usage/stats/daily?date=2024-03-15

# Get weekly stats
GET /api/usage/stats/weekly?year=2024&week=11

# Get reduction %
GET /api/usage/stats/reduction?period=week&ref=2024-W11
```

### Waste Reports

```bash
# Submit report (multipart)
POST /api/reports
Content-Type: multipart/form-data
image=<file>&latitude=12.9716&longitude=77.5946&description=Plastic bottles

# Get heatmap data
GET /api/reports/heatmap

# Admin: approve report
PATCH /api/reports/1/approve
```

### Events

```bash
# List events
GET /api/events

# Create event
POST /api/events
{"title":"Beach Cleanup","locationName":"Juhu Beach","latitude":19.0948,
 "longitude":72.8258,"eventDatetime":"2024-04-15T09:00:00Z"}

# Register for event
POST /api/events/1/register
```

### QR Tracking

```bash
# Admin: generate QR
POST /api/qr/generate?entityType=BIN&entityId=BIN-001

# Submit scan
POST /api/qr/scan
{"qrPayload":"BIN:BIN-001:uuid-token","latitude":12.9716,"longitude":77.5946}
```

### Gamification

```bash
# Get profile + points + badges
GET /api/users/me

# Get leaderboard
GET /api/users/leaderboard
```

---

## 6. Points System

| Action | Points |
|--------|--------|
| Log plastic usage | +5 |
| Waste report approved | +10 |
| Attend completed event | +20 |
| Scan QR code | +5 |

## 7. Badge Thresholds

| Badge | Threshold |
|-------|-----------|
| Eco Beginner | 50 points |
| Plastic Warrior | 200 points |
| Community Champion | 500 points |
| Participant | First completed event |

---

## 8. Troubleshooting

**Backend won't start**
- Check MySQL is running: `mysql -u root -p`
- Verify DB credentials in `application.yml`
- Check port 8080 is free: `netstat -an | grep 8080`

**Flutter can't connect to backend**
- Ensure backend is running
- Check `baseUrl` in `api_constants.dart` matches your setup
- For Android emulator, use `10.0.2.2` not `localhost`
- Ensure `android:usesCleartextTraffic="true"` is in AndroidManifest.xml for HTTP

**Google Maps not showing**
- Verify API key is correct and Maps SDK is enabled
- Check billing is enabled on Google Cloud project

**TFLite model not loading**
- Ensure model file is at `assets/models/plastic_detection.tflite`
- Verify `pubspec.yaml` includes the assets path
- Run `flutter pub get` after adding the model
