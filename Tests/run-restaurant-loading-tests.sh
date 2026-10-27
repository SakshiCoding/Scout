#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-loading-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/Restaurant.swift Scout/Services/RestaurantEnrichment.swift \
  Scout/AppState/AppState+RestaurantLoading.swift Tests/RestaurantLoadingTests.swift \
  -o "$test_dir/loading-tests"
"$test_dir/loading-tests"
