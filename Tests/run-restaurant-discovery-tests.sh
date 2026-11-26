#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-discovery-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library Scout/Models/Restaurant.swift Scout/Models/PlaceSearchResult.swift \
 Scout/Models/SavedPlaceMatch.swift Scout/Services/RestaurantDiscoveryState.swift \
 Tests/RestaurantDiscoveryTests.swift -o "$test_dir/discovery-tests"
"$test_dir/discovery-tests"
