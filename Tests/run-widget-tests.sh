#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-widget-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/Restaurant.swift \
  Scout/Models/ScoutWidgetSnapshot.swift \
  Tests/WidgetSnapshotTests.swift \
  -o "$test_dir/widget-tests"
"$test_dir/widget-tests" "$@"
