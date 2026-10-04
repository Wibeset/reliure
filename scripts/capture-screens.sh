#!/bin/sh
# Captures the six tour screens from the iOS app in the simulator, light and dark,
# and writes them as AVIF + WebP to assets/screens/<lang>/.
#
#   scripts/capture-screens.sh fr      # or: en
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
# A simulator name or UDID; a UDID keeps the capture off a simulator you're using.
DEVICE=${DEVICE:-iPhone 17 Pro}
UDID_PATTERN='[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}'
if echo "$DEVICE" | grep -qxE "$UDID_PATTERN"; then
  UDID=$DEVICE
else
  # "Name (" so « iPhone 17 Pro » doesn't pick « iPhone 17 Pro Max ».
  UDID=$(xcrun simctl list devices available | grep -F "    $DEVICE (" | grep -m1 -oE "$UDID_PATTERN")
fi
BUNDLE=ca.wibeset.Reliure
OUT=$SITE/assets/screens/$LANG_CODE
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

xcodebuild -project "$IOS/Reliure.xcodeproj" -scheme Reliure -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$IOS/build" build -quiet
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl install "$UDID" "$IOS/build/Build/Products/Debug-iphonesimulator/Reliure.app"
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
trap 'xcrun simctl status_bar "$UDID" clear; rm -rf "$TMP"' EXIT

mkdir -p "$OUT"
# A goal the sample library is on track for, so the goal card shows progress rather than an invitation.
GOAL=${GOAL:-3}
# Site name → app debug screen ("" is the home screen the app opens on).
for pair in home: update:update add:add statistics:statistics calendar:calendar share:share; do
  name=${pair%%:*} screen=${pair#*:}
  for appearance in light dark; do
    suffix=$([ "$appearance" = dark ] && echo -dark || true)
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE" -seedSampleData -inMemoryStore \
      -"readingGoal.$(date +%Y)" "$GOAL" -appearance "$appearance" \
      -AppleLanguages "($LANG_CODE)" -AppleLocale "$LOCALE" ${screen:+-debugScreen "$screen"} >/dev/null
    sleep 5
    xcrun simctl io "$UDID" screenshot "$TMP/raw.png" >/dev/null 2>&1
    # 750 px wide covers the phone frame at 2x.
    sips -s format png --resampleWidth 750 "$TMP/raw.png" --out "$TMP/shot.png" >/dev/null
    cwebp -quiet -q 80 -m 6 -sharp_yuv "$TMP/shot.png" -o "$OUT/$name$suffix.webp"
    avifenc -q 60 -s 4 "$TMP/shot.png" "$OUT/$name$suffix.avif" >/dev/null
    echo "$OUT/$name$suffix"
  done
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
