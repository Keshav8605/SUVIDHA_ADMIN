#!/usr/bin/env bash
set -o errexit

# Download & install Flutter into the build environment
git clone https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

# Initialize Flutter
flutter doctor

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web release
flutter build web --release
