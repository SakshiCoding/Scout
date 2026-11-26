#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-home-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
compile=(xcrun swiftc)
run=("$test_dir/home-tests")
if [[ "${1:-}" == --simulator ]]; then
    simulator="$2"
    shift 2
    sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
    compile=(xcrun --sdk iphonesimulator swiftc -sdk "$sdk" -target "$(uname -m)-apple-ios17.6-simulator")
    run=(xcrun simctl spawn "$simulator" "$test_dir/home-tests")
fi
out="${1:-$test_dir}"
mkdir -p "$out"
# Compile the existing model preview fixtures without the AppState-only helper.
sed '/\/\/ MARK: - AppState preview helper/,$d' 'Scout/Preview Content/MockData.swift' > "$test_dir/MockData.swift"
"${compile[@]}" -parse-as-library Scout/Models/Restaurant.swift Scout/Models/Media.swift Scout/Models/Circle.swift \
 Scout/Models/WishlistSearch.swift Scout/Models/PlacePhoto.swift Scout/Services/WishlistPhotoLoadState.swift \
 Scout/Services/PlacePhotoRequestQueue.swift Scout/Theme/AtlasTheme.swift Scout/Views/Shared/AvatarStack.swift \
 Scout/Views/Wishlist/CompactWishlistPhotoCredit.swift Scout/Views/Wishlist/RestaurantRowView.swift Scout/Views/Wishlist/WishlistTogetherCard.swift \
 "$test_dir/MockData.swift" Tests/WishlistHomeTests.swift -o "$test_dir/home-tests"
"${run[@]}" "$out" "$PWD"
