#!/usr/bin/env bash
set -o errexit

(
  git clone https://github.com/flutter/flutter.git /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"

  flutter config --enable-web
  flutter precache --web
  flutter pub get
  flutter build web --release
)
