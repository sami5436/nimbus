#!/usr/bin/env bash
# Presubmit for Nimbus. Must pass before any PR. Exits non-zero on the first failure.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== swift build"
swift build --package-path "$ROOT/NimbusKit"

echo "== self-check"
swift run --package-path "$ROOT/NimbusKit" NimbusSelfCheck

echo "== app typecheck"
"$ROOT/scripts/typecheck-app.sh"

echo "== no em dashes"
if grep -rn $'\xe2\x80\x94' "$ROOT" --include='*.swift' --include='*.md' --include='*.yml' \
    --exclude-dir=.build --exclude-dir=.git; then
  echo "Em dash found. Use a colon, comma or parentheses instead." >&2
  exit 1
fi

# `swift test` needs XCTest and Swift Testing, which Command Line Tools alone do not ship.
if xcrun --find xctest >/dev/null 2>&1; then
  echo "== swift test"
  swift test --package-path "$ROOT/NimbusKit"
else
  echo "== swift test (skipped: no Xcode toolchain active)"
fi
echo "presubmit: OK"
