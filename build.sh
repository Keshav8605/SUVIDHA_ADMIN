#!/usr/bin/env bash
set -o errexit

# Download Flutter
git clone https://github.com/flutter/flutter.git /tmp/flutter

# Pre-cache Flutter for web
/tmp/flutter/bin/flutter config --enable-web
/tmp/flutter/bin/flutter precache --web

# Get dependencies
/tmp/flutter/bin/flutter pub get

# Build web release
/tmp/flutter/bin/flutter build web --release
