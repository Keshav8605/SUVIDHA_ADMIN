#!/usr/bin/env bash
# fail on first error
set -o errexit

# Install Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$(pwd)/flutter/bin:$PATH"

# Initialize Flutter
flutter doctor

# Enable web
flutter config --enable-web

# Get project dependencies
flutter pub get

# Build web release
flutter build web --release
