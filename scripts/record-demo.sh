#!/usr/bin/env bash
# Records docs/demo.mp4 and docs/demo.gif by running the XCUITest demo tour on a simulator.
# Needs Xcode, xcodegen and ffmpeg (brew install xcodegen ffmpeg).
set -euo pipefail
cd "$(dirname "$0")/.."

MP4=docs/demo.mp4
GIF=docs/demo.gif
mkdir -p docs

xcodegen generate >/dev/null
# A dedicated simulator keeps the recording clean and clear of other test runs.
DEVICE_NAME="Nimbus Demo"
UDID=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' || true)
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl create "$DEVICE_NAME" "iPhone 17 Pro")
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true

xcrun simctl privacy "$UDID" grant location com.sami5436.nimbus 2>/dev/null || true

# Build first so recording starts right before the tour, not before compilation.
DEST="platform=iOS Simulator,id=$UDID"
xcodebuild -project Nimbus.xcodeproj -scheme NimbusDemo -destination "$DEST" build-for-testing -quiet

TMP=$(mktemp -d)
RAW="$TMP/demo.mp4"
READY=/tmp/nimbus-demo-ready  # fixed path: the test writes it
REC=""
# Always stop the recorder and remove temp files, on success or failure.
trap '[ -z "$REC" ] || kill -INT "$REC" 2>/dev/null || true; rm -rf "$TMP" "$READY"' EXIT
rm -f "$READY"

# The test drops $READY once the forecast is on screen; recording starts then, so launch time is skipped.
xcodebuild -project Nimbus.xcodeproj -scheme NimbusDemo -destination "$DEST" \
  test-without-building -only-testing:NimbusUITests/NimbusUITests/testDemoTour -quiet &
TEST=$!
while [ ! -e "$READY" ]; do
  kill -0 "$TEST" 2>/dev/null || { wait "$TEST"; exit 1; }
  sleep 0.2
done
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$RAW" &
REC=$!

TEST_STATUS=0
wait "$TEST" || TEST_STATUS=$?
kill -INT "$REC"
wait "$REC" || true
REC=""
[ "$TEST_STATUS" -eq 0 ] || exit "$TEST_STATUS"

# Drop the last 2 s (the app has quit by then) and shrink the capture to keep the MP4 small.
LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAW")
ffmpeg -y -loglevel error -i "$RAW" -t "$(awk -v l="$LEN" 'BEGIN { print l - 2 }')" -vf "scale=590:-2" -c:v libx264 -crf 28 -preset slow -pix_fmt yuv420p -movflags +faststart "$MP4"

# Palette-based GIF, 10 fps, 400 px wide.
ffmpeg -y -loglevel error -i "$MP4" \
  -vf "fps=10,scale=400:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=64[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
  "$GIF"
ls -lh "$MP4" "$GIF"
