#!/bin/sh
# Captures the four tour screens from the iOS app in the simulator, light and dark,
# and writes them as AVIF + WebP to assets/screens/<lang>/.
#
#   scripts/capture-screens.sh fr      # or: en (once the app has an English UI)
#
# Needs Xcode, ../reliure-ios, and cwebp + avifenc (brew install webp libavif).
set -eu

LANG_CODE=${1:?usage: $0 fr|en}
case "$LANG_CODE" in
  fr) LOCALE=fr_CA ;;
  en) LOCALE=en_CA ;;
  *) echo "unknown language: $LANG_CODE" >&2; exit 1 ;;
esac

SITE=$(cd "$(dirname "$0")/.." && pwd)
IOS=${IOS_REPO:-$SITE/../reliure-ios}
DEVICE=${DEVICE:-iPhone 17 Pro}
BUNDLE=ca.wibeset.Reliure
OUT=$SITE/assets/screens/$LANG_CODE
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

xcodebuild -project "$IOS/Reliure.xcodeproj" -scheme Reliure -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE" -derivedDataPath "$IOS/build" build -quiet
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl install booted "$IOS/build/Build/Products/Debug-iphonesimulator/Reliure.app"
xcrun simctl status_bar booted override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
trap 'xcrun simctl status_bar booted clear; rm -rf "$TMP"' EXIT

mkdir -p "$OUT"
# Site name → app debug screen ("" is the home screen the app opens on).
for pair in home: update:update add:add statistics:statistics; do
  name=${pair%%:*} screen=${pair#*:}
  for appearance in light dark; do
    suffix=$([ "$appearance" = dark ] && echo -dark || true)
    xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch booted "$BUNDLE" -seedSampleData -inMemoryStore -appearance "$appearance" \
      -AppleLanguages "($LANG_CODE)" -AppleLocale "$LOCALE" ${screen:+-debugScreen "$screen"} >/dev/null
    sleep 5
    xcrun simctl io booted screenshot "$TMP/raw.png" >/dev/null 2>&1
    # 750 px wide covers the phone frame at 2x.
    sips -s format png --resampleWidth 750 "$TMP/raw.png" --out "$TMP/shot.png" >/dev/null
    cwebp -quiet -q 80 -m 6 -sharp_yuv "$TMP/shot.png" -o "$OUT/$name$suffix.webp"
    avifenc -q 60 -s 4 "$TMP/shot.png" "$OUT/$name$suffix.avif" >/dev/null
    echo "$OUT/$name$suffix"
  done
done
xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
