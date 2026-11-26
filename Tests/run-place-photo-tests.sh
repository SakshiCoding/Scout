#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-photo-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library Scout/Models/PlacePhoto.swift Scout/Services/PlacePhotoLoadState.swift \
    Scout/Theme/AtlasTheme.swift Scout/Views/Detail/RestaurantCoverImage.swift \
    Scout/Views/Detail/PlacePhotoCredits.swift Tests/PlacePhotoTests.swift -o "$test_dir/photo-tests"
"$test_dir/photo-tests" "${1:-$test_dir/photo-cover.png}"
