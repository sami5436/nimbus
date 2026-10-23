#!/usr/bin/env bash
# Records docs/demo.mp4 and docs/demo.gif by running the XCUITest demo tour on a simulator.
# Needs Xcode, xcodegen and ffmpeg (brew install xcodegen ffmpeg).
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"
MP4=docs/demo.mp4
GIF=docs/demo.gif
mkdir -p docs

xcodegen generate >/dev/null
UDID=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true

# Build first so recording starts right before the tour, not before compilation.
DEST="platform=iOS Simulator,id=$UDID"
xcodebuild -project Nimbus.xcodeproj -scheme Nimbus -destination "$DEST" build-for-testing -quiet

rm -f "$MP4"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$MP4" &
REC=$!
trap 'kill -INT $REC 2>/dev/null || true' EXIT
sleep 2

xcodebuild -project Nimbus.xcodeproj -scheme Nimbus -destination "$DEST" \
  test-without-building -only-testing:NimbusUITests/NimbusUITests/testDemoTour -quiet

sleep 1
kill -INT "$REC"
wait "$REC" || true
trap - EXIT

# Palette-based GIF, 15 fps, 400 px wide.
ffmpeg -y -loglevel error -i "$MP4" \
  -vf "fps=15,scale=400:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  "$GIF"
ls -lh "$MP4" "$GIF"
