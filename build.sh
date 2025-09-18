#!/usr/bin/env bash
set -o errexit

# Install Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$(pwd)/flutter/bin:$PATH"

# Initialize Flutter (downloads artifacts)
flutter doctor

# Enable web
flutter config --enable-web

# Get project dependencies
flutter pub get

# Build web release
flutter build web --release
