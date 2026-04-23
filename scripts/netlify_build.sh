#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter-sdk}"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter --disable-analytics
flutter config --enable-web
flutter pub get
flutter precache --web
flutter build web --release
