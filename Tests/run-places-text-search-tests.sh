#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-text-search-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library Scout/Models/Restaurant.swift Scout/Models/PlaceSearchResult.swift \
 Scout/Services/PlaceTypeHints.swift Scout/Services/PlacesTextSearchFallback.swift \
 Tests/PlacesTextSearchFallbackTests.swift -o "$test_dir/places-tests"
"$test_dir/places-tests"
