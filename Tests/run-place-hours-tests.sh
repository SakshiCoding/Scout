#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-hours-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/PlaceContactDetails.swift Scout/Services/PlaceDetailsLoadState.swift \
  Scout/Theme/AtlasTheme.swift Scout/Views/Detail/RestaurantHoursCard.swift \
  Tests/PlaceHoursTests.swift -o "$test_dir/hours-tests"
output_dir="${1:-$test_dir}"
mkdir -p "$output_dir"
"$test_dir/hours-tests" "$output_dir"
