#!/usr/bin/env bash
set -o errexit

# Download & install Flutter into the build environment
git clone https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

# Pre-cache Flutter artifacts for web
flutter config --enable-web
flutter precache --web

# Get project dependencies
flutter pub get

# Build web release
flutter build web --release
