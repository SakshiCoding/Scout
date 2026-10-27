#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-shortcut-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/Restaurant.swift Scout/Models/WishlistFilter.swift \
  Scout/Models/ScoutDestination.swift Scout/AppState/AppState+Navigation.swift \
  Scout/Intents/ScoutShortcuts.swift Tests/ShortcutTests.swift \
  -o "$test_dir/shortcut-tests"
"$test_dir/shortcut-tests" "$@"
