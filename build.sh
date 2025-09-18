#!/usr/bin/env bash
# fail on first error
set -o errexit

# Install Flutter
git clone https://github.com/flutter/flutter.git && ./flutter/bin/flutter pub get
export PATH="$PATH:pwd/flutter/bin"

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web
flutter build web --release