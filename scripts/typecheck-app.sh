#!/usr/bin/env bash
# Type-checks App/Sources against the macOS SDK and the built NimbusKit modules.
# Stand-in for an iOS build until Xcode is installed. Keep app code cross-platform or guard with #if os(iOS).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
swift build --package-path "$ROOT/NimbusKit" >/dev/null
BIN="$(swift build --package-path "$ROOT/NimbusKit" --show-bin-path)"
swiftc -typecheck -parse-as-library -swift-version 6 \
  -target "$(uname -m)-apple-macos14.0" \
  -sdk "$(xcrun --show-sdk-path)" \
  -I "$BIN/Modules" \
  "$ROOT"/App/Sources/*.swift
echo "typecheck-app: OK"
