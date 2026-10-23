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

if [ -d /Applications/Xcode.app ]; then
  echo "== swift test (Xcode present)"
  swift test --package-path "$ROOT/NimbusKit"
fi
echo "presubmit: OK"
