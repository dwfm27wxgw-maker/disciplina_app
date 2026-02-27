#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Disciplina · Blindar =="
echo "Repo: $ROOT_DIR"
echo

echo "-> Check: archivos Dart contaminados..."
BAD_PATTERNS='total [0-9]+|drwxr-xr|Try correcting|Pods.xcodeproj|jesusmoralesordas@|BUILD FAILED|Error launching application|Result bundle written to path'
if grep -RIn --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=ios/Pods --exclude-dir=android/.gradle -E "$BAD_PATTERNS" lib >/tmp/disciplina_badgrep.txt 2>/dev/null; then
  echo
  echo "❌ Detectado texto de consola pegado dentro de lib/ (Dart contaminado)."
  echo "   Revisa estos hits:"
  cat /tmp/disciplina_badgrep.txt
  echo
  echo "Solución rápida: abre el archivo y borra todo lo que NO sea Dart (imports/classes)."
  exit 2
else
  echo "✅ OK (no se detecta basura típica)."
fi
echo

echo "-> Check: flutter analyze..."
flutter analyze || true
echo

echo "-> flutter pub get..."
flutter pub get
echo

if [[ -d "ios" ]]; then
  echo "-> iOS: pod install..."
  pushd ios >/dev/null
  pod install
  popd >/dev/null
  echo
fi

MODE="${1:-all}"

case "$MODE" in
  ios)
    echo "-> Build iOS (simulator debug)..."
    flutter build ios --simulator --debug
    ;;
  android)
    echo "-> Build Android (apk debug)..."
    flutter build apk --debug
    ;;
  run-ios)
    UDID="${2:-}"
    if [[ -z "$UDID" ]]; then
      echo "Uso: ./tools/blindar.sh run-ios <UDID>"
      echo "Tip: flutter devices"
      exit 3
    fi
    echo "-> Run iOS (UDID=$UDID)..."
    flutter run -d "$UDID"
    ;;
  run-android)
    DEVICE="${2:-}"
    if [[ -z "$DEVICE" ]]; then
      echo "Uso: ./tools/blindar.sh run-android <DEVICE_ID>"
      echo "Tip: flutter devices"
      exit 3
    fi
    echo "-> Run Android (device=$DEVICE)..."
    flutter run -d "$DEVICE"
    ;;
  all)
    echo "-> Build iOS (simulator debug)..."
    flutter build ios --simulator --debug
    echo
    echo "-> Build Android (apk debug)..."
    flutter build apk --debug
    ;;
  *)
    echo "Modo no reconocido: $MODE"
    echo "Modos: all | ios | android | run-ios <UDID> | run-android <ID>"
    exit 4
    ;;
esac

echo
echo "✅ Blindaje completado."
