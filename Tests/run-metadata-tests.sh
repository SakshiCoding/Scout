#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-metadata-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/Restaurant.swift \
  Scout/Models/SharedRestaurantImport.swift \
  Scout/Services/GeminiService.swift \
  Tests/GeminiMetadataTests.swift \
  -o "$test_dir/metadata-tests"
"$test_dir/metadata-tests"
