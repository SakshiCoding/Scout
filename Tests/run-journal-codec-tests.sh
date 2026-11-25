#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
fixture_dir="${1:?Pass the directory containing real fixture.jpg/png/heic/heif/mov/mp4/m4v files}"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-codec-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
compile=(xcrun swiftc)
run=("$test_dir/codec-tests")
if [[ "${2:-}" == --simulator ]]; then
  sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
  compile=(xcrun --sdk iphonesimulator swiftc -sdk "$sdk" -target "$(uname -m)-apple-ios17.6-simulator")
  run=(xcrun simctl spawn "${3:?Pass a booted simulator UUID}" "$test_dir/codec-tests")
fi
"${compile[@]}" -parse-as-library Scout/Models/Media.swift Scout/Services/ScoutMediaUploadPolicy.swift \
  Scout/Services/JournalMediaFile.swift Scout/Services/MediaThumbnailRenderer.swift Tests/JournalCodecTests.swift \
  -o "$test_dir/codec-tests"
"${run[@]}" "$fixture_dir"
