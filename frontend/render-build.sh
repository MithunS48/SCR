#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
export PATH="$PATH:/opt/flutter/bin"

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web
flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL:-https://plasticwatch-backend.onrender.com/api}
