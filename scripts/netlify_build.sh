#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter-sdk}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"

if [ ! -d "${FLUTTER_HOME}/.git" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "${FLUTTER_VERSION}" "${FLUTTER_HOME}"
else
  if ! git -C "${FLUTTER_HOME}" fetch --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}"; then
    git -C "${FLUTTER_HOME}" fetch --depth 1 origin "${FLUTTER_VERSION}"
  fi
  git -C "${FLUTTER_HOME}" checkout --detach "${FLUTTER_VERSION}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter --disable-analytics
flutter config --enable-web
flutter pub get
flutter precache --web
flutter build web --release
