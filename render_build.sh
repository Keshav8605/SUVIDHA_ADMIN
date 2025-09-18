#!/usr/bin/env bash
# exit on error
set -o errexit

# Install Flutter and its dependencies
flutter clean
flutter pub get

# Build the web app in release mode
flutter build web --release