#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-cover-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
compile_command=(xcrun swiftc)
run_command=("$test_dir/cover-tests")
if [[ "${1:-}" == "--simulator" ]]; then
  simulator_id="$2"
  shift 2
  simulator_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
  simulator_arch=$(uname -m)
  compile_command=(xcrun --sdk iphonesimulator swiftc -sdk "$simulator_sdk" -target "$simulator_arch-apple-ios17.6-simulator")
  run_command=(xcrun simctl spawn "$simulator_id" "$test_dir/cover-tests")
fi
"${compile_command[@]}" -parse-as-library \
  Scout/Models/Media.swift Scout/Models/RestaurantJournalCover.swift \
  Scout/Services/MediaThumbnailRenderer.swift Scout/Services/MediaThumbnailStore.swift \
  Scout/Services/RestaurantCoverLoadState.swift Scout/Theme/AtlasTheme.swift \
  Scout/Views/Detail/RestaurantCoverImage.swift Tests/RestaurantCoverTests.swift \
  -o "$test_dir/cover-tests"
output_dir="${1:-$test_dir}"
mkdir -p "$output_dir"
"${run_command[@]}" "$output_dir" "${2:-}"
