#!/usr/bin/env bash
# Genera las carpetas de plataforma (android/ios) que faltan y agrega los permisos de iOS.
# flutter create NO sobreescribe los archivos que ya existen (AndroidManifest.xml y MainActivity.kt).
set -e
cd "$(dirname "$0")/.."

flutter create . --project-name finto_flutter --org com.josh --platforms android,ios

PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ] && command -v /usr/libexec/PlistBuddy >/dev/null; then
  add() { /usr/libexec/PlistBuddy -c "Delete :$1" "$PLIST" 2>/dev/null || true
          /usr/libexec/PlistBuddy -c "Add :$1 string $2" "$PLIST"; }
  add NSCameraUsageDescription "Finto usa la cámara para tomar foto de tus tickets."
  add NSPhotoLibraryUsageDescription "Finto usa tus fotos para adjuntar el ticket de un movimiento."
  add NSMicrophoneUsageDescription "Finto usa el micrófono para dictar la nota de un movimiento."
  add NSSpeechRecognitionUsageDescription "Finto convierte tu voz en texto para escribir la nota."
  add NSLocationWhenInUseUsageDescription "Finto guarda dónde registraste cada movimiento para mostrarlo en un mapa."
  add NSFaceIDUsageDescription "Finto usa Face ID para que entres sin escribir tu contraseña."
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Finto" "$PLIST" || true
  echo "Permisos de iOS agregados a $PLIST"
else
  echo "No se encontró PlistBuddy (solo existe en macOS). Copia las claves de tool/ios_permissions_reference.plist a $PLIST a mano."
fi

flutter pub get
echo "Listo. Corre: flutter run"
