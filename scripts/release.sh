#!/usr/bin/env bash
#
# Builds a distributable DMG of Look Ma No Hands.
#
# Prerequisites:
#   - xcodegen installed          (brew install xcodegen)
#   - create-dmg installed        (brew install create-dmg)
#   - Models payload populated at LookMaNoHands/Resources/Models/
#     (see scripts/populate-models.sh or the project README)
#
# Output:
#   dist/LookMaNoHands-<version>.dmg
#
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SCHEME="LookMaNoHands"
PROJECT="$ROOT/LookMaNoHands.xcodeproj"
ENTITLEMENTS="$ROOT/LookMaNoHands/Resources/LookMaNoHands.entitlements"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
  "$ROOT/LookMaNoHands/Resources/Info.plist")

BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/LookMaNoHands.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DIST_DIR="$ROOT/dist"
DMG="$DIST_DIR/LookMaNoHands-$VERSION.dmg"

echo "==> Cleaning previous build"
rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_DIR" "$DIST_DIR"

echo "==> Regenerating Xcode project"
xcodegen generate

echo "==> Verifying bundled models are present"
if [[ ! -f "$ROOT/LookMaNoHands/Resources/Models/whisperkit/openai_whisper-base/AudioEncoder.mlmodelc/coremldata.bin" ]]; then
  echo "ERROR: Whisper model missing. Populate LookMaNoHands/Resources/Models/ before running."
  exit 1
fi
if [[ ! -f "$ROOT/LookMaNoHands/Resources/Models/fluidaudio/Models/kokoro/kokoro_21_5s.mlmodelc/coremldata.bin" ]]; then
  echo "ERROR: Kokoro model missing. Populate LookMaNoHands/Resources/Models/ before running."
  exit 1
fi

echo "==> Archiving Release build (ad-hoc signed)"
if command -v xcbeautify >/dev/null 2>&1; then
  FILTER=(xcbeautify --quiet)
else
  FILTER=(cat)
fi
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE" \
  archive \
  CODE_SIGN_IDENTITY=- \
  | "${FILTER[@]}"

echo "==> Exporting .app"
cp -cR "$ARCHIVE/Products/Applications/$SCHEME.app" "$EXPORT_DIR/"

echo "==> Deep re-sign with hardened runtime + entitlements"
# Strip any extended attributes that could invalidate the signature,
# then re-sign every nested bundle with ad-hoc + hardened runtime.
xattr -cr "$EXPORT_DIR/$SCHEME.app"
codesign --force --deep --sign - \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  "$EXPORT_DIR/$SCHEME.app"
codesign --verify --deep --strict --verbose=2 "$EXPORT_DIR/$SCHEME.app"

echo "==> Building DMG"
rm -f "$DMG"
# Stage: app + INSTALL.md, drag-to-/Applications link added by create-dmg.
STAGE="$BUILD_DIR/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -cR "$EXPORT_DIR/$SCHEME.app" "$STAGE/"
cp "$ROOT/INSTALL.md" "$STAGE/"

create-dmg \
  --volname "Look Ma No Hands $VERSION" \
  --window-size 560 380 \
  --icon-size 96 \
  --icon "$SCHEME.app" 130 170 \
  --app-drop-link 420 170 \
  --icon "INSTALL.md" 275 290 \
  --hdiutil-quiet \
  --no-internet-enable \
  "$DMG" \
  "$STAGE/"

echo
echo "Built: $DMG"
du -h "$DMG"
echo
echo "Next: mount the DMG, drag LookMaNoHands.app somewhere else, set quarantine"
echo "      with:  xattr -w com.apple.quarantine \"0081;00000000;Chrome;\" /path/to/LookMaNoHands.app"
echo "      then simulate the first-open Gatekeeper flow before shipping to friends."
